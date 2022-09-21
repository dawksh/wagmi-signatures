import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const config: HardhatUserConfig = {
	solidity: "0.8.13",
	networks: {
		mumbai: {
			url: process.env.URL,
			accounts: [process.env.PRIVATE_KEY as string],
		},
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN,
	},
};

export default config;
