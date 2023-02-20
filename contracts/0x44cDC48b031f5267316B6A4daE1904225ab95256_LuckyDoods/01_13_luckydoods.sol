//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ░██╗░░░░░░░██╗███████╗██╗██████╗░███████╗  ████████╗██╗░░██╗███████╗
// ░██║░░██╗░░██║██╔════╝╚█║██╔══██╗██╔════╝  ╚══██╔══╝██║░░██║██╔════╝
// ░╚██╗████╗██╔╝█████╗░░░╚╝██████╔╝█████╗░░  ░░░██║░░░███████║█████╗░░
// ░░████╔═████║░██╔══╝░░░░░██╔══██╗██╔══╝░░  ░░░██║░░░██╔══██║██╔══╝░░
// ░░╚██╔╝░╚██╔╝░███████╗░░░██║░░██║███████╗  ░░░██║░░░██║░░██║███████╗
// ░░░╚═╝░░░╚═╝░░╚══════╝░░░╚═╝░░╚═╝╚══════╝  ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝

//  ██╗░░░░░██╗░░░██╗░█████╗░██╗░░██╗██╗░░░██╗  ██████╗░░█████╗░░█████╗░██████╗░░██████╗░░░
//  ██║░░░░░██║░░░██║██╔══██╗██║░██╔╝╚██╗░██╔╝  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝░░░  
//  ██║░░░░░██║░░░██║██║░░╚═╝█████═╝░░╚████╔╝░  ██║░░██║██║░░██║██║░░██║██║░░██║╚█████╗░░░░  
//  ██║░░░░░██║░░░██║██║░░██╗██╔═██╗░░░╚██╔╝░░  ██║░░██║██║░░██║██║░░██║██║░░██║░╚═══██╗██╗
//  ███████╗╚██████╔╝╚█████╔╝██║░╚██╗░░░██║░░░  ██████╔╝╚█████╔╝╚█████╔╝██████╔╝██████╔╝╚█║  
//  ╚══════╝░╚═════╝░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░  ╚═════╝░░╚════╝░░╚════╝░╚═════╝░╚═════╝░░╚╝  

//  ██╗░░██╗██╗░░░  ░██████╗░███╗░░░███╗██╗
//  ██║░░██║██║░░░  ██╔════╝░████╗░████║██║
//  ███████║██║░░░  ██║░░██╗░██╔████╔██║██║
//  ██╔══██║██║██╗  ██║░░╚██╗██║╚██╔╝██║╚═╝
//  ██║░░██║██║╚█║  ╚██████╔╝██║░╚═╝░██║██╗
//  ╚═╝░░╚═╝╚═╝░╚╝  ░╚═════╝░╚═╝░░░░░╚═╝╚═╝

contract LuckyDoods is ERC721ABurnable, DefaultOperatorFilterer, Ownable {

    // -- SETUP
    using Strings for uint256;

    string public constant DOOD_TOKEN_URI = "https://luckydoods.com/metadata/";

    constructor() ERC721A("Lucky Doods", "LUCKY") {}

    uint256 public constant maximum_supply_of_doods = 1000;
    bool public is_frosted = true; // <-- GOODBYE PAPER HANDS

    // -- FUNCTIONS

    function mint_doods(uint256 number_of_doods, address lucky_recipient, uint256 maximum_in_batch, uint256 maximum_per_transaction, uint256 price_per_dood, uint8 v, bytes32 r, bytes32 s) public payable {
        
        uint256 current_supply_of_doods = totalSupply();

        require(number_of_doods <= maximum_per_transaction, "Wow! Hold on there partner. You can only mint a maximum of 10 LuckyDoods at a time.");
        require(current_supply_of_doods + number_of_doods <= maximum_in_batch, "Oh Snap! We're only selling a few LuckyDoods at a time. Looks like you're trying to mint more than there are currently on offer.");
        require(current_supply_of_doods + number_of_doods <= maximum_supply_of_doods, "Easy there Cowboy! Looks like you're trying to exceed the maximum supply of LuckyDoods.");
        require(msg.value >= price_per_dood * number_of_doods, "Cheeky! You're not sending enough Ethereum. We need the full amount of Ethereum requested in order to pay for all the drip your Dood comes with and to make sure they're fully coated in Lucky Sauce.");

        require(ecrecover(keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(lucky_recipient, maximum_in_batch, maximum_per_transaction, price_per_dood))
        )), v, r, s) == owner(), "Hmmm... You trying to pull a fast one on us? That signature doesn't look right to me.");

        _safeMint(lucky_recipient, number_of_doods);

    }

    function withdraw_all() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function change_frost(bool frost) public onlyOwner {
        is_frosted = frost;
    }

    // -- OVERRIDES

    function tokenURI(uint256 tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Erm... Strange... Looks like this token does not exist..?");
        return string(abi.encodePacked(DOOD_TOKEN_URI, tokenId.toString()));
    }

    // -- FROSTING + OS ENFORCEMENT
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721A) {
        require(from == address(0) || is_frosted == false, "Uh Oh! The transfer or sale of this token is temporarily locked. But don't sweat it, your NFT will soon be transferable and re-sellable :)");   
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        require(is_frosted == false, "Uh Oh! The sale of this token is temporarily locked. But don't sweat it, your NFT will soon be re-sellable :)");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        require(is_frosted == false, "Uh Oh! The sale of this token is temporarily locked. But don't sweat it, your NFT will soon be re-sellable :)");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}