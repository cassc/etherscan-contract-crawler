// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// NFTC Prerelease Contracts
import './FlavorInfoManager.sol';

// Error Codes
error UnrecognizedFlavorId();
error InvalidValuePayment();
error InvalidAccess();
error CannotChangeMaxSupply();
error InvalidMaxSupply();
error ExceedsMaxSupplyForFlavor();

/**
 * @title ExpandableTypedTokenExtension
 * @author @NiftyMike | @NFTCulture
 * @dev Extension contract for Expandable Token Types.
 */
abstract contract ExpandableTypedTokenExtension is FlavorInfoManager, AccessControl {
    using Strings for uint256;

    bool private immutable ALLOW_MAX_SUPPLY_INCREASE;

    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR_ROLE');

    constructor(bool __allowMaxSupplyIncrease) FlavorInfoManager() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // CREATOR_ROLE can create new flavors and update existing ones.
        _grantRole(CREATOR_ROLE, msg.sender);

        ALLOW_MAX_SUPPLY_INCREASE = __allowMaxSupplyIncrease;
    }

    function createNewTokenFlavors(
        uint256[] memory __flavorIds,
        uint256[] memory __flavorPrices,
        uint256[] memory __flavorMaxSupplies,
        string[] memory __flavorUris
    ) external {
        if (!hasRole(CREATOR_ROLE, msg.sender)) revert InvalidAccess();

        require(
            __flavorIds.length == __flavorPrices.length &&
                __flavorIds.length == __flavorMaxSupplies.length &&
                __flavorIds.length == __flavorUris.length,
            'Unmatched arrays'
        );

        for (uint256 idx = 0; idx < __flavorIds.length; idx++) {
            FlavorInfo memory newFlavor = FlavorInfo(
                uint64(__flavorIds[idx]),
                uint64(__flavorPrices[idx]),
                uint64(__flavorMaxSupplies[idx]),
                0,
                __flavorUris[idx]
            );

            _incrementMaxSupply(newFlavor.maxSupply);
            _createFlavorInfo(newFlavor);
        }
    }

    function updateTokenFlavor(
        uint256 __flavorId,
        uint256 __flavorPrice,
        uint256 __flavorMaxSupply,
        string memory __flavorUri
    ) external {
        if (!hasRole(CREATOR_ROLE, msg.sender)) revert InvalidAccess();
        if (__flavorMaxSupply != 0 && !ALLOW_MAX_SUPPLY_INCREASE) revert CannotChangeMaxSupply();

        FlavorInfo memory previousFlavor = _getFlavorInfo(__flavorId);
        _checkFlavorIsValid(previousFlavor);

        if (__flavorPrice > 0) {
            previousFlavor.price = uint64(__flavorPrice);
        }

        if (__flavorMaxSupply > 0) {
            if (__flavorMaxSupply < previousFlavor.totalMinted) revert InvalidMaxSupply();

            if (__flavorMaxSupply > previousFlavor.maxSupply) {
                _incrementMaxSupply(__flavorMaxSupply - previousFlavor.maxSupply);
            } else {
                _decrementMaxSupply(previousFlavor.maxSupply - __flavorMaxSupply);
            }

            previousFlavor.maxSupply = uint64(__flavorMaxSupply);
        }

        previousFlavor.flavorId = uint64(__flavorId); // This doesn't strictly need to be done, but doing it anyway.
        previousFlavor.uriFragment = __flavorUri;

        _updateFlavorInfo(previousFlavor);
    }

    function _getUriFragmentForToken(
        uint256 tokenId,
        FlavorInfo memory tokenFlavor
    ) internal pure returns (string memory) {
        _checkFlavorIsValid(tokenFlavor);

        return
            string(
                abi.encodePacked(tokenFlavor.uriFragment, _tokenFilenameForFlavoredToken(tokenId))
            );
    }

    function _tokenFilenameForFlavoredToken(uint256 tokenId) internal pure returns (string memory) {
        // Special: Append the slash, so it looks like '/0'
        return string(abi.encodePacked('/', tokenId.toString()));
    }

    function _checkFlavorIsValid(FlavorInfo memory tokenFlavor) internal pure {
        if (tokenFlavor.flavorId == 0) revert UnrecognizedFlavorId();
    }

    function _checkValueIsValid(
        FlavorInfo memory tokenFlavor,
        uint256 count,
        uint256 valueSent
    ) internal pure {
        uint256 valueNeeded = tokenFlavor.price * count;
        if (valueSent != valueNeeded) revert InvalidValuePayment();
    }

    function _checkCountIsValid(FlavorInfo memory tokenFlavor, uint256 count) internal pure {
        if (tokenFlavor.maxSupply == 0) return; // Open Edition
        if (tokenFlavor.totalMinted + count > tokenFlavor.maxSupply)
            revert ExceedsMaxSupplyForFlavor();
    }
}