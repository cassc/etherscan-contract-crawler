//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

interface IApproveLogic {
    /**
     * @dev See {IERC721-Approval}.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev See {IERC721-ApprovalForAll}.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev See {IERC721-approve}.
     */
    function _approve(address to, uint256 tokenId) external;
}

abstract contract ApproveExtension is IApproveLogic, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function approve(address to, uint256 tokenId) external;\n"
            "function setApprovalForAll(address operator, bool approved) external;\n"
            "function _approve(address to, uint256 tokenId) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](3);
        functions[0] = IApproveLogic.approve.selector;
        functions[1] = IApproveLogic.setApprovalForAll.selector;
        functions[2] = IApproveLogic._approve.selector;

        interfaces[0] = Interface(type(IApproveLogic).interfaceId, functions);
    }
}