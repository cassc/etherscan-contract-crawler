pragma solidity ^0.8.1;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { IWETH } from "../../interfaces/tokens/IWETH.sol";
import { SwapData } from "../../core/types/Common.sol";
import { UseStore, Write } from "../../actions/common/UseStore.sol";
import { Swap } from "./Swap.sol";
import { WETH, SWAP } from "../../core/constants/Common.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { SWAP } from "../../core/constants/Common.sol";

contract SwapAction is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Write for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory) external payable override {
    address swapAddress = registry.getRegisteredService(SWAP);
    
    SwapData memory swap = parseInputs(data);

    IERC20(swap.fromAsset).safeApprove(swapAddress, swap.amount);
    uint256 received = Swap(swapAddress).swapTokens(swap);

    store().write(bytes32(received));

    emit Action(SWAP, bytes32(received));
  }

  function parseInputs(bytes memory _callData) public pure returns (SwapData memory params) {
    return abi.decode(_callData, (SwapData));
  }
}