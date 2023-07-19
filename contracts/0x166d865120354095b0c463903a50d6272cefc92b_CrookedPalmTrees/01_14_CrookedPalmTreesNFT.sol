pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CrookedPalmTrees is ERC721Enumerable, Ownable {
    using SafeMath for uint;
    using Strings for uint;
    using Address for address;

    uint public price;
    uint public cutDownFee;
    uint public killSharksFee;
    uint public buildUpFee;
    uint public immutable maxSupply;
    bool public mintingEnabled = true;
    bool public cutDown;
    bool public buildUp;
    bool public killSharks;
    uint public buyLimit;
    string private _baseURIPrefix;
    address payable immutable cash;

    constructor (
        string memory _name, 
        string memory _symbol, 
        uint _maxSupply, 
        uint _price, 
        uint _buyLimit,
        string memory _uri, 
        address payable _cash
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        price = _price;
        buyLimit = _buyLimit;
        _baseURIPrefix = _uri;
        cash = _cash;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        _baseURIPrefix = newUri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBuyLimit(uint256 newBuyLimit) external onlyOwner {
        buyLimit = newBuyLimit;
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mintNFTs(uint256 quantity) external payable {
        require(totalSupply().add(quantity) <= maxSupply, "Max supply exceeded");
        if (_msgSender() != owner()) {
            require(mintingEnabled, "Minting has not been enabled");
            require(quantity <= buyLimit, "Buy limit exceeded");
            require(price.mul(quantity) == msg.value, "Incorrect ETH value");
        }
        require(quantity > 0, "Invalid quantity");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), totalSupply().add(1));
        }
    }
    
    
    function toggleCutDown() external onlyOwner {
        cutDown = !cutDown;
    }
    
    function toggleBuildUp() external onlyOwner {
        buildUp = !buildUp;
    }
    
    function toggleKillSharks() external onlyOwner {
        killSharks = !killSharks;
    }
    
    function cutDownYourPalmTree(uint _tokenId) external payable {
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved for token");
        require(cutDownFee <= msg.value, "Not enough ETH");
        require(cutDown, "Can't cut");
        emit PalmCut(_tokenId);
    }

    event PalmCut(
        uint indexed _id
    );

    function buildUpIsland(uint _tokenId) external payable {
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved for token");
        require(buildUpFee <= msg.value, "Not enough ETH");
        require(buildUp, "can't build up");
        emit PalmBuildUp(_tokenId);
    }

    event PalmBuildUp(
        uint indexed _id
    );

    function removeSharks(uint _tokenId) external payable {
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved for token");
        require(killSharksFee <= msg.value, "Not enough ETH");
        require(killSharks, "Can't kill sharks");
        emit SharksKilled(_tokenId);
    }

    event SharksKilled(
        uint indexed _id
    );
    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint cashFee = balance.div(10);
        uint amount = balance.sub(cashFee);

        cash.transfer(cashFee);
        payable(owner()).transfer(amount);
    }
}