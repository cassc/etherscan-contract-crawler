// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title A library for deploying contracts EIP-3171 style.
 * @author Agustin Aguilar <[email protected]>
 */
contract Create3Factory {
    /**
     * @notice The bytecode for a contract that proxies the creation of another contract
     * @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract
     * address 0x67363d3d37363d34f03d5260086018f3:
     *
     * 0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
     * 0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
     * 0x02  0x52  0x52                  MSTORE
     * 0x03  0x60  0x6008                PUSH1 08        8
     * 0x04  0x60  0x6018                PUSH1 18        24 8
     * 0x05  0xf3  0xf3                  RETURN
     *
     * 0x363d3d37363d34f0:
     *
     * 0x00  0x36  0x36                  CALLDATASIZE    cds
     * 0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
     * 0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
     * 0x03  0x37  0x37                  CALLDATACOPY
     * 0x04  0x36  0x36                  CALLDATASIZE    cds
     * 0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
     * 0x06  0x34  0x34                  CALLVALUE       val 0 cds
     * 0x07  0xf0  0xf0                  CREATE          addr
     */
    bytes public constant PROXY_BYTECODE = hex'67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3';

    // KECCAK_PROXY_BYTECODE = keccak256(PROXY_BYTECODE);
    bytes32 public constant KECCAK_PROXY_BYTECODE = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /**
     * @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
     * @param salt Salt of the contract creation, resulting address will be derivated from this value only
     * @return Address of the deployed contract, reverts on error
     * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
     */
    function addressOf(bytes32 salt) public view returns (address) {
        bytes32 addr = keccak256(abi.encodePacked(hex'ff', address(this), salt, KECCAK_PROXY_BYTECODE));
        address proxy = address(uint160(uint256(addr)));
        return address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', proxy, hex'01')))));
    }

    /**
     * @notice Creates a new contract with given `creationCode` and `salt`
     * @param salt Salt of the contract creation, resulting address will be derivated from this value only
     * @param creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
     * @return instance Address of the deployed contract, reverts on error
     */
    function create(bytes32 salt, bytes memory creationCode) external payable returns (address instance) {
        // Get target final address
        instance = addressOf(salt);
        require(_codeSize(instance) == 0, 'CREATE3_TARGET_ALREADY_EXISTS');

        // Create proxy using CREATE2
        address proxy;
        bytes memory proxyCreationCode = PROXY_BYTECODE;
        assembly {
            proxy := create2(0, add(proxyCreationCode, 32), mload(proxyCreationCode), salt)
        }
        require(proxy != address(0), 'CREATE3_ERROR_CREATING_PROXY');

        // Call proxy with final creation code
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = proxy.call{ value: msg.value }(creationCode);
        require(success && _codeSize(instance) > 0, 'CREATE3_ERROR_CREATING_CONTRACT');
    }

    /**
     * @notice Returns the size of the code on a given address
     * @param contractAddress Address that may or may not contain code
     * @return size of the code on the given `contractAddress`
     */
    function _codeSize(address contractAddress) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(contractAddress)
        }
    }
}