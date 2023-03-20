// SPDX-License-Identifier: MIT
/*
░██████╗░░█████╗░██╗░░░░░██████╗░██████╗░░█████╗░██╗░░░██╗███████╗
██╔════╝░██╔══██╗██║░░░░░██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝╚════██║
██║░░██╗░██║░░██║██║░░░░░██║░░██║██████╦╝██║░░██║░╚████╔╝░░░███╔═╝
██║░░╚██╗██║░░██║██║░░░░░██║░░██║██╔══██╗██║░░██║░░╚██╔╝░░██╔══╝░░
╚██████╔╝╚█████╔╝███████╗██████╔╝██████╦╝╚█████╔╝░░░██║░░░███████╗
░╚═════╝░░╚════╝░╚══════╝╚═════╝░╚═════╝░░╚════╝░░░░╚═╝░░░╚══════╝
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./asset/DefaultOperatorFilterer.sol";
import "./asset/ERC721A.sol";

error MaxWalletExceeded();
error WithdrawFailed();
error InsufficientFund();
error SaleClosed();
error NoBotMint();
error MintedOut();
error MustMintOne();
error InvalidTokenID();

contract goldboyz is 
    ERC721A, 
    Ownable, 
    ERC2981, 
    DefaultOperatorFilterer {
    bool public toggleMint = false;
    uint public price = 0.0025 ether;
    uint public constant supply = 1888; 
    uint public constant freePerWallet = 1;
    uint public constant maxPerWallet = 5;
    string public constant ext = ".json";
    string public baseURI = "https://goldbz.infura-ipfs.io/ipfs/QmPbjDNEoGNPqFqe8ABXwAUFGAHGFc37MdM8gmkApn7aaC/metadata/";

    constructor() ERC721A("GoldBoyz", "gbzz") {
        setRoyaltyInfo(700);
        _mint(msg.sender, 1);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        if(!_exists(_tokenId)) revert InvalidTokenID();
        return string(abi.encodePacked(baseURI,_toString(_tokenId),ext));
    }

    function toggle(bool mintStart) external onlyOwner {
        toggleMint = !mintStart;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!success) revert WithdrawFailed();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function publicMint(uint quantity) external payable {
        if(!toggleMint) revert SaleClosed();
        if(quantity == 0) revert MustMintOne();
        if(!(supply >= _totalMinted() + quantity)) revert MintedOut();
        if(tx.origin != msg.sender) revert NoBotMint();      
        if(_numberMinted(msg.sender) + quantity > maxPerWallet) revert MaxWalletExceeded();

        if(_numberMinted(msg.sender) >= freePerWallet){
            if(msg.value < quantity * price) revert InsufficientFund();
        }else{
            if(msg.value < (quantity - freePerWallet) * price) revert InsufficientFund();
        }
        _mint(msg.sender, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    function setUri(string calldata _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setRoyaltyInfo(uint96 royalty) public onlyOwner {
        _setDefaultRoyalty(msg.sender, royalty);
    }

}