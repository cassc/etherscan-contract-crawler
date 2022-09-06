// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {NFTSale} from "./NFTSale.sol";
import {RandomnessBatches} from "./RandomnessBatches.sol";
import {TokenURI} from "./TokenURI.sol";

/// The main Wassieverse contract
///
/// Besides the top level logic, we rely on several inherited contracts:
///   - {ERC721A} - The underlying NFT implementation
///   - {NFTSale} - Details of the token sale (whitelist and public) are in {NFTSale}
///   - {TokenURI} - Deals with the ability to futurely add updated metadata,
///     and allow users to flip their items between the two
///   - {RandomnessBatches} deal with batch reveals in a pseudo-random way
///
/// @dev Unfortunately, we need both AccessControl and Ownable. The first
///   because of our internal logic, the later because OpenSea wants us to
contract WassieverseNFT is
    NFTSale,
    TokenURI,
    RandomnessBatches,
    ERC721A,
    ERC2981,
    Ownable
{
    using Strings for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant ROYALTIES_ROLE = keccak256("ROYALTIES_ROLE");
    bytes32 public constant REVEAL_ROLE = keccak256("REVEAL_ROLE");

    error NotAuthorized();

    /// @param _startWhitelist start of whitelisted sale
    /// @param _startPublic start of public sale
    /// @param _priceWhitelist item price for whitelist sale
    /// @param _pricePub item price for public sale
    /// @param _supply Max total supply
    /// @param _whitelistMax max whitelist minting allowance
    /// @param _publicMax max public minting allowance
    /// @param _whitelistMerkleRoot merkle root used to authenticate whitelisted mints
    /// @param _revealBatchSize Size of each reveal batch
    /// @param _baseURI base URI for revealed items
    /// @param _unrevealedURI full URI for all items while unrevealed
    constructor(
        uint64 _startWhitelist,
        uint64 _startPublic,
        uint256 _priceWhitelist,
        uint256 _pricePub,
        uint16 _supply,
        uint16 _whitelistMax,
        uint16 _publicMax,
        bytes32 _whitelistMerkleRoot,
        uint16 _revealBatchSize,
        string memory _baseURI,
        string memory _unrevealedURI
    )
        NFTSale(
            _startWhitelist,
            _startPublic,
            _priceWhitelist,
            _pricePub,
            _supply,
            _whitelistMax,
            _publicMax,
            _whitelistMerkleRoot
        )
        RandomnessBatches(_supply, _revealBatchSize, _startWhitelist)
        ERC721A("Wassieverse", "WASSIE")
    {
        _updateRegularBaseURI(_baseURI);
        _updateUnrevealedURI(_unrevealedURI);

        _grantRole(ROYALTIES_ROLE, msg.sender);
        _grantRole(REVEAL_ROLE, msg.sender);
    }

    /// Sets a new regularBaseURI
    /// Can only be called until sales actually start
    /// @dev To minimize human-error, it checks that the URI ends with `/`
    ///   (since without `/` URI would still be valid, but wouldn't concat
    ///   properly with tokenId)
    /// @param _newRegularBaseURI new URI to use
    function updateRegularBaseURI(string memory _newRegularBaseURI)
        external
        onlyRole(SALE_ROLE)
        onlyUntilImmutable
    {
        _updateRegularBaseURI(_newRegularBaseURI);
    }

    /// Sets a new unrevealedURI
    /// Can only be called until sales actually start
    /// @param _newUnrevealedURI new URI to use
    function updateUnrevealedURI(string memory _newUnrevealedURI)
        external
        onlyOwner
        onlyUntilImmutable
    {
        _updateUnrevealedURI(_newUnrevealedURI);
    }

    //
    // ERC721A
    //

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 id)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        uint256 shuffledID = shuffleID(id);
        if (shuffledID == 0) {
            return unrevealedURI;
        } else {
            return
                string(
                    abi.encodePacked(
                        baseURIFor(id),
                        shuffledID.toString(),
                        ".json"
                    )
                );
        }
    }

    //
    // ERC165
    //

    /// @dev See {IERC165-supportsInterface}
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721A, NFTSale, AccessControl)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId) ||
            NFTSale.supportsInterface(interfaceId);
    }

    //
    // ERC2981
    //

    /// Sets the royalty information that all ids in this contract will default to.
    ///
    /// @param _receiver cannot be the zero address.
    /// @param _feeNumerator cannot be greater than the fee denominator.
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyRole(ROYALTIES_ROLE)
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// Removes default royalty information
    function deleteDefaultRoyalty() external onlyRole(ROYALTIES_ROLE) {
        _deleteDefaultRoyalty();
    }

    //
    // Public API
    //

    /// Withdraws any ERC20 tokens sent to the contract by mistake
    /// @dev only callable by the admin role
    ///
    /// @param token The ERC20 token to withdraw
    /// @param amount The amount to withdraw
    function withdrawERC20(IERC20 token, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        token.safeTransfer(msg.sender, amount);
    }

    /// Allows holders to flip an item between old and new metadata
    /// Only works after new metadata is set and commited by the team
    ///
    /// @notice After triggering this, a metadata refresh may be needed on frontends to reflect changes
    /// @notice The token ID required is *not* the one shown on the JSON, which is a randomized one, but rather the on-chain one. See `{unshuffleID}`
    ///
    /// @param _id the internal ID of the item
    /// @param _v the new value. `true` means new metadata will be used
    function flipURI(uint256 _id, bool _v) external {
        if (ownerOf(_id) != msg.sender) {
            revert NotAuthorized();
        }

        _flipURI(_id, _v);
    }

    /// Reveals a single batch
    /// @notice Can only be called by the allowed role
    function forceReveal(uint256 _batchIdx)
        external
        onlyRole(REVEAL_ROLE)
        rngContribute
    {
        _rngReveal(_batchIdx);
    }

    /// Reveals a single batch
    /// Can be called by anyone, but only works under two conditions:
    ///   - The batch has been fully minted (e.g.: batch 0: items 0..249)
    ///   - A grace period of two weeks has passed since mintint started
    function publicReveal(uint256 _batchIdx) external rngContribute {
        _rngTryReveal(_batchIdx, totalSupply());
    }

    //
    // Internal
    //

    /// @inheritdoc NFTSale
    function _mintFromSale(address _to, uint256 _quantity)
        internal
        override(NFTSale)
        rngContribute
    {
        _mint(_to, _quantity);
    }
}