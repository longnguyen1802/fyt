import {BigNumber} from 'ethers';

export const p: BigNumber = BigNumber.from(
  '115792089237316195423570985008687907852837564279074904382605163141518161494337',
);
export const q: BigNumber = BigNumber.from('341948486974166000522343609283189');
export const g: BigNumber = BigNumber.from(
  '3382179820063921351711459720945002840687054300606715993250688069077934439078',
);
export const numeParentFee: BigNumber = BigNumber.from(1);
export const demoParentFee: BigNumber = BigNumber.from(2);
export const protocolFee: BigNumber = BigNumber.from(100);
export const joinFee: BigNumber = BigNumber.from(100000);
export const signerDepositFee: BigNumber = BigNumber.from(100000);
export const deploymenLength: number = 7 * 70; // 700 block a day
export const roundLong: number = 120;
export const referPhaseLength = 40;
export const moneyPhaseLength = 30;
export const networkUrls: {[key: string]: string} = {
  ganache: 'http://localhost:8545',
  ganachecli: 'http://localhost:7545',
};
