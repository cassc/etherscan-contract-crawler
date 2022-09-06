//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


contract FeeCalculator {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint128;
    using SafeMath for uint;

    struct FeeData {
        IERC20Metadata feeToken;
        uint gasEstimate;
        uint gasPrice;
        uint feeAmountUSD;
        uint feeTokenETHPrice;
        uint ethUSDPrice;
    }

    function computeFees(FeeData memory data) public view returns (uint dexibleFee, uint gasFee, uint totalFees) {
        
        uint estGasCost = data.gasPrice * data.gasEstimate;
        console.log("Estimated gas cost", estGasCost);
        uint decs = data.feeToken.decimals();
        gasFee = (estGasCost.mul(10**decs)).div(data.feeTokenETHPrice);
        console.log("Gas portion in fee token", gasFee);

        //all pricing comes in as 18-decimal points. We need to maintain that level 
        //of granularity when computing USD price for fee token. This results in 
        //36-decimal point number
        uint feeTokenUSDPrice = data.ethUSDPrice.mul(data.feeTokenETHPrice);
        console.log("Fee token price in USD", feeTokenUSDPrice);
        
        //now divide the USD fee (in equivalent fee-token decimals) by the usd price for fee token
        //that tells us how many tokens make up the equivalent USD value.
        dexibleFee = data.feeAmountUSD.mul(10**(36+decs)).div(feeTokenUSDPrice);

        console.log("Dexible fee", dexibleFee); 

        totalFees = dexibleFee.add(gasFee);

        console.log("Total fees", totalFees);
    }
}