pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AltCoins is ERC721A , Ownable {
    using Strings for uint256;

    uint256 public totalAmount = 100000;
    string public URIRoot = "https://assets.altcoins.gg/v1/metadata/";
    string public URIExtension = ".json";
    uint256 public whitelistPrice = 0.00069 ether;
    uint256 public price = 0.0012 ether;
    bool public paused = true;
    bool public isWhitelistActive = true;
    uint256 public publicAmount = 500;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public mintCount;

    constructor() ERC721A("AltCoins", "ALTCOIN") {
        uint256 amount = 5 * totalAmount / 100;
        _mintERC2309(owner(),  amount);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(URIRoot, Strings.toString(_tokenId), URIExtension)) ;
    }

    function ownerMint(uint256 quantity) public onlyOwner {
        require(quantity + _totalMinted() <= totalAmount, "You cannot mint more than the total amount!");
        _mint(owner(), quantity);
    }

    function mint(uint256 quantity) external payable {
        require(!paused, "Contract is paused");
        require(quantity + _totalMinted() <= totalAmount, "You cannot mint more than the total amount!");
        if(isWhitelistActive){
            require(whitelist[msg.sender] >= quantity, "You cannot mint that many!");
            require(msg.value >= quantity * whitelistPrice, "I need more dough!");
            whitelist[msg.sender] = whitelist[msg.sender] - quantity;
        } else {
            require(mintCount[msg.sender] + quantity <= publicAmount , "You cannot mint that many!");
            require(msg.value >= quantity * price, "I need more dough!");
            mintCount[msg.sender] = mintCount[msg.sender] + quantity;
        }

        _mint(msg.sender, quantity);
    }

    function setURIRoot(string memory _uriRoot) public onlyOwner {
        URIRoot = _uriRoot;
    }

    function setURIExtension(string memory _uriExtension) public onlyOwner {
        URIExtension = _uriExtension;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setWhitelistPrice(uint256 _price) public onlyOwner {
        whitelistPrice = _price;
    }

    function setTotalAmount(uint256 _amount) public onlyOwner {
        require(_amount >= _totalMinted(), "Amount must be greater than total minted");
        totalAmount = _amount;
    }

    function setWhiteListActive(bool _v) public onlyOwner {
        isWhitelistActive = _v;
    } 

    function setWhiteListVal(address _user, uint256 _val) public onlyOwner{
        whitelist[_user] = _val;
    }

    function setWhiteListVals(address[] memory _addresses, uint256 _amount) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            setWhiteListVal(_addresses[i], _amount);
        }
    }

    function setPaused(bool _p) public onlyOwner {
        paused = _p;
    }

    function setPublicAmount(uint256 _amount) public onlyOwner {
        publicAmount = _amount;
    }

    function withdrawal() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}