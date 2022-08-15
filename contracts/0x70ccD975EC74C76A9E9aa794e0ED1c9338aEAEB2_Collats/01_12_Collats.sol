// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./interface/ICollats.sol";
import "./interface/ICollatsMinter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//TODO: Exchange Rate Logic
/// @custom:security-contact [email protected]
contract Collats is
    Initializable,
    ICollats,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    BackupAsset public redeemBackupAsset;
    BackupAsset[] public backupAssets;
    ICollatsMinter public minter;
    Rate public fee;

    function initialize(
        uint256 _feeNumerator,
        uint256 _feeDenominator,
        address _backupAsset,
        uint256 _backupAssetDecimals,
        address[] memory _assets,
        uint256[] memory _decimals,
        address _minter
    ) external initializer {
        fee = Rate(_feeNumerator, _feeDenominator);
        __ERC20_init("Collats", "Collats");
        __Ownable_init();
        setRedeemAsset(_backupAsset, 1, 1, _backupAssetDecimals, true);
        for (uint256 i = 0; i < _assets.length; i++) {
            setBackupAsset(_assets[i], 1, 1, _decimals[i], true);
        }
        setMinter(_minter);
    }

    function buyCollats()
        public
        payable
        whenNotPaused
        returns (uint256 collatsBought)
    {
        uint256 amountBackUpAsset = minter.swapEthForBackUpAsset{
            value: msg.value
        }(address(this));

        return _mintCollats(amountBackUpAsset, minter.backUpAssetDecimals());
    }

    function buyCollatsWithERC20(address token, uint256 amount)
        public
        whenNotPaused
        returns (uint256 collatsBought)
    {
        require(amount > 0, "Collats: Please specify an amount");

        IERC20Upgradeable(token).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );

        uint256 amountBackUpAsset;
        uint256 backUpAssetDecimals;

        BackupAsset memory backUpAsset = getBackupAsset(token);

        if (backUpAsset.isAllowed) {
            amountBackUpAsset = amount;
            backUpAssetDecimals = backUpAsset.decimals;
        } else {
            IERC20Upgradeable(token).safeApprove(address(minter), amount);

            amountBackUpAsset = minter.swapTokenForBackUpAsset(
                address(this),
                token,
                amount
            );
            backUpAssetDecimals = minter.backUpAssetDecimals();
        }
        return _mintCollats(amountBackUpAsset, backUpAssetDecimals);
    }

    function redeem(uint256 amountInWei)
        public
        whenNotPaused
        returns (
            uint256 assetAmount,
            uint256 decimals,
            address asset
        )
    {
        require(
            amountInWei >= 1 ether,
            "Collats: Amount needs to be at least 1 Collat"
        );
        require(
            balanceOf(_msgSender()) >= amountInWei,
            "Collats: Not enough balance"
        );

        uint256 amount = _collatsToToken(
            amountInWei,
            redeemBackupAsset.decimals
        );

        _burn(_msgSender(), amountInWei);

        redeemBackupAsset.asset.safeTransfer(_msgSender(), amount);

        emit CollatsRedeemed(
            _msgSender(),
            amount,
            redeemBackupAsset.decimals,
            address(redeemBackupAsset.asset)
        );

        return (
            amount,
            redeemBackupAsset.decimals,
            address(redeemBackupAsset.asset)
        );
    }

    function redeemWithERC20(address token, uint256 amountInWei)
        public
        whenNotPaused
        returns (
            uint256 assetAmount,
            uint256 decimals,
            address asset
        )
    {
        BackupAsset memory backUpAsset = getBackupAsset(token);

        require(backUpAsset.isAllowed, "Collats: Asset is not supported");
        require(
            amountInWei >= 1 ether,
            "Collats: Amount needs to be at least 1 Collat in wei"
        );
        require(
            balanceOf(_msgSender()) >= amountInWei,
            "Collats: Not enough balance"
        );

        uint256 amount = _collatsToToken(amountInWei, backUpAsset.decimals);

        _burn(_msgSender(), amountInWei);

        IERC20Upgradeable(token).safeTransfer(_msgSender(), amount);

        emit CollatsRedeemed(_msgSender(), amount, backUpAsset.decimals, token);

        return (amount, backUpAsset.decimals, token);
    }

    function _mintCollats(
        uint256 amountBackUpAsset,
        uint256 backUpAssetDecimals
    ) private returns (uint256 collatsBought) {
        require(amountBackUpAsset > 0, "Collats: Not enough liquidity");

        uint256 collatsToMint = _tokenToCollats(
            amountBackUpAsset,
            backUpAssetDecimals
        );

        collatsBought =
            (collatsToMint * (fee.denominator - fee.numerator)) /
            fee.denominator;
        _mint(_msgSender(), collatsBought);

        uint256 feeAmount = (collatsToMint - collatsBought);
        _mint(owner(), feeAmount);

        emit CollatsMinted(
            _msgSender(),
            collatsToMint,
            collatsBought,
            feeAmount
        );
    }

    function _tokenToCollats(uint256 _amount, uint256 _decimals)
        private
        pure
        returns (uint256)
    {
        return _amount * decimalFactor(_decimals);
    }

    function _collatsToToken(uint256 _amount, uint256 _decimals)
        private
        pure
        returns (uint256)
    {
        return _amount / decimalFactor(_decimals);
    }

    function decimalFactor(uint256 _decimals) public pure returns (uint256) {
        return 10**(18 - _decimals);
    }

    function setFee(uint256 _numerator, uint256 _denominator) public onlyOwner {
        fee = Rate(_numerator, _denominator);
        emit FeeChanged(_numerator, _denominator);
    }

    function setRedeemAsset(
        address _assetAddress,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _decimals,
        bool _isAllowed
    ) public onlyOwner {
        redeemBackupAsset = BackupAsset(
            IERC20Upgradeable(_assetAddress),
            Rate(_numerator, _denominator),
            _decimals,
            _isAllowed
        );
        emit RedeemBackUpAssetChanged(redeemBackupAsset);
    }

    function setBackupAsset(
        address _assetAddress,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _decimals,
        bool _isAllowed
    ) public onlyOwner {
        BackupAsset memory backUpAsset = BackupAsset(
            IERC20Upgradeable(_assetAddress),
            Rate(_numerator, _denominator),
            _decimals,
            _isAllowed
        );

        for (uint256 i; i < backupAssets.length; i++) {
            if (address(backupAssets[i].asset) == _assetAddress) {
                backupAssets[i] = backUpAsset;
                emit BackupAssetModified(backUpAsset);
                return;
            }
        }
        backupAssets.push(backUpAsset);
        emit BackupAssetAdded(backUpAsset);
    }

    function getBackupAssets() public view returns (BackupAsset[] memory) {
        return backupAssets;
    }

    function getBackupAsset(address token)
        public
        view
        returns (BackupAsset memory)
    {
        for (uint256 i; i < backupAssets.length; i++) {
            if (address(backupAssets[i].asset) == token) {
                return backupAssets[i];
            }
        }
        return BackupAsset(IERC20Upgradeable(address(0)), Rate(0, 0), 0, false);
    }

    function setMinter(address _minter) public onlyOwner {
        minter = ICollatsMinter(_minter);
        emit MinterChanged(_minter);
    }

    function getAmountIn(address from, uint256 amountOut)
        public
        view
        returns (uint256 amountIn)
    {
        uint256 amount = (amountOut * fee.denominator) /
            (fee.denominator - fee.numerator);

        BackupAsset memory backUpAsset = getBackupAsset(from);

        amountIn = backUpAsset.isAllowed
            ? _collatsToToken(amount, backUpAsset.decimals)
            : minter.getAmountIn(
                from,
                _collatsToToken(amount, minter.backUpAssetDecimals())
            );
    }

    function getAmountOut(address from, uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 amount;
        BackupAsset memory backUpAsset = getBackupAsset(from);
        backUpAsset.isAllowed
            ? amount = _tokenToCollats(amountIn, backUpAsset.decimals)
            : amount = _tokenToCollats(
            minter.getAmountOut(from, amountIn),
            minter.backUpAssetDecimals()
        );

        amountOut =
            (amount * (fee.denominator - fee.numerator)) /
            fee.denominator;
    }

    function getVersion() public pure returns (uint256) {
        return 0;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}