import {BigNumber} from "ethers";
import { getRandomBigNumber,modPower } from "./Math";
  
export function generateKeyPair(g: BigNumber, q: BigNumber, p: BigNumber): { pubKey: BigNumber, privKey: BigNumber } {
    const privKey: BigNumber = getRandomBigNumber(q);
    const pubKey: BigNumber = modPower(g, privKey, p);
    return { pubKey, privKey };
}