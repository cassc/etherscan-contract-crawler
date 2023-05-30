// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.7.0 <0.9.0;

// KEYCard V1 (Developed by Daniel Kantor)
// Ownership of this card provides exclusive access to discounts, events, and investment opportunities in both the metaverse and physical world.
// This card is one of 118 verifiably unique KEYCards secured by the Ethereum blockchain, issued exclusively to KEYS Token holders.
// Please visit https://keystoken.io/keycard to redeem your benefits.
// Please join us on discord for any questions https://discord.gg/keystoken

contract KEYCard is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    string private baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.18 ether;
    uint256 public maxSupply = 118;
    uint256 public maxMintAmount = 1;
    uint256 public nftPerAddressLimit = 1;
    uint256 public minKeysNeeded = 8888000000000;

    // KEYS Contract
    address constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    // Locked KEYS Contract
    address constant LOCKED_KEYS = 0x08DC692FE528fFEcF675Ab3f76981553e060Fd8A;

    // Tuesday, December 28, 2021 6:18:18 PM GMT-08:00
    // Wednesday, December 29, 2021 2:18:18 AM UTC
    uint256 public publicSaleDate = 1640744298;
    
    bool public paused = false;
    mapping(address => uint256) public addressMintedBalance;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    //MODIFIERS
    modifier notPaused() {
        require(!paused, "the contract is paused");
        _;
    }

    modifier saleStarted() {
        require(block.timestamp >= publicSaleDate, "Sale has not started yet");
        _;
    }

    modifier minimumMintAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _;
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  MINT FUNCTION  ///////////////////////////
    /////////////////////////////////////////////////////////////////
    
    function mint(uint256 _mintAmount) external payable notPaused saleStarted minimumMintAmount(_mintAmount) {
        
        // Validations 
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        validations(ownerMintedCount, _mintAmount);

        uint256 supply = totalSupply();

        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  PUBLIC FUNCTIONS  ////////////////////////
    /////////////////////////////////////////////////////////////////
    
    receive() external payable {}

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function getCurrentCost() external view returns (uint256)  {
        return cost;
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  ONLY OWNER FUNCTIONS  ////////////////////
    /////////////////////////////////////////////////////////////////

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setNftPerAddressLimit(uint256 _limit) external onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPublicSaleDate(uint256 _publicSaleDate) external onlyOwner {
        publicSaleDate = _publicSaleDate;
    }

    function gift(uint256 _mintAmount, address destination) external onlyOwner {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[destination]++;
            _safeMint(destination, supply + i);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success);
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  INTERNAL FUNCTIONS  //////////////////////
    /////////////////////////////////////////////////////////////////

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function validations(uint256 _ownerMintedCount, uint256 _mintAmount) internal {
        uint256 amountOfKeysOwned = IERC20(KEYS).balanceOf(msg.sender);
        uint256 amountOfLockedKeysOwned = IERC20(LOCKED_KEYS).balanceOf(msg.sender);
        uint256 totalKeysOwned = amountOfKeysOwned.add(amountOfLockedKeysOwned);

        require(_ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        require(_mintAmount <= maxMintAmount, "max mint amount per transaction exceeded");
        require(totalKeysOwned >= minKeysNeeded);
    }
}