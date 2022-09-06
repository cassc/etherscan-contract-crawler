// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract m00nb1rd5 is ERC721A, Ownable, Pausable {

    string private baseURI;
    string private baseURISuffix;

    uint256 public supply = 10000;
    uint256 public freeSupply = 2500;
    uint256 public cost = 0.001 ether;
    uint256 public maxPerWallet = 2;
    uint256 public maxFreePerWallet = 1;

    event Minted(address indexed receiver, uint256 quantity);

    constructor() ERC721A("m00nb1rd5", "m00nb1rd5") {
        _pause();
    }

    modifier checkEOA() {
        require(msg.sender == tx.origin, "NonEOA!");
        _;
    }

    function publicMint(uint256 _quantity) external payable whenNotPaused checkEOA {
        require(_numberMinted(msg.sender) + _quantity <= maxPerWallet, "WalletLimitExceeded!");
        require(_totalMinted() + _quantity <= supply, "SupplyExceeded!");
        require(msg.value >= calculateMintCost(_quantity), "InvalidEtherAmount!");
        
        _mint(msg.sender, _quantity);

        emit Minted(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external onlyOwner {
        require(_numberMinted(msg.sender) + _quantity <= 50, "TeamLimitExceeded!");
        require(_totalMinted() + _quantity <= supply, "SupplyExceeded!");
        require(_quantity > 0, "InvalidQuantity!");

        _mint(msg.sender, _quantity);

        emit Minted(msg.sender, _quantity);
    }

    function setFreeSupply(uint256 _new) external onlyOwner {
        require(_new <= supply, "SupplyExceeded!");
        freeSupply = _new;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= 0, "InvalidBalance!");
        
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "WithdrawalFailed!");
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NonExistentToken");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), baseURISuffix));
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setBaseURISuffix(string calldata _uriSuffix) external onlyOwner {
        baseURISuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function calculateMintCost(uint256 _quantity) internal view returns (uint256 _totalCost) {
        require(_quantity > 0, "InvalidQuantity!");
        if (_totalMinted() <= freeSupply && _numberMinted(msg.sender) == 0) {
            if (_quantity == maxFreePerWallet) {
                return 0 ether;
            } else {
                return (_quantity - maxFreePerWallet) * cost;
            }
        } else {
            return _quantity * cost;
        }
    }
}