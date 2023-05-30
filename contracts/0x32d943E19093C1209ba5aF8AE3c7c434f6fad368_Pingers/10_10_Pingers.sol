// SPDX-License-Identifier: MIT
// Pingers by DevonFigures
// Contract Author: cygaar
pragma solidity ^0.8.17;

// ⠀⠀⢀⣠⠤⠶⠖⠒⠒⠶⠦⠤⣄⠀⠀⠀⣀⡤⠤⠤⠤⠤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⣴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣦⠞⠁⠀⠀⠀⠀⠀⠀⠉⠳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⡾⠁⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣘⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⢀⡴⠚⠉⠁⠀⠀⠀⠀⠈⠉⠙⠲⣄⣤⠤⠶⠒⠒⠲⠦⢤⣜⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⡄⠀⠀⠀⠀⠀⠀⠀⠉⠳⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⠹⣆⠀⠀⠀⠀⠀⠀⣀⣀⣀⣹⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⣠⠞⣉⣡⠤⠴⠿⠗⠳⠶⣬⣙⠓⢦⡈⠙⢿⡀⠀⠀⢀⣼⣿⣿⣿⣿⣿⡿⣷⣤⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⣾⣡⠞⣁⣀⣀⣀⣠⣤⣤⣤⣄⣭⣷⣦⣽⣦⡀⢻⡄⠰⢟⣥⣾⣿⣏⣉⡙⠓⢦⣻⠃⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠉⠉⠙⠻⢤⣄⣼⣿⣽⣿⠟⠻⣿⠄⠀⠀⢻⡝⢿⡇⣠⣿⣿⣻⣿⠿⣿⡉⠓⠮⣿⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠙⢦⡈⠛⠿⣾⣿⣶⣾⡿⠀⠀⠀⢀⣳⣘⢻⣇⣿⣿⣽⣿⣶⣾⠃⣀⡴⣿⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠙⠲⠤⢄⣈⣉⣙⣓⣒⣒⣚⣉⣥⠟⠀⢯⣉⡉⠉⠉⠛⢉⣉⣡⡾⠁⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⣠⣤⡤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⡿⠋⠀⠀⠀⠀⠈⠻⣍⠉⠀⠺⠿⠋⠙⣦⠀⠀⠀⠀⠀⠀⠀
// ⠀⣀⣥⣤⠴⠆⠀⠀⠀⠀⠀⠀⠀⣀⣠⠤⠖⠋⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀⠀⠀
// ⠸⢫⡟⠙⣛⠲⠤⣄⣀⣀⠀⠈⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠏⣨⠇⠀⠀⠀⠀⠀
// ⠀⠀⠻⢦⣈⠓⠶⠤⣄⣉⠉⠉⠛⠒⠲⠦⠤⠤⣤⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣠⠴⢋⡴⠋⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠉⠓⠦⣄⡀⠈⠙⠓⠒⠶⠶⠶⠶⠤⣤⣀⣀⣀⣀⣀⣉⣉⣉⣉⣉⣀⣠⠴⠋⣿⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠉⠓⠦⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⠁⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠙⠛⠒⠒⠒⠒⠒⠤⠤⠤⠒⠒⠒⠒⠒⠒⠚⢉⡇⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠴⠚⠛⠳⣤⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠚⠁⠀⠀⠀⠀⠘⠲⣄⡀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⠋⠙⢷⡋⢙⡇⢀⡴⢒⡿⢶⣄⡴⠀⠙⠳⣄⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⡀⠈⠛⢻⠛⢉⡴⣋⡴⠟⠁⠀⠀⠀⠀⠈⢧⡀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⠘⣶⢋⡞⠁⠀⠀⢀⡴⠂⠀⠀⠀⠀⠹⣄⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠈⠻⢦⡀⠀⣰⠏⠀⠀⢀⡴⠃⢀⡄⠙⣆⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡾⢷⡄⠀⠀⠀⠀⠉⠙⠯⠀⠀⡴⠋⠀⢠⠟⠀⠀⢹⡄

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";

error InvalidSaleState();
error InsufficientPrice();
error NotOnAllowlist();
error AllowlistSupplyReached();
error MaxSupplyReached();
error WithdrawFailed();
error InvalidAllowlist();
error DescendingSaleState();
error CantSetOffset();
error OffsetAlreadySet();

contract Pingers is Ownable, OperatorFilterer, ERC2981, ERC721A {
    event AuctionStarted(uint256 startTime);

    enum SaleStates {
        CLOSED,
        ALLOWLIST,
        AUCTION
    }

    uint256 public constant MAX_SUPPLY = 69;
    uint256 public constant ALLOWLIST_SUPPLY = 59;
    uint256 public constant ALLOWLIST_PRICE = 0.169 ether;
    address public constant ROYALTY_RECEIVER = 0x4B9C62fa49e4D1c760c207d5Ffa0C800C499cE46;

    // Auction Parameters
    uint256 public constant DA_START_PRICE = 4.2069 ether;
    uint256 public constant DA_END_PRICE = 0.169 ether;
    uint256 public constant DA_STEP = 69 seconds;
    uint256 public constant DA_DECAY_PER_STEP = 0.042 ether;
    uint256 public auctionStart;

    SaleStates public saleState;
    bool public operatorFilteringEnabled = true;
    string public baseTokenURI = "";
    string public unrevealedURI = "";
    uint256 public metadataOffset;

    constructor() ERC721A("Pingers", "PINGERS") {
        _registerForOperatorFiltering();

        // Set initial 6.9% royalty
        _setDefaultRoyalty(ROYALTY_RECEIVER, 690);
    }

    function allowlistMint() external payable {
        if (saleState != SaleStates.ALLOWLIST) revert InvalidSaleState();

        uint64 numAllowlists = _getAux(msg.sender);
        if (numAllowlists == 0) revert NotOnAllowlist();
        if (_totalMinted() + numAllowlists > ALLOWLIST_SUPPLY) {
            revert AllowlistSupplyReached();
        }
        if (msg.value < ALLOWLIST_PRICE * numAllowlists) revert InsufficientPrice();

        _setAux(msg.sender, 0);
        _mint(msg.sender, numAllowlists);
    }

    function allowlistCount(address user) external view returns (uint8) {
        return uint8(_getAux(user));
    }

    // =========================================================================
    //                            Auction Functions
    // =========================================================================

    function getAuctionPrice() public view returns (uint256) {
        if (auctionStart == 0) return DA_START_PRICE;
        uint256 elapsed = block.timestamp - auctionStart;
        uint256 steps = elapsed / DA_STEP;
        uint256 decay = steps * DA_DECAY_PER_STEP;
        unchecked {
            if (decay > DA_START_PRICE - DA_END_PRICE) {
                return DA_END_PRICE;
            }
            return DA_START_PRICE - decay;
        }
    }

    function auctionMint() external payable {
        if (saleState != SaleStates.AUCTION) revert InvalidSaleState();
        unchecked {
            if (_totalMinted() + 1 > MAX_SUPPLY) revert MaxSupplyReached();
        }

        uint256 currentPrice = getAuctionPrice();
        if (msg.value < currentPrice) revert InsufficientPrice();

        _mint(msg.sender, 1);

        // Refund if over
        unchecked {
            uint256 difference = msg.value - currentPrice;
            if (difference > 0) {
                _transferETH(msg.sender, difference);
            }
        }
    }

    // =========================================================================
    //                           Owner Only Functions
    // =========================================================================

    function setSaleState(uint8 newSaleState) external onlyOwner {
        if (newSaleState <= uint8(saleState)) {
            revert DescendingSaleState();
        }
        saleState = SaleStates(newSaleState);
        if (saleState == SaleStates.AUCTION) {
            auctionStart = block.timestamp;
            emit AuctionStarted(block.timestamp);
        }
    }

    function setAllowlist(address[] calldata addresses, uint8[] calldata amounts) external onlyOwner {
        if (addresses.length != amounts.length) {
            revert InvalidAllowlist();
        }
        for (uint256 i; i < addresses.length;) {
            _setAux(addresses[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external onlyOwner {
        bool success = _transferETH(msg.sender, address(this).balance);
        if (!success) {
            revert WithdrawFailed();
        }
    }

    // =========================================================================
    //                            Internal Functions
    // =========================================================================

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success,) = to.call{value: value, gas: 30000}(new bytes(0));
        return success;
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    function setUnrevealedURI(string calldata uri) external onlyOwner {
        unrevealedURI = uri;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // Add one because the tokenIds start at 1
        uint256 offsetTokenId = ((tokenId + metadataOffset) % MAX_SUPPLY) + 1;
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 && metadataOffset != 0
            ? string(abi.encodePacked(baseURI, _toString(offsetTokenId), ".json"))
            : unrevealedURI;
    }

    function setMetadataOffset() external {
        // Only allow offset to be set once metadata url is in place
        if (bytes(_baseURI()).length == 0) revert CantSetOffset();
        if (metadataOffset != 0) revert OffsetAlreadySet();
        metadataOffset = uint256(
            keccak256(
                abi.encode(
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender,
                    tx.gasprice
                )
            )
        ) + 1;
    }
}