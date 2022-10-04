//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/Extension.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
// To follow Extension principles, maybe best to separate each function into a different Extension
interface ITransferLogic {
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;
}

abstract contract TransferExtension is ITransferLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function transferFrom(address from, address to, uint256 tokenId) external;\n"
            "function safeTransferFrom(address from, address to, uint256 tokenId) external;\n"
            "function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](3);
        functions[0] = ITransferLogic.transferFrom.selector;
        functions[1] = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
        functions[2] = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));

        interfaces[0] = Interface(type(ITransferLogic).interfaceId, functions);
    }
}