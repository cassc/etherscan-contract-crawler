// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "IERC20.sol";

interface ICTOKEN is IERC20 {
    function exchangeRateStored() external view returns(uint);
    function borrowBalanceStored(address account) external view returns(uint);
    function decimals() external view returns(uint8);
}

contract DebtRepayer {
   
    /*
     * Constant used as mantissa for dividing maxDiscount and zeroDiscountReserveThreshold
     */
    uint public immutable baseline;
    
    /*
     * maxDiscount denotes the maximum cut in value,
     * a user can have when selling their debt.
     * The maxDiscount can be seen as the starting point of the discount rate.
     * Must be set between 0 and baseline, with baseline denoting a 100% discount.
     * setable by governance
     */
    uint public maxDiscount;
    
    /*
     * zeroDiscountReserveThreshold, is the threshold at which the discount on selling reaches 0
     * If discount is 0, you can buy all of the reserves at 0 discount, even if pushing the discount rate up with the sell.
     * Must be set between 0 and baseline, with baseline meaning 0 discount at 100% reserve to debt rate.
     * setable by governance
     */
    uint public zeroDiscountReserveThreshold;

    /*
     * The governance of the contract. Can set maxDiscount, zeroDiscountReserveThreshold, Governance, Treasury and sweep tokens from the contract
     */
    address public governance;

    /*
     * The controller of the contract. Can set maxDiscount, zeroDiscountReserveThreshold, Governance, Treasury and sweep tokens from the contract
     */
    address public controller;
    /*
     * The address to which anTokens are paid to.
     */
    address public treasury;

    address public constant anEth = 0x697b4acAa24430F254224eB794d2a85ba1Fa1FB8;
    address public constant anYfi = 0xde2af899040536884e062D3a334F2dD36F34b4a4;
    address public constant anBtc = 0x17786f3813E6bA35343211bd8Fe18EC4de14F28b;

    IERC20 constant yfi = IERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);
    IERC20 constant wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(uint decimals, uint maxDiscount_, uint zeroDiscountReserveThreshold_, address governance_, address controller_, address treasury_){
        require(maxDiscount_ <= 10 ** decimals);
        require(zeroDiscountReserveThreshold_ <= 10 ** decimals);
        zeroDiscountReserveThreshold = zeroDiscountReserveThreshold_;
        maxDiscount = maxDiscount_;
        baseline = 10 ** decimals;
        governance = governance_;
        controller = controller_;
        treasury = treasury_;
    }

    /*
     * @notice Function called by users to sell their anTokens to the contract.
     * anTokens must be approved!
     * @param anToken The address of the anToken the user wishes to sell. Must be either anEth, anYfi or anBtc
     * @param amount The amount of anTokens the user wish to sell
     * @param minOut The amount of underlying tokens the user must get in return.
     * It is recommended to either set this as amountOut(anToken, underlying, amount)
     */
    function sellDebt(address anToken, uint amount, uint minOut) public {
        require(IERC20(anToken).balanceOf(msg.sender) >= amount, "NOT ENOUGH DEBT TOKENS");
        IERC20 underlying;
        if(anToken == anYfi){
            underlying = yfi;
        } else if(anToken == anBtc){
            underlying = wbtc;
        } else if(anToken == anEth){
            underlying = weth;
        } else {
            revert("UNKNOWN COLLATERAL TOKEN");
        }
        require(minOut <= underlying.balanceOf(address(this)), "NOT ENOUGH RESERVES");
        (uint receiveAmount, uint payAmount) = amountOut(anToken, underlying, amount);
        require(receiveAmount >= minOut, "RECEIVED LOWER THAN EXPECTED");
        uint treasuryFunds = IERC20(anToken).balanceOf(treasury);
        uint userFunds = underlying.balanceOf(msg.sender);
        require(IERC20(address(anToken)).transferFrom(msg.sender, treasury, payAmount), "TRANSFER FROM FAILED");
        require(IERC20(anToken).balanceOf(treasury) - treasuryFunds >= payAmount, "TREASURY TRANSFER FAILED");
        underlying.transfer(msg.sender, receiveAmount);
        require(underlying.balanceOf(msg.sender) - userFunds >= receiveAmount, "USER TRANSFER FAILED");

        emit debtRepayment(address(underlying), receiveAmount, payAmount);
    }
    
    /*
     * @notice Function for calculating the expected amount of underlying out, when selling a specific amount
     * @param anToken The anToken to sell
     * @param underlying The underlying token of the anToken
     * @amount The amount of anToken to sell
     */
    function amountOut(address anToken, IERC20 underlying, uint amount) public view returns(uint, uint){
        uint receiveAmount = convertToUnderlying(anToken, amount) * currentDiscount(anToken)/baseline;
        if(receiveAmount > underlying.balanceOf(address(this))){
            amount = amount * underlying.balanceOf(address(this)) / receiveAmount;
            receiveAmount = underlying.balanceOf(address(this));
        }
        return(receiveAmount, amount);
    }
    
    /*
     * @notice View function for getting the current discount baseline = 0% discount, 0 = 100% discount
     */
    function currentDiscount(address anToken) public view returns(uint){
        uint reserves;
        if(anToken == anYfi){
            reserves = yfi.balanceOf(address(this));
        } 
        else if(anToken == anBtc){
            reserves = wbtc.balanceOf(address(this));
        }
        else if(anToken == anEth){
            reserves = weth.balanceOf(address(this));
        } else {
            revert("UNKNOWN COLLATERAL TOKEN");
        }
        return calculateDiscount(reserves, remainingDebt(anToken));
    }

    /*
     * @notice view function for calculating the current debt of a specific anchor market
     * @dev The function subtracts anTokens owned by treasury from attackers debt
     * @param anToken Address of market of which debt you want to see
     */
    function remainingDebt(address anToken) public view returns(uint){
        uint repaid = IERC20(anToken).balanceOf(treasury);
        return ICTOKEN(anToken).borrowBalanceStored(0xeA0c959BBb7476DDD6cD4204bDee82b790AA1562) - convertToUnderlying(anToken, repaid);
    }

    /*
     * @notice Converts an amount of anTokens into the corresponding amount of underlying
     * @param anToken The anToken to convert
     * @param amount The amount to convert
     */
    function convertToUnderlying(address anToken, uint amount) public view returns(uint){
        ICTOKEN cToken = ICTOKEN(anToken);
        return amount * cToken.exchangeRateStored() / 10 ** 18;
    }
    
    function calculateDiscount(uint reserveAmount, uint debtOutstanding) private view returns(uint){
        uint reserveRatio = reserveAmount * baseline / debtOutstanding;
        if( reserveRatio < zeroDiscountReserveThreshold){
            return baseline - (maxDiscount - maxDiscount * reserveRatio / zeroDiscountReserveThreshold);
        }
        return baseline;
    }
   
    //If we receive any eth, we want to revert. Alternatively, turn it into wETH
    receive() external payable {
        revert("Eth not allowed");
    }

    // *******************
    // * OWNER FUNCTIONS *
    // *******************
    
    /*
     * @notice function for sweeping any token owned by this contract to the treasury address
     * Only callable by governance or controller
     * @token Address of the ERC20 token to sweep
     * @amount Amount to sweep
     */
    function sweepTokens(address token, uint amount) public{
        require(msg.sender == governance || msg.sender == controller);
        require(IERC20(token).balanceOf(address(this)) >= amount);
        IERC20(token).transfer(treasury, amount);
    }

    /*
     * @notice function for setting a new maxDiscount. Only callable by governance or controller.
     * If set to 0, the maxDiscount is 0%
     * If set to baseline, the maxDiscount is 100%
     * @param newMaxDiscount The new maxDiscount rate. Must be set between 0 and baseline.
     */ 
    function setMaxDiscount(uint newMaxDiscount) public{
        require(msg.sender == governance || msg.sender == controller);
        require(newMaxDiscount <= baseline);
        maxDiscount = newMaxDiscount;
    }
    
    /*
     * @notice function for setting a new zeroDiscountReserveThreshold. Only callable by governanceor controller.
     * If set to 1, the discount rate will be 0% when 1/baseline of debt has been paid to the contract.
     * If set to baseline, the discount rate will be 0% when 100% of debt has been paid to the contract.
     * @param newZeroDiscountReserveThreshold The new zero discount reserve threshold. Must be set between 1 and baseline.
     */
    function setZeroDiscountReserveThreshold(uint newZeroDiscountReserveThreshold) public{
        require(msg.sender == governance || msg.sender == controller);
        require(newZeroDiscountReserveThreshold <= baseline);
        require(newZeroDiscountReserveThreshold > 0);
        zeroDiscountReserveThreshold = newZeroDiscountReserveThreshold;
    }

    /*
     * @notice Function for setting the new governance. Only callable by governance.
     * @param newGovernance The address of the newGovernance
     */
    function setGovernance(address newGovernance) public{
        require(msg.sender == governance);
        governance = newGovernance;
    }

    /*
     * @notice Function for setting a new treasury. Only callable by governance.
     * @param newTreasury The address of the new treasury.
     */
    function setTreasury(address newTreasury) public{
        require(msg.sender == governance);
        treasury = newTreasury;
    }

    /*
     * @notice Function for setting a new controller. Only callable by governance.
     * @param newController The address of the new controller.
     */
    function setController(address newController) public{
        require(msg.sender == governance);
        controller = newController;
    }

    event debtRepayment(address underlying, uint receiveAmount, uint paidAmount);

}
