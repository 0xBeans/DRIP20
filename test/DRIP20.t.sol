// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/Test.sol";
import {MockDRIP20} from "./mocks/MockDRIP20.sol";
import {DRIP20} from "../src/DRIP20.sol";

interface Vm {
    function prank(address) external;

    function startPrank(address) external;

    function startPrank(address, address) external;

    function stopPrank() external;

    function roll(uint256) external;

    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;

    function expectEmit(
        bool,
        bool,
        bool,
        bool
    ) external;
}

contract DRIP20Test is DSTest {
    MockDRIP20 token;

    address user1;
    address user2;
    address user3;

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function setUp() public {
        token = new MockDRIP20("MOCK", "MOCK", 18, 10); // token emission is 10 per block
        user1 = address(0xaa);
        user2 = address(0xbb);
        user3 = address(0xcc);
    }

    function testMint() public {
        vm.startPrank(user1);
        token.mint(1e18);
        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(user1), 1e18);
    }

    function testSimpleBurn() public {
        vm.startPrank(user1);
        token.mint(1e18);
        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(user1), 1e18);

        token.burn(user1, 0.5e18);
        assertEq(token.totalSupply(), 1e18 - 0.5e18);
        assertEq(token.balanceOf(user1), 1e18 - 0.5e18);
    }

    function testSimpleTransfer() public {
        vm.startPrank(user1);
        token.mint(1e18);
        token.transfer(user2, 0.5e18);

        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(user2), 0.5e18);
        assertEq(token.balanceOf(user1), 1e18 - 0.5e18);
    }

    function testSimpleTransferFrom() public {
        vm.startPrank(user1);
        token.mint(1e18);
        token.approve(address(this), type(uint256).max);
        vm.stopPrank();

        token.transferFrom(user1, user2, 0.5e18);

        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(user2), 0.5e18);
        assertEq(token.balanceOf(user1), 1e18 - 0.5e18);
    }

    function testDripSingleUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);

        // check event is emitted
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), user1, 0);

        token.startDripping(user1);

        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(user1), 0);

        // should accumulate 4 * 10 tokens
        vm.roll(5);

        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);
    }

    function testDripMultiUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        vm.roll(5);

        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);

        token.startDripping(user2);
        token.startDripping(user3);

        // nothing should change since we didnt roll blocks
        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);
        assertEq(token.balanceOf(user2), 0);
        assertEq(token.balanceOf(user3), 0);

        // roll 5 blocks, each user should've accrued 50 tokens
        vm.roll(10);

        assertEq(token.totalSupply(), 40 + 50 * 3);
        assertEq(token.balanceOf(user1), 40 + 50);
        assertEq(token.balanceOf(user2), 50);
        assertEq(token.balanceOf(user3), 50);
    }

    function testStopDripSingleUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        vm.roll(5);

        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);

        token.stopDripping(user1);

        // nothing should change since we didnt roll blocks
        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);

        // roll 5 blocks, no changes should occur
        vm.roll(10);

        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);
    }

    function testStopDripMultiUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        token.startDripping(user2);
        token.startDripping(user3);
        vm.roll(5);

        assertEq(token.totalSupply(), 40 * 3);
        assertEq(token.balanceOf(user1), 40);
        assertEq(token.balanceOf(user2), 40);
        assertEq(token.balanceOf(user3), 40);

        token.stopDripping(user1);
        token.stopDripping(user2);

        // nothing should change since we didnt roll blocks
        assertEq(token.totalSupply(), 40 * 3);
        assertEq(token.balanceOf(user1), 40);
        assertEq(token.balanceOf(user2), 40);
        assertEq(token.balanceOf(user3), 40);

        // roll 5 blocks, only user 3 should accrue 50 tokens
        vm.roll(10);

        assertEq(token.totalSupply(), 120 + 50);
        assertEq(token.balanceOf(user1), 40);
        assertEq(token.balanceOf(user2), 40);
        assertEq(token.balanceOf(user3), 40 + 50);
    }

    function testTransferFromDrippingUserToNonDrippingUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        vm.roll(5);

        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);

        vm.prank(user1);
        token.transfer(user2, 20);

        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 20);
        assertEq(token.balanceOf(user2), 20);

        // roll 5 blocks, user1 should've accrued 50 tokens
        vm.roll(10);

        assertEq(token.totalSupply(), 40 + 50);
        assertEq(token.balanceOf(user1), 20 + 50);
        assertEq(token.balanceOf(user2), 20);
    }

    function testTransferFromDrippingUserToDrippingUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        token.startDripping(user2);
        vm.roll(5);

        assertEq(token.totalSupply(), 80);
        assertEq(token.balanceOf(user1), 40);
        assertEq(token.balanceOf(user2), 40);

        vm.prank(user1);
        token.transfer(user2, 20);

        assertEq(token.totalSupply(), 80);
        assertEq(token.balanceOf(user1), 40 - 20);
        assertEq(token.balanceOf(user2), 40 + 20);

        // roll 5 blocks, user1 and 2 should've accrued 50 tokens
        vm.roll(10);

        assertEq(token.totalSupply(), 80 + 50 * 2);
        assertEq(token.balanceOf(user1), 20 + 50);
        assertEq(token.balanceOf(user2), 60 + 50);
    }

    function testTransferFromNonDrippingUserToDrippingUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        vm.roll(5);

        vm.prank(user2);
        token.mint(100);

        assertEq(token.totalSupply(), 140);
        assertEq(token.balanceOf(user1), 40);
        assertEq(token.balanceOf(user2), 100);

        vm.prank(user2);
        token.transfer(user1, 50);

        assertEq(token.totalSupply(), 140);
        assertEq(token.balanceOf(user1), 40 + 50);
        assertEq(token.balanceOf(user2), 100 - 50);

        // roll 5 blocks, user1 should've accrued 50 tokens
        vm.roll(10);

        assertEq(token.totalSupply(), 140 + 50);
        assertEq(token.balanceOf(user1), 90 + 50);
        assertEq(token.balanceOf(user2), 50);
    }

    function testBurnFromDrippingUser() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        vm.roll(5);

        assertEq(token.totalSupply(), 40);
        assertEq(token.balanceOf(user1), 40);

        token.burn(user1, 40);

        // nothing should change since we didnt roll blocks
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(user1), 0);

        // roll 5 blocks, no changes should occur
        vm.roll(10);

        assertEq(token.totalSupply(), 50);
        assertEq(token.balanceOf(user1), 50);
    }

    function testRevertTransferMoreThanBalance() public {
        vm.startPrank(user1);
        token.mint(40);

        vm.expectRevert(stdError.arithmeticError);
        token.transfer(user2, 50);
    }

    function testRevertBurnMoreThanBalance() public {
        vm.startPrank(user1);
        token.mint(40);

        vm.expectRevert(stdError.arithmeticError);
        token.burn(user1, 50);
    }

    function testRevertStartDrip() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        token.startDripping(user1);
        vm.expectRevert(DRIP20.UserAlreadyAccruing.selector);
        token.startDripping(user1);
    }

    function testRevertStopDrip() public {
        // need to start on a non zero block number since we use block 0 as 'not dripping'
        vm.roll(1);
        vm.expectRevert(DRIP20.UserNotAccruing.selector);
        token.stopDripping(user1);
    }
}
