// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// libraries
import { UUPSUpgradeable } from "../../lib/openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../../lib/openzeppelin/contracts/utils/Strings.sol";

// interfaces
import { IVaultShareDescriptor } from "../interfaces/IVaultShareDescriptor.sol";

contract HashnoteVaultShareDescriptor is OwnableUpgradeable, UUPSUpgradeable, IVaultShareDescriptor {
    // solhint-disable-next-line no-empty-blocks
    constructor() { }

    /**
     * @dev init contract and set owner
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice return tokenURL for a NFT position
     * @dev we just simply return a static url for now
     */
    function tokenURI(uint256 id) external pure override returns (string memory) {
        return string(abi.encodePacked("https://hashnote.com/token/", Strings.toString(id)));
    }

    /**
     * @dev Upgradable by the owner.
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }
}