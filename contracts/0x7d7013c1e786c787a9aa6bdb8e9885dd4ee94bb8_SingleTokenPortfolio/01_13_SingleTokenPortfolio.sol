//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import { Registry } from "../Registry.sol";
import { Entity } from "../Entity.sol";
import { Portfolio } from "../Portfolio.sol";
import { ISwapWrapper } from "../interfaces/ISwapWrapper.sol";
import { Auth, Authority } from "../lib/auth/Auth.sol";
import { Math } from "../lib/Math.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

contract SingleTokenPortfolio is Portfolio {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    ERC20 public immutable baseToken;

    /**
     * @param _registry Endaoment registry.
     * @param _asset Underlying ERC20 asset token for portfolio.
     * @param _shareTokenName Name of ERC20 portfolio share token.
     * @param _shareTokenSymbol Symbol of ERC20 portfolio share token.
     * @param _cap Amount of baseToken that this portfolio's asset balance should not exceed.
     * @param _redemptionFee Percentage fee as ZOC that should go to treasury on redemption. (100 = 1%).
     */
    constructor(
        Registry _registry,
        address _asset,
        string memory _shareTokenName,
        string memory _shareTokenSymbol,
        uint256 _cap,
        uint256 _depositFee,
        uint256 _redemptionFee
    ) Portfolio(_registry, _asset, _shareTokenName, _shareTokenSymbol, _cap, _depositFee, _redemptionFee) {
        baseToken = _registry.baseToken();
    }

    /**
     * @notice Takes some amount of assets from this portfolio as assets under management fee.
     * @dev Importantly, updates exchange rate to change the shares/assets calculations.
     * @param _amountAssets Amount of assets to take.
     */
    function takeFees(uint256 _amountAssets) external override requiresAuth {
        ERC20(asset).safeTransfer(registry.treasury(), _amountAssets);
        emit FeesTaken(_amountAssets);
    }

    function totalAssets() public view override returns (uint256) {
        return ERC20(asset).balanceOf(address(this));
    }

    /**
     * @inheritdoc Portfolio
     * @dev Rounding down favors the portfolio, so the user gets slightly less and the portfolio gets slightly more, that way it prevents
     * a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number due to rounding error.
     */
    function convertToShares(uint256 _assets) public view override returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _assets : _assets.mulDivDown(_supply, totalAssets());
    }

    /**
     * @notice This method is needed on deposit because we already possess the assets that we want to convert.
     * @dev Rounding down favors the portfolio, so the user gets slightly less and the portfolio gets slightly more, that way it prevents
     * a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number due to rounding error.
     */
    function _convertToSharesLessAssets(uint256 _assets) private view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _assets : _assets.mulDivDown(totalSupply, totalAssets() - _assets);
    }

    /**
     * @inheritdoc Portfolio
     * @dev Rounding down in both of these favors the portfolio, so the user gets slightly less and the portfolio gets slightly more,
     * that way it prevents a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number
     * due to rounding error.
     */
    function convertToAssets(uint256 _shares) public view override returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), _supply);
    }

    /**
     * @dev Rounding down in both of these favors the portfolio, so the user gets slightly less and the portfolio gets slightly more,
     * that way it prevents a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number
     * due to rounding error.
     */
    function convertToAssetsShutdown(uint256 _shares) public view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _shares : _shares.mulDivDown(baseToken.balanceOf(address(this)), _supply);
    }

    /**
     * @inheritdoc Portfolio
     * @dev We convert `baseToken` to `asset` via a swap wrapper.
     * `_data` should be a packed swap wrapper address concatenated with the bytes payload your swap wrapper expects.
     * i.e. `bytes.concat(abi.encodePacked(address swapWrapper), SWAP_WRAPPER_BYTES)`.
     * To determine if this deposit exceeds the cap, we get the asset/baseToken exchange rate and multiply it by `totalAssets`.
     */ 
    function deposit(uint256 _amountBaseToken, bytes calldata _data) external override returns (uint256) {
        if (didShutdown) revert DepositAfterShutdown();
        if (!_isEntity(Entity(msg.sender))) revert NotEntity();

        ISwapWrapper _swapWrapper = ISwapWrapper(address(bytes20(_data[:20])));
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidSwapper();

        baseToken.safeTransferFrom(msg.sender, address(this), _amountBaseToken);
        (uint256 _amountSwap, uint256 _amountFee) = _calculateFee(_amountBaseToken, depositFee);
        baseToken.safeApprove(address(_swapWrapper), _amountBaseToken);
        uint256 _assets = _swapWrapper.swap(address(baseToken), asset, address(this), _amountSwap, _data[20:]);
        // Convert totalAssets to baseToken unit to measure against cap.
        if (totalAssets() * _amountSwap / _assets > cap) revert ExceedsCap();
        uint256 _shares = _convertToSharesLessAssets(_assets);
        if (_shares == 0) revert RoundsToZero();
        _mint(msg.sender, _shares);
        baseToken.safeTransfer(registry.treasury(), _amountFee);

        emit Deposit(msg.sender, msg.sender, _assets, _shares, _amountBaseToken, _amountFee);
        return _shares;
    }

     /**
     * @inheritdoc Portfolio
     * @dev After converting `shares` to `assets`, we convert `assets` to `baseToken` via a swap wrapper.
     * `_data` should be a packed swap wrapper address concatenated with the bytes payload your swap wrapper expects.
     * i.e. `bytes.concat(abi.encodePacked(address swapWrapper), SWAP_WRAPPER_BYTES)`.
     */ 
    function redeem(uint256 _amountShares, bytes calldata _data) external override returns (uint256) {
        if(didShutdown) return _redeemShutdown(_amountShares);
        ISwapWrapper _swapWrapper = ISwapWrapper(address(bytes20(_data[:20])));
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidSwapper();
        uint256 _assetsOut = convertToAssets(_amountShares);
        _burn(msg.sender, _amountShares);
        ERC20(asset).safeApprove(address(_swapWrapper), 0);
        ERC20(asset).safeApprove(address(_swapWrapper), _assetsOut);
        uint256 _baseTokenOut = _swapWrapper.swap(asset, address(baseToken), address(this), _assetsOut, _data[20:]);
        (uint256 _netAmount, uint256 _fee) = _calculateFee(_baseTokenOut, redemptionFee);
        baseToken.safeTransfer(registry.treasury(), _fee);
        baseToken.safeTransfer(msg.sender, _netAmount);
        emit Redeem(msg.sender, msg.sender, _assetsOut, _amountShares, _netAmount, _fee);
        return _netAmount;
    }

    /**
     * @inheritdoc Portfolio
     */
    function shutdown(bytes calldata _data) external override requiresAuth returns (uint256) {
        if (didShutdown) revert DidShutdown();

        ISwapWrapper _swapWrapper = ISwapWrapper(address(bytes20(_data[:20])));
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidSwapper();
        
        didShutdown = true;
        uint256 _assetsOut = totalAssets();
        ERC20(asset).safeApprove(address(_swapWrapper), 0);
        ERC20(asset).safeApprove(address(_swapWrapper), _assetsOut);
        uint256 _baseTokenOut = _swapWrapper.swap(asset, address(baseToken), address(this), _assetsOut, _data[20:]);
        emit Shutdown(_assetsOut, _baseTokenOut);
        return _baseTokenOut;
    }

    /**
     * @notice Handles redemption after shutdown, exchanging shares for baseToken.
     * @param _amountShares Shares being redeemed.
     * @return Amount of baseToken received. 
     */
    function _redeemShutdown(uint256 _amountShares) private returns (uint256) {
        uint256 _baseTokenOut = convertToAssetsShutdown(_amountShares);
        _burn(msg.sender, _amountShares);
        (uint256 _netAmount, uint256 _fee) = _calculateFee(_baseTokenOut, redemptionFee);
        baseToken.safeTransfer(registry.treasury(), _fee);
        baseToken.safeTransfer(msg.sender, _netAmount);
        emit Redeem(msg.sender, msg.sender, _baseTokenOut, _amountShares, _netAmount, _fee);
        return _netAmount;
    }
}