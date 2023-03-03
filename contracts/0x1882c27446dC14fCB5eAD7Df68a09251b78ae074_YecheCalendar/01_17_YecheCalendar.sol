//SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.7;  
  
import "erc721a/contracts/ERC721A.sol";  
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./../DefaultOperatorFilterer.sol";
import { IYecheAuctionHouse } from "./IYecheAuction.sol";

contract YecheCalendar is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard, ERC2981 {  
    using Counters for Counters.Counter;

    address public auctionContractAddress = 0x454A91351f41e5311Aec4A5De205b725F1EFfa9b;

    uint256 public minAuctionID = 0;
    uint256 public maxAuctionID = 42;
    
    string public metadataURI;

    mapping (address => bool) private gifters; 
    mapping (address => bool) public claimed;

    address public split;

    bool public mintPaused = true;
    bool public metadataURILocked = false;

    uint96 private royaltyBps = 1000;

    function updateRoyalty(uint96 _royaltyBps) public onlyOwner {
        require(split!=address(0), "split address not set, please set split address before updating royalty");
        royaltyBps = _royaltyBps;
        _setDefaultRoyalty(split, royaltyBps);
    }

    function updateAuctionContractAddress(address _address) public onlyOwner {
        auctionContractAddress = _address;
    }

    function updateMinAuctionID(uint256 _minAuctionID) public onlyOwner {
        minAuctionID = _minAuctionID;
    }

    function updateMaxAuctionID(uint256 _maxAuctionID) public onlyOwner {
        maxAuctionID = _maxAuctionID;
    }

    function updateMintPaused(bool _mintPaused) public onlyOwner {
        mintPaused = _mintPaused;
    }

    function updateMetadataURI(string calldata givenMetadataURI) public onlyOwner {
        require(!metadataURILocked, "metadata uri locked");
        metadataURI = givenMetadataURI;
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        return metadataURI;
    }

    function lockMetadataURI() public onlyOwner {
        metadataURILocked = true;
    }

    function updateGifters(address _address, bool canGift) public onlyOwner {
        gifters[_address] = canGift;
    }

    modifier onlyGifter() {
        require(gifters[msg.sender] == true, "only gifters can gift");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract.");
        _;
    }
 
    constructor() ERC721A("YecheCalendar", "CALENDAR") {
        gifters[msg.sender] = true;
    } 
    
    function userBidOnAuction(address user) public view returns (bool) {
        IYecheAuctionHouse auctionContract = IYecheAuctionHouse(auctionContractAddress);
        bool userBid = auctionContract.getUserBid(user, minAuctionID, maxAuctionID);
        return userBid;
    }

    function mint() public nonReentrant callerIsUser {
        require(!mintPaused, "minting paused");
        require(!claimed[msg.sender], "wallet already claimed");
        require(userBidOnAuction(msg.sender), "user did not bid on auction");

        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function gift(uint256 quantity, address to) public onlyGifter {
        _safeMint(to, quantity);
    }

    function setSplitAddress(address _address) public onlyOwner {
        split = _address;
        _setDefaultRoyalty(split, royaltyBps);
    }

    // Opensea Operator filter registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}