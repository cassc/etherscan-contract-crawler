pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AngryApesArmyNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint;
    
    string baseURI;
    string public contractURI;
    
    uint public constant MAX_ANGRYAPES = 3333;
    uint public constant MAX_SALE = 25;
    uint public constant MAX_PRESALE = 2;
    
    address saleAddress;
    address devAddress;

    uint public price;
    
    mapping(address => uint256) private preSaleAllowance;
    
    bool public hasPreSaleStarted = false;
    bool public preSaleOver = false;
    bool public hasSaleStarted = false;
    
    event AngryApeMinted(uint indexed tokenId, address indexed owner);
    
    constructor(string memory baseURI_, string memory contractURI_) ERC721("Angry Ape Army", "AAA") {

        price = 0.08 ether;
        saleAddress = 0xD5144Af3d05C57Ba545e1B51A1769f4B4149d4dD;
        devAddress = 0x02441eE4BDdaD4887415d596971f026b561CE023;
        baseURI = baseURI_;
        contractURI = contractURI_;
    }
    
    function mintTo(address _to) internal {
        uint mintIndex = totalSupply();
        _safeMint(_to, mintIndex);
        emit AngryApeMinted(mintIndex, _to);
    }
    
    function mint(uint _quantity) external payable  {
        require(hasSaleStarted, "Sale hasn't started.");
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "Quantity cannot be bigger than MAX_BUYING.");
        require(totalSupply().add(_quantity) <= MAX_ANGRYAPES, "Sold out.");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "Ether value sent is below the price.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }
    
    function preMint(uint _quantity) external payable  {
        require(hasPreSaleStarted, "Presale hasn't started.");
        require(!preSaleOver, "Presale is over, no more allowances.");
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_PRESALE, "Quantity cannot be bigger than MAX_PREMINTING.");
        require(preSaleAllowance[msg.sender].sub(_quantity) >= 0, "The user is not allowed to do further presale buyings.");
        require(preSaleAllowance[msg.sender] >= _quantity, "This address is not allowed to buy that quantity.");
        require(totalSupply().add(_quantity) <= MAX_ANGRYAPES, "Sold out");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "Ether value sent is below the price.");
        
        preSaleAllowance[msg.sender] = preSaleAllowance[msg.sender].sub(_quantity);
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }
    
    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "Quantity cannot be bigger than MAX_SALE.");
        require(totalSupply().add(_quantity) <= MAX_ANGRYAPES, "Sold out.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(_to);
        }
    }
    
    function batchMintByOwner(address[] memory _mintAddressList, uint256[] memory _quantityList) external onlyOwner {
        require (_mintAddressList.length == _quantityList.length, "The length should be same");

        for (uint256 i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _quantityList[i]);
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
    
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }
    
    function setContractURI(string memory _URI) external onlyOwner {
        contractURI = _URI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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

    function setSaleAddress(address _saleAddress) external onlyOwner {
        saleAddress = _saleAddress;
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
    
    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 devAmount = totalBalance;

        uint256 saleAmount = totalBalance.mul(9000).div(10000); // 90%
        devAmount = devAmount.sub(saleAmount); // 10%

        (bool withdrawSale, ) = saleAddress.call{value: saleAmount}("");
        require(withdrawSale, "Withdraw Failed To Sale address.");

        (bool withdrawDev, ) = devAddress.call{value: devAmount}("");
        require(withdrawDev, "Withdraw Failed To Dev");
    }
}