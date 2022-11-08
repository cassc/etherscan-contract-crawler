// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./SNIF.sol";

/// @title SNIF
/// @author @KfishNFT
/// @notice Sneaky's Internet Friends Collection
/** @dev Any function which updates state will require a signature from an address with the correct role
    This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin */
contract SNIFV2 is SNIF {
    IOperatorDenylistRegistry public operatorDenylistRegistry;

    function setOperatorDenylistRegistry(address operatorDenylistRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorDenylistRegistry = IOperatorDenylistRegistry(operatorDenylistRegistry_);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!operatorDenylistRegistry.isOperatorDenied(msg.sender), "Operator Denied");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}

interface IOperatorDenylistRegistry {
    function isOperatorDenied(address operator) external view returns (bool);
}