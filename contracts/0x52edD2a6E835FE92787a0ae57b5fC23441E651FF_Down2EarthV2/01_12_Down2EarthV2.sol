// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Down2EarthV2 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    uint256 public presaleCost = 0.025 ether;
    uint256 public cost = 0.035 ether;
    uint256 public maxSupply = 4220;
    uint256 public maxMintAmount = 3; 

    bool public preSaleLive;
    bool public mintLive;

    mapping(address => bool) private allowList;
    mapping(address => uint256) private allowListMintCount;
    mapping(address => uint256) private mintCount;

    modifier preSaleIsLive() {
        require(preSaleLive, "preSale not live");
        _;
    }
 
    modifier mintIsLive() {
        require(mintLive, "mint not live");
        _;
    }

    constructor() ERC721A("Down2EarthV2", "D2EV2") {
    }

    function isAllowListed(address _address) public view returns (bool){
        return allowList[_address];
    }

    function mintsAvailableForAddress(address _address) public view returns (uint256){
        return mintCount[_address];
    }

    function allowListMintsLeftForAddress(address _address) public view returns (uint256){
        return allowListMintCount[_address];
    }    

    // Minting functions
    function mint(uint256 _mintAmount) external payable mintIsLive {
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(minted + _mintAmount <= maxMintAmount, "mint over max");
        require(totalSupply() + _mintAmount <= maxSupply, "mint over supply");
        require(msg.value >= cost * _mintAmount, "insufficient funds");

        mintCount[_to] = minted + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function preSaleMint(uint256 _mintAmount) external payable preSaleIsLive {
        
        address _to = msg.sender;

        require(allowList[_to], "not not allowlisted");

        uint256 mintLeft = allowListMintCount[_to];

        require(mintLeft - _mintAmount >= 0, "mint over max");
        require(totalSupply() + _mintAmount <= maxSupply, "mint over supply");
        require(msg.value >= presaleCost * _mintAmount, "insufficient funds");

        allowListMintCount[_to] = mintLeft - _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // Only Owner executable functions
    function mintByOwner(address[] calldata _to, uint256[] calldata _mintAmount) external onlyOwner {
        require(_to.length == _mintAmount.length, "args not same size.");
        for (uint256 i; i < _to.length; i++) {
            require(totalSupply() + _mintAmount[i] <= maxSupply, "mint over supply");
            _safeMint(_to[i], _mintAmount[i]);
        }
    }

    function mintZeroDay(address[] calldata _to, uint256[] calldata _mintAmount) external onlyOwner {
        require(_to.length == _mintAmount.length, "args not same size.");
        
        for (uint256 i; i < _to.length; i++) {
            require(totalSupply() + _mintAmount[i] <= maxSupply, "mint over supply");
            _safeMint(_to[i], _mintAmount[i]);
            if(allowList[_to[i]] == false){
                allowList[_to[i]] = true;
            }
            allowListMintCount[_to[i]] += _mintAmount[i];
        }
    }

    function addToWhiteList(address[] calldata _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            allowList[_addresses[i]] = true;
            allowListMintCount[_addresses[i]] = 3;
        }
    }

    function togglePreSaleLive() external onlyOwner {
        if (preSaleLive) {
            preSaleLive = false;
            return;
        }
        preSaleLive = true;
    }

    function toggleMintLive() external onlyOwner {
        if (mintLive) {
            mintLive = false;
            return;
        }
        preSaleLive = false;
        mintLive = true;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        cost = newPrice;
    }
    function setPresalePrice(uint256 newPrice) public onlyOwner {
        presaleCost = newPrice;
    }    
    
    function setMaxPerWallet(uint256 newMax) public onlyOwner {
        maxMintAmount = newMax;
    }    
    

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}