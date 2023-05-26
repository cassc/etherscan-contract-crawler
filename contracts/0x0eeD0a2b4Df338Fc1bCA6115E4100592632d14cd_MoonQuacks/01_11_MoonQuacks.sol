pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonQuacks is ERC721A, Ownable{

    uint256 constant public MAX_SUPPLY = 3500;
    uint256 constant public MAX_BUY_PER_ADDRESS = 15;
    uint256 constant public MAX_PER_TX = 5;
    uint256 constant public PRICE = 0.015 ether;

    bool public isPublicSaleActive = false;

    uint256 public freeMax = 500;
    uint256 public nonFreeMax = 3000;

    string public contractURIString = "https://api.moonquacks.xyz/contract";
    string public baseURI = "https://api.moonquacks.xyz/metadata/";

    uint256 public totalSupplyFree;
    uint256 public totalSupplyPublic;
    
    constructor() ERC721A("MoonQuacks", "MQ") {}

    //////// Internal functions

    // Override start token id to set to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    //////// External functions
    function freeMint(uint256 _amount) external payable publicSaleActive {
        require(tx.origin == msg.sender, "No contract minting");
        require(_amount <= MAX_PER_TX, "Too many mints per tx");
        require(totalSupplyFree + _amount <= freeMax, "Not enough free mints left");
        
        uint256 userMintsTotal =  _numberMinted(msg.sender);
        require(userMintsTotal + _amount <= MAX_BUY_PER_ADDRESS, "Max mint limit");

        totalSupplyFree += _amount;

        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount) external payable publicSaleActive {
        require(tx.origin == msg.sender, "No contract minting");
        require(_amount <= MAX_PER_TX, "Too many mints per tx");
        require(totalSupplyPublic + _amount <= nonFreeMax, "Not enough mints left");

        uint256 userMintsTotal = _numberMinted(msg.sender);
        require(userMintsTotal + _amount <= MAX_BUY_PER_ADDRESS, "Max mint limit");

        uint256 price = PRICE;
        checkValue(price * _amount);
        totalSupplyPublic += _amount;

        _safeMint(msg.sender, _amount);
    }



    //////// Public View functions
    function contractURI() public view returns (string memory) {
        return contractURIString;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    //////// Private functions
    function checkValue(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    //////// Owner functions
    function mintTo(uint256 _amount, address _user) external onlyOwner {
        require(totalSupplyPublic + _amount <= nonFreeMax, "Not enough mints left");

        uint256 userMintsTotal = _numberMinted(_user);
        require(userMintsTotal + _amount <= MAX_BUY_PER_ADDRESS, "Max mint limit");

        totalSupplyPublic += _amount;

        _safeMint(_user, _amount);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURIString = _contractURI;
    }

    function setFreeMintMax(uint256 _freeMintMax) external onlyOwner {
        freeMax = _freeMintMax;
        nonFreeMax =  MAX_SUPPLY - freeMax;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        require(succ, "transfer failed");
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner{
        isPublicSaleActive = _isPublicSaleActive;
    }

    //////// Modifiers
    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }
}