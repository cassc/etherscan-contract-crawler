// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MarkovsDream is ERC721, Ownable {
    uint16 private _tokenTokenIdMax = 32;
    string private _baseURIValue = "https://ocd.harm.work/tokens/";
    uint256 private _price = 5 ether;
    bool private _paused = true;
    address payable private adminWallet = payable(0x9011Eb570D1bE09eA4d10f38c119DCDF29725c41);

    constructor() ERC721("Markov's Dream", "MD") {}

    function setTokenIdMax(uint16 newTokenIdMax) external onlyOwner {
        _tokenTokenIdMax = newTokenIdMax;
    }

    function setPaused(bool newPaused) external onlyOwner {
        _paused = newPaused;
    }

    function mint(address recipient, uint16 tokenId)
        external
        payable
    {
        require(!_paused, "Contract not activated yet");
        require(msg.value >= _price, "You did not send enough ether");
        require(tokenId <= _tokenTokenIdMax, "TokenId exceeds maximum");
        _safeMint(recipient, tokenId);
        adminWallet.transfer(msg.value);
    }

    function totalSupply() external view returns (uint) {
        return _tokenTokenIdMax;
    }

    function updateAdminWallet(address payable _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function adminMint(address recipient, uint16 tokenId) external onlyOwner {
        _safeMint(recipient, tokenId);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;    
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURIValue = newBaseURI;
    }
}