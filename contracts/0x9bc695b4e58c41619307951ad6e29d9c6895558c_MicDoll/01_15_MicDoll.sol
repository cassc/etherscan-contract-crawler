//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;
import "./ContextMicDoll.sol";

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MicDoll is ERC721AQueryable,DefaultOperatorFilterer,ReentrancyGuard,Pausable,Ownable,ContextMicDoll {  

    string public baseUri;

    struct TransferParam {
        address to;
        uint256 tokenId;
    }

    event SetBaseURI(address indexed sender, string indexed uri);
    
    constructor(address config_) ERC721A("MicDoll", "MICDOLL") {
        _checkConfig(IConfig(config_));
        baseUri='https://nftmeta.mmmm.world/micdoll/';
    }

    //by override the _startTokenId() method to set the start id number 
    function _startTokenId() internal pure override  returns (uint256) {
        return 6001;
    }

    // =============================================================
    // about ownership
    // relate with  "@openzeppelin/contracts/access/Ownable.sol"
    // =============================================================

    //let the founction renounceOwnership in  father contract become invalid
    function renounceOwnership() public override onlyOwner {
    }

    //let admin and owner both can call the founction transferOwnership
    function transferOwnership(address newOwner) public override {
        require(owner() == _msgSender() || config.hasRole(Registry.ADMIN_ROLE, _msgSender()),"Ownable: only message sender or admin can transfer ownership");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // =============================================================
    // about baseURI
    // =============================================================
    
    //set baseURI
    function setBaseURI(string memory uri_) external onlyAdmin {
        baseUri = uri_;
        emit SetBaseURI(msg.sender, uri_);
    }
    
    //override _baseURI() which is in the father contract
    function _baseURI() internal  view   override  returns (string memory) {
        return baseUri;
    }

    // =============================================================
    // about pause and unpause
    // relate with "@openzeppelin/contracts/security/Pausable.sol";
    // =============================================================

    //pause transfer function
    function pause() public isPauser {
        _pause();
    }

    //unpause transfer function
    function unpause() public isPauser {
        _unpause();
    }

    // =============================================================
    // about mint burn and transfer
    // =============================================================

    //single or batch mint by giving a quantity param 
    function mint(uint256 quantity) public  isMinter {
        address to = _HotWalletContract();
        _safeMint(to, quantity);
    }  

    //single burn
    function burn(uint256 tokenId) public isBurner {
        _burn(tokenId, true);
    }

    //batch burn
    function batchBurn(uint256[] memory tokenIds) public  nonReentrant isBurner{
        require (tokenIds.length > 0, "SN110: invalid tokenIds param");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "SN113:only tokenID owner can burn his token");
            _burn(tokenIds[i], true);
        }
    }
    //batch transfer
    function batchTransfer(TransferParam[] memory transfers) public  nonReentrant isTransferer{
        require (transfers.length > 0, "SN110: invalid transfers param");
        for (uint i = 0; i < transfers.length; i++) {
            address to = transfers[i].to;
            uint256 tokenId = transfers[i].tokenId;
            require(ownerOf(tokenId) == msg.sender, "SN114:only tokenID owner can transfer his token");
            safeTransferFrom(msg.sender, to, tokenId);
        }
    }

    //check if the from and to address is in the blacklist ;check  if the transfer founction is paused.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused isNotInTheBlacklist(from) isNotInTheBlacklist(to)  {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // =============================================================
    // to obey the   opensea  Operator Filter Registry standard
    // override the ERC721 transfer and approval methods
    // relate with "operator-filter-registry/src/DefaultOperatorFilterer.sol";
    // =============================================================
    function setApprovalForAll(address operator, bool approved) public override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}