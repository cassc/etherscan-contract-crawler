// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IFeeApprover {

    function check(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setFeeMultiplier(uint _feeMultiplier) external;
    function feePercentX100() external view returns (uint);

    function setTokenUniswapPair(address _tokenUniswapPair) external;
   
    function setCoreTokenAddress(address _coreTokenAddress) external;
    function sync() external;
    function calculateAmountsAfterFee(        
        address sender, 
        address recipient, 
        uint256 amount
    ) external  returns (uint256 transferToAmount, uint256 transferToFeeBearerAmount);

 

}