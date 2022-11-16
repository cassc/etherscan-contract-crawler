//
//  ________  ___       ___      ___
// |\   __  \|\  \     |\  \    /  /|
// \ \  \|\  \ \  \    \ \  \  /  / /
//  \ \   ____\ \  \    \ \  \/  / /
//   \ \  \___|\ \  \____\ \    / /
//    \ \__\    \ \_______\ \__/ /
//     \|__|     \|_______|\|__|/
//
// Paralverse Asamisan collection
//
// by @G2#5600
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../../interfaces/IPLVManager.sol";
import "../../utils/PLVErrors.sol";

contract PLVAsami is ERC721AQueryable, ERC2981, Ownable, Pausable, ReentrancyGuard {
    string public constant NAME = "Asamisan Paralverse";
    string public constant SYMBOL = "ASAMI.PLV";
    uint256 public constant TOTAL_SUPPLY = 3333;

    address public manager;
    string private _baseTokenURI;

    /* ==================== EVENTS ==================== */

    event Mint(address indexed who, uint256 level);

    /* ==================== MODIFIERS ==================== */
    modifier onlyManager() {
        if (_msgSender() != manager) revert InvalidCaller();
        _;
    }

    /* ==================== METHODS ==================== */

    /**
     * @dev contract intializer
     *
     * @param _uri token uri
     */
    constructor(string memory _uri) ERC721A(NAME, SYMBOL) {
        _baseTokenURI = _uri;
        _setDefaultRoyalty(_msgSender(), 750);
    }

    /**
     * @dev mint NFT
     *
     * @param _who Minter address
     * @param _qty Mint quantity
     */
    function mint(address _who, uint256 _qty)
        external
        whenNotPaused
        onlyManager
        nonReentrant
        returns (uint256 nextTokenId)
    {
        if (_totalMinted() >= TOTAL_SUPPLY) revert MaxMintExceed();

        nextTokenId = _nextTokenId();

        _safeMint(_who, _qty);
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev disable the token transfer when it is not in idle
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        (uint256 status, , ) = IPLVManager(manager).statusOf(tokenId);
        if (status == 0) {
            super._beforeTokenTransfers(from, to, tokenId, quantity);
            return;
        }
        revert("Transfer not allowed");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /* ==================== OWNER METHODS ==================== */

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    /**
     * @dev Owner can set the token base uri
     *
     * @param _uri BaseURI
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    /**
     * @dev Owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner can unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner can set royalty receiver and fee
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /* ==================== VIEW METHODS ==================== */

    function supportsInterface(bytes4 interfaceId) public view override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}