// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@overnight-contracts/core/contracts/Strategy.sol";
import "@overnight-contracts/core/contracts/interfaces/IHedgeExchanger.sol";


contract StrategyEts is Strategy {

    // --- params

    IERC20 public asset;
    IERC20 public rebaseToken;
    IHedgeExchanger public hedgeExchanger;


    // --- events
    event StrategyUpdatedParams();


    // --- structs

    struct StrategyParams {
        address asset;
        address rebaseToken;
        address hedgeExchanger;
    }


    // --- constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- setters

    function setParams(StrategyParams calldata params) external onlyAdmin {
        asset = IERC20(params.asset);
        rebaseToken = IERC20(params.rebaseToken);
        hedgeExchanger = IHedgeExchanger(params.hedgeExchanger);

        emit StrategyUpdatedParams();
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(asset), "Some token not compatible");

        asset.approve(address(hedgeExchanger), _amount);
        hedgeExchanger.buy(_amount, "");
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(asset), "Some token not compatible");

        rebaseToken.approve(address(hedgeExchanger), _amount);
        hedgeExchanger.redeem(_amount);

        return asset.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(asset), "Some token not compatible");

        uint256 rebaseTokenAmount = rebaseToken.balanceOf(address(this));
        rebaseToken.approve(address(hedgeExchanger), rebaseTokenAmount);
        hedgeExchanger.redeem(rebaseTokenAmount);

        return asset.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue();
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        return asset.balanceOf(address(this)) + rebaseToken.balanceOf(address(this));
    }

    function _claimRewards(address _beneficiary) internal override returns (uint256) {
        return 0;
    }

}