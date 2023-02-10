// SPDX-License-Identifier: MIT
/**
        888888b.   d8b 888                                              
        888  "88b  Y8P 888                                              
        888  .88P      888                                              
        8888888K.  888 888888 .d8888b .d88b.  888d888 88888b.  .d8888b  
        888  "Y88b 888 888   d88P"   d88""88b 888P"   888 "88b 88K      
        888    888 888 888   888     888  888 888     888  888 "Y8888b. 
        888   d88P 888 Y88b. Y88b.   Y88..88P 888     888  888      X88 
        8888888P"  888  "Y888 "Y8888P "Y88P"  888     888  888  88888P' 
 */
pragma solidity 0.8.18;

import { IERC721A, ERC721A, ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title It ain't much but it's honest work
 * @author The Bitcorns farmers association
 */
contract Bitcorns is ERC721AQueryable, DefaultOperatorFilterer, Ownable, ReentrancyGuard, ERC2981, Pausable {
    error SwapNotEnabled();
    error WrongPrice(uint256 expexted, uint256 received);
    error MaxSupplyExceeded(uint256 maxSupply);
    error ProvenanceHashAlreadySet(bytes32 provenanceHash);
    error SwapNotAuthorizedFor(uint256 tokenId, address sender);
    error StartingIndexAlreadySet(uint256 startingIndex);
    error StartingIndexBlockNotSet(uint256 startingIndexBlock);
    error StartingIndexBlockAlreadySet(uint256 startingIndexBlock);

    event TokenSwapped(uint256 tokenId, string btcAddress);

    uint256 public constant PRICE = 0.25 ether;
    uint256 public MAX_SUPPLY = 2016;

    string public provenanceHash;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    bool public swapEnabled;
    string public baseURI;
    address payable public payee;

    mapping(uint256 => string) public tokenIdToBTCAddress;

    constructor(string memory baseURI_, address payable payee_) ERC721A("Bitcorns", "Bitcorns") {
        baseURI = baseURI_;
        payee = payee_;
        _setDefaultRoyalty(payee_, 500);
        _safeMint(payee_, 1);
        _pause();
    }

    function mint(uint256 amount) external payable nonReentrant whenNotPaused {
        if (_totalMinted() + amount > MAX_SUPPLY) revert MaxSupplyExceeded(MAX_SUPPLY);
        if (msg.value != PRICE * amount) revert WrongPrice(PRICE * amount, msg.value);
        _safeMint(msg.sender, amount);

        if (startingIndexBlock == 0 && (totalSupply() == MAX_SUPPLY)) {
            startingIndexBlock = block.number;
        }
    }

    function swapForOrdinal(uint256 tokenId, string calldata btcAddress) external payable nonReentrant {
        if (!swapEnabled) revert SwapNotEnabled();
        if (ownerOf(tokenId) != msg.sender) revert SwapNotAuthorizedFor(tokenId, msg.sender);
        tokenIdToBTCAddress[tokenId] = btcAddress;
        _burn(tokenId);
        emit TokenSwapped(tokenId, btcAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSwapStatus(bool swapEnabled_) external onlyOwner {
        swapEnabled = swapEnabled_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setProvenanceHash(string calldata provenanceHash_) external onlyOwner {
        provenanceHash = provenanceHash_;
    }

    function setPayee(address payable payee_) external onlyOwner {
        payee = payee_;
    }

    function withdraw() external whenNotPaused {
        Address.sendValue(payee, address(this).balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner whenNotPaused {
        uint balance = token.balanceOf(address(this));
        SafeERC20.safeTransfer(token, payee, balance);
    }

    function setStartingIndex() external nonReentrant {
        if (startingIndex != 0) revert StartingIndexAlreadySet(startingIndex);
        if (startingIndexBlock == 0) revert StartingIndexBlockNotSet(startingIndexBlock);

        if (block.number - startingIndexBlock > 255) {
            //reset the block
            startingIndexBlock = block.number;
            return;
        }
        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function setStartingIndexBlockIfNotSet() external onlyOwner {
        if (startingIndexBlock != 0) revert StartingIndexBlockAlreadySet(startingIndexBlock);
        startingIndexBlock = block.number;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory result = string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));

        return bytes(baseURI).length != 0 ? result : "";
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721A, IERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}