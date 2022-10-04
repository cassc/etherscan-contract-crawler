//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

interface ISetTokenURILogic {
    /**
     * @dev See {ERC721URIStorage-_setTokenURI}.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    /**
     * @dev See {ERC721URIStorageMock-_setBaseURI}.
     */
    function _setBaseURI(string memory _tokenURI) external;
}

abstract contract SetTokenURIExtension is ISetTokenURILogic, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function _setTokenURI(uint256 tokenId, string memory _tokenURI) external;\n"
            "function _setBaseURI(string memory _tokenURI) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](2);
        functions[0] = ISetTokenURILogic._setTokenURI.selector;
        functions[1] = ISetTokenURILogic._setBaseURI.selector;

        interfaces[0] = Interface(type(ISetTokenURILogic).interfaceId, functions);
    }
}