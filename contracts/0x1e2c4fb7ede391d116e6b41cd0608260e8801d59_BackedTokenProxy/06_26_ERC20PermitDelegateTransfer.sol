/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2022 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/**
 * @dev 
 *
 * This contract is a based (copy-paste with changes) on OpenZeppelin's draft-ERC20Permit.sol (token/ERC20/extensions/draft-ERC20Permit.sol).
 * 
 * The changes are:
 *  - Adding also delegated transfer functionality, that is similar to permit, but doing the actual transfer and not approval.
 *  - Cutting some of the generalities to make the contacts more straight forward for this case (e.g. removing the counters library). 
 *
*/

contract ERC20PermitDelegateTransfer is ERC20Upgradeable {
    mapping(address => uint256) public nonces;

    // Calculating the Permit typehash:
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // Calculating the Delegated Transfer typehash:
    bytes32 public constant DELEGATED_TRANSFER_TYPEHASH =
        keccak256("DELEGATED_TRANSFER(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)");

    // Immutable variable for Domain Separator:
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;

    // A version number:
    string internal constant VERSION = "1";

    /**
     * @dev Permit, approve via a sign message, using erc712.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        _checkOwner(owner, structHash, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @dev Delegated Transfer, transfer via a sign message, using erc712.
     */
    function delegatedTransfer(
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(DELEGATED_TRANSFER_TYPEHASH, owner, to, value, _useNonce(owner), deadline));

        _checkOwner(owner, structHash, v, r, s);

        _transfer(owner, to, value);
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = nonces[owner];
        nonces[owner]++;
    }

    function _checkOwner(address owner, bytes32 structHash, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(DOMAIN_SEPARATOR, structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
    }

    function _buildDomainSeparator() internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}