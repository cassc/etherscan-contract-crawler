// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TanakaChanmaroru is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 private _currentTokenId;
    uint256 public maxSupply = 15;
    uint256 public mintPrice = 250000000000000000; // 0.25Eth
    uint256 public preSaleStartTime = 1673956800; //2023-01-17 21:00:00 +09:00
    uint256 public saleStartTime = 1674043200; //2023-01-18 21:00:00 +09:00
    string public baseURI = "https://japansake.xyz/metadata/TxC/";
    string public baseExtension = ".json";
    address public withdrawAddress;
    mapping(address => uint256) public preSaleList;

    constructor() ERC721("Tanaka x Chanmaroru", "TxC") {
        _currentTokenId = 1;
        withdrawAddress = msg.sender;
        preSaleList[0x3BE5677864AD8851db077AC57e78C0Eecc0586b4] = 1;
        preSaleList[0xd04CC1589ac7ec0fE9Af8DE43E151E276ae2e4F4] = 1;
        preSaleList[0x797979aE51b5FC1f4b2938Eb9f949524896b7f04] = 1;
        preSaleList[0x56A13f6B07031a61E9c8F6446cFAe9ec4Def2E44] = 1;
        preSaleList[0x85E55785059ff0e100b140666fe0818e9FBeCf3a] = 1;
        preSaleList[0xb568eF90b63eF34f069faa3C03cB77E1D0ec4008] = 1;
        preSaleList[0xE27A311ab12dF25e2885e7BF51Cd494a6488b380] = 1;
        preSaleList[0xDD12A0c04BE3fF962E7321f11Bc08DbE227c25aC] = 1;
        preSaleList[0x1A8028927383A0665B62B4AA6eEfD5Dd66cB5A38] = 1;
        preSaleList[0xC048226670753063491bA4cF9bfFA4E23585DFdf] = 1;
        preSaleList[0x78aAd7F842d0C85bdF8C45BF4f5b527e412463Bd] = 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TanakaChanmaroru: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(),baseExtension));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function preSaleMint() external nonReentrant payable {
        require(preSaleStartTime <= block.timestamp , "can not mint, is not sale");
        require(block.timestamp <= saleStartTime , "can not mint, is not sale");
        require(msg.value >= mintPrice, "TanakaChanmaroru: Invalid price");
        require(_currentTokenId <= maxSupply  , 'TanakaChanmaroru: can not mint, over max size');

        require(preSaleList[msg.sender] >= 1,"exceeded allocated count");

        preSaleList[msg.sender]--;
        uint256 tokenId = _currentTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    function mint() external nonReentrant payable {
        require(saleStartTime <= block.timestamp , "can not mint, is not sale");
        require(msg.value >= mintPrice, "TanakaChanmaroru: Invalid price");
        require(_currentTokenId <= maxSupply  , 'TanakaChanmaroru: can not mint, over max size');
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

    function setPreSaleStartTime(uint256 _time) external onlyOwner {
        preSaleStartTime = _time;
    }

    function setPreSaleList(address[] calldata _address, uint256[] calldata _value) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            preSaleList[_address[i]] = _value[i];
        }
    }

    function withdraw() external onlyOwner {
        (bool result, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(result, "transfer failed");
    }

    receive() external payable {}
}