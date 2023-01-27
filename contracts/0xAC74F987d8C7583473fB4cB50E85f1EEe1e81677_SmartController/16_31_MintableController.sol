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

import "./StandardController.sol";
import "./MintableTokenLib.sol";
import "./SystemRole.sol";

/**
* @title MintableController
* @dev This contracts implements functionality allowing for minting and burning of tokens.
*/
contract MintableController is SystemRole, StandardController {

  using MintableTokenLib for TokenStorage;

  /**
   * @dev Contract constructor.
   * @param storage_ Address of the token storage for the controller.
   * @param initialSupply The amount of tokens to mint upon creation.
   * @param frontend_ Address of the authorized frontend.
   */
  constructor(address storage_, uint initialSupply, address frontend_)
    StandardController(storage_, initialSupply, frontend_)
    { }

  /**
   * @dev Assigns the system role to an account.
   */
  function addSystemAccount(address account) public override onlyOwner {
    super.addSystemAccount(account);
  }

  /**
   * @dev Removes the system role from an account.
   */
  function removeSystemAccount(address account) public override onlyOwner {
    super.removeSystemAccount(account);
  }

  /**
   * @dev Mints new tokens.
   * @param caller Address of the caller passed through the frontend.
   * @param to Address to credit the tokens.
   * @param amount Number of tokens to mint.
   */
  function mintTo_withCaller(address caller, address to, uint amount)
    public
    guarded(caller)
    onlySystemAccount(caller)
    returns (bool)
  {
    avoidBlackholes(to);
    return token.mint(to, amount);
  }

  /**
   * @dev Burns tokens from token owner.
   * This removes the burned tokens from circulation.
   * @param caller Address of the caller passed through the frontend.
   * @param from Address of the token owner.
   * @param amount Number of tokens to burn.
   * @param h Hash which the token owner signed.
   * @param v Signature component.
   * @param r Signature component.
   * @param s Sigature component.
   */
  function burnFrom_withCaller(address caller, address from, uint amount, bytes32 h, uint8 v, bytes32 r, bytes32 s)
    public
    guarded(caller)
    onlySystemAccount(caller)
    returns (bool)
  {
    return token.burn(from, amount, h, v, r, s);
  }

  /**
   * @dev Burns tokens from token owner.
   * This removes the burned tokens from circulation.
   * @param from Address of the token owner.
   * @param amount Number of tokens to burn.
   */
  function burnFrom(address from, uint amount)
    public
    guarded(msg.sender)
    onlySystemAccount(msg.sender)
    returns (bool)
  {
    return token.burn(from, amount);
  }

}
