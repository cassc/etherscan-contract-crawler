//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

/**
 * OnReceive interface for contract-receiver hooks
 */
interface IOnReceiveLogic {
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external returns (bool);
}

abstract contract OnReceiveExtension is IOnReceiveLogic, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function _checkOnERC721Received("
            "address from, address to, uint256 tokenId, bytes memory _data"
            ") external returns (bool);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IOnReceiveLogic._checkOnERC721Received.selector;

        interfaces[0] = Interface(type(IOnReceiveLogic).interfaceId, functions);
    }
}