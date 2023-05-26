// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Percentage is Initializable{

    uint256 private percentageDecimals;

    function __Percentage_init(uint256 percentageDecimals_) internal onlyInitializing 
    {
        require(percentageDecimals_ > 0, "Decimal value can not be zero");
        percentageDecimals = percentageDecimals_;
    } 

    // calculates percentage of input value to the totalValue 
    function calculatePercentage(uint256 inputVal_, uint256 totalValue_) 
        public view returns(uint256)
    {
        if (totalValue_ == 0)
        {
            return 0;
        }
        return (inputVal_ * 100 * percentageDecimals)/ totalValue_;
    }

    // calculates the value of percentage value from the total value
    function calculateValueOfPercentage(uint256 percentage_, uint256 totalValue_) 
        public view returns(uint256)
    {
        return (totalValue_ * percentage_ / (100 * percentageDecimals));
    }

    function _updatePercentageDecimals(uint256 newPercentageDecimals_)internal{
        require(newPercentageDecimals_ > 0, "Decimal value can not be zero");
        percentageDecimals = newPercentageDecimals_;
    }

    function PercentageDecimals()public view returns(uint256){
        return percentageDecimals;
    }

}