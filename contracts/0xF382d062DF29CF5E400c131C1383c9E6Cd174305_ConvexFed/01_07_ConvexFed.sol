pragma solidity ^0.8.13;

import "src/interfaces/IERC20.sol";
import "src/interfaces/curve/IMetaPool.sol";
import "src/interfaces/convex/IConvexBooster.sol";
import "src/interfaces/convex/IConvexBaseRewardPool.sol";
import "src/convex-fed/CurvePoolAdapter.sol";

contract ConvexFed is CurvePoolAdapter{

    uint public immutable poolId;
    IConvexBooster public booster;
    IConvexBaseRewardPool public baseRewardPool;
    IERC20 public crv;
    IERC20 public CVX;
    address public chair; // Fed Chair
    address public gov;
    address public guardian;
    uint public dolaSupply;
    uint public maxLossExpansionBps;
    uint public maxLossWithdrawBps;
    uint public maxLossTakeProfitBps;

    event Expansion(uint amount);
    event Contraction(uint amount);

    constructor(
            address dola_, 
            address CVX_,
            address crvPoolAddr,
            address booster_, 
            address baseRewardPool_, 
            address chair_,
            address gov_, 
            address guardian_,
            uint maxLossExpansionBps_,
            uint maxLossWithdrawBps_,
            uint maxLossTakeProfitBps_)
            CurvePoolAdapter(dola_, crvPoolAddr)
    {
        booster = IConvexBooster(booster_);
        baseRewardPool = IConvexBaseRewardPool(baseRewardPool_);
        crv = IERC20(baseRewardPool.rewardToken());
        CVX = IERC20(CVX_);
        poolId = baseRewardPool.pid();
        IERC20(crvPoolAddr).approve(booster_, type(uint256).max);
        IERC20(crvPoolAddr).approve(baseRewardPool_, type(uint256).max);
        maxLossExpansionBps = maxLossExpansionBps_;
        maxLossWithdrawBps = maxLossWithdrawBps_;
        maxLossTakeProfitBps = maxLossTakeProfitBps_;
        chair = chair_;
        gov = gov_;
        guardian = guardian_;
    }

    /**
    @notice Method for gov to change gov address
    */
    function changeGov(address newGov_) public {
        require(msg.sender == gov, "ONLY GOV");
        gov = newGov_;
    }

    /**
    @notice Method for gov to change the chair
    */
    function changeChair(address newChair_) public {
        require(msg.sender == gov, "ONLY GOV");
        chair = newChair_;
    }
    /**
    @notice Method for gov to change the guardian
    */
    function changeGuardian(address newGuardian_) public {
        require(msg.sender == gov, "ONLY GOV");
        guardian = newGuardian_;
    }

    /**
    @notice Method for current to resign
    */
    function resign() public {
        require(msg.sender == chair, "ONLY CHAIR");
        chair = address(0);
    }

    /**
    @notice Set the maximum acceptable loss when expanding dola supply. Only callable by gov.
    @param newMaxLossExpansionBps The maximum loss allowed by basis points 1 = 0.01%
    */
    function setMaxLossExpansionBps(uint newMaxLossExpansionBps) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossExpansionBps <= 10000, "Can't have max loss above 100%");
        maxLossExpansionBps = newMaxLossExpansionBps;
    }

    /**
    @notice Set the maximum acceptable loss when withdrawing dola supply. Only callable by gov or guardian.
    @param newMaxLossWithdrawBps The maximum loss allowed by basis points 1 = 0.01%
    */
    function setMaxLossWithdrawBps(uint newMaxLossWithdrawBps) public {
        require(msg.sender == gov || msg.sender == guardian, "ONLY GOV");
        require(newMaxLossWithdrawBps <= 10000, "Can't have max loss above 100%");
        maxLossWithdrawBps = newMaxLossWithdrawBps;
    }

    /**
    @notice Set the maximum acceptable loss when Taking Profit from LP tokens. Only callable by gov.
    @param newMaxLossTakeProfitBps The maximum loss allowed by basis points 1 = 0.01%
    */
    function setMaxLossTakeProfitBps(uint newMaxLossTakeProfitBps) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossTakeProfitBps <= 10000, "Can't have max loss above 100%");
        maxLossTakeProfitBps = newMaxLossTakeProfitBps;   
    }
    /**
    @notice Deposits amount of dola tokens into yEarn vault

    @param amount Amount of dola token to deposit into yEarn vault
    */
    function expansion(uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        dolaSupply += amount;
        dola.mint(address(this), amount);
        metapoolDeposit(amount, maxLossExpansionBps);
        require(booster.depositAll(poolId, true), 'Failed Deposit');
        emit Expansion(amount);
    }

    /**
    @notice Withdraws an amount of dola token to be burnt, contracting DOLA dolaSupply
    @dev Be careful when setting maxLoss parameter. There will almost always be some slippage when trading.
    For example, slippage + trading fees may be incurred when withdrawing from a Curve pool.
    On the other hand, setting the maxLoss too high, may cause you to be front run by MEV
    sandwhich bots, making sure your entire maxLoss is incurred.
    Recommended to always broadcast withdrawl transactions(contraction & takeProfits)
    through a frontrun protected RPC like Flashbots RPC.
    @param amountDola The amount of dola tokens to withdraw. Note that more tokens may
    be withdrawn than requested.
    */
    function contraction(uint amountDola) public {
        require(msg.sender == chair, "ONLY CHAIR");
        //Calculate how many lp tokens are needed to withdraw the dola
        uint crvLpNeeded = lpForDola(amountDola);
        require(crvLpNeeded <= crvLpSupply(), "Not enough crvLP tokens");

        //Withdraw and unwrap curveLP tokens from convex, but don't claim rewards
        require(baseRewardPool.withdrawAndUnwrap(crvLpNeeded, false), "CONVEX WITHDRAW FAILED");

        //Withdraw DOLA from curve pool
        uint dolaWithdrawn = metapoolWithdraw(amountDola, maxLossWithdrawBps);
        require(dolaWithdrawn > 0, "Must contract");
        uint burnAmount = _burnAndPay();
        emit Contraction(burnAmount);
    }

    /**
    @notice Withdraws every remaining crvLP token. Can take up to maxLossWithdrawBps in loss, compared to dolaSupply.
    It will still be necessary to call takeProfit to withdraw any potential rewards.
    */
    function contractAll() public {
        require(msg.sender == chair, "ONLY CHAIR");
        baseRewardPool.withdrawAllAndUnwrap(false);
        uint dolaMinOut = dolaSupply * (10_000 - maxLossWithdrawBps) / 10_000;
        crvMetapool.remove_liquidity_one_coin(crvLpSupply(), 0, dolaMinOut);
        uint burnAmount = _burnAndPay();
        emit Contraction(burnAmount);
    }


    /**
    @notice Withdraws the profit generated by convex staking
    @dev See dev note on Contraction method
    */
    function takeProfit(bool harvestLP) public {
        //This takes crvLP at face value, but doesn't take into account slippage or fees
        //Worth considering that the additional transaction fees incurred by withdrawing the small amount of profit generated by tx fees,
        //may not eclipse additional transaction costs. Set harvestLP = false to only withdraw crv and cvx rewards.
        uint crvLpValue = crvMetapool.get_virtual_price()*crvLpSupply() / 10**18;
        if(harvestLP && crvLpValue > dolaSupply) {
            require(msg.sender == chair, "ONLY CHAIR CAN TAKE CRV LP PROFIT");
            uint dolaSurplus = crvLpValue - dolaSupply;
            uint crvLpToWithdraw = lpForDola(dolaSurplus);
            require(baseRewardPool.withdrawAndUnwrap(crvLpToWithdraw, false), "CONVEX WITHDRAW FAILED");
            uint dolaProfit = metapoolWithdraw(dolaSurplus, maxLossTakeProfitBps);
            require(dolaProfit > 0, "NO PROFIT");
            dola.transfer(gov, dolaProfit);
        }
        require(baseRewardPool.getReward());
        crv.transfer(gov, crv.balanceOf(address(this)));
        CVX.transfer(gov, CVX.balanceOf(address(this)));
    }

    /**
    @notice Burns the remaining dola supply. Useful in case of the FED being completely contracted and wanting to pay off remaining bad debts.
    */
    function burnRemainingDolaSupply() public {
        dola.transferFrom(msg.sender, address(this), dolaSupply);
        _burnAndPay();
    }

    /**
    @notice Burns all dola tokens held by the fed up to the dolaSupply, taking any surplus as profit.
    */
    function _burnAndPay() internal returns(uint burnAmount){
        uint dolaBal = dola.balanceOf(address(this));
        if(dolaBal > dolaSupply){
            IERC20(dola).transfer(gov, dolaBal - dolaSupply);
            IERC20(dola).burn(dolaSupply);
            burnAmount = dolaSupply;
            dolaSupply = 0;
        } else {
            IERC20(dola).burn(dolaBal);
            burnAmount = dolaBal;
            dolaSupply -= dolaBal;
        }
    }
    
    /**
    @notice View function for getting crvLP tokens in the contract + convex baseRewardPool
    */
    function crvLpSupply() public view returns(uint){
        return crvMetapool.balanceOf(address(this)) + baseRewardPool.balanceOf(address(this));
    }
}