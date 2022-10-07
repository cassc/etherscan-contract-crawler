// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdventureERC721.sol";
import "../initializable/IRoyaltiesInitializer.sol";
import "../initializable/IURIInitializer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error AlreadyInitializedRoyalties();
error AlreadyInitializedURI();
error ExceedsMaxRoyaltyFee();
error NonexistentToken();

/**
 * @title AdventureNFT
 * @author Limit Break, Inc.
 * @notice Standardizes commonly shared boilerplate code that adds base/suffix URI and EIP-2981 royalties to {AdventureERC721} contracts.
 */
abstract contract AdventureNFT is AdventureERC721, ERC2981, IRoyaltiesInitializer, IURIInitializer {
    using Strings for uint256;

    /// @dev The maximum allowable royalty fee is 10%
    uint96 public constant MAX_ROYALTY_FEE_NUMERATOR = 1000;

    /// @notice Specifies whether or not the contract is initialized
    bool public initializedRoyalties;

    /// @notice Specifies whether or not the contract is initialized
    bool public initializedURI;

    /// @dev Base token uri
    string public baseTokenURI;

    /// @dev Token uri suffix/extension
    string public suffixURI = ".json";

    /// @dev Emitted when base URI is set.
    event BaseURISet(string baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string suffixURI);

    /// @dev Emitted when royalty is set.
    event RoyaltySet(address receiver, uint96 feeNumerator);

    /// @dev Initializes parameters of tokens with royalties.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeRoyalties(address receiver, uint96 feeNumerator) public override onlyOwner {
        if(initializedRoyalties) {
            revert AlreadyInitializedRoyalties();
        }

        setRoyaltyInfo(receiver, feeNumerator);

        initializedRoyalties = true;
    }

    /// @dev Initializes parameters of tokens with uri values.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeURI(string memory baseURI_, string memory suffixURI_) public override onlyOwner {
        if(initializedURI) {
            revert AlreadyInitializedURI();
        }

        setBaseURI(baseURI_);
        setSuffixURI(suffixURI_);

        initializedURI = true;
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Sets base URI
    function setBaseURI(string memory baseTokenURI_) public onlyOwner {
        baseTokenURI = baseTokenURI_;

        emit BaseURISet(baseTokenURI_);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string memory suffixURI_) public onlyOwner {
        suffixURI = suffixURI_;

        emit SuffixURISet(suffixURI_);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
        if(feeNumerator > MAX_ROYALTY_FEE_NUMERATOR) {
            revert ExceedsMaxRoyaltyFee();
        }
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltySet(receiver, feeNumerator);
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) {
            revert NonexistentToken();
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AdventureERC721, ERC2981, IERC165) returns (bool) {
        return
        interfaceId == type(IRoyaltiesInitializer).interfaceId ||
        interfaceId == type(IURIInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}