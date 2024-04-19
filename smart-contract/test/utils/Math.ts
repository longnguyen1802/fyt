import {ethers} from "hardhat";
import {BigNumber} from "ethers";

export function modPower(base: BigNumber, exponent: BigNumber, modulus: BigNumber): BigNumber {
    let result: BigNumber = BigNumber.from(1);
    base = base.mod(modulus);
    while (exponent.gt(BigNumber.from(0))) {
      if (exponent.mod(2).eq(BigNumber.from(1))) {
        result = result.mul(base).mod(modulus);
      }
      exponent = exponent.div(2);
      base = base.mul(base).mod(modulus);
    }
    return result;
  }
  
  export function gcd(a: BigNumber, b: BigNumber): BigNumber {
    // Convert the inputs to BigNumber
    let aBN: BigNumber = BigNumber.from(a.toString());
    let bBN: BigNumber = BigNumber.from(b.toString());
  
    // Implement the Euclidean algorithm to find the GCD
    while (!bBN.isZero()) {
      const temp: BigNumber = bBN;
      bBN = aBN.mod(bBN);
      aBN = temp;
    }
  
    return aBN;
  }
  
  export function getRandomBigNumber(max: BigNumber): BigNumber {
    return ethers.BigNumber.from(ethers.utils.randomBytes(32)).mod(max);
  }

  export function getRandomRelativePrime(max: BigNumber, moduloNumber: BigNumber): BigNumber {
    let number: BigNumber = getRandomBigNumber(max);
    let subMod: BigNumber = moduloNumber.mod(number);
    while (!gcd(number, subMod).eq(BigNumber.from(1))) {
      number = getRandomBigNumber(max);
      subMod = moduloNumber.mod(number);
    }
    return number;
  }