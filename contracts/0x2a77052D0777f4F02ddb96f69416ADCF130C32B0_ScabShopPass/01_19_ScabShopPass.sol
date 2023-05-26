// SPDX-License-Identifier: MIT

/**
░░░░░░░░▒░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░▒░░░░░░░░░
░░░░░░▒▓███░░░░░░░░▒▒▒▒▒░░▒▒███░░░░░░░▓▒██░░░░░░░░
░░░░▓█░░░▓█▒░░░░▒▓▒░░░░░░░░░░██░░░░░░██▒░██░░░░░░░
░░░░▒██░░▒▒░░░░▓█░░░░░░░░░░░░██▓░░░░░▓█▓░▒█▒░░░░░░
░░░░░▒██░░░░░░██░░░░░░░░░░░░▒░██▒░░░░▓█▓▒▒░░░░░░░░
░░░░░░▓██░░░░▓█▒░░░░░░░░░░░░▒░▒██░░░░▓██▓▓░░░░░░░░
░░░░░░░▓██░░░██░░░░░░░░░░░░▓░░░██▒░░░▓█▓▒██░░░░░░░
░░░░░░░░██▓░░██▒░░░░░░░░░░▒░░░░▒██░░░▓█▓░▓██░░░░░░
░░░░░░░░░██▓░▓██░░░░░░░░░▒▒░░░░░██▒░░▓█▓░░▓██░░░░░
░░░░░░░░░░██▒░██▓░░░░▓███████▒░░▒██░░▓█▓░░░█▓░░░░░
░░░░▒█▒░░░░█▓░░▓█▓░░░░░░░░░░░░░░░▓█▒░▓█▓░░▒░░░░░░░
░░░░▓██░░░▒░░░░░▒██▒░░░░░░░░░░░▓░░░░░▓██▒░░░░░░░░░
░░░░░▓██▓░░░░░░░░░░▒▓▓▓▒▒░░▒▒▓▓▒░░░░░▓▓░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

CTHDRL x Scott Campbell

Contract: Shop Pass by Scab Shop
Forked From: https://github.com/ourzora/nft-editions
Original Creators: Zora & The Legendary Iain Nash
**/

pragma solidity ^0.8.6;

import {ERC721Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import {IERC2981Upgradeable, IERC165Upgradeable} from '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {CountersUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import {AddressUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import {SharedNFTLogic} from './ScabShopPass/SharedNFTLogic.sol';
import {IEditionSingleMintable} from './ScabShopPass/IEditionSingleMintable.sol';

/**
    This is a smart contract for handling dynamic contract minting.
*/
contract ScabShopPass is
    ERC721Upgradeable,
    IEditionSingleMintable,
    IERC2981Upgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    event PriceChanged(uint256 amount);
    event AllowListChanged(bytes32 root);
    event StartTimeChanged(uint256 time);
    event EditionSold(uint256 price, address owner);

    // metadata
    string public description;

    // Metadata for
    string private _contractURI;

    // Media Urls
    // animation_url field in the metadata
    string private animationUrl;
    // Hash for the associated animation
    bytes32 private animationHash;
    // Image in the metadata
    string private imageUrl;
    // Hash for the associated image
    bytes32 private imageHash;

    // Total size of edition that can be minted
    uint256 public editionSize;

    // Current token id minted
    CountersUpgradeable.Counter private atEditionId;

    // Royalty amount in bps
    uint256 royaltyBPS;

    // Addresses that have claimed their allowlist spot
    mapping(address => uint16) allowlistClaimed;

    // Price for sale
    uint256 public salePrice;

    // Merkle root for allowlist
    bytes32 public alMerkleRoot;

    // Start time for purhcasing to be available
    uint256 public startTime;

    // NFT rendering logic contract
    SharedNFTLogic private immutable sharedNFTLogic;

    // Global constructor for factory
    constructor(SharedNFTLogic _sharedNFTLogic) {
        sharedNFTLogic = _sharedNFTLogic;
    }

    /**
      @param _owner User that owns and can mint the edition, gets royalty and sales payouts and can update the base url if needed.
      @param _name Name of edition, used in the title as "$NAME NUMBER/TOTAL"
      @param _symbol Symbol of the new token contract
      @param _description Description of edition, used in the description field of the NFT
      @param _imageUrl Image URL of the edition. Strongly encouraged to be used, if necessary, only animation URL can be used. One of animation and image url need to exist in a edition to render the NFT.
      @param _imageHash SHA256 of the given image in bytes32 format (0xHASH). If no image is included, the hash can be zero.
      @param _animationUrl Animation URL of the edition. Not required, but if omitted image URL needs to be included. This follows the opensea spec for NFTs
      @param _animationHash The associated hash of the animation in sha-256 bytes32 format. If animation is omitted the hash can be zero.
      @param _editionSize Number of editions that can be minted in total. If 0, unlimited editions can be minted.
      @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
      @param _startTime Time that purchasing will be available
      @dev Function to create a new edition. Can only be called by the allowed creator
           Sets the only allowed minter to the address that creates/owns the edition.
           This can be re-assigned or updated later
     */
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _animationUrl,
        bytes32 _animationHash,
        string memory _imageUrl,
        bytes32 _imageHash,
        uint256 _editionSize,
        uint256 _royaltyBPS,
        uint256 _startTime
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        // Set ownership to original sender of contract call
        transferOwnership(_owner);
        description = _description;
        animationUrl = _animationUrl;
        animationHash = _animationHash;
        imageUrl = _imageUrl;
        imageHash = _imageHash;
        editionSize = _editionSize;
        royaltyBPS = _royaltyBPS;
        startTime = _startTime;
        // Set edition id start to be 1 not 0
        atEditionId.increment();
    }

    /**
        ADMIN
     */

    /**
        Simple override for owner interface.
     */
    function owner()
        public
        view
        override(OwnableUpgradeable, IEditionSingleMintable)
        returns (address)
    {
        return super.owner();
    }

    /**
      @dev Allows for updates of edition urls by the owner of the edition.
           Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function updateEditionURLs(
        string memory _imageUrl,
        string memory _animationUrl
    ) public onlyOwner {
        imageUrl = _imageUrl;
        animationUrl = _animationUrl;
    }

    /**
      @param _salePrice if sale price is 0 sale is stopped, otherwise that amount
                       of ETH is needed to start the sale.
      @dev This sets a simple ETH sales price
           Setting a sales price allows users to mint the edition until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
        emit PriceChanged(salePrice);
    }

    /**
      @param _merkleRoot is the precalculated merkle root for a given
                        state of the allowlist.
      @dev This sets the merkle root, which controls what wallets are
           on the allowlist and allowed to mint during the pre-mint.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        alMerkleRoot = _merkleRoot;
        emit AllowListChanged(alMerkleRoot);
    }

    /**
        @param _startTime The UNIX timestamp when purchases will be allowed to be made
     */
    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
        emit StartTimeChanged(startTime);
    }

    /**
        @param newContractURI The URI of the new contract metadata
     */
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    /**
      @dev Makes the contract URI public
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
      @dev This withdraws ETH from the contract to the contract owner.
     */
    function withdraw() external onlyOwner {
        // No need for gas limit to trusted address.
        AddressUpgradeable.sendValue(payable(owner()), address(this).balance);
    }

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditions(address[] memory recipients)
        external
        override
        onlyOwner
        returns (uint256)
    {
        return _mintEditions(recipients);
    }

    /**
      @param to address to send the newly minted edition to
      @dev This mints a single edition to the given address.
     */
    function mintEdition(address to)
        external
        override
        onlyOwner
        returns (uint256)
    {
        address[] memory toMint = new address[](1);
        toMint[0] = to;
        return _mintEditions(toMint);
    }

    /**
        USER
     */

    /**
        Simple eth-based sales function
        More complex sales functions can be implemented through ISingleEditionMintable interface
     */

    /**
      @dev This allows the user to purchase an edition
           at the given price in the contract.
     */
    function purchase() external payable returns (uint256) {
        require(salePrice > 0, 'Not for sale');
        require(msg.value == salePrice, 'Wrong price');
        require(block.timestamp > startTime, 'Purchasing is not yet available');
        require(
            balanceOf(msg.sender) < 5 || msg.sender == owner(),
            'Limit three passes per wallet'
        );

        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;
        emit EditionSold(salePrice, msg.sender);
        return _mintEditions(toMint);
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'Not approved');
        _burn(tokenId);
    }

    /**
        MINTING
     */

    /**
      @param proof merkle proof that sender is on the allowlist
      @dev This allows the user on the allowlist to purchase an edition
           at the given price in the contract before the sale start time.
     */
    function prePurchase(bytes32[] calldata proof)
        external
        payable
        returns (uint256)
    {
        require(salePrice > 0, 'Price not set');
        require(msg.value == salePrice, 'Wrong price');
        require(_isAllowedToMint(), 'Needs to be an allowed minter.');

        // Check merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, alMerkleRoot, leaf),
            'Needs to be on the allowlist.'
        );

        // Increment claim of this address
        allowlistClaimed[msg.sender] += 1;

        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;
        emit EditionSold(salePrice, msg.sender);
        return _mintEditions(toMint);
    }

    /**
      @dev Private function to mint als without any access checks.
           Called by the public edition minting functions.
     */
    function _mintEditions(address[] memory recipients)
        internal
        returns (uint256)
    {
        uint256 startAt = atEditionId.current();
        uint256 endAt = startAt + recipients.length - 1;
        require(editionSize == 0 || endAt <= editionSize, 'Sold out');
        while (atEditionId.current() <= endAt) {
            _mint(
                recipients[atEditionId.current() - startAt],
                atEditionId.current()
            );
            atEditionId.increment();
        }
        return atEditionId.current();
    }

    /**
      @dev This helper function checks if the msg.sender is allowed to mint the
            given edition id.
     */
    function _isAllowedToMint() internal view returns (bool) {
        if (owner() == msg.sender) {
            return true;
        }
        return allowlistClaimed[msg.sender] < 3;
    }

    /**
        INFO
     */

    /// Returns the number of editions allowed to mint (max_uint256 when open edition)
    function numberCanMint() public view override returns (uint256) {
        // Return max int if open edition
        if (editionSize == 0) {
            return type(uint256).max;
        }
        // atEditionId is one-indexed hence the need to remove one here
        return editionSize + 1 - atEditionId.current();
    }

    /// @dev returns the number of minted tokens within the edition
    function totalSupply() public view returns (uint256) {
        return atEditionId.current() - 1;
    }

    /**
      @dev Get URIs for edition NFT
      @return imageUrl, imageHash, animationUrl, animationHash
     */
    function getURIs()
        public
        view
        returns (
            string memory,
            bytes32,
            string memory,
            bytes32
        )
    {
        return (imageUrl, imageHash, animationUrl, animationHash);
    }

    /**
        @dev Get royalty information for token
        @param _salePrice Sale price for the token
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (owner() == address(0x0)) {
            return (owner(), 0);
        }
        return (owner(), (_salePrice * royaltyBPS) / 10_000);
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), 'No token');

        return
            sharedNFTLogic.createMetadataEdition(
                name(),
                description,
                imageUrl,
                animationUrl,
                tokenId,
                editionSize
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }
}