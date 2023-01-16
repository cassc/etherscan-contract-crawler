pragma solidity ^0.8.17;

import "./ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "./DefaultOperatorFiltererUpgradeable.sol";


contract DobermanGangV2 is ERC721AQueryableUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable {
    uint256 public cost;   
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    address private withdrawWallet;
    bool private mintable;
    string baseURI;
   
   /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMax) public onlyOwner {
        maxMintAmount = _newMax;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleMintable() public onlyOwner {
        mintable = !mintable;
    }

    function getWithdrawWallet() public view returns (address) {
        return withdrawWallet;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function adminMint(address to, uint256 _mintAmount) public onlyOwner {
        _mint(to, _mintAmount);
    }

    function airdropMint(uint256[] calldata tokenIds, address[] calldata owners) public onlyOwner {
        require(tokenIds.length == owners.length);
        require(tokenIds.length > 0);
        require(!mintable);
        for (uint i = 0; i < tokenIds.length; i++) {
            _airdropMint(tokenIds[i], owners[i]);
        }        
    }

    function mint(uint256 _mintAmount) external payable {
        require(mintable);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(totalSupply() + _mintAmount <= maxSupply);
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {            
            require(msg.value >= cost * _mintAmount);
        }

        _mint(msg.sender, _mintAmount);
    }

    function _startTokenId() internal view virtual override(ERC721AUpgradeable) returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual  override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable virtual 
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }    
}