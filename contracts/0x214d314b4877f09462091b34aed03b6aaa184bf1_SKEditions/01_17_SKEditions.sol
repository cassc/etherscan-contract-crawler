// SPDX-License-Identifier: UNLICENSED
// ****************************************************************************** //
// ****************************************************************************** //
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ //
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ //
// ░░░██████╗██╗░░██╗░░███████╗██████╗░██╗████████╗██╗░█████╗░███╗░░██╗░██████╗░░ //
// ░░██╔════╝██║░██╔╝░░██╔════╝██╔══██╗██║╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝░░ //
// ░░╚█████╗░█████═╝░░░█████╗░░██║░░██║██║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░░░ //
// ░░░╚═══██╗██╔═██╗░░░██╔══╝░░██║░░██║██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗░░ //
// ░░██████╔╝██║░╚██╗░░███████╗██████╔╝██║░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝░░ //
// ░░╚═════╝░╚═╝░░╚═╝░░╚══════╝╚═════╝░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░░░ //
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ //
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ //
// ░░░░░░░░░░░░░░░░░░░ ASTRO EDITIONS & CONTRACT BY SKING.ETH ░░░░░░░░░░░░░░░░░░░ //
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ //
// ****************************************************************************** //
// ****************************************************************************** //

pragma solidity ^0.8.17;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

error InsufficientBalance();
error MaxMintReached();
error MaxSaleReached();
error NoBotsAllowed();
error SaleNotActive();
error TokenNotAvailable();

contract SKEditions is ERC1155, OperatorFilterer, ERC2981, Ownable, CantBeEvil {
    bool public operatorFilteringEnabled = true;
    bool public saleEnabled = false;
    uint256 public constant MAX_MINT = 3;
    uint256 private _currentIndex;
    string private _baseURI;

    struct Token {
        bool active;
        bool created;
        uint16 minted;
        uint16 qty;
        uint64 cost;
    }

    mapping(uint256 => Token) public tokens;

    constructor(string memory baseURI, address deployer) ERC1155(baseURI) CantBeEvil(LicenseVersion.PERSONAL) {
        _baseURI = baseURI;
        transferOwnership(deployer);
        _registerForOperatorFiltering();
        _setDefaultRoyalty(msg.sender, 750);
    }

    function mint(uint256 tokenId, uint16 qty) external payable {
        // Is the sale active
        if (!saleEnabled) revert SaleNotActive();

        // Only allow sender to mint
        if (tx.origin != msg.sender) revert NoBotsAllowed();

        // Get token
        Token storage token = tokens[tokenId];
        bool _active = token.active;

        // No token
        if (!_active) revert TokenNotAvailable();

        uint256 _cost = token.cost;
        uint256 _minted = token.minted;
        uint256 _qty = token.qty;

        // Is there enough supply to mint
        if (_qty > 0 && _minted + qty > _qty) revert MaxSaleReached();

        // Stop wallet minting more than 3 at a time
        // Stop wallet owning more than 3 during mint unless transferred out
        uint256 _owned = balanceOf(msg.sender, tokenId);
        if (_owned + qty > MAX_MINT) revert MaxMintReached();

        // Can sender afford mint
        if (msg.value < qty * _cost) revert InsufficientBalance();

        // Mint
        _mint(msg.sender, tokenId, qty, "");

        // Increase minted qty
        token.minted += qty;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        Token memory token = tokens[_id];
        bool _active = token.active;

        // No token
        if (!_active) revert TokenNotAvailable();

        return string(abi.encodePacked(super.uri(0), Strings.toString(_id)));
    }

    function getRemaining(uint256 tokenId) external view returns (uint16 qty, uint16 minted) {
        Token memory token = tokens[tokenId];
        if (!token.created) revert TokenNotAvailable();
        return (token.qty, token.minted);
    }

    function createToken(bool active, uint16 qty, uint64 cost) external onlyOwner {
        tokens[++_currentIndex] = Token(active, true, 0, qty, cost);
    }

    function toggleToken(uint256 tokenId) external onlyOwner {
        Token storage token = tokens[tokenId];
        if (!token.created) revert TokenNotAvailable();
        token.active = !token.active;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function toggleSale() external onlyOwner {
        saleEnabled = !saleEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (ERC1155, ERC2981, CantBeEvil)
    returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}