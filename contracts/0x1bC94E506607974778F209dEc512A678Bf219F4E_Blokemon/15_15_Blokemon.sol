// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import  "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract Blokemon is ERC721Enumerable, Ownable{
    uint256 public mintPrice = .001 ether;
    uint256 public totalAmount;
    uint256 public maxPerWallet;
    uint256 public maxSupply;
    bool public isMintEnabled; // default to false
    address payable public withdrawWallet;
    string internal baseTokenUri; // used for image location
    mapping(address => uint256) public mintedWallets;
    mapping (uint256 => bool) public minted;

    constructor() payable ERC721('Blokemon', 'BKMN'){
        maxSupply = 12216;
        maxPerWallet = 25;
        isMintEnabled = true;
    }

    function toggleIsMintEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner{
        maxSupply = maxSupply_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner{
        maxPerWallet = maxPerWallet_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner{
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory){
        require (_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{value: address(this).balance}('');
        require(success, 'withdraw failed');
    }

    function mint(uint256[] memory _arr) public payable {
        require(isMintEnabled, 'Minting is not enabled');
        require(mintedWallets[msg.sender] + _arr.length <= maxPerWallet, 'exceed max wallet');
        require(msg.value == _arr.length * mintPrice, 'wrong value');
        require(maxSupply > totalAmount, 'Sold Out');

        for(uint256 i = 0; i < _arr.length; i++){
            mintedWallets[msg.sender]++;
            totalAmount++;
            _safeMint(msg.sender, _arr[i]);
        }

    }
}