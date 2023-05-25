// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@erc721a/ERC721AUpgradeable.sol";
import "@opregister/DefaultOperatorFilterer.sol";
import "@ozc-upgradeable/OwnableUpgradeable.sol";
import "./IBurner.sol";
import "@solmate/auth/Owned.sol";

error MintInactive();
error NotOwner(address sender, address expected);

contract TwelveDays is ERC721AUpgradeable, OwnableUpgradeable, DefaultOperatorFilterer {
    IBurner public BURNER = IBurner(0x304fbb8C76e9a21ebdD6e8a6a71c6D30F4a817b6);
    
    bool public mintActive = false;
    string private baseTokenURI = "";

    function initialize() initializerERC721A initializer public {
        __ERC721A_init('12DaysOfCrypto', '12DOC');
        __Ownable_init();
    }

    function mint(uint256 burnToken) public {
        if (!mintActive) {
            revert MintInactive();
        }

        if (msg.sender != BURNER.ownerOf(burnToken)) {
            revert NotOwner(msg.sender, BURNER.ownerOf(burnToken));
        }

        BURNER.burn(burnToken);
        _mint(msg.sender, 1);
    }

    function toggleMint() public onlyOwner {
        mintActive = !mintActive;
    }

    function setBurnContract(address burnAddress) public onlyOwner {
        BURNER = IBurner(burnAddress);
    }

    function setBaseURI(string calldata newURI) public onlyOwner {
        baseTokenURI = newURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
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
}