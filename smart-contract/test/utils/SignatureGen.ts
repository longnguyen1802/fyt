import { getRandomRelativePrime } from "./Math";
import {BigNumber} from "ethers";
import { Cryptography } from "../../typechain-types";
export async function generateElgamaSignature(cryptography:Cryptography, message:BigNumber, prikey:BigNumber, p:BigNumber, q:BigNumber) {
    const nonce = getRandomRelativePrime(q, p.sub(1));
    const [r, s] = await cryptography.generateElgamaSignature(
      nonce,
      message,
      prikey,
    );
    return { r, s };
  }