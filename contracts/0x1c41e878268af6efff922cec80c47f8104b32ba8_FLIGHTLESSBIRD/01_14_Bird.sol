// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";


contract FLIGHTLESSBIRD is ERC721A, Ownable, ReentrancyGuard {

    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;
    string public baseURI;

    uint256 public PRICE = 0.0055 * 10**18;

    mapping(address => uint256) public freeMinted;

    uint256 public tokensReserved;
    uint256 public immutable reserveAmount;
    uint256 public immutable maxPerMint;

    string private _contractMetadataURI = "ipfs://QmXfwCe6uaHFFqHMGtwhpzwDbxDmoj7NJ4mbRrwv61Mkmu";

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event PriceChange(uint256 price);
    event Withdrawed(address addr, uint amount);

    constructor(
        string memory initBaseURI,
        uint256 _maxPerMint,
        uint256 _reserveAmount
    ) ERC721A("The Flightless Bird", "The Flightless Bird", _maxPerMint, 5555) {
        baseURI = initBaseURI;
        maxPerMint = _maxPerMint;
        reserveAmount = _reserveAmount;
        status = Status.Pending;
    }

    function reserve(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "TFB: zero address");
        require(amount > 0, "TFB: invalid amount");
        require(
            totalSupply() + amount <= collectionSize,
            "TFB: max supply exceeded"
        );

        require(
            tokensReserved + amount <= reserveAmount,
            "TFB: max reserve amount exceeded"
        );
        require(
            amount % maxPerMint == 0,
            "TFB: can only mint a multiple of the maxBatchSize"
        );

        uint256 numChunks = amount / maxPerMint;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(recipient, maxPerMint);
        }
        tokensReserved += amount;
        emit ReservedToken(msg.sender, recipient, amount);
    }

    function mint(uint256 amount) external payable {
        require(status == Status.PublicSale, "TFB: Public sale is not active.");
        require(
            tx.origin == msg.sender,
            "TFB: contract is not allowed to mint."
        );

        require(amount > 0, "TFB: invalid amount");

        require(
            amount <= maxPerMint,
            "TFB: Exceeds the single maximum limit."
        );

        require(
            totalSupply() + amount + reserveAmount - tokensReserved <= collectionSize,
            "TFB: Max supply exceeded."
        );

        uint256 totalPrice;

        if(freeMinted[msg.sender] == 0){
            freeMinted[msg.sender] = 1;
            totalPrice = (amount - 1) * PRICE;
        }else{
            totalPrice = amount * PRICE;
        }

        _safeMint(msg.sender, amount);
        refundIfOver(totalPrice);

        emit Minted(msg.sender, amount);
    }

    function withdraw() external nonReentrant onlyOwner {
        require(address(this).balance > 0, "TFB: Insufficient balance");
        Address.sendValue(payable(owner()), address(this).balance);
        emit Withdrawed(owner(), address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    function setContractMetadataURI(string calldata newContractMetadataUri) public onlyOwner {
        _contractMetadataURI = newContractMetadataUri;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
        emit PriceChange(newPrice);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setOwnersExplicit(uint256 quantity)
    external
    onlyOwner
    nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function maxSupply() external view returns (uint256) {
        return collectionSize;
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "TFB: Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // start from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
}