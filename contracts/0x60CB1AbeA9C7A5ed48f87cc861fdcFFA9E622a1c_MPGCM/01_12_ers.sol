// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MPGCM is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;

    uint256 public constant tokenSupply = 250;
    uint256 public totalWhitelist;
    string public tokenBaseURI;
    bool public mintLive;

    mapping(address => uint256) public totalPurchases;
    mapping(address => uint256) private whitelisted;

    constructor(string memory initTokenBaseURI) ERC721("MPGCM", "MPGCM") {
        tokenBaseURI = initTokenBaseURI;
        mintLive = false;
    }

    function claimMedal() external payable {
        require(whitelisted[msg.sender] != 0, "Gold tier member only!");
        require(mintLive, "Minting period not started");
        require(_tokenCounter.current() <= tokenSupply, "All NFT already minted");
        require(_tokenCounter.current() + 1 <= tokenSupply, "Minting would exceed the maximum supply");
        require(totalPurchases[msg.sender] + 1 <= 1, "You can not mint more than one");

        totalPurchases[msg.sender] += 1;

        if (!_exists(whitelisted[msg.sender])) {
            _safeMint(msg.sender, whitelisted[msg.sender]);
            _tokenCounter.increment();
        }
    }

    function totalClaim() external view returns (uint256) {
        return _tokenCounter.current();
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function toggleSale() external onlyOwner {
        mintLive = !mintLive;
    }

    function whitelistUser(address[] memory user, uint256[] memory tokenID) external onlyOwner{
        require(!mintLive, "Minting phase need to be closed");
        require(totalWhitelist + user.length <= tokenSupply, "Whitelist fully booked!");
        for (uint256 i = 0; i < user.length; i++) {
            if (whitelisted[user[i]] == 0) {
                totalWhitelist++;
                whitelisted[user[i]] = tokenID[i];
            }
        }
    }

    function removeWhitelistUser(address[] memory user) external onlyOwner {
        require(!mintLive, "Minting phase need to be closed");
        for (uint256 i = 0; i < user.length; i++) {
            if (whitelisted[user[i]] != 0) {
                if(totalPurchases[user[i]] == 0){
                    totalWhitelist--;
                    delete whitelisted[user[i]];
                }
            }
        }
    }

    function isWhitelist(address to) public view returns(bool){
        if(whitelisted[to] != 0){
            return true;
        }
        return false;
    }

    function tokenWhitelist(address to) public view returns(uint){
        if(_exists(whitelisted[to])){
            return whitelisted[to];
        }
        return 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }
}