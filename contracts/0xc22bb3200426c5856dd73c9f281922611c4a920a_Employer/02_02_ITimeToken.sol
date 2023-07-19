// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITimeToken {
    function DEVELOPER_ADDRESS() external returns (address);
    function BASE_FEE() external returns (uint256);
    function COMISSION_RATE() external returns (uint256);
    function SHARE_RATE() external returns (uint256);
    function TIME_BASE_LIQUIDITY() external returns (uint256);
    function TIME_BASE_FEE() external returns (uint256);
    function TOLERANCE() external returns (uint256);
    function dividendPerToken() external returns (uint256);
    function firstBlock() external returns (uint256);
    function liquidityFactorNative() external returns (uint256);
    function liquidityFactorTime() external returns (uint256);
    function numberOfHolders() external returns (uint256);
    function numberOfMiners() external returns (uint256);
    function sharedBalance() external returns (uint256);
    function poolBalance() external returns (uint256);
    function totalMinted() external returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);
    function averageMiningRate() external view returns (uint256);
    function donateEth() external payable;
    function enableMining() external payable;
    function enableMiningWithTimeToken() external;
    function fee() external view returns (uint256);
    function feeInTime() external view returns (uint256);
    function mining() external;
    function saveTime() external payable returns (bool success);
    function spendTime(uint256 timeAmount) external returns (bool success);
    function swapPriceNative(uint256 amountNative) external view returns (uint256);
    function swapPriceTimeInverse(uint256 amountTime) external view returns (uint256);
    function accountShareBalance(address account) external view returns (uint256);
    function withdrawableShareBalance(address account) external view returns (uint256);
    function withdrawShare() external;
}