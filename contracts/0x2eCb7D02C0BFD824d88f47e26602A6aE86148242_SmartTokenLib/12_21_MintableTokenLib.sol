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
import "./SignatureChecker.sol";
import "./ERC20Lib.sol";
import "./TokenStorage.sol";

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

library MintableTokenLib {

  using SafeMath for uint;
  using SignatureChecker for address;

    /**
     * @dev Mints new tokens.
     * @param db Token storage to operate on.
     * @param to The address that will recieve the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(
        TokenStorage db,
        address to,
        uint amount
    )
        external
        returns (bool)
    {
        db.addBalance(to, amount);
        return true;
    }

    /**
     * @dev Burns tokens.
     * @param db Token storage to operate on.
     * @param from The address holding tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        TokenStorage db,
        address from,
        uint amount
    )
        public
        returns (bool)
    {
        db.subBalance(from, amount);
        return true;
    }

    /**
     * @dev Burns tokens from a specific address.
     * To burn the tokens the caller needs to provide a signature
     * proving that the caller is authorized by the token owner to do so.
     * @param db Token storage to operate on.
     * @param from The address holding tokens.
     * @param amount The amount of tokens to burn.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     */
    function burn(
        TokenStorage db,
        address from,
        uint amount,
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (bool)
    {
      bytes memory signature;
      if (r != bytes32(0) || s != bytes32(0)) {
        signature = bytes(abi.encodePacked(r,s,v));
      }
      require(
          from.isValidSignatureNow(h, signature),
          "signature/hash does not match"
        );
        return burn(db, from, amount);
    }

}
