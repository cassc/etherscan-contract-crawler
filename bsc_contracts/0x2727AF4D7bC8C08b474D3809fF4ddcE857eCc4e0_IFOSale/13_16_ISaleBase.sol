// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./ITreasury.sol";

interface ISaleBase {
    // Amount in MMM
    event TokenSold(address indexed beneficiary, uint256 indexed amount);
    event TokenTransferred(address indexed receiver, uint256 indexed amount);

    // Price (BUSD) per Ves
    function price() external view returns (uint256);

    // The beneficiary vesting wallet address
    function vestingWallet(address) external view returns (address);

    function startTimestamp() external view returns (uint256);

    function endTimestamp() external view returns (uint256);

    function soldToken() external view returns (uint256);

    function maxSaleToken() external view returns (uint256);

    function busdAddress() external view returns (address);

    function usdtAddress() external view returns (address);

    function VesAddress() external view returns (address);

    function pancakeRouterAddress() external view returns (address);

    function treasury() external view virtual returns (ITreasury);

    function buyTokenBNB(uint256) external payable;

    function getBusdForBnb(
        uint256
    ) external view returns (uint256[] memory amounts);

    function buyTokenBUSD(uint256) external;

    function buyTokenUSDT(uint256) external;

    function withdrawToken(address) external;

    //    function withdrawBNB() external;

    //    function transferTokenOwnership(address) external;
}