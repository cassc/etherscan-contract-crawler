// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasury {

    event SendTokensToWhitelistedWallet(address indexed sender, uint amount, address indexed receiver);
    event Whitelist(address indexed sender, bool permission, address indexed wallet);


    function BLXM() external returns (address blxm);
    function SSC() external returns (address ssc);

    function addWhitelist(address wallet) external;
    function removeWhitelist(address wallet) external;
    function whitelist(address wallet) external returns (bool permission);

    function totalBlxm() external view returns (uint totalBlxm);
    function totalRewards() external view returns (uint totalRewards);
    function balanceOf(address investor) external view returns (uint balance);

    function addRewards(uint amount) external;

    function addBlxmTokens(uint amount, address to) external;
    function retrieveBlxmTokens(address from, uint amount, uint rewardAmount, address to) external;

    function sendTokensToWhitelistedWallet(uint amount, address to) external;
}