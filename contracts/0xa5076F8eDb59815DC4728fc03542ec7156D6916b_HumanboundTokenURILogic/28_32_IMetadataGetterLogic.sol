//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/Extension.sol";

interface IMetadataGetterLogic {
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external returns (string memory);

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external returns (string memory);

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external returns (string memory);

    /**
     * @dev Returns the base URI for all tokens.
     */
    function baseURI() external returns (string memory);
}

abstract contract MetadataGetterExtension is IMetadataGetterLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function name() external view returns (string memory);\n"
            "function symbol() external view returns (string memory);\n"
            "function tokenURI(uint256 tokenId) external view returns (string memory);\n"
            "function baseURI() external returns (string memory);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](4);
        functions[0] = IMetadataGetterLogic.name.selector;
        functions[1] = IMetadataGetterLogic.symbol.selector;
        functions[2] = IMetadataGetterLogic.tokenURI.selector;
        functions[3] = IMetadataGetterLogic.baseURI.selector;

        interfaces[0] = Interface(type(IMetadataGetterLogic).interfaceId, functions);
    }
}