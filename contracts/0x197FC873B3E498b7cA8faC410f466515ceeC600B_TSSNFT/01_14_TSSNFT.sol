pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TSSNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint;
    
    uint public constant MAX_SNEAKERHEADZ = 4444;
    uint public constant MAX_SALE = 20;
    uint public constant MAX_PRESALE = 5;

    address payableAddress;
    uint public price;
    
    mapping(address => uint256) private preSaleAllowance;
    
    bool public hasPreSaleStarted = false;
    bool public preSaleOver = false;
    bool public hasSaleStarted = false;
    
    event SneakerHeadzMinted(uint indexed tokenId, address indexed owner);
    
    constructor() ERC721("The SneakerHeadz Society", "TSS") {

        price = 0.05 ether;
        payableAddress = 0x5Aa8Ec62658428Bb46f9E8aDc8fdf8d77329af99;
    }
    
    function mint(uint _quantity) external payable  {
        require(hasSaleStarted, "Sale hasn't started.");
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "Quantity cannot be bigger than MAX_BUYING.");
        require(totalSupply().add(_quantity) <= MAX_SNEAKERHEADZ, "Sold out.");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "Ether value sent is below the price.");
        
        (bool success, ) = payableAddress.call{value:msg.value}("");
        require(success, "Transfer failed.");
        
        for (uint i = 0; i < _quantity; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            emit SneakerHeadzMinted(mintIndex, msg.sender);
        }
    }
    
    function preMint(uint _quantity) external payable  {
        require(hasPreSaleStarted, "Presale hasn't started.");
        require(!preSaleOver, "Presale is over, no more allowances.");
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_PRESALE, "Quantity cannot be bigger than MAX_PREMINTING.");
        require(preSaleAllowance[msg.sender].sub(_quantity) >= 0, "The user is not allowed to do further presale buyings.");
        require(preSaleAllowance[msg.sender] >= _quantity, "This address is not allowed to buy that quantity.");
        require(totalSupply().add(_quantity) <= MAX_SNEAKERHEADZ, "Sold out");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "Ether value sent is below the price.");
        
        (bool success, ) = payableAddress.call{value:msg.value}("");
        require(success, "Transfer failed.");
        
        preSaleAllowance[msg.sender] = preSaleAllowance[msg.sender].sub(_quantity);
        
        for (uint i = 0; i < _quantity; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            emit SneakerHeadzMinted(mintIndex, msg.sender);
        }
    }
    
    function mintByOwner(address _to, uint256 _quantity) external onlyOwner {
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "Quantity cannot be bigger than MAX_BUYING.");
        require(totalSupply().add(_quantity) <= MAX_SNEAKERHEADZ, "Sold out.");
        
        for (uint i = 0; i < _quantity; i++) {
            uint mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
            emit SneakerHeadzMinted(mintIndex, _to);
        }
    }

    
    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://api.tssnft.com/token/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.tssnft.com/contract/nft";
    }
    
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }
    
    function startSale() external onlyOwner {
        require(!hasSaleStarted, "Sale already active.");
        
        hasSaleStarted = true;
        hasPreSaleStarted = false;
        preSaleOver = true;
    }

    function pauseSale() external onlyOwner {
        require(hasSaleStarted, "Sale is not active.");
        
        hasSaleStarted = false;
    }
    
    function startPreSale() external onlyOwner {
        require(!preSaleOver, "Presale is over, cannot start again.");
        require(!hasPreSaleStarted, "Presale already active.");
        
        hasPreSaleStarted = true;
    }

    function pausePreSale() external onlyOwner {
        require(hasPreSaleStarted, "Presale is not active.");
        
        hasPreSaleStarted = false;
    }

    function setPayableAddress(address _payableAddress) external onlyOwner {
        payableAddress = _payableAddress;
    }
    
    function checkEarlyBird(address earlyBirdAddress) public view returns (uint) {
        return preSaleAllowance[earlyBirdAddress];
    }
    
    
    function addEarlyBirds(address[] memory earlyBirdAddresses) external onlyOwner {
        require(!preSaleOver, "presale is over, no more allowances");
        
        for (uint i = 0; i < earlyBirdAddresses.length; i++) {
            preSaleAllowance[earlyBirdAddresses[i]] = MAX_PRESALE;
        }
    }
}