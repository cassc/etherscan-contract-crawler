// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../interfaces/IERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// @dev Caution: We assume all failed transfers cause reverts and ignore the returned bool.
interface IXINV {
    function rewardTreasury() external view returns(address);
    function balanceOf(address) external view returns (uint);
    function exchangeRateStored() external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function syncDelegate(address user) external;
    function accrualBlockNumber() external view returns (uint);
    function getCash() external view returns (uint);
    function totalSupply() external view returns (uint);
    function rewardPerBlock() external view returns (uint);
}

interface IDbrDistributor {
    function stake(uint amount) external;
    function unstake(uint amount) external;
    function claim(address to) external;
    function claimable(address user) external view returns(uint);
}

/**
 * @title INV Escrow
 * @notice Collateral is stored in unique escrow contracts for every user and every market.
 * This escrow allows user to deposit INV collateral directly into the xINV contract, earning APY and allowing them to delegate votes on behalf of the xINV collateral
 * @dev Caution: This is a proxy implementation. Follow proxy pattern best practices
 */
contract INVEscrow {
    using FixedPointMathLib for uint;

    address public market;
    IDelegateableERC20 public token;
    address public beneficiary;
    uint public stakedXINV;
    IXINV public immutable xINV;
    IDbrDistributor public immutable distributor;
    mapping(address => bool) public claimers;

    constructor(IXINV _xINV, IDbrDistributor _distributor) {
        xINV = _xINV;
        distributor = _distributor;
    }

    /**
     * @notice Initialize escrow with a token
     * @dev Must be called right after proxy is created.
     * @param _token The IERC20 token representing the INV governance token
     * @param _beneficiary The beneficiary who may delegate token voting power
     */
    function initialize(IDelegateableERC20 _token, address _beneficiary) public {
        require(market == address(0), "ALREADY INITIALIZED");
        market = msg.sender;
        token = _token;
        beneficiary = _beneficiary;
        _token.delegate(_token.delegates(_beneficiary));
        _token.approve(address(xINV), type(uint).max);
        xINV.syncDelegate(address(this));
    }
    
    /**
     * @notice Transfers the associated ERC20 token to a recipient.
     * @param recipient The address to receive payment from the escrow
     * @param amount The amount of ERC20 token to be transferred.
     */
    function pay(address recipient, uint amount) public {
        require(msg.sender == market, "ONLY MARKET");
        uint invBalance = token.balanceOf(address(this));
        if(invBalance < amount) {
            uint invNeeded = amount - invBalance;
            uint xInvToUnstake = invNeeded * 1 ether / viewExchangeRate();
            stakedXINV -= xInvToUnstake;
            distributor.unstake(xInvToUnstake);
            xINV.redeemUnderlying(invNeeded); // we do not check return value because transfer call will fail if this fails anyway
        }
        token.transfer(recipient, amount);
    }
    
    /**
     * @notice Allows the beneficiary to claim DBR tokens
     * @dev Requires the caller to be the beneficiary
     */
    function claimDBR() public {
        require(msg.sender == beneficiary, "ONLY BENEFICIARY");
        distributor.claim(msg.sender);
    }

    /**
     * @notice Allows the beneficiary or allowed claimers to claim DBR tokens on behalf of another address
     * @param to The address to which the claimed tokens will be sent
     * @dev Requires the caller to be the beneficiary or an allowed claimer
     */
    function claimDBRTo(address to) public {
        require(msg.sender == beneficiary || claimers[msg.sender], "ONLY BENEFICIARY OR ALLOWED CLAIMERS");
        distributor.claim(to);
    }

    /**
     * @notice Returns the amount of claimable DBR tokens for the contract
     * @return The amount of claimable tokens
     */
    function claimable() public view returns (uint) {
        return distributor.claimable(address(this));
    }

    /**
     * @notice Sets or unsets an address as an allowed claimer
     * @param claimer The address of the claimer to set or unset
     * @param allowed A boolean value to determine if the claimer is allowed or not
     * @dev Requires the caller to be the beneficiary
     */
    function setClaimer(address claimer, bool allowed) public {
        require(msg.sender == beneficiary, "ONLY BENEFICIARY");
        claimers[claimer] = allowed;
    }

    /**
    * @notice Get the token balance of the escrow
    * @return Uint representing the INV token balance of the escrow including the additional INV accrued from xINV
    */
    function balance() public view returns (uint) {
        uint invBalance = token.balanceOf(address(this));
        uint invBalanceInXInv = stakedXINV * viewExchangeRate() / 1 ether;
        return invBalance + invBalanceInXInv;
    }
    
    /**
     * @notice Function called by market on deposit. Will deposit INV into xINV 
     * @dev This function should remain callable by anyone to handle direct inbound transfers.
     */
    function onDeposit() public {
        uint invBalance = token.balanceOf(address(this));
        if(invBalance > 0) {
            uint xinvBal = xINV.balanceOf(address(this));
            xINV.mint(invBalance); // we do not check return value because we don't want errors to block this call
            stakedXINV += xINV.balanceOf(address(this)) - xinvBal;
            distributor.stake(stakedXINV - xinvBal);
        }
    }

    /**
     * @notice Delegates voting power of the underlying xINV.
     * @param delegatee The address to be delegated voting power
     */
    function delegate(address delegatee) public {
        require(msg.sender == beneficiary, "ONLY BENEFICIARY");
        token.delegate(delegatee);
        xINV.syncDelegate(address(this));
    }

    /**
     * @notice View function to calculate exact exchangerate for current block
     */
    function viewExchangeRate() internal view returns (uint) {
        uint accrualBlockNumberPrior = xINV.accrualBlockNumber();
        if (accrualBlockNumberPrior == block.number) return xINV.exchangeRateStored();
        uint blockDelta = block.number - accrualBlockNumberPrior;
        uint rewardsAccrued = xINV.rewardPerBlock() * blockDelta;
        uint treasuryInvBalance = token.balanceOf(xINV.rewardTreasury());
        uint treasuryxInvAllowance = token.allowance(xINV.rewardTreasury(), address(xINV));
        if( treasuryInvBalance <= rewardsAccrued || treasuryxInvAllowance <= rewardsAccrued) return xINV.exchangeRateStored();
        return (xINV.getCash() + rewardsAccrued).divWadDown(xINV.totalSupply());
    }

}