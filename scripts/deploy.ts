import { ethers } from "hardhat";
require("dotenv").config();

async function main() {
	const WAGMI = await ethers.getContractFactory("WAGMI");
	const lock = await WAGMI.deploy(
		"0xABB70f7F39035586Da57B3c8136035f87AC0d2Aa",
		1,
		process.env.ACTION_ID as string
	);

	await lock.deployed();

	console.log(`Wagmi deployed to ${lock.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
