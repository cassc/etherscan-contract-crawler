/* SPDX-License-Identifier: apache-2.0 */
/**
 * Copyright 2022 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.8.11;

import "./Claimable.sol";
import "./CanReclaimToken.sol";
import "./NoOwner.sol";
import "./TokenStorageLib.sol";

/**
 * @title TokenStorage
 * @dev External storage for tokens.
 * The storage is implemented in a separate contract to maintain state
 * between token upgrades.
 */
contract TokenStorage is Claimable, CanReclaimToken, NoOwner {

    using TokenStorageLib for TokenStorageLib.TokenStorage;

    TokenStorageLib.TokenStorage internal tokenStorage;

    /**
     * @dev Increases balance of an address.
     * @param to Address to increase.
     * @param amount Number of units to add.
     */
    function addBalance(address to, uint amount) external onlyOwner {
        tokenStorage.addBalance(to, amount);
    }

    /**
     * @dev Decreases balance of an address.
     * @param from Address to decrease.
     * @param amount Number of units to subtract.
     */
    function subBalance(address from, uint amount) external onlyOwner {
        tokenStorage.subBalance(from, amount);
    }

    /**
     * @dev Sets the allowance for a spender.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @param amount Qunatity of allowance.
     */
    function setAllowed(address owner, address spender, uint amount) external onlyOwner {
        tokenStorage.setAllowed(owner, spender, amount);
    }

    /**
     * @dev Returns the supply of tokens.
     * @return Total supply.
     */
    function getSupply() external view returns (uint) {
        return tokenStorage.getSupply();
    }

    /**
     * @dev Returns the balance of an address.
     * @param who Address to lookup.
     * @return Number of units.
     */
    function getBalance(address who) external view returns (uint) {
        return tokenStorage.getBalance(who);
    }

    /**
     * @dev Returns the allowance for a spender.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @return Number of units.
     */
    function getAllowed(address owner, address spender)
        external
        view
        returns (uint)
    {
        return tokenStorage.getAllowed(owner, spender);
    }

    /**
     * @dev Explicit override of transferOwnership from Claimable and Ownable
     * @param newOwner Address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public override(Claimable, Ownable){
      Claimable.transferOwnership(newOwner);
    }
}
