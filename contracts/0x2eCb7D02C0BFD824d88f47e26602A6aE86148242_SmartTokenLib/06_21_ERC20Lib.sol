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

import "./SafeMath.sol";
import "./TokenStorage.sol";

/**
 * @title ERC20Lib
 * @dev Standard ERC20 token functionality.
 * https://github.com/ethereum/EIPs/issues/20
 */
library ERC20Lib {

    using SafeMath for uint;

    /**
     * @dev Transfers tokens [ERC20].
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transfer(TokenStorage db, address caller, address to, uint amount)
        external
        returns (bool success)
    {
        db.subBalance(caller, amount);
        db.addBalance(to, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from a specific address [ERC20].
     * The address owner has to approve the spender beforehand.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to debet the tokens from.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transferFrom(
        TokenStorage db,
        address caller,
        address from,
        address to,
        uint amount
    )
        external
        returns (bool success)
    {
        uint allowance_ = db.getAllowed(from, caller);
        db.subBalance(from, amount);
        db.addBalance(to, amount);
        db.setAllowed(from, caller, allowance_.sub(amount));
        return true;
    }

    /**
     * @dev Approves a spender [ERC20].
     * Note that using the approve/transferFrom presents a possible
     * security vulnerability described in:
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.quou09mcbpzw
     * Use transferAndCall to mitigate.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param spender The address of the future spender.
     * @param amount The allowance of the spender.
     */
    function approve(TokenStorage db, address caller, address spender, uint amount)
        public
        returns (bool success)
    {
        db.setAllowed(caller, spender, amount);
        return true;
    }

    /**
     * @dev Returns the number tokens associated with an address.
     * @param db Token storage to operate on.
     * @param who Address to lookup.
     * @return balance Balance of address.
     */
    function balanceOf(TokenStorage db, address who)
        external
        view
        returns (uint balance)
    {
        return db.getBalance(who);
    }

    /**
     * @dev Returns the allowance for a spender
     * @param db Token storage to operate on.
     * @param owner The address of the owner of the tokens.
     * @param spender The address of the spender.
     * @return remaining Number of tokens the spender is allowed to spend.
     */
    function allowance(TokenStorage db, address owner, address spender)
        external
        view
        returns (uint remaining)
    {
        return db.getAllowed(owner, spender);
    }

}
