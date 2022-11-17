// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YonetsuruConmaru is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 private _currentTokenId;
    uint256 public maxSupply = 10;
    uint256 public mintPrice = 200000000000000000; // 0.2Eth
    uint256 public saleStartTime = 1669809600; //2022-11-30 21:00:00 +09:00
    string public baseURI = "https://japansake.xyz/metadata/YxC/";
    string public baseExtension = ".json";
    address public withdrawAddress;

    constructor() ERC721("Yonetsuru x Conmaru", "YxC") {
        _currentTokenId = 1;
        withdrawAddress = msg.sender;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "YonetsuruConmaru: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(),baseExtension));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function mint() external nonReentrant payable {
        require(saleStartTime <= block.timestamp , "can not mint, is not sale");
        require(msg.value >= mintPrice, "YonetsuruConmaru: Invalid price");
        require(_currentTokenId <= maxSupply  , 'YonetsuruConmaru: can not mint, over max size');
         uint256 tokenId = _currentTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function setPrice(uint256 _priceInWei) external onlyOwner {
        mintPrice = _priceInWei;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _value) public onlyOwner {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value) public onlyOwner {
        baseExtension = _value;
    }

    function setWithdrawAddress(address _address) external onlyOwner {
        withdrawAddress = _address;
    }

    function setSaleStartTime(uint256 _time) external onlyOwner {
        saleStartTime = _time;
    }

    function withdraw() external onlyOwner {
        (bool result, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(result, "transfer failed");
    }

    receive() external payable {}
}