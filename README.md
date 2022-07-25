# DRIP20

This is an lightweight ERC20 implementation that supports token dripping(streaming). Rather than wallets `claiming` tokens, tokens will `drip` into desired wallets at an emission rate accrued per block.

TLDR; Calculates a wallet's balance based on emission rate and the block num a wallet starts accruing at. Token balances of accuring wallets will increase every block.

I foresee this being the most useful in games and certain NFT projects.

## Installation / setup

If using Foundry: `forge install 0xBeans/DRIP20` 

Else: git clone this repo.

## Contracts

DRIP20.sol - ERC20 implementation that supports dripping. 

- Must define `_emissionRatePerBlock` which determines how many tokens will be dripped into each wallet per block. This value is immutable after intialization.
- `_startDripping(address)` and `_stopDripping(address)` add and remove wallets respectively.

GIGADRIP20.sol - Modification of `DRIP20.sol` that allows wallets to receive larger emissions based on a `multiplier`.

- Same constructor args as `DRIP20.sol`
- `_startDripping(address, multiplier)` and `_stopDripping(address, , multiplier)` increase and decrease a wallets emissions respectively.
  
  -  All wallets start off with `multiplier == 0` (not receiving any token drips). Example: `_startDripping(newWallet, 1)` will increase `newWallet` multiplier to `1`, meaning it will receive drips at the `_emissionRatePerBlock`. A second txn of `_startDripping(newWallet, 3)` will add `3` to its emission rate, so now `newWallet` will have `4 * _emissionRatePerBlock` dripped into its wallet per block.
  - Same thing happens for `_stopDripping(address, multiplier)`, but it decreases a wallets multiplier until it goes back to 0 (no drips).

For NFT projects, you can override ERC721 transfer() to call `_startDripping()` and `_stopDripping()` appropriately.

## Example Use Cases

`DRIP20.sol` - Any project that is currently yielding tokens for their users - but rather than having users `claim`, it can directly be dripped into their wallets.

`GIGADRIP20.sol` - NFT projects or games where each NFT yields certain amount of tokens per set time. For example, let's say `Project A` releases 10k PFPs, and each PFP earns 5 `$ATokens` per day. If a wallet has 10 PFPs, they would need to earn 5 * 10 `ATokens` per day. Rather than have the wallet claim `$ATokens` every so often, these tokens can be dripped into the wallet. For GIGADRIP20, this wallet's `multiplier` would be 5 (or however many PFPs they own) and the emission rate per block would sum up to 5 tokens a day.

## Gas usage

[Here is a repo benchmarking OpenZeppelin's ERC20 implementation.](https://github.com/alephao/solidity-benchmarks/blob/main/ERC20.md)

Both `DRIP20.sol` and `GIGADRIP20.sol` are very comparable in gas usage, in some scenarios even cheaper.

Check out the report in `gas-report.txt`


## Security

This is an experimental implementation of ERC20 and has not received a professional audit. I promise no security guarantees and will not be liable for any issues.

## Testing

I use [Foundry](https://github.com/foundry-rs/foundry).

## Caveats

This is the base implementation of ERC20 tokens that support dripping. So, these are things you should know:

Since token dripping per block does not emit any events, token indexers such as Etherscan may not show the correct holder balances. We emit a transfer event when an address begins dripping, however, transfer events to update balances don't get emitted until an explicit transfer happens. Thus, token indexers will show the correct # of holders but balances of each holder will be a lower bound. Other rebasing tokens face this issue as well (maybe this will get fixed once indexers don't solely rely on events).

There is no `maxSupply` or global `stopDripping` function. I initially designed this for a game where the game economy continues to grow and inflate. Think about Maplestory or Axie Infinity, their in-game currency doesn't have a `maxSupply` because that would stunt game growth and worsen playability (nor does it plan to prevent wallets from earning in the future). The economy just continues to grow and inflate as they add users.

Also, because this is a `base` implementation, I believe the implementing contract should define the logic for `maxSupply` or the logic for stopping emissions completely. Similarly to OpenZeppelin's base ERC20 implementation, it doesn't specify a `maxSupply` and it's on the implementing contract to add this logic if desired. Tbh, You could probably write some cool functions to stop wallet streaming (since you get gas refunds on this since you're clearing storage).

## Shoutouts

T11s and [Solmate](https://github.com/Rari-Capital/solmate) for the slim ERC20 implementation.
[Superfluid](https://github.com/superfluid-finance) and [Proof of Humanity](https://www.proofofhumanity.id/) for the token dripping inspiration.

## Contributions

Feel free to submit a PR for anything

## Todo

- Potentially add EIP-2612.
- Potentially have mutable emissions - would need to be careful about totalSupply() calculations and ensure proper emission block calculations.
- Potentially write extensions with `maxSupply` and emission stoppage functionality.
