// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error InsufficientFunds();
error MintingTooMany();
error SaleNotStarted();
error InvalidProof();
error CannotBeCalledByContract();

/**
 * @title Vendetta Society Minting Contract
 * @notice This contract is intended to allow users to mint ERC-721A NFTs to the Vendetta Society Collection
 */
contract VendettaSociety is ERC721A, Ownable {
    using Strings for uint256;

    enum SaleState {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }

    /**
     * @dev Constant variables cannot be changed after deployment
     */
    uint256 public constant COLLECTION_SIZE = 2222;
    uint256 public constant MAX_MINT_AMOUNT = 10;
    uint256 public constant MINT_PRICE = 0.13 ether;
    string public BASE_URI;
    string public UNREVEALED_URI =
        "ipfs://bafkreih53eg2hlh2mcn7i7tbjyercdndvgdwli7xoc3qenyfielxth63gu";
    bool public isRevealed = false;
    address public constant COMMUNITY_WALLET =
        0xe856D6837ac526Ad4497Ec3a980A4FE2c2Fb5391;

    bytes32 public allowlistMerkleRoot;
    SaleState public saleState;

    /**
     * @notice Mapping that returns the number of NFTs minted by an address
     * @return uint256 Number of NFTs minted
     */
    mapping(address => uint256) public nftsMinted;

    /**
     * @notice Modifier that stops other contracts from interacting with this one
     */
    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CannotBeCalledByContract();
        _;
    }

    /**
     * @dev Initially sets up the sale as closed
     * @param _allowlistMerkleRoot bytes32 Allowlist Merkle Root
     */
    constructor(bytes32 _allowlistMerkleRoot)
        ERC721A("Vendetta Society", "VD")
    {
        saleState = SaleState.CLOSED;
        allowlistMerkleRoot = _allowlistMerkleRoot;
        _safeMint(COMMUNITY_WALLET, 322);
    }

    /**
     * @notice Allows allowlisted users to mint NFTs
     * @dev saleState must be 1
     * @param _merkleProof bytes32[] Merkle Proof
     * @param _mintAmount uint256 Mint Amount
     */
    function allowlistMint(bytes32[] memory _merkleProof, uint256 _mintAmount)
        public
        payable
        callerIsUser
    {
        if (totalSupply() + _mintAmount > COLLECTION_SIZE)
            revert MintingTooMany();
        if (saleState != SaleState.ALLOWLIST) revert SaleNotStarted();
        if (nftsMinted[msg.sender] + _mintAmount > MAX_MINT_AMOUNT)
            revert MintingTooMany();
        if (msg.value < _mintAmount * MINT_PRICE) revert InsufficientFunds();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf)))
            revert InvalidProof();

        nftsMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Allows any user to mint NFTs
     * @dev saleState must be 2
     * @param _mintAmount uint256 Mint Amount
     */
    function publicMint(uint256 _mintAmount) public payable callerIsUser {
        if (totalSupply() + _mintAmount > COLLECTION_SIZE)
            revert MintingTooMany();
        if (saleState != SaleState.PUBLIC) revert SaleNotStarted();
        if (nftsMinted[msg.sender] + _mintAmount > MAX_MINT_AMOUNT)
            revert MintingTooMany();
        if (msg.value < _mintAmount * MINT_PRICE) revert InsufficientFunds();

        nftsMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Mints community mint amount to community wallet
     */
    function communityMint(uint256 _amount) public onlyOwner {
        _safeMint(COMMUNITY_WALLET, _amount);
    }

    /**
     * @notice Mints rest of collection to community wallet
     */
    function mintRestOfCollection() public onlyOwner {
        uint256 mintAmount = COLLECTION_SIZE - totalSupply();
        _safeMint(COMMUNITY_WALLET, mintAmount);
    }

    /**
     * @notice Sets a new allowlist merkle root
     * @param _allowlistMerkleRoot bytes32 Allowlist Merkle Root
     */
    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot)
        public
        onlyOwner
    {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    /**
     * @notice Sets the sale state
     * @dev 0 = Closed, 1 = Allowlist Sale, 2 = Public Sale
     * @param _saleState uint256 Sale State number
     */
    function setSaleState(uint256 _saleState) public onlyOwner {
        saleState = SaleState(_saleState);
    }

    /**
     * @notice Sets the baseURI
     * @param _baseURI uint256 Sale State number
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
        UNREVEALED_URI = _unrevealedURI;
    }

    function setIsRevealed(bool _isRevealed) public onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Get tokenURI for a given token ID
     * @param  _tokenId uint256 ID of the token to query
     * @return string token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        if (!isRevealed) {
            return UNREVEALED_URI;
        }
        return string(abi.encodePacked(BASE_URI, _tokenId.toString(), ".json"));
    }

    // /**
    // * @notice Withdraws all ETH from the contract to owner wallet
    //  */
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 WMCut = (balance * 5) / 100;
        uint256 communityCut = balance - WMCut;
        (bool os, ) = payable(0x52852eC693CC222b75B6a488950388D875Dc5067).call{
            value: WMCut
        }("");
        require(os);
        (bool cs, ) = payable(COMMUNITY_WALLET).call{value: communityCut}("");
        require(cs);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}