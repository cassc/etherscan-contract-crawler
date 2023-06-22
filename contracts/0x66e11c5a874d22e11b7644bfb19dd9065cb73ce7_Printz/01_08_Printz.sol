// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Printz is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.015 ether;
    uint256 public constant MAX_AMOUNT_PER_TX = 2;
    uint256 public constant MAX_MINTS_PER_WALLET = 2;

    string public uriSuffix = "";
    string public uriPrefix;
    bool public paused = true;

    constructor() ERC721A("Printz", "PRINTZ") {
        setUriPrefix("https://printznft.xyz/api/printz/");
    }

    //Error Checking
    modifier mintCompliance(address _receiver, uint256 _mintAmount) {
        require(!paused, "The contract is paused!");
        require(_mintAmount > 0 && _mintAmount <= MAX_AMOUNT_PER_TX, "Invalid mint amount!");
        require(_numberMinted(_receiver) + _mintAmount <= MAX_MINTS_PER_WALLET, "Reciever Has Exceeded the limit");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (MINT_PRICE * _mintAmount), "Not enough ether sent");
        _;
    }

    //For giveaways and rewards
    function ownerMintForAddress(address _receiver, uint256 _mintAmount) external onlyOwner {
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(_receiver, _mintAmount);
    }

    function mintForAddress(address _receiver, uint256 _mintAmount) external payable mintCompliance(_receiver, _mintAmount) {
        _safeMint(_receiver, _mintAmount);
    }

    function mint(uint256 _mintAmount) external payable mintCompliance(msg.sender, _mintAmount) {
        _safeMint(msg.sender, _mintAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function resetUriSuffix() external onlyOwner {
        uriSuffix = "";
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentUriPrefix = _baseURI();
        return bytes(currentUriPrefix).length > 0 ? string(abi.encodePacked(currentUriPrefix, _tokenId.toString(), uriSuffix)) : "";
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}