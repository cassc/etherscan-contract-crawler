// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

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
abstract contract ExpandableTypedTokenExtension is AccessControl {
    using Strings for uint256;

    bool private immutable ALLOW_MAX_SUPPLY_INCREASE;
    uint256 private _maxSupply;

    struct TokenFlavor {
        uint64 flavorId;
        uint64 price;
        uint64 maxSupply;
        uint64 totalMinted;
        string uriFragment;
    }

    // Storage for Token Flavors
    mapping(uint256 => TokenFlavor) private _tokenFlavors;

    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR_ROLE');

    constructor(bool __allowMaxSupplyIncrease) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // CREATOR_ROLE can create new flavors and update existing ones.
        _grantRole(CREATOR_ROLE, msg.sender);

        ALLOW_MAX_SUPPLY_INCREASE = __allowMaxSupplyIncrease;

        _initializeFlavors();
    }

    function _getInitialFlavors() internal virtual returns (TokenFlavor[] memory);

    function _initializeFlavors() private {
        TokenFlavor[] memory initialTokenFlavors = _getInitialFlavors();

        for (uint256 idx = 0; idx < initialTokenFlavors.length; idx++) {
            TokenFlavor memory current = initialTokenFlavors[idx];
            _maxSupply += current.maxSupply;
            _tokenFlavors[current.flavorId] = current;
        }
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
            TokenFlavor memory newFlavor = TokenFlavor(
                uint64(__flavorIds[idx]),
                uint64(__flavorPrices[idx]),
                uint64(__flavorMaxSupplies[idx]),
                0,
                __flavorUris[idx]
            );
            _maxSupply += newFlavor.maxSupply;
            _tokenFlavors[newFlavor.flavorId] = newFlavor;
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

        TokenFlavor memory previousFlavor = _tokenFlavors[__flavorId];
        _checkFlavorIsValid(previousFlavor);

        if (__flavorPrice > 0) {
            previousFlavor.price = uint64(__flavorPrice);
        }

        if (__flavorMaxSupply > 0) {
            if (__flavorMaxSupply < previousFlavor.totalMinted) revert InvalidMaxSupply();

            _maxSupply += (__flavorMaxSupply - previousFlavor.maxSupply);
            previousFlavor.maxSupply = uint64(__flavorMaxSupply);
        }

        previousFlavor.flavorId = uint64(__flavorId); // This doesn't strictly need to be done, but doing it anyway.
        previousFlavor.uriFragment = __flavorUri;

        _tokenFlavors[__flavorId] = previousFlavor;
    }

    function _expandableMaxSupply() internal view returns (uint256) {
        return _maxSupply;
    }

    function _getTokenFlavor(uint256 flavorId) internal view returns (TokenFlavor memory) {
        return _tokenFlavors[flavorId];
    }

    function _saveTokenFlavor(TokenFlavor memory tokenFlavor) internal {
        _tokenFlavors[tokenFlavor.flavorId] = tokenFlavor;
    }

    function _getUriFragmentForToken(uint256 tokenId, TokenFlavor memory tokenFlavor)
        internal
        pure
        returns (string memory)
    {
        _checkFlavorIsValid(tokenFlavor);

        return string(abi.encodePacked(tokenFlavor.uriFragment, _tokenFilenameForFlavoredToken(tokenId)));
    }

    function _tokenFilenameForFlavoredToken(uint256 tokenId) internal pure returns (string memory) {
        // Special: Append the slash, so it looks like '/0'
        return string(abi.encodePacked('/', tokenId.toString()));
    }

    function _checkFlavorIsValid(TokenFlavor memory tokenFlavor) internal pure {
        if (tokenFlavor.flavorId == 0) revert UnrecognizedFlavorId();
    }

    function _checkValueIsValid(
        TokenFlavor memory tokenFlavor,
        uint256 count,
        uint256 valueSent
    ) internal pure {
        uint256 valueNeeded = tokenFlavor.price * count;
        if (valueSent != valueNeeded) revert InvalidValuePayment();
    }

    function _checkCountIsValid(TokenFlavor memory tokenFlavor, uint256 count) internal pure {
        if (tokenFlavor.maxSupply == 0) return; // Open Edition
        if (tokenFlavor.totalMinted + count > tokenFlavor.maxSupply) revert ExceedsMaxSupplyForFlavor();
    }
}