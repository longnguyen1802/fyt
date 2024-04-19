import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber,Signer } from "ethers";
import { MemberAccount,Protocol } from "../typechain-types";
import { setupProtocol} from "./helpers/setup";

describe("Deployment", () => {
  // Constant just for testing
  const protocolFee: BigNumber = BigNumber.from(100);
  const deploymenLength: number = 7 * 700; // 7000 block a day

  describe("Deployment State", () => {
    let protocol: Protocol;
    let account1: MemberAccount;
    let account2: MemberAccount;
    let account3: MemberAccount;
    let user1: Signer;
    let user2: Signer;
    let user3: Signer;

    before(async () => {
      const { protocol: p, account1: a1, account2: a2, account3: a3, user1: u1, user2: u2, user3: u3 } = await setupProtocol();
      protocol = p;
      account1 = a1;
      account2 = a2;
      account3 = a3;
      user1 = u1;
      user2 = u2;
      user3 = u3;

      // Register initial members
      await account1.connect(user1).registerInitialMember(protocolFee, { value: protocolFee });
      await account2.connect(user2).registerInitialMember(protocolFee, { value: protocolFee });
      await account3.connect(user3).registerInitialMember(protocolFee, { value: protocolFee });

      // Advance blocks to simulate deployment completion
      const currentBlockNumber: number = await ethers.provider.getBlockNumber();
      await time.advanceBlockTo(currentBlockNumber + deploymenLength);
    });

    it("closeDeployment and check state", async () => {
      await protocol.closeDeploymentState();
      const numMem: BigNumber = await protocol.numberMember();
      expect(numMem.toString()).to.eq("3");
    });

    it("Start new round", async () => {
      // Start a new round
      await expect(protocol.startNewRound()).not.to.be.reverted;
    });
  });
});