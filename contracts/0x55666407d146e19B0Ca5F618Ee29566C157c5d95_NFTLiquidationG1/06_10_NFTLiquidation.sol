// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./NFTLiquidationInterface.sol";
import "./NFTLiquidationStorage.sol";
import "./NFTLiquidationProxy.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IComptroller.sol";
import "./ICToken.sol";
import "./IOracle.sol";

/**
 * @title Drops's NFT Liquidation Proxy Contract
 * @author Drops
 */
contract NFTLiquidationG1 is NFTLiquidationV1Storage, NFTLiquidationInterface {
    using SafeMath for uint256;

    /// @notice Emitted when an admin set comptroller
    event NewComptroller(address oldComptroller, address newComptroller);

    /// @notice Emitted when an admin set the cether address
    event NewCEther(address cEther);

    /// @notice Emitted when an admin set the protocol fee recipient
    event NewProtocolFeeRecipient(address _protocolFeeRecipient);

    /// @notice Emitted when an admin set the protocol fee
    event NewProtocolFeeMantissa(uint256 _protocolFeeMantissa);

    /// @notice Emitted when emergency withdraw the underlying asset
    event EmergencyWithdraw(address to, address underlying, uint256 amount);

    /// @notice Emitted when emergency withdraw the NFT
    event EmergencyWithdrawNFT(address to, address underlying, uint256 tokenId);

    constructor() public {}

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /*** Liquidator functions ***/

    /**
     * @notice Execute the proxy liquidation with single token repay
     */
    function liquidateWithSingleRepay(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount) external payable nonReentrant {
        require(borrower != address(0), "invalid borrower address");

        (, , uint256 borrowerShortfall) = IComptroller(comptroller).getAccountLiquidity(borrower);
        require(borrowerShortfall > 0, "invalid borrower liquidity shortfall");
        liquidateWithSingleRepayFresh(borrower, cTokenCollateral, cTokenRepay, repayAmount);
        transferSeizedTokenFresh(cTokenCollateral, false);
    }

    /**
     * @notice Execute the proxy liquidation with single token repay and selected seize token value
     */
    function liquidateWithSingleRepayV2(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount, uint256[] memory _seizeIndexes, bool claimDToken) external payable nonReentrant {
        require(borrower != address(0), "invalid borrower address");

        (, , uint256 borrowerShortfall) = IComptroller(comptroller).getAccountLiquidity(borrower);
        require(borrowerShortfall > 0, "invalid borrower liquidity shortfall");
        require(seizeIndexes_.length == 0, "invalid initial seize indexes");
        seizeIndexes_ = _seizeIndexes;
        liquidateWithSingleRepayFresh(borrower, cTokenCollateral, cTokenRepay, repayAmount);
        transferSeizedTokenFresh(cTokenCollateral, claimDToken);
    }

    function seizeIndexes() external view returns(uint256[] memory) {
        return seizeIndexes_;
    }

    function liquidateWithSingleRepayFresh(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount) internal {
        require(extraRepayAmount == 0, "invalid initial extra repay amount");

        uint256 borrowedAmount = ICErc20(cTokenRepay).borrowBalanceCurrent(borrower);

        require(repayAmount >= borrowedAmount, "invalid token repay amount");
        extraRepayAmount = repayAmount.sub(borrowedAmount);

        if (cTokenRepay != cEther) {
            address underlying = ICErc20(cTokenRepay).underlying();

            IERC20(underlying).transferFrom(msg.sender, address(this), repayAmount);
            IERC20(underlying).approve(cTokenRepay, borrowedAmount);
            require(ICErc20(cTokenRepay).liquidateBorrow(borrower, borrowedAmount, cTokenCollateral) == 0, "liquidateBorrow failed");

            uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
            uint256 remained = extraRepayAmount.sub(protocolFee);

            IERC20(underlying).approve(cTokenRepay, remained);
            require(ICErc20(cTokenRepay).mint(remained) == 0, "ctoken mint failed");
            IERC20(cTokenRepay).transfer(borrower, IERC20(cTokenRepay).balanceOf(address(this)));

            IERC20(underlying).transfer(protocolFeeRecipient, protocolFee);
        } else {
            require(msg.value == repayAmount, "incorrect ether amount");

            ICEther(cTokenRepay).liquidateBorrow{value: borrowedAmount}(borrower, cTokenCollateral);

            uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
            uint256 remained = extraRepayAmount.sub(protocolFee);

            // borrower.transfer(remained);
            ICEther(cTokenRepay).mint{value: remained}();
            IERC20(cTokenRepay).transfer(borrower, IERC20(cTokenRepay).balanceOf(address(this)));

            protocolFeeRecipient.transfer(protocolFee);
        }

        // we ensure that all borrow balances are repaid fully
        require(ICErc20(cTokenRepay).borrowBalanceCurrent(borrower) == 0, "invalid token borrow balance");

        extraRepayAmount = 0;
    }

    function transferSeizedTokenFresh(address cTokenCollateral, bool claimDToken) internal {
        uint256 seizedTokenAmount = ICErc721(cTokenCollateral).balanceOf(address(this));
        uint256 i;
        uint256 redeemTokenId;
        if (seizedTokenAmount > 0) {
            if (claimDToken) {
                for(; i < seizedTokenAmount; i++) {
                    ICErc721(cTokenCollateral).transfer(msg.sender, 0);
                }
            } else {
                ICErc721(cTokenCollateral).approve(cTokenCollateral, seizedTokenAmount);
                for(; i < seizedTokenAmount; i++) {
                    redeemTokenId = ICErc721(cTokenCollateral).userTokens(address(this), 0);
                    ICErc721(cTokenCollateral).redeem(0);
                    IERC721(ICErc721(cTokenCollateral).underlying()).transferFrom(address(this), msg.sender, redeemTokenId);
                }
            }
        }

        // we ensure that all seized tokens transfered and all borrow balances are repaid fully
        require(ICErc721(cTokenCollateral).balanceOf(address(this)) == 0, "failed transfer all seized tokens");
        require(IERC721(ICErc721(cTokenCollateral).underlying()).balanceOf(address(this)) == 0, "failed transfer all seized tokens");

        delete seizeIndexes_;
    }

    // /**
    //  * @notice Execute the proxy liquidation with multiple tokens repay
    //  */
    // function liquidateWithMutipleRepay(address payable borrower, address cTokenCollateral, address cTokenRepay1, uint256 repayAmount1, address cTokenRepay2, uint256 repayAmount2) external nonReentrant {
    //     require(borrower != address(0), "invalid borrower address");

    //     (, , uint256 borrowerShortfall) = IComptroller(comptroller).getAccountLiquidity(borrower);
    //     require(borrowerShortfall > 0, "invalid borrower liquidity shortfall");

    //     // we do accrue interest before liquidation to ensure that repay will be done with full amount
    //     uint error = ICErc20(cTokenRepay1).accrueInterest();
    //     require(error == 0, "repay token accure interest failed");

    //     error = ICErc20(cTokenRepay2).accrueInterest();
    //     require(error == 0, "repay token accure interest failed");

    //     error = ICErc721(cTokenCollateral).accrueInterest();
    //     require(error == 0, "collateral token accure interest failed");

    //     liquidateWithMutipleRepayFresh(borrower, cTokenCollateral, cTokenRepay1, repayAmount1, cTokenRepay2, repayAmount2);
    // }

    // function liquidateWithMutipleRepayFresh(address payable borrower, address cTokenCollateral, address cTokenRepay1, uint256 repayAmount1, address cTokenRepay2, uint256 repayAmount2) internal {
    //     require(extraRepayAmount == 0, "invalid initial extra repay amount");

    //     uint256 seizeTokenBeforeBalance = ICErc721(cTokenCollateral).balanceOf(address(this));

    //     uint256 borrowedAmount1 = ICErc20(cTokenRepay1).borrowBalanceCurrent(borrower);
    //     uint256 borrowedAmount2 = ICErc20(cTokenRepay2).borrowBalanceCurrent(borrower);

    //     require(repayAmount1 >= borrowedAmount1, "invalid token1 repay amount");
    //     require(repayAmount2 >= borrowedAmount2, "invalid token2 repay amount");
    //     extraRepayAmount = repayAmount1.sub(borrowedAmount1).add(getExchangedAmount(cTokenRepay2, cTokenRepay1, repayAmount2));

    //     if (cTokenRepay1 != cEther) {
    //         require(msg.value == repayAmount2, "incorrect ether amount");

    //         address underlying = ICErc20(cTokenRepay1).underlying();

    //         require(ICErc20(cTokenRepay1).liquidateBorrow(borrower, borrowedAmount1, cTokenCollateral) == 0, "liquidateBorrow failed");
    //         ICEther(cTokenRepay2).repayBorrowBehalf{value: borrowedAmount2}(borrower);

    //         uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
    //         uint256 remained = extraRepayAmount.sub(protocolFee);
    //         IERC20(underlying).transferFrom(msg.sender, borrower, remained);
    //         IERC20(underlying).transferFrom(msg.sender, protocolFeeRecipient, protocolFee);
    //     } else {
    //         require(msg.value == repayAmount1, "incorrect ether amount");

    //         ICEther(cTokenRepay1).liquidateBorrow{value: borrowedAmount1}(borrower, cTokenCollateral);
    //         require(ICErc20(cTokenRepay2).repayBorrowBehalf(borrower, borrowedAmount2) == 0,  "repayBorrowBehalf failed");

    //         uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
    //         uint256 remained = extraRepayAmount.sub(protocolFee);
    //         borrower.transfer(remained);
    //         protocolFeeRecipient.transfer(protocolFee);
    //     }

    //     uint256 seizeTokenAfterBalance = ICErc721(cTokenCollateral).balanceOf(address(this));
    //     uint256 seizedTokenAmount = seizeTokenAfterBalance.sub(seizeTokenBeforeBalance);

    //     // require(possibleSeizeTokens == seizedTokenAmount, "invalid seized amount");

    //     if (seizedTokenAmount > 0) {
    //         for(uint256 i; i < seizedTokenAmount; i++) {
    //             ICErc721(cTokenCollateral).transfer(msg.sender, 0);
    //         }
    //         require(ICErc721(cTokenCollateral).balanceOf(address(this)) == 0, "failed transfer all seized tokens");
    //     }

    //     // we ensure all borrow balances are repaid fully
    //     require(ICErc20(cTokenRepay1).borrowBalanceCurrent(borrower) == 0, "invalid token1 borrow balance");
    //     require(ICErc20(cTokenRepay2).borrowBalanceCurrent(borrower) == 0, "invalid token2 borrow balance");

    //     extraRepayAmount = 0;
    // }

    struct GetExtraRepayLocalVars {
        uint256 cTokenCollateralBalance;
        uint256 cTokenCollateralExchangeRateMantissa;
        uint256 cTokenCollateralAmount;
        uint256 collateralValue;
        uint256 repayValue;
    }

    function getSingleTokenExtraRepayAmount(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount) public view returns(uint256) {
        uint256 liquidationIncentiveMantissa = IComptroller(comptroller).liquidationIncentiveMantissa();

        GetExtraRepayLocalVars memory vars;

        (, vars.cTokenCollateralBalance, , vars.cTokenCollateralExchangeRateMantissa) = ICErc721(cTokenCollateral).getAccountSnapshot(borrower);
        vars.cTokenCollateralAmount = vars.cTokenCollateralBalance.mul(1e18).div(vars.cTokenCollateralExchangeRateMantissa);

        vars.collateralValue = getCTokenUnderlyingValue(cTokenCollateral, vars.cTokenCollateralAmount);
        vars.repayValue = (getCTokenUnderlyingValue(cTokenRepay, repayAmount)).mul(liquidationIncentiveMantissa).div(1e18);

        return vars.collateralValue.sub(vars.repayValue).div(getUnderlyingPrice(cTokenRepay));
    }

    function getBaseTokenExtraRepayAmount(address payable borrower, address cTokenCollateral, address cTokenRepay1, uint256 repayAmount1, address cTokenRepay2, uint256 repayAmount2) public view returns(uint256) {
        uint256 liquidationIncentiveMantissa = IComptroller(comptroller).liquidationIncentiveMantissa();

        GetExtraRepayLocalVars memory vars;

        (, vars.cTokenCollateralBalance, , vars.cTokenCollateralExchangeRateMantissa) = ICErc721(cTokenCollateral).getAccountSnapshot(borrower);
        vars.cTokenCollateralAmount = vars.cTokenCollateralBalance.mul(1e18).div(vars.cTokenCollateralExchangeRateMantissa);

        vars.collateralValue = getCTokenUnderlyingValue(cTokenCollateral, vars.cTokenCollateralAmount);
        vars.repayValue = (getCTokenUnderlyingValue(cTokenRepay1, repayAmount1).add(getCTokenUnderlyingValue(cTokenRepay2, repayAmount2)))
                                    .mul(liquidationIncentiveMantissa).div(1e18);

        return vars.collateralValue.sub(vars.repayValue).div(getUnderlyingPrice(cTokenRepay1));
    }

    function getCTokenUnderlyingValue(address cToken, uint256 underlyingAmount) public view returns (uint256) {
        address oracle = IComptroller(comptroller).oracle();
        uint256 underlyingPrice = IOracle(oracle).getUnderlyingPriceView(cToken);

        return underlyingPrice * underlyingAmount;
    }

    function getUnderlyingPrice(address cToken) public view returns (uint256) {
        address oracle = IComptroller(comptroller).oracle();
        return IOracle(oracle).getUnderlyingPriceView(cToken);
    }

    function getExchangedAmount(address cToken1, address cToken2, uint256 token1Amount) public view returns (uint256) {
        uint256 token1Price = getUnderlyingPrice(cToken1);
        uint256 token2Price = getUnderlyingPrice(cToken2);
        return token1Amount.mul(token1Price).div(token2Price);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /*** Admin functions ***/
    function initialize() onlyAdmin public {
        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    function _become(NFTLiquidationProxy proxy) public {
        require(msg.sender == NFTLiquidationProxy(proxy).admin(), "only proxy admin can change brains");
        proxy._acceptImplementation();
    }

    function _setComptroller(address _comptroller) external onlyAdmin nonReentrant {
        require(_comptroller != address(0), "comptroller can not be zero");

        address oldComptroller = comptroller;
        comptroller = _comptroller;

        emit NewComptroller(oldComptroller, comptroller);
    }

    function setCEther(address _cEther) external onlyAdmin nonReentrant {
        require(_cEther != address(0), "invalid cToken address");
        require(ICEther(_cEther).isCToken() == true, "not cToken");

        cEther = _cEther;

        emit NewCEther(cEther);
    }

    function setProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyAdmin nonReentrant {
        require(_protocolFeeRecipient != address(0), "invalid recipient address");

        protocolFeeRecipient = _protocolFeeRecipient;

        emit NewProtocolFeeRecipient(protocolFeeRecipient);
    }

    function setProtocolFeeMantissa(uint256 _protocolFeeMantissa) external onlyAdmin nonReentrant {
        require(protocolFeeMantissa <= 1e18, "invalid fee");

        protocolFeeMantissa = _protocolFeeMantissa;

        emit NewProtocolFeeMantissa(protocolFeeMantissa);
    }

    /**
     * @notice Emergency withdraw the assets that the users have deposited
     * @param underlying The address of the underlying
     * @param withdrawAmount The amount of the underlying token to withdraw
     */
    function emergencyWithdraw(address underlying, uint256 withdrawAmount) external onlyAdmin nonReentrant {
        if (underlying == address(0)) {
            require(address(this).balance >= withdrawAmount);
            msg.sender.transfer(withdrawAmount);
        } else {
            require(IERC20(underlying).balanceOf(address(this)) >= withdrawAmount);
            IERC20(underlying).transfer(msg.sender, withdrawAmount);
        }

        emit EmergencyWithdraw(admin, underlying, withdrawAmount);
    }

    /**
     * @notice Emergency withdraw the NFTs
     * @param underlying The address of the underlying
     * @param tokenId The id of the underlying token to withdraw
     */
    function emergencyWithdrawNFT(address underlying, uint256 tokenId) external onlyAdmin nonReentrant {
        IERC721(underlying).transferFrom(address(this), msg.sender, tokenId);

        emit EmergencyWithdrawNFT(admin, underlying, tokenId);
    }

    /**
     * @notice payable function needed to receive ETH
     */
    fallback () payable external {
    }
}