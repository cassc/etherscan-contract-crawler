// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract TokenSale is Ownable {
    event SaleStatusChange(uint256 indexed saleId, bool enabled);

    using BitMaps for BitMaps.BitMap;

    uint256 constant PUBLIC_SALE = 0;

    struct SaleConfig {
        bool enabled;
        uint8 maxPerTransaction;
        uint64 unitPrice;
        address signerAddress;
    }

    mapping(uint256 => SaleConfig) private _saleConfig;
    mapping(uint256 => BitMaps.BitMap) private _allowlist;

    modifier canMint(
        uint256 saleId,
        address to,
        uint256 amount
    ) {
        _guardMint(to, amount);

        unchecked {
            SaleConfig memory saleConfig = _saleConfig[saleId];
            require(saleConfig.enabled, "Sale not enabled");
            require(amount <= saleConfig.maxPerTransaction, "Exceeds max per transaction");
            require(amount * saleConfig.unitPrice == msg.value, "Invalid funds provided");
        }

        _;
    }

    function allowlistMint(
        uint256 saleId,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external payable virtual canMint(saleId, _msgSender(), amount) {
        require(_validateSignature(saleId, nonce, signature), "Invalid signature");
        require(_allowlist[saleId].get(nonce), "Nonce already used");

        _allowlist[saleId].unset(nonce);

        _mintTokens(_msgSender(), amount);
    }

    function publicMint(uint256 amount) external payable virtual canMint(PUBLIC_SALE, _msgSender(), amount) {
        _mintTokens(_msgSender(), amount);
    }

    function devMint(uint256 amount) external virtual onlyOwner {
        _guardMint(_msgSender(), amount);

        _mintTokens(_msgSender(), amount);
    }

    function getPublicSaleConfig() external view returns (SaleConfig memory) {
        return _saleConfig[PUBLIC_SALE];
    }

    function getSaleConfig(uint256 saleId) external view returns (SaleConfig memory) {
        return _saleConfig[saleId];
    }

    function setPublicSaleConfig(uint256 maxPerTransaction, uint256 unitPrice) external onlyOwner {
        _saleConfig[PUBLIC_SALE].maxPerTransaction = uint8(maxPerTransaction);
        _saleConfig[PUBLIC_SALE].unitPrice = uint64(unitPrice);
    }

    function setSaleConfig(
        uint256 saleId,
        uint256 maxPerTransaction,
        uint256 unitPrice,
        address signerAddress
    ) external onlyOwner {
        _saleConfig[saleId].maxPerTransaction = uint8(maxPerTransaction);
        _saleConfig[saleId].unitPrice = uint64(unitPrice);
        _saleConfig[saleId].signerAddress = signerAddress;
    }

    function setPublicSaleStatus(bool enabled) external onlyOwner {
        if (_saleConfig[PUBLIC_SALE].enabled != enabled) {
            _saleConfig[PUBLIC_SALE].enabled = enabled;
            emit SaleStatusChange(PUBLIC_SALE, enabled);
        }
    }

    function setSaleStatus(uint256 saleId, bool enabled) external onlyOwner {
        if (_saleConfig[saleId].enabled != enabled) {
            _saleConfig[saleId].enabled = enabled;
            emit SaleStatusChange(saleId, enabled);
        }
    }

    function initAllowlist(uint256 saleId, uint256 size) external onlyOwner {
        BitMaps.BitMap storage allowlist = _allowlist[saleId];

        uint256 buckets = size / 256 + 1;
        for (uint256 i; i < buckets; ++i) {
            allowlist._data[i] = ~uint256(0); // set every bit to 1
        }
    }

    function getAllowlistNonceStatus(uint256 saleId, uint256 nonce) external view returns (bool) {
        BitMaps.BitMap storage allowlist = _allowlist[saleId];
        return allowlist.get(nonce);
    }

    function setAllowlistNonceStatus(
        uint256 saleId,
        uint256 nonce,
        bool value
    ) external onlyOwner {
        BitMaps.BitMap storage allowlist = _allowlist[saleId];
        allowlist.setTo(nonce, value);
    }

    function _validateSignature(
        uint256 saleId,
        uint256 nonce,
        bytes calldata signature
    ) internal view virtual returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(saleId, nonce, _msgSender()));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        return SignatureChecker.isValidSignatureNow(_saleConfig[saleId].signerAddress, message, signature);
    }

    function _guardMint(address to, uint256 quantity) internal view virtual {}

    function _mintTokens(address to, uint256 quantity) internal virtual;
}