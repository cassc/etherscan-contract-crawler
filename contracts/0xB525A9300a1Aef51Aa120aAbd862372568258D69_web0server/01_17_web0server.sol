// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import './web0.sol';

/// @title web0server
/// @author web0
/// @notice Issues and configures web0 pages

contract web0server is IERC721Receiver, ReentrancyGuard {


    web0 private _web0;
    address private _default_template;


    modifier onlyOwner(){
        require(msg.sender == owner(), "ONLY_OWNER");
        _;
    }


    constructor(address web0_, address default_template_){
        _web0 = web0(web0_);
        _default_template = default_template_;
    }


    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override pure returns (bytes4){
        return this.onERC721Received.selector;
    }


    /// @dev return the address holding the web0 #0 nft
    function owner() public view returns(address owner_){
        return _web0.ownerOf(0);
    }

    /// @dev allow owner to set the default template
    function setDefaultTemplate(address default_template_) public onlyOwner {
        _default_template = default_template_;
    }

    function issuePages(string[] memory titles_, address template_) public nonReentrant returns(uint[] memory) {

        uint id_head_ = _web0.getPageCount()-1;
        _web0.createPages(titles_);
        uint[] memory ids = new uint[](titles_.length);
        
        uint i;
        while(i < titles_.length){
            ids[i] = id_head_ + (i+1);
            _web0.setPageTemplate(ids[i], template_ == address(0) ? _default_template : template_);
            _web0.transferFrom(address(this), msg.sender, ids[i]);
            ++i;
        }

        return ids;

    }

    


}