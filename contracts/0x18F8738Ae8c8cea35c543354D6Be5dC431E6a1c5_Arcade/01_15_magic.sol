//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Arcade is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    string public baseTokenURI;
    uint public constant supply = 99;
    bool public whitelistSale = false;
    bool public reserveListSale = false;
    mapping(address => bool) private mintedWallets;
    address[] private whitelistAddr;
    address[] private reserveListAddr;

    constructor(string memory baseURI) ERC721("4rcade", "GG") {
        setBaseURI(baseURI);
    }

    modifier isUser() {
        require(tx.origin == msg.sender, "not hooman");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
        
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function toggleReserveListSale() external onlyOwner {
        reserveListSale = !reserveListSale;
    }

    function reserveNFTs(uint numTokens) public onlyOwner {
        uint tokensMinted = _tokenIds.current();
        require(tokensMinted.add(numTokens) <= supply, "exceeds supply");
        for (uint i = 0; i < numTokens; i++) {
            _mintToken();
        }
    }

    function isWhitelisted(address addy) private view returns (bool) {
        for (uint i = 0; i < whitelistAddr.length; i++) {
            if (whitelistAddr[i] == addy)
                return true;
        }
        return false;
    }
    
    function isReserveListed(address addy) private view returns (bool) {
        for (uint i = 0; i < reserveListAddr.length; i++) {
            if (reserveListAddr[i] == addy)
                return true;
        }
        return false;
    }

    function mintWhitelist() public isUser {
        require(whitelistSale, "whitelist mint not active");
        require(isWhitelisted(msg.sender), "sorry, not on whitelist");
        require(!mintedWallets[msg.sender], "already minted");
        uint tokensMinted = _tokenIds.current();
        require(tokensMinted.add(1) <= supply, "exceeds supply");
        
        _mintToken();
        mintedWallets[msg.sender] = true;
    }

    function mintReserveList() public isUser {
        require(reserveListSale, "reserve list mint not active");
        require(isReserveListed(msg.sender), "sorry, not on reserve list");
        require(!mintedWallets[msg.sender], "already minted");
        uint tokensMinted = _tokenIds.current();
        require(tokensMinted.add(1) <= supply, "exceeds supply");
        
        _mintToken();
        mintedWallets[msg.sender] = true;
    }

    function _mintToken() private {
        _tokenIds.increment();
        _mint(msg.sender, _tokenIds.current());
    }

    function reserveListAdd(address[] memory addys) public onlyOwner {
        for (uint i = 0; i < addys.length; i++) {
            reserveListAddr.push(addys[i]);
        }
    }

    function whitelistAdd(address[] memory addys) public onlyOwner {
        for (uint i = 0; i < addys.length; i++) {
            whitelistAddr.push(addys[i]);
        }
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "youre broke");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "failed withdrawal");
    }   
}