//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { ServiceRegistry } from "./ServiceRegistry.sol";
import { OperationStorage } from "./OperationStorage.sol";
import { OperationsRegistry } from "./OperationsRegistry.sol";
import { DSProxy } from "../libs/DS/DSProxy.sol";
import { Address } from "../libs/Address.sol";
import { TakeFlashloan } from "../actions/common/TakeFlashloan.sol";
import { IERC3156FlashBorrower } from "../interfaces/flashloan/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../interfaces/flashloan/IERC3156FlashLender.sol";
import { SafeERC20, IERC20 } from "../libs/SafeERC20.sol";
import { SafeMath } from "../libs/SafeMath.sol";
import { FlashloanData, Call } from "./types/Common.sol";
import { OPERATION_STORAGE, OPERATIONS_REGISTRY, OPERATION_EXECUTOR } from "./constants/Common.sol";
import { FLASH_MINT_MODULE } from "./constants/Maker.sol";

contract OperationExecutor is IERC3156FlashBorrower {
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ServiceRegistry public immutable registry;

  /**
   * @dev Emitted once an Operation has completed execution
   * @param name The address initiating the deposit
   * @param calls The call data for the actions the operation must executes
   **/
  event Operation(string name, Call[] calls);

  constructor(ServiceRegistry _registry) {
    registry = _registry;
  }

  function executeOp(Call[] memory calls, string calldata operationName) public payable {
    OperationStorage opStorage = OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
    opStorage.lock();
    OperationsRegistry opRegistry = OperationsRegistry(
      registry.getRegisteredService(OPERATIONS_REGISTRY)
    );

    opStorage.clearStorage();
    opStorage.setOperationActions(opRegistry.getOperation(operationName));
    aggregate(calls);
    
    opStorage.clearStorage();
    opStorage.unlock();
    emit Operation(operationName, calls);
  }

  function aggregate(Call[] memory calls) internal {
    OperationStorage opStorage = OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
    bool hasActionsToVerify = opStorage.hasActionsToVerify();
    for (uint256 current = 0; current < calls.length; current++) {
      if (hasActionsToVerify) {
        opStorage.verifyAction(calls[current].targetHash);
      }

      address target = registry.getServiceAddress(calls[current].targetHash);

      target.functionDelegateCall(
        calls[current].callData,
        "OpExecutor: low-level delegatecall failed"
      );
    }
  }

  function callbackAggregate(Call[] memory calls) external {
    require(msg.sender == registry.getRegisteredService(OPERATION_EXECUTOR), "OpExecutor: Caller forbidden");
    aggregate(calls);
  }

  function onFlashLoan(
    address initiator,
    address asset,
    uint256 amount,
    uint256 fee,
    bytes calldata data
  ) external override returns (bytes32) {
    address lender = registry.getRegisteredService(FLASH_MINT_MODULE);

    require(msg.sender == lender, "Untrusted flashloan lender");
    
    FlashloanData memory flData = abi.decode(data, (FlashloanData));

    require(IERC20(asset).balanceOf(address(this)) >= flData.amount, "Flashloan inconsistency");

    if (flData.dsProxyFlashloan) {
      IERC20(asset).safeTransfer(initiator, flData.amount);

      DSProxy(payable(initiator)).execute(
        address(this),
        abi.encodeWithSelector(this.callbackAggregate.selector, flData.calls)
      );
    } else {
      OperationStorage opStorage = OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
      opStorage.setInitiator(initiator);
      aggregate(flData.calls);
    }

    uint256 paybackAmount = amount.add(fee);
    require(IERC20(asset).balanceOf(address(this)) >= paybackAmount, "Insufficient funds for payback");

    IERC20(asset).safeApprove(lender, paybackAmount);

    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }
}