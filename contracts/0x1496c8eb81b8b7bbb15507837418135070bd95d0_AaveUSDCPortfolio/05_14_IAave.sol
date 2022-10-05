pragma solidity 0.8.13;

// Aave V2 interfaces.
interface IAToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool success);
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

interface ILendingPool {
    // The referral program is currently inactive. so pass 0 as the referralCode.
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external;
}