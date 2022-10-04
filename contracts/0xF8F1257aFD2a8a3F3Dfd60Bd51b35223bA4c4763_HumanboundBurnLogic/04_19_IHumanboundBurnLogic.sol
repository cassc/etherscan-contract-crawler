// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/base/burn/Burn.sol";

interface IHumanboundBurnLogic {
    event BurntWithProof(uint256 tokenId, string burnProofURI);
    event BurntByOwner(uint256 tokenId);

    function burn(uint256 tokenId, string memory burnProofURI) external;

    function burn(uint256 tokenId) external;
}

abstract contract HumanboundBurnExtension is IHumanboundBurnLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function burn(uint256 tokenId, string memory burnProofURI) external;\n"
            "function burn(uint256 tokenId) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](2);
        functions[0] = bytes4(keccak256("burn(uint256,string)"));
        functions[1] = bytes4(keccak256("burn(uint256)"));

        interfaces[0] = Interface(type(IHumanboundBurnLogic).interfaceId, functions);
    }
}