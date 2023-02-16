// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ext/ERC721A.sol";

error PresaleNotLive();
error ContractMintDetected();
error ExceedsSupply();
error MaxPerWalletReached();
error TransactionFailed();
error InvalidTokenId();
error InsufficientFunds();

contract blurrock is ERC721A, Ownable {
    uint256 public constant collection = 3000;
    uint256 public cost = 0.0035 ether;
    uint256 public constant maxPerWallet = 5;
    bool public sale = false;
    string public baseURI = "";

    constructor() ERC721A("Blur Rock", "BLURROCK") {
        _mint(msg.sender, 1);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setBaseURI(string calldata _meta) public onlyOwner {
        baseURI = _meta;
    }

    function goLive(bool toggle) external onlyOwner {
        sale = toggle;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!success) revert TransactionFailed();
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if(!_exists(id)) revert InvalidTokenId();
        return string(abi.encodePacked(id,_toString(id), ".json"));
    }

    function mint(uint256 amount) external payable {
        if(!sale) revert PresaleNotLive();
        if(tx.origin != msg.sender) revert ContractMintDetected();
        if(_totalMinted() + amount > collection) revert ExceedsSupply();
        if(_numberMinted(msg.sender) + amount > maxPerWallet) revert MaxPerWalletReached();
        if(msg.value < amount * cost) revert InsufficientFunds();
        _mint(msg.sender, amount);
    }
}