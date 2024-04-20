import { ethers } from 'hardhat';
import { network } from 'hardhat';
import { time } from "@nomicfoundation/hardhat-network-helpers";

const ganacheProvider = new ethers.providers.JsonRpcProvider('http://localhost:8545');

// Function to mine a specified number of blocks
export async function mineBlocks(numberOfBlocks: number): Promise<void> {
    for (let i = 0; i < numberOfBlocks; i++) {
        await network.provider.send("evm_mine");
    }
}

// Get the current block number
export async function getCurrentBlockNumber(): Promise<number> {
    if(network.name == "ganache"){
        let currentBlockNumber = await ganacheProvider.getBlockNumber();
        return currentBlockNumber;
    }
    else{
        let currentBlockNumber = await ethers.provider.getBlockNumber();
        return currentBlockNumber;
    }
    
}

// Advance block to a specific number
export async function advanceBlockTo(targetBlockNumber: number): Promise<void> {
    if(network.name=="ganache"){
        const currentBlock = await getCurrentBlockNumber();
        if (targetBlockNumber < currentBlock) {
            throw new Error(`Target block number (${targetBlockNumber}) is in the past`);
        }

        const blocksToMine = targetBlockNumber - currentBlock;
        await mineBlocks(blocksToMine);
    }
    else{
        //const currentBlock = await getCurrentBlockNumber();
        await time.advanceBlockTo(targetBlockNumber);
    }
    
}
