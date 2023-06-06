/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMarketplace.sol";
import "./WithTreasury.sol";

contract Marketplace is IMarketplace, WithTreasury, ERC1155Holder, AccessControl, ReentrancyGuard {
    bytes32 public constant SELLABLE_ROLE = keccak256("SELLABLE_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    /// @dev seller => Sales
    mapping(address => Sale[]) private _sales;

    constructor(address payable modaTreasury_, uint256 treasuryFee_) WithTreasury(modaTreasury_, treasuryFee_) {
        require(treasuryFee_ > 0, "Treasury fee cannot be 0");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SELLER_ROLE, msg.sender);
    }

    function createSale(
        address tokenHolder,
        address payable beneficiary,
        address token,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 pricePerToken,
        uint256 startAt,
        uint256 endAt,
        uint256 maxCountPerWallet
    ) external override onlyRole(SELLER_ROLE) {
        require(hasRole(SELLABLE_ROLE, token), "Unsupported token");
        require(address(0) != beneficiary, "Beneficiary cannot be 0x0");
        require(tokenAmount > 0, "Token amount cannot be 0");
        require(startAt < endAt, "Start must be before end");
        require(startAt >= block.timestamp, "Must start in the future");
        require(maxCountPerWallet > 0, "Max wallet count must be gt 0");

        IERC1155(token).safeTransferFrom(tokenHolder, address(this), tokenId, tokenAmount, "");

        _sales[msg.sender].push(
            Sale({
                tokenHolder: tokenHolder,
                beneficiary: beneficiary,
                token: token,
                tokenId: tokenId,
                tokenAmount: tokenAmount,
                pricePerToken: pricePerToken,
                startAt: startAt,
                endAt: endAt,
                maxCountPerWallet: maxCountPerWallet
            })
        );

        emit SaleCreated(msg.sender, _sales[msg.sender].length - 1);
    }

    function purchase(
        address seller,
        uint256 saleId,
        uint256 tokenAmount
    ) external payable override nonReentrant {
        require(tokenAmount > 0, "Cannot mint 0 tokens");
        Sale storage sale = _sales[seller][saleId];
        require(tokenAmount <= sale.tokenAmount, "Insufficient supply");

        if (seller == _msgSender()) {
            sale.tokenAmount -= tokenAmount;
            IERC1155(sale.token).safeTransferFrom(address(this), _msgSender(), sale.tokenId, tokenAmount, "");
            emit Purchase(sale.token, sale.tokenId, _msgSender(), seller, saleId, tokenAmount, block.timestamp);
            return;
        }

        require(sale.startAt <= block.timestamp, "Sale has not started yet");
        require(sale.endAt > block.timestamp, "Sale has ended");
        require(msg.value == sale.pricePerToken * tokenAmount, "Wrong payment amount");

        require(
            (IERC1155(sale.token).balanceOf(msg.sender, sale.tokenId) + tokenAmount) <= sale.maxCountPerWallet,
            "Cannot exceed max count per wallet"
        );

        uint256 totalPrice = sale.pricePerToken * tokenAmount;
        uint256 fee = (treasuryFee * totalPrice) / 10_000;
        modaTreasury.transfer(fee);
        sale.beneficiary.transfer(totalPrice - fee);

        sale.tokenAmount -= tokenAmount;

        IERC1155(sale.token).safeTransferFrom(address(this), _msgSender(), sale.tokenId, tokenAmount, "");

        emit Purchase(sale.token, sale.tokenId, _msgSender(), seller, saleId, tokenAmount, block.timestamp);
    }

    function saleAt(address seller, uint256 index) external view override returns (Sale memory) {
        return _sales[seller][index];
    }

    function saleCount(address seller) external view override returns (uint256) {
        return _sales[seller].length;
    }

    function setTreasuryFee(uint256 newFee_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTreasuryFee(newFee_);
    }

    function setTreasury(address payable newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTreasury(newTreasury);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}