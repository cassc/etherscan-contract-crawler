// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/**
  _   _ ____      __     _______ 
 | \ | |  _ \   /\\ \   / / ____|
 |  \| | |_) | /  \\ \_/ / |     
 | . ` |  _ < / /\ \\   /| |     
 | |\  | |_) / ____ \| | | |____ 
 |_| \_|____/_/    \_\_|  \_____|
 */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract nbayc is ERC721, Ownable {

    bool public isActive = true;
    uint private totalSupply_ = 0;
    uint private nbFreeMint = 1000;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_) ERC721("nbayc", "NBAYC") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
        _baseURIextended = "ipfs://Qmer4mngi52iKHvmfVme1r2Kgty4ybm6pn1pbVt4bLvWuV/";
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function setNbFree(uint nbFree) external onlyOwner {
        nbFreeMint = nbFree;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setSaleState(bool newState) public onlyOwner {
        isActive = newState;
    }

    function freeMint(uint256 numberOfTokens) public {
        require(isActive, "Sale must be active to mint nbaycs");
        require(numberOfTokens <= 3, "Exceeded max token purchase (max 3)");
        require(
            totalSupply_ + numberOfTokens <= nbFreeMint,
            "Only the  first apes were free. Please use mint function now ;)"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply_ + 1;
            if (totalSupply_ < nbFreeMint) {
                _safeMint(msg.sender, mintIndex);
                totalSupply_ = totalSupply_ + 1;
            }
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(isActive, "Sale must be active to mint nbaycs");
        require(numberOfTokens <= 10, "Exceeded max token purchase");
        require(
            totalSupply_ + numberOfTokens <= 5000,
            "Purchase would exceed max supply of tokens"
        );
        require(
            0.015 ether * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply_ + 1;
            if (totalSupply_ < 5000) {
                _safeMint(msg.sender, mintIndex);
                totalSupply_ = totalSupply_ + 1;
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }
}