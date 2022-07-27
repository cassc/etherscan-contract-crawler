// ····································································································
// ····································································································
// ····································································································
// ····································································································
// ····································································································
// ····································································································
// ····································································································
// ····································································································
// ······························xxxxxxxx························xxxxxxxx······························
// ····························xxxxxxxxxxxx····················xxxxxxxxxxxx····························
// ··························xxxxxxxxxxxxxxxx················xxxxxxxxxxxxxxxx··························
// ··························xxxxxxxxxxxxxxxxxx············xxxxxxxxxxxxxxxxxx··························
// ··························xxxxxxxxxxxxxxxxxxxx········xxxxxxxxxxxxxxxxxxxx··························
// ···························xxxxxxxxxxxxxxxxxxxxx····xxxxxxxxxxxxxxxxxxxxx···························
// ······························xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx······························
// ································xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx································
// ··································xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx··································
// ····································xxxxxxxxxxxxxxxxxxxxxxxxxxxx····································
// ······································xxxxxxxxxxxxxxxxxxxxxxxx······································
// ······································xxxxxxxxxxxxxxxxxxxxxxxx······································
// ····································xxxxxxxxxxxxxxxxxxxxxxxxxxxx····································
// ··································xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx··································
// ································xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx································
// ·····························xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx·····························
// ···························xxxxxxxxxxxxxxxxxxxxx····xxxxxxxxxxxxxxxxxxxxx···························
// ··························xxxxxxxxxxxxxxxxxxxx········xxxxxxxxxxxxxxxxxxxx··························
// ··························xxxxxxxxxxxxxxxxxx············xxxxxxxxxxxxxxxxxx··························
// ···························xxxxxxxxxxxxxxx················xxxxxxxxxxxxxxxx··························
// ····························xxxxxxxxxxxx····················xxxxxxxxxxxxx···························
// ······························xxxxxxx························xxxxxxxxxx·····························
// ·····························································xxxxxxxxxx·····························
// ·····························································xxxx··xxx······························
// ·····························································xxxx··xxx······························
// ·····························································xxxx··xxx······························
// ···································································xxxx·····························
// ··································································xxxxx·····························
// ··································································xxxxx·····························
// ··································································xxxxx·····························
// ····································································································
// ····································································································
// ····································································································
// ····································································································
// ····································································································
// ····································································································


pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FeverDreamFriends is ERC721A, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxTokens = 1111;
    uint256 public _price = 80000000000000000; // 0.08 ETH
    uint256 public _presale_price = 70000000000000000; // 0.07 ETH
    uint256 public _OG_price = 60000000000000000; // 0.06 ETH

    bool private _saleActive = false;
    bool private _presaleActive = false;
    bool private _OGSaleActive = false;

    address _developer = 0xD54a775a1e4d55B111f83920d885D278aE633373;
    address _marketer = 0x49b1836deb054707a6656107E55fB499a569E0bc;


    string public _prefixURI = "ipfs://QmXRRGRWADaMfYkcumYQWJx8c4XCwp6pWZk8qA1hmzLHME/"; //pre-reveal json

    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _OGList;

    constructor() ERC721A("FeverDreamFriends", "FDF") 
    {
    }


    //view functions
    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function Sale() public view returns (bool) {
        return _saleActive;
    }

    function preSale() public view returns (bool) {
        return _presaleActive;
    }

    function OGSale() public view returns (bool) {
        return _OGSaleActive;
    }

    function numSold() public view returns (uint256) {
        return totalSupply();
    }

    function displayMax() public view returns (uint256) {
        return _maxTokens;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return _whitelist[_addr];
    }

    function isOGListed(address _addr) public view returns (bool) {
        return _OGList[_addr];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    } 

    //variable changing functions

    function changeMax(uint256 _newMax) public onlyOwner {
        _maxTokens = _newMax;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function toggleOGSale() public onlyOwner {
        _OGSaleActive = !_OGSaleActive;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function changePresalePrice(uint256 _newPrice) public onlyOwner {
        _presale_price = _newPrice;
    }

    function change_OG_price(uint256 _newPrice) public onlyOwner {
        _OG_price = _newPrice;
    }

    function whiteListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
    }

    function OGListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _OGList[accounts[i]] = true;
        }
    }

    //onlyOwner contract interactions
    function mintTo(uint256 quantity, address _addr) public onlyOwner {
        _safeMint(_addr, quantity);
    }

    function withdraw_all() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_developer).transfer(balance * 15 / 100);
        payable(_marketer).transfer(balance * 10 / 100);
        payable(msg.sender).transfer(balance * 75 / 100);
    }


    //minting functionality

    function mintItems(uint256 amount) public payable {
        require(_saleActive);
        uint256 totalMinted = totalSupply();
        require(totalMinted + amount <= _maxTokens);
        require(msg.value >= amount * _price);
        _safeMint(_msgSender(), amount);
    }

    function presaleMintItems(uint256 amount) public payable {
        require(_presaleActive);
        require(_whitelist[_msgSender()], "Mint: Unauthorized Access");

        uint256 totalMinted = totalSupply();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _presale_price);

        _safeMint(_msgSender(), amount);
        //_whitelist[_msgSender()] = false; Unlimited TXN allowed for WL
    }

    function OGMintItems(uint256 amount) public payable {
        require(_OGSaleActive);
        require(_OGList[_msgSender()], "Mint: Unauthorized Access");

        uint256 totalMinted = totalSupply();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _OG_price);

        _safeMint(_msgSender(), amount);
        //_whitelist[_msgSender()] = false; Unlimited TXN allowed for WL
    }

    function crossMint(address _to) public payable {
        require(_saleActive, "sale is closed");
        require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
              "This function is for Crossmint only."
            );
        uint256 totalMinted = totalSupply();
        require(totalMinted + 1 <= _maxTokens, "we are maxed out");
        require(msg.value >= _price, "price is wrong");
        _safeMint(_to, 1);
    }

}