// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/ILendingLogic.sol";

contract MockLendingLogic is ILendingLogic {
    uint256 private apr;

    function setAPR(uint256 _apr) public {
        apr = _apr;
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        return apr;
    }

    function getAPRFromUnderlying(address _token) public view override returns(uint256) {
        return apr;
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _underlying;
        data[0] = bytes(abi.encode(_amount));
    }
    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = bytes(abi.encode(_amount));
    }

    function exchangeRate(address) external pure override returns(uint256) {
        return 10**18;
    }

    function exchangeRateView(address) external pure override returns(uint256) {
        return 10**18;
    }
}