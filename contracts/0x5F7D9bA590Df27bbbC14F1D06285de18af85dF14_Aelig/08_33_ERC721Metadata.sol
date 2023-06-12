// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Lendable.sol";
import "./Roles.sol";

contract ERC721Metadata is
    IERC721Metadata,
    Lendable,
    Roles
{
    string internal constant nftName = "Aelig";
    string internal constant nftSymbol = "AELIG";
    string internal baseURL;

    function name()
        external
        override
        pure
        returns(string memory)
    {
        return nftName;
    }

    function symbol()
        external
        override
        pure
        returns(string memory)
    {
        return nftSymbol;
    }

    function tokenURI(
        uint256 _tokenId
    )
        external
        override
        view
        validNFToken(_tokenId)
        returns (string memory)
    {
        string memory uri = baseURL;
        uri = string.concat(uri, "?id=");
        uri = string.concat(uri, Strings.toString(block.chainid));
        uri = string.concat(uri, "-");
        uri = string.concat(uri, _toAsciiString(address(this)));
        uri = string.concat(uri, "-");
        uri = string.concat(uri, Strings.toString(_tokenId));
        return uri;
    }

    function updateBaseUrl(
        string memory _newBaseUrl
    )
        external
        override
    {
        require(msg.sender == manager, errors.NOT_AUTHORIZED);
        baseURL = _newBaseUrl;
    }

    function _toAsciiString(
        address x
    )
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
        }
        return string(s);
    }

    function _char(
        bytes1 b
    )
        internal
        pure
        returns (bytes1 c)
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}