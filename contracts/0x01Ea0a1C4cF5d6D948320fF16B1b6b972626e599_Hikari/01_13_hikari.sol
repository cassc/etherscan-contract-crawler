// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Hikari is ERC721A, Ownable, ReentrancyGuard
{
    using Strings for string;

    uint public constant MAX_TOKENS = 5555;
    uint public PRESALE_LIMIT = 5555;
    uint public presaleTokensSold = 0;
    uint public constant NUMBER_RESERVED_TOKENS = 10;
    uint256 public PRICE = 0.09 ether; //for stage 2
    uint public perAddressLimit = 1;
    
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    bool public whitelist = true;
    bool public revealed = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 root;
    bytes32 rootML; //for Mark of Legends whitelist
    mapping(address => uint) public addressMintedBalance;

    //Dutch auction settings
    struct TokenBatchPriceData {
        uint128 pricePaid;
        uint8 quantityMinted;
    }

    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    mapping(address => uint) public addressMintedBalanceDA;

    uint256 public DA_STARTING_TIMESTAMP = 1649620800; //10th April 4pm EST
    uint256 public DA_QUANTITY = 1850;
    uint256 public DA_STARTING_PRICE = 0.3 ether;
    uint256 public DA_ENDING_PRICE = 0.1 ether;
    uint256 public DA_DECREMENT = 0.05 ether;
    uint256 public DA_DECREMENT_FREQUENCY = 1200; //decrement price every 1200 seconds (20 minutes).
    uint256 public DA_FINAL_PRICE;
    bool public DA_FINISHED = false;

    constructor() ERC721A("Hikari", "Hikari") {}

    function currentPrice() public view returns (uint256) 
    {
        require(block.timestamp >= DA_STARTING_TIMESTAMP, "Dutch auction has not started!");

        if (DA_FINAL_PRICE > 0) return DA_FINAL_PRICE;

        uint256 timeSinceStart = block.timestamp - DA_STARTING_TIMESTAMP;
        uint256 decrementsSinceStart = timeSinceStart / DA_DECREMENT_FREQUENCY;
        uint256 totalDecrement = decrementsSinceStart * DA_DECREMENT; //How much eth to remove

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= DA_STARTING_PRICE - DA_ENDING_PRICE) {
            return DA_ENDING_PRICE;
        }
        return DA_STARTING_PRICE - totalDecrement;
    }

    function mintDutchAuction(uint8 amount) public payable 
    {    
        require(block.timestamp >= DA_STARTING_TIMESTAMP, "Dutch auction has not started!");
        require(!DA_FINISHED, "Dutch auction not active");
        require(amount > 0 && amount <= 4, "Max 4 NFTs per transaction");
        require(addressMintedBalanceDA[msg.sender] + amount <= 100, "Max NFT per address exceeded");

        uint256 _currentPrice = currentPrice();

        require(msg.value >= amount * _currentPrice, "Not enough ETH for transaction");
        require(totalSupply() + amount <= DA_QUANTITY, "Purchase would exceed max supply");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        
        if (totalSupply() + amount == DA_QUANTITY)
            DA_FINAL_PRICE = _currentPrice;

        userToTokenBatchPriceData[msg.sender].push(TokenBatchPriceData(uint128(msg.value), amount));
        addressMintedBalanceDA[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function refundExtraETH() public nonReentrant
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        uint256 totalRefund;

        for (uint256 i = userToTokenBatchPriceData[msg.sender].length; i > 0; i--) 
        {
            uint256 expectedPrice = userToTokenBatchPriceData[msg.sender][i - 1].quantityMinted * DA_FINAL_PRICE;
            uint256 refund = userToTokenBatchPriceData[msg.sender][i - 1].pricePaid - expectedPrice;
            userToTokenBatchPriceData[msg.sender].pop();
            totalRefund += refund;
        }

        (bool success, ) = payable(msg.sender).call{value: totalRefund}("");
        require(success, "Transfer failed");
    }

    function mintToken(uint8 amount, bytes32[] memory proof, bool isMarkOfLegends) external payable
    {
        require(preSaleIsActive || saleIsActive, "Sale must be active to mint");
        require(!preSaleIsActive || presaleTokensSold + amount <= PRESALE_LIMIT, "Purchase would exceed max supply");
        
        if (isMarkOfLegends)
        {
            require(!whitelist || verifyML(proof), "Address not whitelisted");
            require(!preSaleIsActive || addressMintedBalance[msg.sender] + amount <= 2, "Max NFT per address exceeded");
        }
        else
        {
            require(!whitelist || verify(proof), "Address not whitelisted");
            require(!preSaleIsActive || addressMintedBalance[msg.sender] + amount <= perAddressLimit, "Max NFT per address exceeded");
        }
        
        require(amount > 0 && amount <= 4, "Max 4 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        
        if (preSaleIsActive) {
            presaleTokensSold += amount;
            addressMintedBalance[msg.sender] += amount;
        }

        _safeMint(msg.sender, amount);  
    }

    function setDA_STARTING_TIMESTAMP(uint256 newDA_STARTING_TIMESTAMP) external onlyOwner 
    {
        DA_STARTING_TIMESTAMP = newDA_STARTING_TIMESTAMP;
    }

    function finishDA(uint256 _price) external onlyOwner
    {
        DA_FINISHED = true;
        DA_FINAL_PRICE = _price;
    }

    //case ethereum does something crazy, and for setting stage 3 price
    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setPresaleLimit(uint newLimit) external onlyOwner 
    {
        PRESALE_LIMIT = newLimit;
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner 
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner 
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipWhitelistingState() external onlyOwner 
    {
        whitelist = !whitelist;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted+= amount;
        _safeMint(to, amount); 
    }
    
    function withdraw() external nonReentrant onlyOwner
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function setRootML(bytes32 _root) external onlyOwner 
    {
        rootML = _root; //for Mark of Legends whitelist
    }

    function verify(bytes32[] memory proof) internal view returns (bool) 
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    function verifyML(bytes32[] memory proof) internal view returns (bool) 
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); //for Mark of Legends whitelist
        return MerkleProof.verify(proof, rootML, leaf);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) 
    {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        // Execution should never reach this point.
        revert();
    }

    ////
    //URI management part
    ////
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) 
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}