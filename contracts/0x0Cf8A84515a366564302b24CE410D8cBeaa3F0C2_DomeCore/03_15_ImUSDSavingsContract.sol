// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ImUSDSavingsContract {

    function balanceOf(address account) external view returns (uint256);
    
    function balanceOfUnderlying(address _user) external view returns (uint256 balance);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function redeemAndUnwrap(
        uint256 _amount,
        bool _isCreditAmt,
        uint256 _minAmountOut,
        address _output,
        address _beneficiary,
        address _router,
        bool _isBassetOut
    )
        external
        returns (
            uint256 creditsBurned,
            uint256 massetRedeemed,
            uint256 outputQuantity
        );
    


}