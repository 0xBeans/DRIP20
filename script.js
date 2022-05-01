// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// const hre = require("hardhat");

// async function main() {
//   // Hardhat always runs the compile task when running scripts with its command
//   // line interface.
//   //
//   // If this script is run directly using `node` you may want to call compile
//   // manually to make sure everything is compiled
//   // await hre.run('compile');

//   // We get the contract to deploy
//   const Greeter = await hre.ethers.getContractFactory("Greeter");
//   const greeter = await Greeter.deploy("Hello, Hardhat!");

//   await greeter.deployed();

//   console.log("Greeter deployed to:", greeter.address);
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });

const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // const Token = await ethers.getContractFactory("TheHungryGames");
  // const token = await Token.deploy();

  const Pixelmon = await ethers.getContractFactory("Test20");
  // const Tubbies = await ethers.getContractFactory("Tubbies");

  const pixelmon = await Pixelmon.deploy("DRIP","DRIP",18,'250000000000000000');
  // const tubbies = await Tubbies.deploy();

  // let data = {
  //   address: tubbiesSweeper.address,
  //   abi: JSON.parse(tubbiesSweeper.interface.format("json")),
  // };
  // fs.writeFileSync("frontend/src/tubbiesSweeper.json", JSON.stringify(data));

  // data = {
  //   address: tubbiesSweeperFactory.address,
  //   abi: JSON.parse(tubbiesSweeperFactory.interface.format("json")),
  // };
  // fs.writeFileSync(
  //   "frontend/src/tubbiesSweeperFactory.json",
  //   JSON.stringify(data)
  // );

  // data = {
  //   address: tubbies.address,
  //   abi: JSON.parse(tubbies.interface.format('json'))
  // };
  // fs.writeFileSync('frontend/src/tubbies.json', JSON.stringify(data));

  console.log("pixelmon address:", pixelmon.address);
  // console.log("tubbies address:", wrapped.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
