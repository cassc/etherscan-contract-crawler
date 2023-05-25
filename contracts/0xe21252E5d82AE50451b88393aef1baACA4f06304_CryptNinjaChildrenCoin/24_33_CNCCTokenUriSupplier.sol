// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AdminWithMinterBurnerControl.sol";
import "default-nft-contract/contracts/libs/TokenSupplier/TokenUriSupplier.sol";

contract CNCCTokenUriSupplier is TokenUriSupplier, AdminWithMinterBurnerControl {
    using Strings for uint256;

    function _defaultTokenUri(uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURI, tokenId.toString(), "_coin", baseExtension)
            );
    }

    function _uri(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return TokenUriSupplier.tokenURI(tokenId);
    }

    function setBaseURI(string memory _value)
        public
        override
        onlyAdmin
    {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value)
        external
        override
        onlyAdmin
    {
        baseExtension = _value;
    }

    function setExternalSupplier(address _value)
        external
        override
        onlyAdmin
    {
        externalSupplier = ITokenUriSupplier(_value);
    }
}