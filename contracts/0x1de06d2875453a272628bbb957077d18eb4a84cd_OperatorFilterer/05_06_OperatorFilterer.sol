// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./02_06_IERC721CreatorExtensionApproveTransfer.sol";
import "./01_06_IERC1155CreatorExtensionApproveTransfer.sol";
import "./06_06_IOperatorFilterRegistry.sol";
import "./03_06_ERC165Checker.sol";

contract OperatorFilterer is IERC165 {
    error OperatorNotAllowed(address operator);

    address public immutable OPERATOR_FILTER_REGISTRY;
    address public immutable SUBSCRIPTION;

    constructor(address operatorFilterRegistry, address subscription) {
        OPERATOR_FILTER_REGISTRY = operatorFilterRegistry;
        SUBSCRIPTION = subscription;

        IOperatorFilterRegistry(OPERATOR_FILTER_REGISTRY).registerAndSubscribe(address(this), SUBSCRIPTION);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId
            || interfaceId == type(IERC1155CreatorExtensionApproveTransfer).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev ERC1155: Called by creator contract to approve a transfer
     */
    function approveTransfer(address operator, address from, address, uint256[] calldata, uint256[] calldata)
        external
        view
        returns (bool)
    {
        return isOperatorAllowed(operator, from);
    }

    /**
     * @dev ERC721: Called by creator contract to approve a transfer
     */
    function approveTransfer(address operator, address from, address, uint256) external view returns (bool) {
        return isOperatorAllowed(operator, from);
    }

    /**
     * @dev Check OperatorFiltererRegistry to see if operator is approved
     */
    function isOperatorAllowed(address operator, address from) internal view returns (bool) {
        if (from != operator) {
            if (!IOperatorFilterRegistry(OPERATOR_FILTER_REGISTRY).isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }

        return true;
    }
}