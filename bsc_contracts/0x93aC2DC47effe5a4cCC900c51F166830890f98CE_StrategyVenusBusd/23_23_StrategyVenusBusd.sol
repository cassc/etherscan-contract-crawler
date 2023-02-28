// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@overnight-contracts/core/contracts/Strategy.sol";
import "@overnight-contracts/connectors/contracts/stuff/Venus.sol";
import "@overnight-contracts/connectors/contracts/stuff/PancakeV2.sol";

contract StrategyVenusBusd is Strategy {

    // --- structs

    struct StrategyParams {
        address busdToken;
        address vBusdToken;
        address unitroller;
        address pancakeRouter;
        address xvsToken;
        address wbnbToken;
    }


    // --- params

    IERC20 public busdToken;
    VenusInterface public vBusdToken;
    Unitroller public unitroller;
    IPancakeRouter02 public pancakeRouter;
    IERC20 public xvsToken;
    IERC20 public wbnbToken;


    // --- events

    event StrategyUpdatedParams();


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setParams(StrategyParams calldata params) external onlyAdmin {
        busdToken = IERC20(params.busdToken);
        vBusdToken = VenusInterface(params.vBusdToken);
        unitroller = Unitroller(params.unitroller);
        pancakeRouter = IPancakeRouter02(params.pancakeRouter);
        xvsToken = IERC20(params.xvsToken);
        wbnbToken = IERC20(params.wbnbToken);

        emit StrategyUpdatedParams();
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(busdToken), "Some token not compatible");

        busdToken.approve(address(vBusdToken), _amount);
        vBusdToken.mint(_amount);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(busdToken), "Some token not compatible");

        vBusdToken.redeemUnderlying(_amount);

        return busdToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(busdToken), "Some token not compatible");

        vBusdToken.redeem(vBusdToken.balanceOf(address(this)));

        return busdToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue();
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        return (vBusdToken.balanceOf(address(this)) * vBusdToken.exchangeRateStored() / 1e18) + busdToken.balanceOf(address(this));
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        if (vBusdToken.balanceOf(address(this)) > 0) {
            address[] memory tokens = new address[](1);
            tokens[0] = address(vBusdToken);
            unitroller.claimVenus(address(this), tokens);
        }

        // sell rewards
        uint256 totalBusd;

        uint256 xvsBalance = xvsToken.balanceOf(address(this));
        if (xvsBalance > 0) {
            uint256 xvsAmountOut = PancakeSwapLibrary.getAmountsOut(
                pancakeRouter,
                address(xvsToken),
                address(wbnbToken),
                address(busdToken),
                xvsBalance
            );

            if (xvsAmountOut > 0) {
                totalBusd += PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    address(xvsToken),
                    address(wbnbToken),
                    address(busdToken),
                    xvsBalance,
                    xvsAmountOut * 99 / 100,
                    address(this)
                );
            }
        }

        if (totalBusd > 0) {
            busdToken.transfer(_to, totalBusd);
        }

        return totalBusd;
    }

}