// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract SkyClubPass is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum Status {
        Pending,
        PublicSale,
        Finished
    }

    Status public status;
    string public baseURI;
    uint256 public tokensReserved;
    uint256 public immutable maxMint;
    uint256 public immutable maxSupply;
    uint256 public immutable reserveAmount;
    uint256[] public passLimit = [350,150,55];
    uint256[3] public currentPassAmount;
    uint256[] public passLevel;
    uint256[] public price = [0.2 ether, 0.5 ether, 1 ether]; // 0.1 ETH
    
    mapping(address => bool) public publicMinted;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

  

    constructor(
        string memory initBaseURI,
        uint256 _maxBatchSize,
        uint256 _collectionSize,
        uint256 _reserveAmount
    ) ERC721A("SkyClubPass", "SkyClubPass", _maxBatchSize, _collectionSize) {
        baseURI = initBaseURI;
        maxMint = _maxBatchSize;
        maxSupply = _collectionSize;
        reserveAmount = _reserveAmount;
        passLevel = new uint8[](maxSupply);
    }

   
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    
    function mint(uint256 amount,uint8 _level) external payable {
        require(status == Status.PublicSale, "SkyClubPass: Public sale is not active.");
        require(_level < 3, "SkyClubPass: wrong level");
        require(currentPassAmount[_level] + amount <= passLimit[_level],"SkyClubPass: max level supply exceeded, try another");

        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "SkyClubPass: Max supply exceeded."
        );
        uint currentSupply = totalSupply();

        currentPassAmount[_level] += amount;
        for(uint i = currentSupply; i < currentSupply + amount;i++){
            passLevel[i] = _level;
        }

        _safeMint(msg.sender, amount);
        refundIfOver(amount, _level);

        emit Minted(msg.sender, amount);
    }

    function refundIfOver(uint amount, uint256 _level) private {
        require(msg.value >= amount * price[_level], "SkyClubPass: Need to send more ETH.");
        if (msg.value > amount * price[_level]) {
            payable(msg.sender).transfer(msg.value - amount* price[_level]);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory){
            require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,passLevel[tokenId].toString())): "";

    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        (bool success1, ) = payable(msg.sender)
            .call{value: balance}("");
        require(success1, "Transfer 1 failed.");
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
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

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}