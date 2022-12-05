// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "closedsea/src/OperatorFilterer.sol";

error OnlyTrunkContractMayCall();
error TransferFailed();

contract Rotn is ERC721, ERC2981, OperatorFilterer, Ownable, ReentrancyGuard {

    using Strings for uint256;
    string private _baseTokenURI;
    address internal trunkContractAddress;

    bool public operatorFilteringEnabled = true;

    constructor(
        string memory initialBaseURI,
        address payable royaltiesReceiver
    ) ERC721("ROTN", "ROTN") {
        _baseTokenURI = initialBaseURI;
        setRoyaltyInfo(royaltiesReceiver, 500);
        _registerForOperatorFiltering();
    }

    function openTrunk(address to, uint256 trunkId) external virtual nonReentrant returns (uint256) {
        if(_msgSender() != trunkContractAddress) revert OnlyTrunkContractMayCall();
        _safeMint(to, trunkId);
        return trunkId;
    }

    // ======== IERC2981 ========

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }
         
    // ======== OperatorFilterer ========

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) 
        public 
        override 
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    // ======== Admin ========

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    function getTrunkContractAddress() external view returns (address) {
        return trunkContractAddress;
    }

    function setTrunkContractAddress( address contractAddress) external onlyOwner {
        trunkContractAddress = contractAddress;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return 
            ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

}