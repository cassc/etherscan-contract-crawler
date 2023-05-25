//SPDX-License-Identifier: Unlicense

/// @notice MetadataUpadable
/// @author Aureliano Arcon <@aurelarcon> <aurelianoa.eth>
/// @dev This will handle all the necesary functions for the metadata be dynamic

pragma solidity ^0.8.17;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MetadataUpdatable is Ownable {
    using Strings for uint256;

    bool private isRevealed = false;
    string private _contractURI = "";
    string private tokenBaseURI = "";
    string private tokenRevealedBaseURI = "";
    string private tokenBucketURI = "";

    /// @dev struct of a variant
    struct Variant {
        /// @dev the seed of the metadata (CID)
        string seed;

        /// @dev price if aplicable
        uint256 price;

        /// @dev if is active for swap
        bool active;
    }

    /// @dev  mapping (key => variant)
    mapping(string => Variant) private variantMetadata;
    /// @dev mapping(tokenId => key)
    mapping(uint256 => string) private selectedVariant;

    /// events
    event VariantUpdated(uint256 tokenId, string variant);
    event ContractURIUpdated(address indexed _account);
    event BaseURIUpdated(address indexed _account);
    event IsRevealedBaseURI(address indexed _account);

    /// errors
    error NotValidVariantProvided(string variant);


    function _setSelectedVariant(uint256 tokenId, string memory variant) internal {
        if(!isValidVariant(variant)) {
            revert NotValidVariantProvided(variant);
        }
        selectedVariant[tokenId] = variant;

        emit VariantUpdated(tokenId, variant);
    }

    function getSeedByVariant(string memory variant) internal view returns (string memory) {
        return variantMetadata[variant].seed;
    }

    /// will construct the resulted metadata URI String
    /// @notice this will be called by the tokenUri
    /// @param tokenId uint256
    function getTokenURI(uint256 tokenId) internal view returns (string memory) {
        if(!isRevealed) {
            return tokenBaseURI;
        } 
        string memory key = selectedVariant[tokenId];
        string memory bucketURI = tokenBucketURI;
        string memory postURI = "";
        if(bytes(bucketURI).length > 0) {
            postURI = string(abi.encodePacked(tokenBucketURI, "/"));
        }
        return string(abi.encodePacked(
            tokenRevealedBaseURI,  
            variantMetadata[key].seed, 
            "/", 
            postURI,
            tokenId.toString(),
            ".json"
            ));
    }

    /// EXTERNAL FUNCTIONS

    /// create or edit a variant
    /// @param variant string
    /// @param seed string
    /// @param price uint256
    function setVariant(string memory variant, string memory seed, uint256 price, bool active) external onlyOwner {
        Variant memory _variant = Variant (
            seed,
            price,
            active
        );
        variantMetadata[variant] = _variant;
    }

    function setReveal(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }
 
    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;

        emit ContractURIUpdated(msg.sender);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        tokenBaseURI = uri;

        emit BaseURIUpdated(msg.sender);
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
        tokenRevealedBaseURI = revealedBaseURI;

        emit IsRevealedBaseURI(msg.sender);
    }

    function setRevealedBucketURI(string calldata bucketURI) external onlyOwner {
        tokenBucketURI = bucketURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// HELPERS

    function isValidVariant(string memory variant) internal view returns (bool) {
        return variantMetadata[variant].active;
    }

    function getVariantPrice(string memory variant) internal view returns (uint256) {
        return variantMetadata[variant].price;
    }

    function isMetadataRevealed() public view returns (bool) {
        return isRevealed;
    }
}