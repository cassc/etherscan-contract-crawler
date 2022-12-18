// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./GhostERC721Upgradeable/NSGERC721Upgradeable.sol";

contract NSUpgradeableV1 is Initializable, NSGERC721Upgradable, UUPSUpgradeable {
    uint256[5] private __gapBefore;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address roleAdmin_,
        uint256 maxSupply_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        __NSERC721_init(roleAdmin_, name_, symbol_, maxSupply_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(NIGHTSHADE_ADMIN) {}

    /**
     * @dev Reserved for future NS features
     */
    uint256[50] private __gap;
}