// SPDX-License-Identifier: Unlicense
// Version 0.0.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./utils.sol";

contract Eve is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    Ownable,
    Pausable,
    ERC2981,
    DefaultOperatorFilterer
{
    using Address for address;
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    // Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");

    // Constants
    address public constant CUSTOM_SUBSCRIPTION =
        address(0x6438fa583f5f60E37Dcd969D87A515b2b84C4219);
    uint32 public constant MAX_NFTS = 2000; // Maximum allowed number of NFTs
    uint32 public constant MAX_MYTHIC_NFTS = 50; // Maximum allowed number of Mythic NFTs
    uint8 public constant RARITY_COMMON = 1;
    uint8 public constant RARITY_RARE = 2;
    uint8 public constant RARITY_EPIC = 3;
    uint8 public constant RARITY_MYTHIC = 4;

    // Private variables
    string private _baseURI_;
    string private _contractURI;

    BitMaps.BitMap private _isRare;
    BitMaps.BitMap private _isEpic;
    BitMaps.BitMap private _isStaked; // tokenId => stake or not

    // We use 2 ranges of token IDs:
    // 0 - 49: Mythic NFTs
    // 50 - 1999: Normal NFTs
    uint256 private _nextTokenId;
    uint256 private _nextMythicTokenId;

    /// @notice Initializes a new instance of the Eve contract.
    /// @param defaultAdmin_ The address of the default admin
    /// @param defaultRoyalty_ The default royalty percentage
    /// @param baseURI_ The base URI for all NFTs
    /// @param contractURI_ The URI for the contract metadata
    constructor(
        address defaultAdmin_,
        uint96 defaultRoyalty_,
        string memory baseURI_,
        string memory contractURI_
    ) ERC721("Eve", "DM01") DefaultOperatorFilterer() {
        if (defaultAdmin_ == address(0)) {
            revert Utils.AdminIsZeroAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);

        if (defaultRoyalty_ == 0) {
            revert Utils.RoyaltyIsZero();
        }
        _setDefaultRoyalty(defaultAdmin_, defaultRoyalty_);

        _baseURI_ = baseURI_;
        _contractURI = contractURI_;

        _nextTokenId = MAX_MYTHIC_NFTS;
    }

    //------------------------------//
    //        NFT Properties        //
    //------------------------------//

    /// @notice Set the specified NFTs as rare
    /// @dev Only callable by DEFAULT_ADMIN_ROLE
    /// @param tokenIds_ An array of tokenIds
    function setRare(
        uint256[] calldata tokenIds_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds_.length; ) {
            _isRare.set(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the specified NFTs as epic
    /// @dev Only callable by DEFAULT_ADMIN_ROLE
    /// @param tokenIds_ An array of tokenIds
    function setEpic(
        uint256[] calldata tokenIds_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds_.length; ) {
            _isEpic.set(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Determines the rarity of the specified NFTs
    /// Should only be called off-chain
    /// @param tokenIds_ An array of tokenIds to check the rarity of
    /// @return results An array of rarities of the corresponding tokenIds
    function getRarities(
        uint256[] calldata tokenIds_
    ) external view returns (uint8[] memory) {
        uint8[] memory results = new uint8[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; ) {
            if (_exists(tokenIds_[i])) {
                results[i] = tokenIds_[i] < MAX_MYTHIC_NFTS
                    ? RARITY_MYTHIC
                    : (
                        _isEpic.get(tokenIds_[i])
                            ? RARITY_EPIC
                            : (
                                _isRare.get(tokenIds_[i])
                                    ? RARITY_RARE
                                    : RARITY_COMMON
                            )
                    );
            }
            unchecked {
                ++i;
            }
        }
        return results;
    }

    //------------------//
    //     Mint         //
    //------------------//
    /// @dev Mints `tokenId_` and transfers it to `to_`.
    function _mint(address to_, uint256 tokenId_) internal override(ERC721) {
        if (totalSupply() >= MAX_NFTS) {
            revert Utils.NFTQuantityExceedsLimit();
        }
        super._mint(to_, tokenId_);
    }

    /// @dev Safely mints a normal NFT and assigns it to the specified address.
    /// @notice This function can only be called by the contract itself.
    /// @param to_ The address to assign the minted NFT
    /// @return tokenId_ The unique token ID of the NFT
    function _mintNormal(address to_) internal returns (uint256) {
        if (_nextTokenId >= MAX_NFTS) {
            revert Utils.NFTQuantityExceedsLimit();
        }

        uint256 tokenId = _nextTokenId;
        unchecked {
            ++_nextTokenId;
        }
        _mint(to_, tokenId);

        return tokenId;
    }

    /// @dev Safely mints a Mythic NFT and assigns it to the specified address.
    /// @notice This function can only be called by the contract itself.
    /// @param to_ The address to assign the minted NFT
    /// @return tokenId_ The unique token ID of the NFT
    function _mintMythic(address to_) internal returns (uint256) {
        if (_nextMythicTokenId >= MAX_MYTHIC_NFTS) {
            revert Utils.NFTQuantityExceedsLimit();
        }
        uint256 tokenId = _nextMythicTokenId;
        unchecked {
            ++_nextMythicTokenId;
        }
        _mint(to_, tokenId);

        return tokenId;
    }

    /// @notice Mint a number of normal NFTs to an address
    /// @dev Only callable by MINTER_ROLE
    /// @param to_ The address to mint to
    /// @param quantity_ The quantity of NFTs to mint
    /// @return tokenIds An array containing the minted tokenIds
    function mintNormal(
        address to_,
        uint256 quantity_
    ) external onlyRole(MINTER_ROLE) returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](quantity_);
        for (uint256 i = 0; i < quantity_; ) {
            tokenIds[i] = _mintNormal(to_);
            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    /// @notice Mint a number of Mythic NFTs to an address
    /// @dev Only callable by MINTER_ROLE
    /// @param to_ The address to mint to
    /// @param quantity_ The quantity of Mythic NFTs to mint
    /// @return tokenIds An array containing the minted tokenIds
    function mintMythic(
        address to_,
        uint256 quantity_
    ) external onlyRole(MINTER_ROLE) returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](quantity_);
        for (uint256 i = 0; i < quantity_; ) {
            tokenIds[i] = _mintMythic(to_);
            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    /// @notice Allows developers to mint tokens for testing purposes.
    /// @param tos_ The addresses to mint to
    /// @param quantities_ The quantity of Mythic NFTs to mint for each address
    /// @param isMythics_ Indicate if the corresponding tokens are Mythic for each address
    function devMint(
        address[] calldata tos_,
        uint256[] calldata quantities_,
        bool[] calldata isMythics_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = tos_.length;
        if (length != quantities_.length || length != isMythics_.length) {
            revert Utils.UnmatchedArrayLengths();
        }

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                for (uint256 j = 0; j < quantities_[i]; ++j) {
                    if (isMythics_[i]) {
                        _mintMythic(tos_[i]);
                    } else {
                        _mintNormal(tos_[i]);
                    }
                }
            }
        }
    }

    //------------------//
    //     Stake        //
    //------------------//
    /// @notice Stake specified NFTs
    /// @dev Only callable by STAKER_ROLE
    /// @param tokenIds_ An array of tokenIds to stake
    function stake(
        uint256[] calldata tokenIds_
    ) external onlyRole(STAKER_ROLE) {
        if (tokenIds_.length == 0) {
            revert Utils.QuantityIsZero();
        }
        for (uint256 i = 0; i < tokenIds_.length; ) {
            _isStaked.set(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Unstake specified NFTs
    /// @dev Only callable by STAKER_ROLE
    /// @param tokenIds_ An array of tokenIds to unstake
    function unstake(
        uint256[] calldata tokenIds_
    ) external onlyRole(STAKER_ROLE) {
        if (tokenIds_.length == 0) {
            revert Utils.QuantityIsZero();
        }
        for (uint256 i = 0; i < tokenIds_.length; ) {
            _isStaked.unset(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Check if the specified NFTs are staked
    /// @param tokenIds_ An array of tokenIds to check if they are staked
    /// @return results A boolean array indicating if the corresponding tokenId is staked
    function isStaked(
        uint256[] calldata tokenIds_
    ) external view returns (bool[] memory) {
        bool[] memory results = new bool[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; ) {
            results[i] = _isStaked.get(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
        return results;
    }

    //------------------//
    // Custom overrides //
    //------------------//
    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(
        uint256 tokenId_
    ) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId_);

        string memory __baseURI = _baseURI();
        return
            bytes(__baseURI).length > 0
                ? string(
                    abi.encodePacked(__baseURI, tokenId_.toString(), ".json")
                )
                : "";
    }

    /// @dev Returns the base URI for all tokens.
    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    /// @dev Returns the base URI for all tokens.
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /// @notice Set the base URI for the NFT metadata
    /// @dev Only callable by DEFAULT_ADMIN_ROLE
    /// @param baseURI_ The new base URI
    function setBaseURI(
        string calldata baseURI_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURI_ = baseURI_;
    }

    /// @notice Sets the default royalty percentage for all tokens.
    /// @param receiver_ The address to receive the royalty payment.
    /// @param feeNumerator_ The royalty percentage, from 0 to 100000.
    function setDefaultRoyalty(
        address receiver_,
        uint96 feeNumerator_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    /// @notice Checks if a token with the given ID exists.
    /// @param tokenId_ The token ID to query.
    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }

    /// @notice Returns the next token ID that will be minted.
    function nextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    /// @notice Returns the next Mythic token ID that will be minted.
    function nextMythicTokenId() external view returns (uint256) {
        return _nextMythicTokenId;
    }

    //--------------------------------------------------//
    // The following functions are required by Opensea. //
    //--------------------------------------------------//
    /// @notice Returns the contract metadata URI.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Set the contract URI
    /// @dev Only callable by DEFAULT_ADMIN_ROLE
    /// @param contractURI_ The new contract URI
    function setContractURI(
        string calldata contractURI_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = contractURI_;
    }

    /// @dev Checks if the operator_ is a custom filtered operator.
    /// @param operator_ The operator to check.
    function _checkFilterOperatorCustom(address operator_) internal view {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    CUSTOM_SUBSCRIPTION,
                    operator_
                )
            ) {
                revert OperatorNotAllowed(operator_);
            }
        }
    }

    /// @dev Modifier to allow function execution only by allowed operators with custom approvals defined at CUSTOM_SUBSCRIPTION.
    /// @param operator_ The operator to check.
    modifier onlyAllowedOperatorApprovalCustom(address operator_) {
        _checkFilterOperatorCustom(operator_);
        _;
    }

    /// @dev Modifier to allow function execution only by allowed operators.
    /// @param from_ The operator to check.
    modifier onlyAllowedOperatorCustom(address from_) {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from_ != msg.sender) {
            _checkFilterOperatorCustom(msg.sender);
        }
        _;
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(
        address operator_,
        bool approved_
    )
        public
        override(IERC721, ERC721)
        onlyAllowedOperatorApproval(operator_)
        onlyAllowedOperatorApprovalCustom(operator_)
    {
        super.setApprovalForAll(operator_, approved_);
    }

    /// @dev See {IERC721-approve}.
    function approve(
        address operator_,
        uint256 tokenId_
    )
        public
        override(IERC721, ERC721)
        onlyAllowedOperatorApproval(operator_)
        onlyAllowedOperatorApprovalCustom(operator_)
    {
        super.approve(operator_, tokenId_);
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    )
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from_)
        onlyAllowedOperatorCustom(from_)
    {
        super.transferFrom(from_, to_, tokenId_);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    )
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from_)
        onlyAllowedOperatorCustom(from_)
    {
        super.safeTransferFrom(from_, to_, tokenId_);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    )
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from_)
        onlyAllowedOperatorCustom(from_)
    {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    //------------------------------------------------------------//
    //      The following functions are for contract ownership    //
    //------------------------------------------------------------//

    /// @notice Transfer ownership of the contract to a new account
    /// @dev Can only be called by the current owner
    /// @param newOwner_ The address of the new owner
    function transferOwnership(
        address newOwner_
    ) public override(Ownable) onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newOwner_ == address(0)) {
            revert Utils.TransferOwnershipToZeroAddress();
        }
        _transferOwnership(newOwner_);
    }

    /// @notice Renounce ownership of the contract
    /// @dev Can only be called by the current owner
    function renounceOwnership()
        public
        override(Ownable)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _transferOwnership(address(0));
    }

    //------------------------------------------------------------//
    //      The following functions are for contract pause        //
    //------------------------------------------------------------//
    /// @notice Pause the contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    //------------------------------------------------------------//
    // The following functions are overrides required by Solidity.//
    //------------------------------------------------------------//

    /// @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
    /// used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        uint256 end = firstTokenId_ + batchSize_;
        for (uint256 tokenId = firstTokenId_; tokenId < end; ) {
            if (_isStaked.get(tokenId)) {
                revert Utils.TokenIsStaked();
            }
            unchecked {
                ++tokenId;
            }
        }
        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId_
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC2981)
        returns (bool)
    {
        return
            interfaceId_ == type(IAccessControl).interfaceId ||
            interfaceId_ == type(IERC165).interfaceId ||
            interfaceId_ == type(IERC721).interfaceId ||
            interfaceId_ == type(IERC721Metadata).interfaceId ||
            interfaceId_ == type(IERC721Enumerable).interfaceId ||
            interfaceId_ == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}