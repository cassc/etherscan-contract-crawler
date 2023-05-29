/*

 Copyright 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.6.0 <0.8.0;

/// @title Pool Interface - Interface of pool standard functions.
/// @author Gabriele Rigo - <[email protected]>
/// @notice only public view functions are used
interface IPool {
    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Calculates how many shares a user holds.
    /// @param _who Address of the target account.
    /// @return Number of shares.
    function balanceOf(address _who)
        external
        view
        returns (uint256);
    
    /// @dev Returns the total amount of issued tokens for this drago.
    /// @return totaSupply Number of shares.
    function totalSupply()
        external
        view
        returns (uint256 totaSupply);

    /// @dev Gets the address of the logger contract.
    /// @return Address of the logger contract.
    function getEventful()
        external
        view
        returns (address);

    /// @dev Finds details of a drago pool.
    /// @return name String name of a drago.
    /// @return symbol String symbol of a drago.
    /// @return sellPrice Value of the share price in wei.
    /// @return buyPrice Value of the share price in wei.
    function getData()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 sellPrice,
            uint256 buyPrice
        );

    /// @dev Returns the price of a pool.
    /// @return Value of the share price in wei.
    function calcSharePrice()
        external
        view
        returns (uint256);

    /// @dev Finds the administrative data of the pool.
    /// @return Address of the account where a user collects fees.
    /// @return feeCollector Address of the drago dao/factory.
    /// @return dragoDao Number of the fee split ratio.
    /// @return ratio Value of the transaction fee in basis points.
    /// @return transactionFee Value of the subscription fee.
    /// @return minPeriod Number of the minimum holding period for shares.
    function getAdminData()
        external
        view
        returns (
            address,
            address feeCollector,
            address dragoDao,
            uint256 ratio,
            uint256 transactionFee,
            uint32 minPeriod
        );
}