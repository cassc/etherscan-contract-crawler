// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";

contract VeraHeritagePass is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;

    uint256 public constant MAX_SUPPLY = 440;

    uint256 private constant _MAX_MINT_PER_TXN = 5;

    bool public isPaused;

    string private _baseTokenURI;
    uint256 private _price;
    address private _crossmintAddress;
    address private _teamAddress;

    mapping(uint256 => bool) private _claims;

    constructor() ERC721A("Vera Bradley - Heritage Pass", "VERAHP") {
        isPaused = true;
        _baseTokenURI = "https://vera-heritage-pass.lairlabs.workers.dev/";
        _price = 0.04 ether; // ~$82 USD as of deployment time
        _crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
        _teamAddress = 0xbC85137E6BAF9495fB61a5E8B465D5e11ca01930;
    }

    function mintTokens(uint256 quantity) external payable mintGatekeeper(quantity) {
        _mint(msg.sender, quantity);
    }

    function mintTokensCrossmint(address to, uint256 quantity) external payable isCrossmint mintGatekeeper(quantity) {
        _mint(to, quantity);
    }

    modifier mintGatekeeper(uint256 quantity) {
        require(isPaused == false, "Minting is paused");
        require(msg.sender == tx.origin, "No minting from a contract");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Maximum supply exceeded");
        require(msg.value == _price * quantity, "Incorrect payment");
        require(quantity > 0 && quantity <= _MAX_MINT_PER_TXN, "Invalid mint quantity");
        _;
    }

    modifier isCrossmint() {
        require(msg.sender == _crossmintAddress, "Invalid Crossmint address");
        _;
    }

    function hasClaimedBag(uint256 tokenId) external view returns (bool) {
        return _claims[tokenId];
    }

    function claimBag(uint256 tokenId) external onlyOwner {
        require(_claims[tokenId] == false, "Bag already claimed");
        _claims[tokenId] = true;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }
    
    function setIsPaused(bool paused) external onlyOwner {
        isPaused = paused;
    }

    function setCrossmintAddress(address crossmintAddress) external onlyOwner {
        _crossmintAddress = crossmintAddress;
    }

    function setTeamAddress(address teamAddress) external onlyOwner {
        _teamAddress = teamAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mintReserveTokens(address[] calldata to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Maximum supply exceeded");
        for (uint256 i = 0; i < to.length; ++i) {
            _mint(to[i], quantity);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        Address.sendValue(payable(_teamAddress), address(this).balance);
    }
}