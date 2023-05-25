//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// =============================================================
//                           ROCKSTARS
// =============================================================

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "solmate/src/utils/MerkleProofLib.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "solmate/src/utils/LibString.sol";
import "solmate/src/auth/Owned.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// =============================================================
//
//   ▄████  ██▓  ▄████  ▄▄▄       ▄████▄   ██▓▄▄▄█████▓▓██   ██▓
//  ██▒ ▀█▒▓██▒ ██▒ ▀█▒▒████▄    ▒██▀ ▀█  ▓██▒▓  ██▒ ▓▒ ▒██  ██▒
// ▒██░▄▄▄░▒██▒▒██░▄▄▄░▒██  ▀█▄  ▒▓█    ▄ ▒██▒▒ ▓██░ ▒░  ▒██ ██░
// ░▓█  ██▓░██░░▓█  ██▓░██▄▄▄▄██ ▒▓▓▄ ▄██▒░██░░ ▓██▓ ░   ░ ▐██▓░
// ░▒▓███▀▒░██░░▒▓███▀▒ ▓█   ▓██▒▒ ▓███▀ ░░██░  ▒██▒ ░   ░ ██▒▓░
//  ░▒   ▒ ░▓   ░▒   ▒  ▒▒   ▓▒█░░ ░▒ ▒  ░░▓    ▒ ░░      ██▒▒▒ 
//   ░   ░  ▒ ░  ░   ░   ▒   ▒▒ ░  ░  ▒    ▒ ░    ░     ▓██ ░▒░ 
// ░ ░   ░  ▒ ░░ ░   ░   ░   ▒   ░         ▒ ░  ░       ▒ ▒ ░░  
//       ░  ░        ░       ░  ░░ ░       ░            ░ ░     
//                              ░                      ░ ░     
// 
// Nothing is as it might seem in the streets of GC. In the
// shadows of the few prosperous lies the filth of the eye.
//
// High in the sky where decisions are made is the proof of
// those leading the path but not being seen. The truth is
// there but nothing can find it.
//
// Only in the eyes of those truly worthy the truth will be
// revealed. 50b ...

// =============================================================
//                            ERRORS
// =============================================================

error ChipDoesNotExist();
error NotAMemoryChip();
error TransferFailed();
error PunkNotStaked();
error PunkIsStaked();
error NotYourPunk();
error StakingClosed();

// =============================================================
//                       GIGA CITY PUNKS
// =============================================================

contract GigaCity is
    DefaultOperatorFilterer,
    ERC721AQueryable,
    ERC2981,
    Owned,
    ReentrancyGuard {

    // Where is MC at?
    address private _memoryChipContract;

    // Where are our assets hosted?
    string private _baseTokenURI;

    // Once/if we will transition to IPFS this will come in handy
    string private _uriSuffix = '';

    // This is not used for anything in this contract. Move on citizen.
    bool public initiateCountdown;

    // =============================================================
    //                            CONSTRUCTOR
    // =============================================================

    constructor(address memoryChipContract_) ERC721A("Giga City", "GC") Owned(msg.sender) {
        _memoryChipContract = memoryChipContract_;
        initiateCountdown = false;

        // At 3.33%  Filthy Fucking Peasants. 
        _setDefaultRoyalty(_msgSenderERC721A(), 333);
    }

    // =============================================================
    //                          MAKING THE DEAL
    // =============================================================

    function implant(address to) external nonReentrant() {
        // it needs to be the MC contract
        if (_msgSenderERC721A() != _memoryChipContract) revert NotAMemoryChip();
        // Safe mint since minting through contract
        _safeMint(to, 1);
    }

    // =============================================================
    //                              METADATA
    // =============================================================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId_)) revert ChipDoesNotExist();

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, LibString.toString(tokenId_), _uriSuffix))
            : '';
    }

    // =============================================================
    //                              ADMIN
    // =============================================================

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setURISuffix(string calldata uriSuffix_) public onlyOwner {
        _uriSuffix = uriSuffix_;
    }

    function setCountdown(bool newCountdown_) public onlyOwner {
        initiateCountdown = newCountdown_;
    }

    // =============================================================
    //                           WITHDRAW
    // =============================================================

    function withdraw() external onlyOwner nonReentrant() {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    // =============================================================
    //                  ALLOWED OPERATORS OVERRIDES
    // =============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable 
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============================================================
    //                           INTERFACE
    // =============================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
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