// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/ILendingLogic.sol";
import "../../interfaces/IDecimalWrapper.sol";
import "./LendingRegistry.sol";

contract DepositLogicDecimalWrapper is ILendingLogic {
    LendingRegistry public immutable lendingRegistry;
    bytes32 public immutable protocolKey;

    constructor(address _lendingRegistry, bytes32 _protocolKey) {
        require(_lendingRegistry != address(0), "INVALID_LENDING_REGISTRY");
        lendingRegistry = LendingRegistry(_lendingRegistry);
        protocolKey = _protocolKey;
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        address wrapped = lendingRegistry.underlyingToProtocolWrapped(_underlying, protocolKey);
        require(wrapped != address(0), "NO_WRAPPED_FOUND");
        targets = new address[](3);
        data = new bytes[](3);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, wrapped, 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, wrapped, _amount);

        // Deposit into DecimalWrapper
        targets[2] = wrapped;
        data[2] =  abi.encodeWithSelector(IDecimalWrapper.deposit.selector, _amount);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(IDecimalWrapper.withdraw.selector, _amount);

        return(targets, data);
    }

    function exchangeRate(address _wrapped) external override returns(uint256) {
        IDecimalWrapper wrapped = IDecimalWrapper(_wrapped);
        return 10**18 / wrapped.conversion();
    }
    function exchangeRateView(address _wrapped) external view override returns(uint256) {
        IDecimalWrapper wrapped = IDecimalWrapper(_wrapped);
        return 10**18 / wrapped.conversion();
    }

    function getAPRFromUnderlying(address _token) external view override returns(uint256) {
        return 0;
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        return 0;
    }
}