// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../upgradeability/EternalStorage.sol";

/**
 * @title MediatorBalanceStorage
 * @dev Functionality for storing expected mediator balance for native tokens.
 */
contract MediatorBalanceStorage is EternalStorage {
    /**
     * @dev Tells the expected token balance of the contract.
     * @param _token address of token contract.
     * @return the current tracked token balance of the contract.
     */
    function mediatorBalance(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))];
    }

    /**
     * @dev Tells the added token liquidity balance of user.
     * @param _user user address.
     * @param _token address of token contract.
     * @return the current added liquidity balance of user.
     */
    function addedLiquidityBalance(address _user, address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("liquidityForUser", _user, _token))];
    }

    /**
     * @dev Updates expected token balance of the contract.
     * @param _token address of token contract.
     * @param _balance the new token balance of the contract.
     */
    function _setMediatorBalance(address _token, uint256 _balance) internal {
        uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))] = _balance;
    }

    /**
     * @dev Updates added token liquidity balance of user.
     * @param _user address that provides liquidity for bridge.
     * @param _token address of token contract.
     * @param _amount the new token liquidity balance of user.
     */
    function _addLiquidityBalanceForUser(address _user, address _token, uint256 _amount) internal {
        uintStorage[keccak256(abi.encodePacked("liquidityForUser", _user, _token))] = _amount;
    }
}