/*
    Copyright 2020, 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../lib/LibEIP712.sol";

/**
 * @title Permittable
 * @notice EIP-2612: permit implementation for the ERC20 standard
 */
contract Permittable is ERC20Detailed, ERC20 {

    /**
     * @notice EIP712 typehash for Permit
     * @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
     */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @notice EIP712 version
     */
    string private constant EIP712_VERSION = "1";

    /**
     * @notice EIP712 domain separator for this contract
     * @dev Computed in the constructor
     */
    bytes32 public DOMAIN_SEPARATOR;

    /**
     * @notice Mapping of the current expected nonce for each account
     */
    mapping(address => uint256) public nonces;

    /**
     * @notice Construct the Permittable contract
     */
    constructor() public {
        DOMAIN_SEPARATOR = LibEIP712.hashEIP712Domain(name(), EIP712_VERSION, getChainId(), address(this));
    }

    /**
     * @notice Update the allowance of `spender` for `owner` to `value` based on a signed EIP712 message
     * @dev Will revert if:
     *       (1) The permit's nonce is different than expected
     *       (2) The deadline has passed
     *       (3) The permit signature is invalid
     * @param owner Owner that is allowing approval
     * @param spender Spender to approve for `owner`
     * @param value Amount to approve
     * @param deadline Timestamp that the permit is valid until
     * @param v V parameter of the permit signature
     * @param r R parameter of the permit signature
     * @param s S parameter of the permit signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = LibEIP712.hashEIP712Message(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            ))
        );

        address recovered = ecrecover(digest, v, r, s);

        require(recovered == owner, "Permittable: Invalid signature");
        require(now <= deadline, "Permittable: Expired");

        _approve(owner, spender, value);
    }

    /**
     * @notice Retrieve the current chain's ID
     * @dev Internal only - helper
     * @return chain ID
     */
    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}