// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/Pausable.sol";

contract Miles is ERC721A, Ownable, Pausable {
    
    uint256 private _maxSupply;
    uint256 private _limitPerAccount;
    string private _uri;

    constructor() ERC721A("MilesV2", "MILESV2") {
        _maxSupply = 62;
        _limitPerAccount = 1;
        _uri = "https://metaathletes.mypinata.cloud/ipfs/QmRxcDCaNkrQLhAYfQEUEKCEuMF9ba4pU1LUcK7RLFZpvC/";
        pause();
    }

    modifier mintCompliance(uint256 quantity) {
        uint256 supply = quantity + balanceOf(_msgSender());
        require(supply <= _limitPerAccount, "Invalid mint quantity");
        require(_totalMinted() < _maxSupply, "Max supply exceeded");
        _;
    }

    function mint(uint256 quantity) public payable whenNotPaused mintCompliance(quantity){
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(_msgSender(), quantity);
    }

    // overides
    function _startTokenId() internal pure override returns(uint256) {
        return 1;
    }
    
    function _baseURI() internal view override returns(string memory) {
        return _uri;
    }

    // setter fct
    function setBaseUri(string memory uri) external onlyOwner {
        _uri = uri;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        _maxSupply = supply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setLimitPerAccount(uint256 limitPerAccount) external onlyOwner {
        _limitPerAccount = limitPerAccount;
    }

    // getter
    function getBaseURI() external view returns(string memory) {
        return _uri;
    }

    function getLimitPerAccount() external view returns(uint256) {
        return _limitPerAccount;
    }

    function getMaxSupply() external view returns(uint256) {
        return _maxSupply;
    }

    // opt
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Address: insufficient balance");

        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}