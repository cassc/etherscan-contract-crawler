// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ========================== sFraxAsset.sol ========================
// ====================================================================

/**
 * @title sFraxAsset Asset
 * @dev Representation of an on-chain investment
 */
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { Stabilizer, IPriceFeed, IAMM, ChainlinkLibrary, OvnMath, TransferHelper } from "../Stabilizer/Stabilizer.sol";

contract SFraxAsset is Stabilizer {
    
    IERC20Metadata private immutable token;
    IPriceFeed private immutable oracleToken;
    uint24 private immutable poolFee;

    // Variables
    IERC4626 public immutable asset;

    // Events
    event Invested(uint256 indexed tokenAmount);
    event Divested(uint256 indexed usdxAmount);

    constructor(
        string memory _name,
        address _sweep,
        address _usdx,
        address _token,
        address _asset,
        address _oracleUsdx,
        address _oracleToken,
        uint24 _poolFee,
        address _borrower
    ) Stabilizer(_name, _sweep, _usdx, _oracleUsdx, _borrower) {
        asset = IERC4626(_asset);
        token = IERC20Metadata(_token);
        oracleToken = IPriceFeed(_oracleToken);
        poolFee = _poolFee;
    }

    /* ========== Views ========== */

    /**
     * @notice Current Value of investment.
     * @return total with 6 decimal to be compatible with dollar coins.
     */
    function currentValue() public view override returns (uint256) {
        uint256 accruedFeeInUSD = sweep.convertToUSD(accruedFee());
        uint256 assetValueInUSD = super._oracleUsdxToUsd(assetValue());
        return assetValueInUSD + super.currentValue() - accruedFeeInUSD;
    }

    /**
     * @notice Asset Value of investment.
     * @return the Returns the value of the investment in the USD coin
     * @dev the price is obtained from the target asset
     */
    function assetValue() public view virtual returns (uint256) {
        uint256 sharesBalance = asset.balanceOf(address(this));
        // All numbers given are in USDX unless otherwise stated
        return asset.convertToAssets(sharesBalance);
    }

    /* ========== Actions ========== */

    /**
     * @notice Invest.
     * @param usdxAmount Amount to be invested
     * @dev Sends usdx to the target asset to get shares.
     */
    function invest(uint256 usdxAmount, uint256 slippage)
        external
        onlyBorrower
        whenNotPaused
        nonReentrant
        validAmount(usdxAmount)
    {
        _invest(usdxAmount, 0, slippage);
    }

    /**
     * @notice Divest.
     * @param usdxAmount Amount to be divested.
     * @dev Gets usdx back by redeeming shares.
     */
    function divest(uint256 usdxAmount, uint256 slippage)
        external
        onlyBorrower
        nonReentrant
        validAmount(usdxAmount)
        returns (uint256)
    {
        return _divest(usdxAmount, slippage);
    }

    /**
     * @notice Liquidate
     */
    function liquidate() external nonReentrant {
        if(auctionAllowed) revert ActionNotAllowed();
        _liquidate(address(asset), getDebt());
    }

    function _invest(uint256 usdxAmount, uint256, uint256 slippage) internal virtual override {    
        uint256 usdxBalance = usdx.balanceOf(address(this));
        if (usdxBalance == 0) revert NotEnoughBalance();
        if (usdxBalance < usdxAmount) usdxAmount = usdxBalance;

        IAMM _amm = amm();
        uint256 usdxInToken = _oracleUsdxToToken(usdxAmount);
        TransferHelper.safeApprove(address(usdx), address(_amm), usdxAmount);
        uint256 tokenAmount = _amm.swapExactInput(
            address(usdx),
            address(token),
            poolFee,
            usdxAmount,
            OvnMath.subBasisPoints(usdxInToken, slippage)
        );

        TransferHelper.safeApprove(address(token), address(asset), tokenAmount);
        asset.deposit(tokenAmount, address(this));

        emit Invested(usdxAmount);
    }

    function _divest(uint256 usdxAmount, uint256 slippage) internal virtual override returns (uint256 divestedAmount) {        
        uint256 sharesBalance = asset.balanceOf(address(this));
        if (sharesBalance == 0) revert NotEnoughBalance();

        uint256 sharesAmount = asset.convertToShares(usdxAmount);
        if (sharesBalance > sharesAmount) sharesAmount = sharesBalance;

        usdxAmount = asset.convertToAssets(sharesAmount);
        uint256 tokenAmount = asset.withdraw(usdxAmount, address(this), address(this));

        IAMM _amm = amm();
        uint256 tokenInUsdx = _oracleTokenToUsdx(tokenAmount);
        TransferHelper.safeApprove(address(token), address(_amm), tokenAmount);
        divestedAmount = _amm.swapExactInput(
            address(token),
            address(usdx),
            poolFee,
            tokenAmount,
            OvnMath.subBasisPoints(tokenInUsdx, slippage)
        );

        emit Divested(divestedAmount);
    }

    function _getToken() internal view override returns (address) {
        return address(asset);
    }

    function _oracleTokenToUsdx(
        uint256 tokenAmount
    ) internal view returns (uint256) {
        return
            ChainlinkLibrary.convertTokenToToken(
                tokenAmount,
                token.decimals(),
                usdx.decimals(),
                oracleToken,
                oracleUsdx
            );
    }

    function _oracleUsdxToToken(
        uint256 usdxAmount
    ) internal view returns (uint256) {
        return
            ChainlinkLibrary.convertTokenToToken(
                usdxAmount,
                usdx.decimals(),
                token.decimals(),
                oracleUsdx,
                oracleToken
            );
    }

}