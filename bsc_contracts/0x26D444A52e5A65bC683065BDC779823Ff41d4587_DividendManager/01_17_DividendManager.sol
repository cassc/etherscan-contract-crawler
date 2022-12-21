// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IDividendManager.sol";
import "../interfaces/IInvestNFT.sol";
import "../lib/SafeMath.sol";
import "../AssetHandler.sol";


contract DividendManager is IDividendManager, AssetHandler, AccessControl {

    using SafeMath for uint256;
    using SafeMath for int256;

    bytes32 public constant DEPOSITARY_ROLE = keccak256("DEPOSITARY_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 constant internal MAGNITUDE = 2**128;

    mapping(Assets.Key => uint256) internal magnifiedDividendPerShare;
    mapping(Assets.Key => mapping(AccountId => int256)) internal magnifiedDividendCorrections;
    mapping(Assets.Key => mapping(AccountId => uint256)) internal magnifiedDividendPerShareForExcludedAccounts;
    mapping(Assets.Key => mapping(AccountId => uint256)) internal withdrawnDividends;
    mapping(AccountId => bool) internal excludedFromDividends;
    uint256 internal excludedSupply;
    IInvestNFT public depositary;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setDepositary(address newDepositary) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEPOSITARY_ROLE, address(depositary));
        grantRole(DEPOSITARY_ROLE, newDepositary);
        depositary = IInvestNFT(newDepositary);
    }

    function setAsset(Assets.Key key, string memory assetTicker, Assets.AssetType assetType) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return _setAsset(key, assetTicker, assetType);
    }

    function removeAsset(Assets.Key key) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return _removeAsset(key);
    }

    function withdrawDividend(AccountId account) override public {
        for (uint256 i = 0; i < assetsLength(); i++) {
            (Assets.Key assetKey, ) = getAssetAt(i);
            withdrawDividend(account, assetKey);
        }
    }

    function withdrawableDividendOf(AccountId account) override public view returns(Dividend[] memory) {
        uint256 length = assetsLength();
        Dividend[] memory dividends = new Dividend[](length);
        for (uint256 i = 0; i < length; i++) {
            (Assets.Key assetKey, Assets.Asset memory asset) = getAssetAt(i);
            dividends[i] = Dividend(assetKey, asset.assetTicker, withdrawableDividendOf(account, assetKey));
        }
        return dividends;
    }

    function withdrawnDividendOf(AccountId account) override public view returns(Dividend[] memory) {
        uint256 length = assetsLength();
        Dividend[] memory dividends = new Dividend[](length);
        for (uint256 i = 0; i < length; i++) {
            (Assets.Key assetKey, Assets.Asset memory asset) = getAssetAt(i);
            dividends[i] = Dividend(assetKey, asset.assetTicker, withdrawnDividendOf(account, assetKey));
        }
        return dividends;
    }

    function accumulativeDividendOf(AccountId account) override public view returns(Dividend[] memory) {
        uint256 length = assetsLength();
        Dividend[] memory dividends = new Dividend[](length);
        for (uint256 i = 0; i < length; i++) {
            (Assets.Key assetKey, Assets.Asset memory asset) = getAssetAt(i);
            dividends[i] = Dividend(assetKey, asset.assetTicker, accumulativeDividendOf(account, assetKey));
        }
        return dividends;
    }

    function distributeDividends(uint256 amount, Assets.Key assetKey) public {
        uint256 correctedSupply = depositary.issuedShares() - excludedSupply;
        require(correctedSupply > 0, "DividendManager: the number of shares that receive dividends must be greater than 0");
        require(amount > 0, "DividendManager: amount must be greater than 0");
        _transferAssetFrom(msg.sender, address(this), amount, assetKey);
        magnifiedDividendPerShare[assetKey] = magnifiedDividendPerShare[assetKey] + (amount * MAGNITUDE / correctedSupply);
        emit DividendsDistributed(msg.sender, amount, assetKey);
    }

    function includeInDividends(AccountId account) external onlyRole(DEPOSITARY_ROLE) {
        require(excludedFromDividends[account], "DivManager: the specified account is not excluded from dividends");
        excludedFromDividends[account] = false;
        uint256 amount = depositary.shareOf(AccountId.unwrap(account));
        for (uint256 i = 0; i < assetsLength(); i++) {
            (Assets.Key assetKey, ) = getAssetAt(i);
            uint256 delta = magnifiedDividendPerShare[assetKey] - magnifiedDividendPerShareForExcludedAccounts[assetKey][account];
            magnifiedDividendCorrections[assetKey][account] = magnifiedDividendCorrections[assetKey][account] + (delta * amount).toInt256Safe();
            delete magnifiedDividendPerShareForExcludedAccounts[assetKey][account];
        }
        excludedSupply -= amount;
    }

    function excludeFromDividends(AccountId account) external onlyRole(DEPOSITARY_ROLE) {
        require(!excludedFromDividends[account], "DivManager: the specified account is already excluded from dividends");
        excludedFromDividends[account] = true;
        for (uint256 i = 0; i < assetsLength(); i++) {
            (Assets.Key assetKey, ) = getAssetAt(i);
            magnifiedDividendPerShareForExcludedAccounts[assetKey][account] = magnifiedDividendPerShare[assetKey];
        }
        excludedSupply += depositary.shareOf(AccountId.unwrap(account));
    }

    function handleMint(AccountId account) external onlyRole(DEPOSITARY_ROLE) {
        for (uint256 i = 0; i < assetsLength(); i++) {
            (Assets.Key assetKey, ) = getAssetAt(i);
            magnifiedDividendCorrections[assetKey][account] = magnifiedDividendCorrections[assetKey][account] - (magnifiedDividendPerShare[assetKey] * depositary.shareOf(AccountId.unwrap(account))).toInt256Safe();
        }
    }

    function handleBurn(AccountId account) external onlyRole(DEPOSITARY_ROLE) {
        withdrawDividend(account);
        for (uint256 i = 0; i < assetsLength(); i++) {
            (Assets.Key assetKey, ) = getAssetAt(i);
            magnifiedDividendCorrections[assetKey][account] = magnifiedDividendCorrections[assetKey][account] + (magnifiedDividendPerShare[assetKey] * depositary.shareOf(AccountId.unwrap(account))).toInt256Safe();
        }
    }

    function withdrawDividend(AccountId account, Assets.Key assetKey) public {
        uint256 _withdrawableDividend = withdrawableDividendOf(account, assetKey);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[assetKey][account] = withdrawnDividends[assetKey][account] + _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend, assetKey);
            _transferAsset(depositary.ownerOf(AccountId.unwrap(account)), _withdrawableDividend, assetKey);
        }
    }

    function withdrawableDividendOf(AccountId _owner, Assets.Key assetKey) public view returns(uint256) {
        return accumulativeDividendOf(_owner, assetKey) - withdrawnDividends[assetKey][_owner];
    }

    function withdrawnDividendOf(AccountId _owner, Assets.Key assetKey) public view returns(uint256) {
        return withdrawnDividends[assetKey][_owner];
    }

    function accumulativeDividendOf(AccountId account, Assets.Key assetKey) public view returns(uint256) {
        uint256 dividendPerShare = excludedFromDividends[account] ? magnifiedDividendPerShareForExcludedAccounts[assetKey][account] : magnifiedDividendPerShare[assetKey];
        return ((dividendPerShare * depositary.shareOf(AccountId.unwrap(account))).toInt256Safe() + magnifiedDividendCorrections[assetKey][account]).toUint256Safe() / MAGNITUDE;
    }

}