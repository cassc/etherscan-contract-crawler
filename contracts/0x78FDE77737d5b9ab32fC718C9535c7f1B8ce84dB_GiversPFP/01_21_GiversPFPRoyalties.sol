// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';

/// @title Givers PFP Collection by Giveth minter contract
/// @notice modified from Hashlips NFT art engine contracts - https://github.com/HashLips/hashlips_nft_contract
/// @notice This contract contains features for an allow list, art reveal/metadata management and payment for NFTs with ERC20 tokens
contract GiversPFP is ERC721Enumerable, Ownable, Pausable, ERC721Royalty {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    /// address `user` is not on the allow list to mint
    error NotInAllowList(address user);
    /// ERC721Metadata: URI query for nonexistent token `tokenId`
    error TokenNotExists(uint256 tokenId);
    /// Zero mint amount, amount must be positive
    error ZeroMintAmount();
    /// Cannot mint more than `maxMintAmount` in one tx
    error ExceedMaxMintAmount(uint256 maxMintAmount);
    /// Cannot exceed total `maxSupply` supply of tokens
    error ExceedTotalSupplyLimit(uint256 maxSupply);
    /// cannot have more than max balance in address
    error ExceedMaxBalance(uint96 maxBalance);

    event Withdrawn(address indexed account, uint256 amount);
    event ChangedURI(string oldURI, string newURI);
    event ChangedBasedExtension(string oldExtension, string newExtension);
    event AllowListAdded(address indexed account);
    event AllowListRemoved(address indexed account);
    event RevealArt();
    event UpdatedPrice(uint256 oldPrice, uint256 newPrice);
    event UpdatedPaymentToken(address indexed oldPaymentToken, address indexed newPaymentToken);
    event UpdatedMaxMint(uint16 newMaxMint);
    event UpdatedMaxSupply(uint256 newMaxSupply);
    event AllowListEnabled(bool allowList);

    string private baseURI;
    string private baseExtension = '.json';
    uint256 public price;
    uint256 public maxSupply;
    string public notRevealedUri;
    mapping(address => bool) public allowList;
    IERC20 public paymentToken;
    uint16 public maxMintAmount;
    bool public revealed = false;
    bool public allowListOnly = true;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory notRevealedUri_,
        uint256 maxSupply_,
        IERC20 paymentToken_,
        uint256 price_,
        uint16 maxMintAmount_
    ) ERC721(name_, symbol_) {
        notRevealedUri = notRevealedUri_;
        paymentToken = paymentToken_;
        price = price_;
        maxSupply = maxSupply_;
        maxMintAmount = maxMintAmount_;
    }

    /// @notice the ipfs CID hash of where the nft metadata is stored
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setRoyaltyDefault(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice This function will mint multiple NFT tokens to an address
    /// @notice charges a final price calculated by the # of NFTs to mint * the base price per NFT
    /// @param mintAmount_ the amount of NFTs you wish to mint, cannot exceed the maxMintAmount variable
    function mint(uint256 mintAmount_) external whenNotPaused {
        if (allowListOnly && !allowList[msg.sender]) {
            revert NotInAllowList(msg.sender);
        }
        paymentToken.safeTransferFrom(msg.sender, address(this), price * mintAmount_);

        _safeMintMany(mintAmount_, msg.sender);
    }

    /// @notice allows the owner to mint NFTs for free to a specified address - the purpose of this function is for the owner to be able to gift NFTs for promotional purposes
    /// @param mintAmount_ the amount of NFTs to mint in a single transaction
    /// @param recipient the recipient of the minted NFT(s)
    function mintTo(uint256 mintAmount_, address recipient) external whenNotPaused onlyOwner {
        _safeMintMany(mintAmount_, recipient);
    }

    /// @notice internal function to safely mint many NFTs
    /// @param mintAmount_ the amount of NFTs to mint in a single transaction
    /// @param recipient the recipient of the minted NFT(s)
    function _safeMintMany(uint256 mintAmount_, address recipient) internal {
        uint256 supply = totalSupply();
        uint256 recipientBalance = balanceOf(recipient);

        if (recipientBalance + mintAmount_ > maxMintAmount) {
            revert ExceedMaxBalance(maxMintAmount);
        }
        if (mintAmount_ == 0) {
            revert ZeroMintAmount();
        }
        if (mintAmount_ > maxMintAmount) {
            revert ExceedMaxMintAmount(maxMintAmount);
        }
        if (supply + mintAmount_ > maxSupply) {
            revert ExceedTotalSupplyLimit(maxSupply);
        }

        for (uint256 i = 1; i <= mintAmount_;) {
            _safeMint(recipient, supply + i);
            unchecked {
                i++;
            }
        }
    }

    /// @notice function use to toggle on and off the allow list, when the allow list is on (true) only users on the allow list can call the mint() function
    /// @param allowListOnly_ controls to set the allow list on (true) or off (false)
    function setAllowListOnly(bool allowListOnly_) external onlyOwner {
        allowListOnly = allowListOnly_;
        emit AllowListEnabled(allowListOnly);
    }

    /// @notice internal function to add a given address to the allow list, allowing it to call mint when allow list is on
    /// @param address_ the address you wish to add to the allow list
    function _addToAllowList(address address_) internal {
        allowList[address_] = true;
        emit AllowListAdded(address_);
    }

    /// @notice add a given address to the allow list, allowing it to call mint when allow list is on
    /// @param address_ the address you wish to add to the allow list
    function addToAllowList(address address_) external onlyOwner {
        _addToAllowList(address_);
    }

    /// @notice adds an array of specified addresses to the allow list, allowing them to call mint when allow list is on
    /// @param addresses_ an array of the addresses you wish to add to the allow list
    function addBatchToAllowList(address[] memory addresses_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length;) {
            _addToAllowList(addresses_[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice removes an address from the allow list, preventing them from calling mint when allow list is on
    /// @param address_ the address you wish to remove from the allow list
    function removeFromAllowList(address address_) external onlyOwner {
        allowList[address_] = false;
        emit AllowListRemoved(address_);
    }

    /// @notice shows which NFT IDs are owned by a specific address
    /// @param owner_ the address you wish to check for which NFT IDs they own.
    function walletOfOwner(address owner_) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokenIds;
    }

    /// @notice displays the ipfs link to where the metadata is stored for a specific NFT ID
    /// @param tokenId the NFT ID of which you wish to get the ipfs CID hash for
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenNotExists(tokenId);
        }

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), baseExtension)) : '';
    }

    /// @notice change the ipfs CID hash of where the nft metadata is stored. effectively can change the metadata of all nfts
    /// @param baseURI_ the ipfs CID you wish to change the base URI to
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice internal function to change the ipfs CID hash of where the nft metadata is stored. effectively can change the metadata of all nfts
    /// @param baseURI_ the ipfs CID you wish to change the base URI to
    function _setBaseURI(string memory baseURI_) internal {
        string memory oldURI = baseURI;
        baseURI = baseURI_;
        emit ChangedURI(oldURI, baseURI);
    }

    /// @notice changes the metadata for all nfts from the base "hidden" image and nft metadata to the final unique artwork and metadata for the collection
    /// @param baseURI_ the ipfs CID where the final metadata is stored
    function reveal(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
        revealed = true;
        emit RevealArt();
    }

    /// @notice changes the price per NFT in the specified ERC20 token
    /// @param newPrice_ the new price to pay per NFT minted
    function setPrice(uint256 newPrice_) external onlyOwner {
        uint256 oldPrice = price;
        price = newPrice_;
        emit UpdatedPrice(oldPrice, price);
    }

    /// @notice changes the ERC20 token accepted to pay for NFTs to mint
    /// @param paymentToken_ the address of a compatible ERC20 token to accept as payments
    /// @dev withdraws any positive balance of old token before chaining paymentToken
    function withdrawAndChangePaymentToken(IERC20 paymentToken_) external onlyOwner {
        _withdraw();
        address oldPaymentToken = address(paymentToken);
        paymentToken = paymentToken_;
        emit UpdatedPaymentToken(oldPaymentToken, address(paymentToken));
    }

    /// @notice change the maximum amount of NFTs of this collection that can be minted in on tx with mint()
    /// @param maxMintAmount_ the new maximum of NFTs that can be minted in one tx (max 256)
    function setMaxMintAmount(uint16 maxMintAmount_) external onlyOwner {
        maxMintAmount = maxMintAmount_;
        emit UpdatedMaxMint(maxMintAmount);
    }

    /// @notice change the maximum supply of the NFT collection - used to extend the collection if there is more art available
    /// @param maxSupply_ the new max supply of the nft collection
    function setMaxSupply(uint96 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
        emit UpdatedMaxSupply(maxSupply_);
    }

    /// @notice changes the base filename extension for the ipfs stored metadata (not images), by default this should be .json
    /// @param baseExtension_ the new filename extension for nft metadata
    function setBaseExtension(string memory baseExtension_) external onlyOwner {
        emit ChangedBasedExtension(baseExtension, baseExtension_);
        baseExtension = baseExtension_;
    }

    /// @notice pauses the contract, preventing any functions from being called
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpauses the contract, allowing functions to be called
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice withdraws all payment token funds held by this contract to the contract owner address
    function _withdraw() internal {
        uint256 tokenBalance = paymentToken.balanceOf(address(this));
        if (tokenBalance > 0) {
            paymentToken.safeTransfer(owner(), tokenBalance);
            emit Withdrawn(owner(), tokenBalance);
        }
    }

    ///@notice external function that allows anyone to withdraw payment tokens held by this contract to the contract owner address
    function withdraw() external {
        _withdraw();
    }

    ///@notice allows the owner to withdraw ether from this contract - we don't expect this contract to hold ether, but just in case...
    function withdrawEther() external payable onlyOwner {
        (bool sent,) = payable(owner()).call{value: address(this).balance}('');
        require(sent, 'Failed to send Ether');
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
}