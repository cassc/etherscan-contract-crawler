// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/SideOwnership.sol";


contract WeMissYou is ERC721A, DefaultOperatorFilterer, Ownable, SideOwnership{

    string public baseTokenURI;
    bool public operatorFilteringEnabled = true;
    bool public enabledAddSideOwnership;
    uint256 public MAX_SUPPLY;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) ERC721A(name_, symbol_){

        baseTokenURI = baseTokenURI_;
    }

    function mint(address[] memory owners) external onlyOwner(){
        require(owners.length > 0, "no owner");
        uint256 tokenId = _nextTokenId();
        
        _safeMint(owners[0], 1);
        for (uint256 i = 1; i < owners.length; i++){
            require(owners[i] != owners[0], "invalid owner address");
            require(!hasSideOwnership(owners[i], tokenId), "already a side owner");
            _addSideOwnership(owners[i], tokenId);
        }
        if (MAX_SUPPLY != 0 && _totalMinted() > MAX_SUPPLY){
            revert("excess MAX_SUPPLY");
        }
    }

    function setSideApprovalForToken(uint256 tokenId, bool approval) external{
        address sender = _msgSender();
        require(hasSideOwnership(sender, tokenId), "not side owner");
        _setSideApprovalForToken(sender, tokenId, approval);
    }

    function addSideOwnership(address account, uint256 tokenId) external virtual fullOwnership(tokenId){
        require(enabledAddSideOwnership, "cannot add side ownerside");
        require(ownerOf(tokenId) != account, "cannot add owner as side owner");
        require(!hasSideOwnership(account, tokenId), "already a side owner");
        _addSideOwnership(account, tokenId);
    }

    function transferSideOwnership(address to, uint256 tokenId) external virtual{
        address sender = _msgSender();
        require(hasSideOwnership(sender, tokenId), "not side owner");
        require(ownerOf(tokenId) != to, "cannot transfer side ownership to owner");
        require(!hasSideOwnership(to, tokenId), "already a side owner");
        _revokeSideOwnership(sender, tokenId);
        _addSideOwnership(to, tokenId);
    }

    function revokeSideOwnership(uint256 tokenId) external virtual{
        address sender = _msgSender();
        require(hasSideOwnership(sender, tokenId), "not side owner");
        _revokeSideOwnership(sender, tokenId);
    }

    function toggleAddSideOwnership() external onlyOwner(){
        enabledAddSideOwnership = !enabledAddSideOwnership;
    }

    // ERC721A calls transferFrom internally in its two safeTransferFrom functions
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) fullOwnership(tokenId) {

        super.transferFrom(from, to, tokenId);
        _afterTransfer(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setMaxSupply(uint256 supply) external onlyOwner(){
        require(MAX_SUPPLY == 0, "Cannot set MAX_SUPPLY");
        MAX_SUPPLY = supply;
    }

    // =============== OperatorFilterer ===============
    function toggleOperatorFiltering() public onlyOwner {
        operatorFilteringEnabled = !operatorFilteringEnabled;
    }

    function _checkFilterOperator(address operator) internal view override {
        if(operatorFilteringEnabled){
            super._checkFilterOperator(operator);
        }
    }
}