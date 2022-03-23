import { expect } from "chai";
import { ethers, network, waffle } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { EthStaking } from "../typechain";

const provider = waffle.provider;

describe("EthStaking Test", function () {
    let deployer : SignerWithAddress;
    let accounts : SignerWithAddress[];
    let ethStaking : EthStaking;
    
    before(async () => {
        [deployer, ...accounts] = await ethers.getSigners();

        const EthStaking = await ethers.getContractFactory("EthStaking");
        ethStaking = await EthStaking.deploy();
        await ethStaking.deployed();

        console.log("EthStaking deployed at ", ethStaking.address);
    });
    
    it("Deposit and Withdraw with rewards", async function() {
        await ethStaking.depositRewards(86400 * 30, {value:ethers.utils.parseEther("200")});

        console.log("Before deposit, ETH balance: ", await accounts[0].getBalance());
        await ethStaking.connect(accounts[0]).deposit({value:ethers.utils.parseEther("100")});
        await ethStaking.connect(accounts[1]).deposit({value:ethers.utils.parseEther("300")});
        console.log("Balance of account0 after deposit : ", await accounts[0].getBalance());
        console.log("Balance of account1 after deposit : ", await accounts[1].getBalance());
        console.log("ETH held in EthStaking contract : ", await provider.getBalance(ethStaking.address));
        
        await network.provider.send("evm_increaseTime", [86400 * 30]);
        await network.provider.send("evm_mine");

        console.log("Pending Rewards of Account0: ", await ethStaking.pendingRewards(accounts[0].address));
        console.log("Pending Rewards of Account1: ", await ethStaking.pendingRewards(accounts[1].address));

        await ethStaking.connect(accounts[0]).withdraw();
        console.log("ETH held in EthStaking contract after withdraw of account0 : ", await provider.getBalance(ethStaking.address));
        await ethStaking.connect(accounts[1]).withdraw();
        console.log("ETH held in EthStaking contract after withdraw of account1 : ", await provider.getBalance(ethStaking.address));

        console.log("Balance of Account0 after withdraw : ", await accounts[0].getBalance());
        console.log("Balance of Account1 after withdraw : ", await accounts[1].getBalance());
    });
});