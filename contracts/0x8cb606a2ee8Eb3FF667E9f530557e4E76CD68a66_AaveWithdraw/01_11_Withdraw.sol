pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { UseStore, Write } from "../common/UseStore.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { ILendingPool } from "../../interfaces/aave/ILendingPool.sol";
import { WithdrawData } from "../../core/types/Aave.sol";
import { AAVE_LENDING_POOL, WITHDRAW_ACTION } from "../../core/constants/Aave.sol";

contract AaveWithdraw is Executable, UseStore {
  using Write for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory) external payable override {
    WithdrawData memory withdraw = parseInputs(data);

    uint256 amountWithdrawn = ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL))
      .withdraw(withdraw.asset, withdraw.amount, withdraw.to);
    store().write(bytes32(amountWithdrawn));

    emit Action(WITHDRAW_ACTION, bytes32(amountWithdrawn));
  }

  function parseInputs(bytes memory _callData) public pure returns (WithdrawData memory params) {
    return abi.decode(_callData, (WithdrawData));
  }
}