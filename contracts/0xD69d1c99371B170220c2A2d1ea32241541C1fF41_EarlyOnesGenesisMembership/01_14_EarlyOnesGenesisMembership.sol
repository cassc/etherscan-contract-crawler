// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// @title EARLY ONES | Genesis Membership Pass
// @author @David_LoDico

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EarlyOnesGenesisMembership is
    ERC721,
    IERC2981,
    Ownable,
    ReentrancyGuard
{
    event TransferSingle(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );

    // Project Wallet
    address private _w1;

    // Collection values
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_TX = 1;
    uint256 public constant MAX_PER_AL_WALLET = 2; // AllowList
    uint256 public constant MAX_PER_OG_WALLET = 3; // OGList
    uint256 public alPrice = 0.04 ether;
    uint256 public ogPrice = 0.03 ether;
    uint256 public tokenPrice = 0.04269 ether;
    uint256 public royaltyPercentage = 75; // 7.5%

    // Mint phase toggles
    bool public PublicMintActive = false;
    bool public ListMintActive = false;

    // Track token count
    uint256 private _nextTokenId = 1;

    // Merkle
    bytes32 public merkleRootAL; // MerkleRoot for AllowList
    bytes32 public merkleRootOG; // MerkleRoot for OGList

    // Track how many tokens addresses have minted
    mapping(address => uint256) public mintBalance;

    // Metadata URIs
    string private _contractURI;
    string public baseURI;

    /**
     * @notice Modifier to check if there is enough supply for the attempted amount to mint
     * @param _numberOfTokens The number of tokens attempting to be minted
     */
    modifier whenSupplyAvailable(uint256 _numberOfTokens) {
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "Exceeds max supply"
        );
        _;
    }

    /**
     * @notice Check functions for correct token amount per tx
     * @param _numberOfTokens The number of tokens attempting to be minted
     */
    modifier whenUnderMaxPerTx(uint256 _numberOfTokens) {
        require(_numberOfTokens <= MAX_PER_TX, "Exceeds max per tx");
        _;
    }
    /**
     * @notice Check functions for correct amount of ETH being sent, not more not less
     * @param _numberOfTokens The number of tokens to calculate the value required from
     */
    modifier whenCorrectEtherSent(uint256 _numberOfTokens, uint256 _price) {
        require(msg.value == _price * _numberOfTokens, "Incorrect ether sent");
        _;
    }

    /**
     * @notice We want a valuable community of real members. Only humans are allowed to execute these functions
     */
    modifier whenHuman() {
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    /**
     * @notice Constructor
     * @dev Pass in Project wallet addresses
     * @dev Pass in the starting contractURI for collection level metadata
     * @dev Pass in the starting baseURI for token placeholder metadata
     */
    constructor(
        address w1,
        string memory _startingContractURI,
        string memory _startingBaseURI
    ) ERC721("EARLY ONES | Genesis Membership", "EARLY") {
        _w1 = w1;
        _contractURI = _startingContractURI;
        baseURI = _startingBaseURI;
    }

    /**
     * @notice Get total supply
     * @return uint256 Number of tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /**
     * @notice Get contractURI
     * @return contractURI The URI for the collection metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Get baseURI
     * @dev Overrides {ERC721-_baseURI}
     * @return baseURI The base token URI for the collection
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Base token minting function
     * @dev Cant overflow, so no check needed
     * @param _to The address to mint tokens to
     * @param _numberOfTokens The number of tokens to be minted
     */
    function _internalMint(address _to, uint256 _numberOfTokens) private {
        for (uint256 i = 0; i < _numberOfTokens; ) {
            _safeMint(_to, _nextTokenId++);

            unchecked {
                ++i;
            }
            emit TransferSingle(msg.sender, _to, _nextTokenId - 1);
        }
    }

    /**
     * @notice Allowlist minting function
     * @dev Check that the allowlist mint is active
     * @dev Check that an address is not trying to mint more than its max. allocation
     * @dev Check that a valid merkle proof is sent with the transaction
     * @dev Mint balance incrementation can go unchecked to save gas because we can't overflow
     * @param _numberOfTokens The number of tokens to be minted
     * @param _merkleProof The proof of allowlist presence required to mint
     */
    function alMint(uint256 _numberOfTokens, bytes32[] memory _merkleProof)
        external
        payable
        whenSupplyAvailable(_numberOfTokens)
        whenCorrectEtherSent(_numberOfTokens, alPrice)
        whenHuman
    {
        require(ListMintActive, "minting is closed for allowlist");
        require(
            mintBalance[msg.sender] + _numberOfTokens <= MAX_PER_AL_WALLET,
            "Exceeds AL wallet limit"
        );

        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRootAL,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid merkle proof"
        );

        unchecked {
            mintBalance[msg.sender] += _numberOfTokens;
        }

        _internalMint(msg.sender, _numberOfTokens);
    }

    /**
     * @notice Allowlist minting function
     * @dev Check that the allowlist mint is active
     * @dev Check that an address is not trying to mint more than its max. allocation
     * @dev Check that a valid merkle proof is sent with the transaction
     * @dev Mint balance incrementation can go unchecked to save gas because we can't overflow
     * @param _numberOfTokens The number of tokens to be minted
     * @param _merkleProof The proof of allowlist presence required to mint
     */
    function ogMint(uint256 _numberOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
        whenSupplyAvailable(_numberOfTokens)
        whenCorrectEtherSent(_numberOfTokens, ogPrice)
        whenHuman
    {
        require(ListMintActive, "minting is closed for allow list");
        require(
            mintBalance[msg.sender] + _numberOfTokens <= MAX_PER_OG_WALLET,
            "Exceeds AL wallet limit"
        );

        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRootOG,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid merkle proof"
        );

        unchecked {
            mintBalance[msg.sender] += _numberOfTokens;
        }

        _internalMint(msg.sender, _numberOfTokens);
    }

    /**
     * @notice Public minting function
     * @dev Check that the public mint is active
     * @param _numberOfTokens The number of tokens to be minted
     */
    function publicMint(uint256 _numberOfTokens)
        external
        payable
        whenSupplyAvailable(_numberOfTokens)
        whenUnderMaxPerTx(_numberOfTokens)
        whenCorrectEtherSent(_numberOfTokens, tokenPrice)
        whenHuman
    {
        require(PublicMintActive, "minting is closed");

        _internalMint(msg.sender, _numberOfTokens);
    }

    /**
     * @notice NFT's for the project
     * @dev Can only be used once before any tokens are minted
     * @dev Tokens will be used for PFPs, marketing and giveaways
     */
    function teamClaim() external onlyOwner {
        require(totalSupply() == 0, "Tokens already claimed");
        _internalMint(_w1, 30); // Community wallet
    }

    /**
     * @notice Update the community wallet address
     * @param _newCommunityWallet The new community wallet address
     */
    function setCommunityWallet(address _newCommunityWallet)
        external
        onlyOwner
    {
        _w1 = _newCommunityWallet;
    }

    /**
     * @notice Update the price of a single token
     * @param _newTokenPrice The new price of a single token
     */
    function setAlPrice(uint256 _newTokenPrice) external onlyOwner {
        alPrice = _newTokenPrice;
    }

    /**
     * @notice Update the price of a single token
     * @param _newTokenPrice The new price of a single token
     */
    function setOgPrice(uint256 _newTokenPrice) external onlyOwner {
        ogPrice = _newTokenPrice;
    }

    /**
     * @notice Update the price of a single token
     * @param _newTokenPrice The new price of a single token
     */
    function setTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    /**
     * @notice Update royalty percentage for secondary sales
     * @param _royaltyPercentage The new royalty percentage
     */
    function setRoyaltyPercentage(uint256 _royaltyPercentage)
        external
        onlyOwner
    {
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @notice Toggle public mint phase
     */
    function togglePublicMint() external onlyOwner {
        PublicMintActive = !PublicMintActive;
    }

    /**
     * @notice Toggle allow list mint phase
     */
    function toggleListMint() external onlyOwner {
        ListMintActive = !ListMintActive;
    }

    /**
     * @notice Update the merkle root used for allowlist management
     * @dev Root string passed must be proceeded by '0x'
     * @param _newMerkleRoot The new root of the merkle tree
     */
    function setMerkleRootAL(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRootAL = _newMerkleRoot;
    }

    /**
     * @notice Update the merkle root used for allowlist management
     * @dev Root string passed must be proceeded by '0x'
     * @param _newMerkleRoot The new root of the merkle tree
     */
    function setMerkleRootOG(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRootOG = _newMerkleRoot;
    }

    /**
     * @notice Update the contractURI
     * @dev This is the collection level metadata URL
     * @param _newContractURI The new contractURI for the collection
     */
    function setContractURI(string memory _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @notice Update the baseURI
     * @dev Must include trailing slash
     * @param _newBaseURI The new baseURI for the collection
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Internal withdraw function
     * @param _balance The balance to be split
     * @param _address The address to send the balance to
     * @param _split The % split of the balance to send to the address
     */
    function _internalWithdraw(
        uint256 _balance,
        address _address,
        uint256 _split
    ) private {
        (bool success, ) = payable(_address).call{
            value: (_balance / 10000) * _split
        }("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Withdraw funds from the contract
     * @dev Community wallet 39.25%, Founder 18.22%, Design 15.19%, Story 15.19%, Dev 12.15%
     * @dev Any balance left is sent to the community wallet
     * @dev Prefer call pattern over transfer to prevent potential out of gas revert for multisigs
     */
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;

        _internalWithdraw(balance, _w1, 10000);

        (bool success, ) = payable(_w1).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Declare support for interfaces used (IERC2981)
     * @dev Overrides {IERC165-supportsInterface}
     * @return bool Whether a checked interface is supported or not
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Set royalty info according to IERC2981 standard
     * @dev Royalties paid to the community wallet
     * @dev Overrides {IERC2981-royaltyInfo}
     * @return address The royalties reciever
     * @return royaltyAmount The amount to be paid
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Non-existent token");

        royaltyAmount = (_salePrice / 100) * (royaltyPercentage / 10);

        return (_w1, royaltyAmount);
    }
}