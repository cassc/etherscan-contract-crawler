// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "./LendingRegistry.sol";
import "../../interfaces/IYVault.sol";

contract StakingLogicYGov is ILendingLogic {

    LendingRegistry public lendingRegistry;
    bytes32 public immutable protocolKey;

    constructor(address _lendingRegistry, bytes32 _protocolKey) {
        require(_lendingRegistry != address(0), "INVALID_LENDING_REGISTRY");
        lendingRegistry = LendingRegistry(_lendingRegistry);
        protocolKey = _protocolKey;
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);


        address YGov = lendingRegistry.underlyingToProtocolWrapped(_underlying, protocolKey);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, YGov, 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, YGov, _amount);

        // Stake in Sushi Bar
        targets[2] = YGov;

        data[2] =  abi.encodeWithSelector(IYVault.deposit.selector, _amount);

        return(targets, data);
    }
    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(IYVault.withdraw.selector, _amount);

        return(targets, data);
    }

    function getAPRFromUnderlying(address _token) external view override returns(uint256) {
        return uint256(-1);
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        return uint256(-1);
    }
    
    function exchangeRate(address _wrapped) external view override returns(uint256) {
        return IYVault(_wrapped).getPricePerFullShare();
    }

    function exchangeRateView(address _wrapped) external view override returns(uint256) {
        return IYVault(_wrapped).getPricePerFullShare();
    }

}