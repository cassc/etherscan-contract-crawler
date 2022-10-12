pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { Write, UseStore } from "../common/UseStore.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { IVariableDebtToken } from "../../interfaces/aave/IVariableDebtToken.sol";
import { IWETHGateway } from "../../interfaces/aave/IWETHGateway.sol";
import { BorrowData } from "../../core/types/Aave.sol";
import { AAVE_WETH_GATEWAY, AAVE_LENDING_POOL, BORROW_ACTION } from "../../core/constants/Aave.sol";

contract AaveBorrow is Executable, UseStore {
  using Write for OperationStorage;

  IVariableDebtToken public constant dWETH =
    IVariableDebtToken(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory) external payable override {
    BorrowData memory borrow = parseInputs(data);

    address wethGatewayAddress = registry.getRegisteredService(AAVE_WETH_GATEWAY);
    dWETH.approveDelegation(wethGatewayAddress, borrow.amount);
    
    IWETHGateway(wethGatewayAddress).borrowETH(
      registry.getRegisteredService(AAVE_LENDING_POOL),
      borrow.amount,
      2,
      0
    );
    address payable to = payable(borrow.to);
    to.transfer(borrow.amount);

    store().write(bytes32(borrow.amount));
    emit Action(BORROW_ACTION, bytes32(borrow.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (BorrowData memory params) {
    return abi.decode(_callData, (BorrowData));
  }
}