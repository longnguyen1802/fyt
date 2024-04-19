/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export interface IMoneyMixerInterface extends utils.Interface {
  functions: {
    "doValidityCheck()": FunctionFragment;
    "getSendMessageIndex(address,uint256)": FunctionFragment;
    "moveToReceivePhase()": FunctionFragment;
    "moveToSignPhase()": FunctionFragment;
    "moveToValidityCheckPhase()": FunctionFragment;
    "recordReceiveTransaction(address,uint256,uint256,uint256,uint256,uint256,uint256)": FunctionFragment;
    "recordSendSignature(address,uint256,uint256)": FunctionFragment;
    "recordSendTransaction(address,uint256,uint256)": FunctionFragment;
    "resetPhaseControl()": FunctionFragment;
    "spendReceiveTransactionMoney(address,uint256)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "doValidityCheck"
      | "getSendMessageIndex"
      | "moveToReceivePhase"
      | "moveToSignPhase"
      | "moveToValidityCheckPhase"
      | "recordReceiveTransaction"
      | "recordSendSignature"
      | "recordSendTransaction"
      | "resetPhaseControl"
      | "spendReceiveTransactionMoney"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "doValidityCheck",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getSendMessageIndex",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "moveToReceivePhase",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "moveToSignPhase",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "moveToValidityCheckPhase",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "recordReceiveTransaction",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "recordSendSignature",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "recordSendTransaction",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "resetPhaseControl",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "spendReceiveTransactionMoney",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;

  decodeFunctionResult(
    functionFragment: "doValidityCheck",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getSendMessageIndex",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "moveToReceivePhase",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "moveToSignPhase",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "moveToValidityCheckPhase",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "recordReceiveTransaction",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "recordSendSignature",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "recordSendTransaction",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "resetPhaseControl",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "spendReceiveTransactionMoney",
    data: BytesLike
  ): Result;

  events: {};
}

export interface IMoneyMixer extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IMoneyMixerInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    doValidityCheck(overrides?: CallOverrides): Promise<[void]>;

    getSendMessageIndex(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    moveToReceivePhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    moveToSignPhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    moveToValidityCheckPhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    recordReceiveTransaction(
      account: PromiseOrValue<string>,
      money: PromiseOrValue<BigNumberish>,
      rho: PromiseOrValue<BigNumberish>,
      delta: PromiseOrValue<BigNumberish>,
      omega: PromiseOrValue<BigNumberish>,
      sigma: PromiseOrValue<BigNumberish>,
      signerPubKey: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    recordSendSignature(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    recordSendTransaction(
      account: PromiseOrValue<string>,
      index: PromiseOrValue<BigNumberish>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    resetPhaseControl(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    spendReceiveTransactionMoney(
      account: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  doValidityCheck(overrides?: CallOverrides): Promise<void>;

  getSendMessageIndex(
    account: PromiseOrValue<string>,
    e: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  moveToReceivePhase(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  moveToSignPhase(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  moveToValidityCheckPhase(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  recordReceiveTransaction(
    account: PromiseOrValue<string>,
    money: PromiseOrValue<BigNumberish>,
    rho: PromiseOrValue<BigNumberish>,
    delta: PromiseOrValue<BigNumberish>,
    omega: PromiseOrValue<BigNumberish>,
    sigma: PromiseOrValue<BigNumberish>,
    signerPubKey: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  recordSendSignature(
    account: PromiseOrValue<string>,
    e: PromiseOrValue<BigNumberish>,
    r: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  recordSendTransaction(
    account: PromiseOrValue<string>,
    index: PromiseOrValue<BigNumberish>,
    e: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  resetPhaseControl(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  spendReceiveTransactionMoney(
    account: PromiseOrValue<string>,
    amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    doValidityCheck(overrides?: CallOverrides): Promise<void>;

    getSendMessageIndex(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    moveToReceivePhase(overrides?: CallOverrides): Promise<void>;

    moveToSignPhase(overrides?: CallOverrides): Promise<void>;

    moveToValidityCheckPhase(overrides?: CallOverrides): Promise<void>;

    recordReceiveTransaction(
      account: PromiseOrValue<string>,
      money: PromiseOrValue<BigNumberish>,
      rho: PromiseOrValue<BigNumberish>,
      delta: PromiseOrValue<BigNumberish>,
      omega: PromiseOrValue<BigNumberish>,
      sigma: PromiseOrValue<BigNumberish>,
      signerPubKey: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    recordSendSignature(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    recordSendTransaction(
      account: PromiseOrValue<string>,
      index: PromiseOrValue<BigNumberish>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    resetPhaseControl(overrides?: CallOverrides): Promise<void>;

    spendReceiveTransactionMoney(
      account: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    doValidityCheck(overrides?: CallOverrides): Promise<BigNumber>;

    getSendMessageIndex(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    moveToReceivePhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    moveToSignPhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    moveToValidityCheckPhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    recordReceiveTransaction(
      account: PromiseOrValue<string>,
      money: PromiseOrValue<BigNumberish>,
      rho: PromiseOrValue<BigNumberish>,
      delta: PromiseOrValue<BigNumberish>,
      omega: PromiseOrValue<BigNumberish>,
      sigma: PromiseOrValue<BigNumberish>,
      signerPubKey: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    recordSendSignature(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    recordSendTransaction(
      account: PromiseOrValue<string>,
      index: PromiseOrValue<BigNumberish>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    resetPhaseControl(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    spendReceiveTransactionMoney(
      account: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    doValidityCheck(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getSendMessageIndex(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    moveToReceivePhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    moveToSignPhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    moveToValidityCheckPhase(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    recordReceiveTransaction(
      account: PromiseOrValue<string>,
      money: PromiseOrValue<BigNumberish>,
      rho: PromiseOrValue<BigNumberish>,
      delta: PromiseOrValue<BigNumberish>,
      omega: PromiseOrValue<BigNumberish>,
      sigma: PromiseOrValue<BigNumberish>,
      signerPubKey: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    recordSendSignature(
      account: PromiseOrValue<string>,
      e: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    recordSendTransaction(
      account: PromiseOrValue<string>,
      index: PromiseOrValue<BigNumberish>,
      e: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    resetPhaseControl(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    spendReceiveTransactionMoney(
      account: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}