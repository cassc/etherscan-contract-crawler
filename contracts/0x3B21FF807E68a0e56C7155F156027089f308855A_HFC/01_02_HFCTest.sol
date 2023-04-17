//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "../tokens/IERC20DP.sol";

contract HFC {
    uint256 constant STANDARD_DECIMAL_PRECISION = 10 ** 18;

    constructor(){

    }
    
    /**
     * @notice Downscales amounts with respect to the primary tokens decimals
     * @param _amount The scaled amount
     * @param _primaryToken The primary token of the returns vault
     * @return uint256
     */
    function getStandardisedDecimalPrecisionDownscale(uint256 _amount, address _primaryToken) public view returns (uint256) {
        return (_amount * (10 ** IERC20DP(_primaryToken).decimals())) / STANDARD_DECIMAL_PRECISION;
    }

    /**
     * @notice Upscales amounts with respect to the tokens decimals
     * @param _amount The amount to be scaled
     * @param _token The token that will be scaled against
     * @return uint256
     */
    function getStandardisedDecimalPrecisionUpscale(uint256 _amount, address _token) public view returns (uint256) {
        return (_amount * STANDARD_DECIMAL_PRECISION) / 10 ** IERC20DP(_token).decimals();
    }


    function honourFundingCall(uint256 _amount, address _token, address _to1, address _to2) public {
        IERC20DP tempToken = IERC20DP(_token);

        tempToken.transferFrom(msg.sender,_to1, getStandardisedDecimalPrecisionDownscale(_amount, _token));
        tempToken.transferFrom(msg.sender, _to2, getStandardisedDecimalPrecisionDownscale(_amount, _token));
    }
}