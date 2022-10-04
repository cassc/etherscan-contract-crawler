// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/Extension.sol";

/**
 * @notice OpenSea specified interface for returning contract-level metadata
 *         https://docs.opensea.io/v2.0/docs/contract-level-metadata
 */
interface IContractMetadata {
    /**
     * @dev Returns contract-level metadata for use with OpenSea
     */
    function contractURI() external returns (string memory);

    /**
     * @dev Sets contract-level metadata for use with OpenSea
     */
    function setContractURI(string memory uri) external;
}

abstract contract ContractMetadataExtension is IContractMetadata, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function contractURI() external returns (string memory);\n"
            "function setContractURI(string memory uri) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](2);
        functions[0] = IContractMetadata.contractURI.selector;
        functions[1] = IContractMetadata.setContractURI.selector;

        interfaces[0] = Interface(type(IContractMetadata).interfaceId, functions);
    }
}