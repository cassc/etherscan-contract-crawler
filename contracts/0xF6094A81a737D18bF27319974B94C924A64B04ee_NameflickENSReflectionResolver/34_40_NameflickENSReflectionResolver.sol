// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

  _  _                               __     _       _              _     
 | \| |   __ _    _ __     ___      / _|   | |     (_)     __     | |__  
 | .` |  / _` |  | '  \   / -_)    |  _|   | |     | |    / _|    | / /  
 |_|\_|  \__,_|  |_|_|_|  \___|   _|_|_   _|_|_   _|_|_   \__|_   |_\_\  
_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| 
"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'                                                 
*/

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ABIResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/AddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ContentHashResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/DNSResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/InterfaceResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/NameResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/PubkeyResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/TextResolver.sol";
import "erc721a/contracts/interfaces/IERC721AQueryable.sol";
import "hardhat/console.sol";

import "./SignatureVerifier.sol";
import "./StringLib.sol";
import "./BytesLib.sol";

interface IExtendedResolver {
    function resolve(
        bytes calldata name,
        bytes calldata data
    ) external view returns (bytes memory);
}

// sighash of addr(bytes32)
bytes4 constant ADDR_ETH_INTERFACE_ID = 0x3b3b57de;
// sighash of addr(bytes32,uint)
bytes4 constant ADDR_INTERFACE_ID = 0xf1cb7e06;

uint256 constant COIN_TYPE_ETH = 60;

error InvalidRequest();

/**
 * Implements an ENS resolver that directs all queries to a CCIP read gateway.
 * Callers must implement EIP 3668 and ENSIP 10.
 */
contract NameflickENSReflectionResolver is IExtendedResolver, ERC165 {
    using StringLib for string;
    using BytesLib for bytes;

    /**
     * @dev Converts an address to a bytes array, but aligned to 32 bytes
     * @param a the address to convert
     * @return b the bytes array
     */
    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            // store the address at the end of the bytes array
            mstore(add(b, 32), a)
        }
    }

    function parse(string memory input) internal pure returns (address) {
        require(bytes(input).length == 42, "Invalid address length");
        require(
            bytes(input)[0] == "0" && bytes(input)[1] == "x",
            "Address should start with '0x'"
        );

        uint160 parsedAddress = 0;
        uint8 startIndex = 2;

        for (uint8 i = startIndex; i < 42; i += 1) {
            uint8 character = uint8(bytes(input)[i]);

            uint8 value;
            if (character >= 48 && character <= 57) {
                value = character - 48; // '0' to '9'
            } else if (character >= 65 && character <= 70) {
                value = character - 55; // 'A' to 'F'
            } else if (character >= 97 && character <= 102) {
                value = character - 87; // 'a' to 'f'
            } else {
                revert("Invalid character in address");
            }

            parsedAddress = parsedAddress * 16 + value;
        }

        return address(parsedAddress);
    }

    /**
     * Resolves a name, as specified by ENSIP 10.
     * @param name The DNS-encoded name to resolve.
     * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
     * @return bytes return data, ABI encoded identically to the underlying function.
     */
    function resolve(
        bytes calldata name,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        bytes4 selector = data.getBytes4(0);
        if (selector == ADDR_ETH_INTERFACE_ID || selector == ADDR_INTERFACE_ID && uint256(data.getBytes32(36)) == COIN_TYPE_ETH) {
            address sub = parse(name.getNodeString(0));
            return addressToBytes(sub);
        }
        revert InvalidRequest();
    }

    /**
     * @dev EIP-165 interface support.
     */
    function supportsInterface(
        bytes4 interfaceID
    ) public view override returns (bool) {
        return
            interfaceID == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}