//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract CollectivePass is ERC721Enumerable, Pausable, AccessControl, ERC2981 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Number of tokens minted per address
    mapping(address => uint) public addrTokensMinted;
    // Mapping for presale address consumed.
    mapping(address => bool) public presaleAddConsumed;

    // BaseURI
    string public baseURI;

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // Mint timing managers
    uint256 public publicMintDate;
    uint256 public presaleListMintDate;

    // Royalty Information
    address royaltyFeeReceiver = 0xa6C73A99A95B96d55f974e77ce8E358143B92F08;
    uint96 royaltyFee = 1000;

    // Reserved Amount
    uint public reservedNFTs = 250;
    Counters.Counter private _reservedNFTsMinted;

    // The max number of NFTs in the collection
    uint public constant MAX_SUPPLY = 987;
    Counters.Counter private _tokenIds;

    // The mint price for the collection
    uint public constant price = 0.2 ether;
    // The maximum number of NFTs per wallet
    uint public maxPerWallet = 1;

    // Merkleroot for presale list
    bytes32 public presaleMerkleRoot;


    constructor(uint256 _publicMintDate, uint256 _presaleListMintDate, string memory _name,
        string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {
        // Grant all the base roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(TREASURY_ROLE, msg.sender);

        // Set the mint dates
        publicMintDate = _publicMintDate;
        presaleListMintDate = _presaleListMintDate;

        // Set default royalties
        _setDefaultRoyalty(royaltyFeeReceiver, royaltyFee);
        setBaseURI(_initBaseURI);
    }

    // Token URI Functions
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(MINTER_ROLE) {
        baseURI = _newBaseURI;
    }

    // Override tokenURI so they all have the same metadata
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"Not Found");
        return string(abi.encodePacked(_baseURI()));
    }

    // Update the royalty information if required if required.
    function setDefaultRoyalty(address _royaltyFeeReceiverAddress, uint96 _royaltyFee) public onlyRole(MINTER_ROLE) {
        royaltyFeeReceiver = _royaltyFeeReceiverAddress;
        royaltyFee = _royaltyFee;
        _setDefaultRoyalty(royaltyFeeReceiver, royaltyFee);
    }

    // Update the Merkle Root
    function setMerkleRoot(bytes32 _root) public onlyRole(MINTER_ROLE) {
        presaleMerkleRoot = _root;
    }

    // Update the max per wallet
    function setMaxPerWallet(uint _number) public onlyRole(MINTER_ROLE) {
        maxPerWallet = _number;
    }

    // Update the Public Mint date
    function setPublicMintDate(uint256 _date) public onlyRole(MINTER_ROLE) {
        publicMintDate = _date;
    }

    // Update the presale list mint date
    function setPresaleListMintDate(uint256 _date) public onlyRole(MINTER_ROLE) {
        presaleListMintDate = _date;
    }

    // Pause the mint for any reason
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    // Unpause the mint if paused
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Returns the ids of the NFTs owned by the wallet address
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Mint Presale NFT
    function presaleMintNFT(bytes32[] calldata _merkleProof) public payable {
        // Check whether the address has already minted their allowlist NFT
        require(!presaleAddConsumed[msg.sender], "Already minted for allowlist");
        // Check whether the wallet is part of the merkleroot
        require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on allowlist");
        // Check that enough ETH was sent
        require(msg.value >= price, "Not enough ETH");
        // Mint Single NFT to the address requested
        _mintSingleNFT();
        // Consume the wallet from the presale list
        presaleAddConsumed[msg.sender] = true;
        addrTokensMinted[msg.sender] += 1;
    }

    // Public Sale Mint Function
    function mintNFT() public payable {
        // Ensure that the wallet doesn't mint more tokens than allowed
        require(addrTokensMinted[msg.sender] + 1 <= maxPerWallet, "Hit max token limit");
        // Calculate the total supply taking into account the reservedNFTs
        uint totalMinted = _tokenIds.current() + reservedNFTs;
        // Check that the public sale is open.
        require(block.timestamp >= publicMintDate, "Public sale not yet open");
        // Check that the collection is not sold out.
        require(totalMinted.add(1) <= MAX_SUPPLY, "Collection sold out");
        // Make sure the tx is sending enough ETH.
        require(msg.value >= price, "Not enough ETH");
        // Mint the NFT
        _mintSingleNFT();
        // Set the number of tokens minted for the address.
        addrTokensMinted[msg.sender] += 1;
    }

    // Common function to mint an NFT to the requesting address
    function _mintSingleNFT() private {
        // Get the current tokenId
        uint256 tokenId = _tokenIds.current();
        // Mint the token for the sender of the message
        _safeMint(msg.sender, tokenId);
        // Increment the tokenId for the sale.
        _tokenIds.increment();
    }

    // Common function to mint an NFT to the given address
    function _mintSingleNFTToAddress(address to) private {
        // Get the current tokenId
        uint256 tokenId = _tokenIds.current();
        // Mint the token for the wallet requested in the sender address
        _safeMint(to, tokenId);
        // Increment the tokenId for the sale.
        _tokenIds.increment();
    }
    
    // Airdrop NFTs Function
    // This is an admin only functionality to be able to mint for wallets.
    function airdropNfts(address[] calldata walletAddresses) public onlyRole(MINTER_ROLE) {
        // Get the current number of reserved NFTs minted.
        uint totalMinted = _reservedNFTsMinted.current();
        // Check that the number of reservedNFTs is not greater than the reservation amount
        require(totalMinted.add(walletAddresses.length) <= reservedNFTs, "Not enough to airdrop");
        // Mint for each of the wallets
        for (uint i = 0; i < walletAddresses.length; i++) {
            // Mint the NFT to the address requested
            _mintSingleNFTToAddress(walletAddresses[i]);
            // Increment the reservedNFTs by 1
            _reservedNFTsMinted.increment();
        }
    }

    // Withdraw the ether in the contract
    // Admin only function to be able to withdraw the money from the contract
    function withdraw() public payable onlyRole(TREASURY_ROLE) {
        // Get the balance of the contract
        uint balance = address(this).balance;
        // The balance must be more than none.
        require(balance > 0, "No ETH to withdraw");
        // Widthdraw the funds to the requesting wallet
        (bool success, ) = (msg.sender).call{value: balance}("");
        // If it didn't succeed, return failure
        require(success, "Failed");
    }

    // Reserve NFTs to be minted for free to the current wallet.
    function reserveNFTs(uint _count) public onlyRole(MINTER_ROLE) {
        // Get the current number of reserved NFTs that are minted
        uint totalMinted = _reservedNFTsMinted.current();

        // Check that there are still enough reserved NFTs to make the reservation
        require(totalMinted.add(_count) <= reservedNFTs, "Not enough to reserve");

        // For each of the requested NFTs
        for (uint i = 0; i < _count; i++) {
            // Mint Single NFT to requesting address
            _mintSingleNFT();
            // Increment the number of minted reserved NFTs
            _reservedNFTsMinted.increment();
        }
    }

    // Required Overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}