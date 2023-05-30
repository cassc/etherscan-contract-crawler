pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Lazy8YachtClub is ERC721A, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxTokens = 8888;
    uint256 public _price = 95000000000000000; // 0.095 ETH
    uint256 public _presale_price = 95000000000000000; // 0.095 ETH
    uint256 public _max_whitelist_mint = 8888; // can be changed

    bool private _saleActive = false;
    bool private _presaleActive = false;

    string public _prefixURI = "ipfs://QmSTMJw7y1PbFtf6NmyHfJPazVfg5aetV6eL1XXZwtoJ95/"; //pre-reveal json

    mapping(address => bool) private _whitelist;

    constructor() ERC721A("Lazy8YachtClub", "LAZY8") 
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

    function numSold() public view returns (uint256) {
        return totalSupply();
    }

    function displayMax() public view returns (uint256) {
        return _maxTokens;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return _whitelist[_addr];
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

    function changeWhitelistMaxMint(uint256 _newMax) public onlyOwner {
        _max_whitelist_mint = _newMax;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
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

    function whiteListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
    }

    //onlyOwner contract interactions

    function mintTo(uint256 quantity, address _addr) public onlyOwner {
        _safeMint(_addr, quantity);
    }

    function withdraw_all() external onlyOwner {
        uint256 balance = address(this).balance;
        //divides the withdraw between everybody
        payable(0x0058052333e3F818C2F3A795c449325A93F32588).transfer(balance * 2025 / 10000); //investor
        payable(0x1F819EA2dCa46FCc2B8BC46F8cAC68d3Eb3d58b6).transfer(balance * 1350 / 10000); //development
        payable(0x5d2FB1BC2Dd42a74E19FBe16f4c5D7f8c0860CE3).transfer(balance * 1125 / 10000); //marketing
        payable(0xF2aE765BCC2108E77384dFFf6EDf1fCf8C10E461).transfer(balance * 5500 / 10000); //operating wallet
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
        require(amount <= _max_whitelist_mint, "Mint: You may only mint up to 10");

        uint256 totalMinted = totalSupply();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _presale_price);

        _safeMint(_msgSender(), amount);
        //_whitelist[_msgSender()] = false; Unlimited TXN allowed for WL
    }

}