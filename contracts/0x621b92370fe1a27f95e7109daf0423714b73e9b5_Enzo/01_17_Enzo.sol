// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&Y:.^?5#@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@&5Y&@#J:      .::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@&5!?B#J:^? ^?^:  :J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@G:!#@Y. :&# [email protected]@J [email protected]@&YJ&@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@B&@@@
// @@@@&J:!&@@~  :&B !#?:    .!G#Y^  !#@G!   [email protected]@@@@G7.  [email protected]@@@@@@G5!   ^[email protected]@@@@@P~.  [email protected]@@
// @@@&7  [email protected]@@!  :&B .^..:::[email protected]@Y.    !77?^    [email protected]@#?!PY^   ^[email protected]@B!:. !?^.   .:[email protected]@?: .GJ7:.    [email protected]@@@
// @@@B   [email protected]@@!  :&B !&&&&&&@@@@@G    [email protected]@&:   [email protected]@&#@@@@J.~5&@@Y    [email protected]&#J    [email protected]@!  :&@@@[email protected]@@@@@
// @@@B   [email protected]@@!  .&B [email protected]@@@@@@@@@@B    [email protected]@@@^   [email protected]@@@@@B?:[email protected]@@@Y    [email protected]@@#.   [email protected]@!  .7B&5~ :75B&@@@@
// @@@B   :[email protected]@! [email protected] [email protected]@@@@@@@@@@G    [email protected]@@@^   [email protected]@@@G7   [email protected]@Y    [email protected]@@B.   [email protected]@Y!:. .~?G5^   [email protected]@@@
// @@@#!   [email protected]@B [email protected]@@@@@@@@&@G    [email protected]@@@^   [email protected]@@BJ???:    [email protected]    [email protected]@@B.   [email protected]@@@&G.^#@@@Y   [email protected]@@@
// @@@@&7    ..P&@@B [email protected]@@@@@#[email protected]    [email protected]@@@^   [email protected]@@@@@@@&Y.  [email protected]    P#@@#.   [email protected]@@#Y^?G#&@@Y   [email protected]@@@
// @@@@@&J:    ..!?5 ~BBBBJ!:~5&@G    [email protected]@@&:   ^G#@@@@@@@? [email protected]   ..!?5   [email protected]#J:  ...:7Y?  :[email protected]@@@
// @@@@@@@#J:              ^[email protected]@@&?    !#@@@?.  :?#@@@@&[email protected]@@@#GJ!:   .!?G#@5.  .!!~.    ^Y&@@@@@
// @@@@@@@@@&BY??????????P#@@@@@@@P??5&@@@@@B?J#@@@@[email protected]@@@@@@@@@@#BJB#@@@@@?~?G#@@@#G!^5&@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@&@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";



contract Enzo is ERC721A, DefaultOperatorFilterer, ERC2981, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public publicBalance;   // internal balance of public mints to enforce limits

    bool public mintingIsActive = false;           // control if mints can proceed
    uint256 public constant maxSupply = 5555;      // total supply
    uint256 public constant maxMint = 10;          // max per mint
    uint256 public constant maxWallet = 10;        // max per wallet
    string public baseURI;                         // base URI of hosted IPFS assets
    string public _contractURI;                    // contract URI for details

    constructor() ERC721A("Enzo", "ENZO") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    // Show contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Specify royalties
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) 
        public 
        onlyOwner 
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or paused
    function toggleMinting() external onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    // Specify a new IPFS URI for token metadata
    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    // Specify a new contract URI
    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    // Internal mint function
    function _mintTokens(uint256 numberOfTokens) private {
        require(numberOfTokens > 0, "Must mint at least 1 token.");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply.");

        // Mint number of tokens requested
        _safeMint(msg.sender, numberOfTokens);

        // Disable minting if max supply of tokens is reached
        if (totalSupply() == maxSupply) {
            mintingIsActive = false;
        }
    }

    // Mint public
    function mintPublic(uint256 numberOfTokens) external payable {
        require(mintingIsActive, "Minting is not active.");
        require(msg.sender == tx.origin, "Cannot mint from external contract.");
        require(numberOfTokens <= maxMint, "Cannot mint more than 10 during mint.");
        require(publicBalance[msg.sender].add(numberOfTokens) <= maxWallet, "Cannot mint more than 10 per wallet.");

        _mintTokens(numberOfTokens);
        publicBalance[msg.sender] = publicBalance[msg.sender].add(numberOfTokens);
    }

    /*
     * Override the below functions from parent contracts
     */

    // Always return tokenURI, even if token doesn't exist yet
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }


    function setApprovalForAll(address operator, bool approved) 
        public 
        override(ERC721A)
        onlyAllowedOperatorApproval(operator) 
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

}