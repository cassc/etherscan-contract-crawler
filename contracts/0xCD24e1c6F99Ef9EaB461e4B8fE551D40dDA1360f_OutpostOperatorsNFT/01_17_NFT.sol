// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract OutpostOperatorsNFT is ERC721, IERC2981, Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;
    using Strings for uint256;

    // General
    uint32 public constant totalSupply = 4444;
    Counters.Counter private currentTokenId;

    // Metadata
    string private baseTokenURI;

    // Public-round
    uint256 public mintPrice;

    // Gifts
    mapping(address => bool) public gifted;
    uint32 public giftsSupply;
    uint32 public giftsClaimed;
    bytes32 public giftListMerkleRoot;

    // Genesis-round
    mapping(address => uint32) public genesisMintCounts;
    uint256 public genesisRoundMintPrice;
    uint32 public genesisRoundSupply;
    uint32 public genesisRoundTotalMinted;
    uint32 public genesisRoundMaxPerWallet;



    // -=[ Initialization ]=-


    constructor() ERC721("OutpostOperators", "OUTPOST") {
        
        baseTokenURI = "";

        // gift round
        giftsSupply = 222;
        giftsClaimed = 0;

        // genesis round
        genesisRoundSupply = 888;
        genesisRoundMintPrice = 0.021 ether;
        genesisRoundTotalMinted = 0;
        genesisRoundMaxPerWallet = 4;

        // public round
        mintPrice = 0.042 ether;
    }



    // -=[ Modifiers ]=-


    modifier canGiftOperator() {
        require(!gifted[msg.sender], "Operator already gifted to this wallet");
        _;
    }

    modifier hasGiftSupply(uint32 num) {
        require(
            giftsClaimed + num <= giftsSupply,
            "No more gifts"
        );
        require(
            currentTokenId.current() + num <= totalSupply,
            "Max supply reached"
        );
        _;
    }


    modifier hasSupply() {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < totalSupply, "Max supply reached");
        _;
    }


    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }



    // -=[ Admin: Setters ]=-
    

    function setGiftListMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        giftListMerkleRoot = _merkleRoot;
    }


    function setGenesisRoundSupply(uint32 _genesisRoundSupply) external onlyOwner {
        genesisRoundSupply = _genesisRoundSupply;
    }

    function setGenesisRoundMintPrice(uint256 _genesisRoundMintPrice) external onlyOwner {
        genesisRoundMintPrice = _genesisRoundMintPrice;
    }


    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }



    // -=[ Gifts ]=-


    function claim(bytes32[] calldata merkleProof)
        external
        nonReentrant
        hasValidMerkleProof(merkleProof, giftListMerkleRoot)
        canGiftOperator()
        hasGiftSupply(1)
        returns (uint256)
    {
        gifted[msg.sender] = true;
        giftsClaimed += 1;

        return _mintOne(msg.sender);
    }

    function reserveForGifting(uint32 numToReserve)
        external
        nonReentrant
        onlyOwner
        hasGiftSupply(numToReserve)
    {
        giftsClaimed += numToReserve;

        for (uint32 i = 0; i < numToReserve; i++) {
            _mintOne(msg.sender);
        }
    }

    function giftOperators(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        hasGiftSupply(uint32(addresses.length))
    {
        uint32 numToGift = uint32(addresses.length);
        giftsClaimed += numToGift;

        for (uint32 i = 0; i < numToGift; i++) {
            _mintOne(addresses[i]);
        }
    }



    // -=[ Minting ]=-


    function mint() external payable 
        nonReentrant
        hasSupply() 
        returns (uint256)
    {
        if (genesisRoundTotalMinted < genesisRoundSupply) {
            require(genesisMintCounts[msg.sender] < genesisRoundMaxPerWallet, "Genesis round wallet limit reached");
            require(msg.value == genesisRoundMintPrice, "ETH amount != genesis price");

            genesisRoundTotalMinted++;
            genesisMintCounts[msg.sender] += 1;
        } else {
            require(msg.value == mintPrice, "ETH amount != price");
        }

        return _mintOne(msg.sender);
    }


    function _mintOne(address recipient) internal 
        returns (uint256)
    {
        uint256 newItemId = nextTokenId();
        _safeMint(recipient, newItemId);
        return newItemId;
    }



    // -=[ Admin: Withdrawals ]=-


    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function withdrawTokens(IERC20 token) public onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }



    // -=[ Token ID Generation ]=-


    function nextTokenId() private returns (uint256) {
        currentTokenId.increment();
        return currentTokenId.current();
    }


    function getLastTokenId() external view returns (uint256) {
        return currentTokenId.current();
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(baseTokenURI, "/", tokenId.toString(), ".json"));
    }



    // -=[ Royalties ]=-

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), salePrice * 5 / 100);
    }

}