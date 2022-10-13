pragma solidity ^0.8.1;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { IWETH } from "../../interfaces/tokens/IWETH.sol";
import { WrapEthData } from "../../core/types/Common.sol";
import { UseStore, Read } from "../../actions/common/UseStore.sol";
import { Swap } from "./Swap.sol";
import { WETH, SWAP } from "../../core/constants/Common.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { WRAP_ETH } from "../../core/constants/Common.sol";

contract WrapEth is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    WrapEthData memory wrapData = parseInputs(data);
    wrapData.amount = store().readUint(bytes32(wrapData.amount), paramsMap[0], address(this));

    if (wrapData.amount == type(uint256).max) {
      wrapData.amount = address(this).balance;
    }
    IWETH(registry.getRegisteredService(WETH)).deposit{ value: wrapData.amount }();

    emit Action(WRAP_ETH, bytes32(wrapData.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (WrapEthData memory params) {
    return abi.decode(_callData, (WrapEthData));
  }
}