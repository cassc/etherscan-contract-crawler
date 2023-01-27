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

/**
 * @title IValidator
 * @dev Contracts implementing this interface validate token transfers.
 */
interface IValidator {

    /**
     * @dev Emitted when a validator makes a decision.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     * @param valid True if transfer approved, false if rejected.
     */
    event Decision(address indexed from, address indexed to, uint amount, bool valid);

    /**
     * @dev Validates token transfer.
     * If the sender is on the blacklist the transfer is denied.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     */
    function validate(address from, address to, uint amount) external returns (bool valid);

}
