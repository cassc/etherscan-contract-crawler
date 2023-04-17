// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
// FOX BLOCKCHAIN \\

FoxChain works to connect all Blockchains in one platform with one click access to any network.

Website     : https://foxchain.app/
Dex         : https://foxdex.finance/
Telegram    : https://t.me/FOXCHAINNEWS
Twitter     : https://twitter.com/FoxchainLabs
Github      : https://github.com/FoxChainLabs

*/

interface IMasterFox {
    function transferOwnership(address newOwner) external; // from Ownable.sol

    function updateMultiplier(uint256 multiplierNumber) external; // onlyOwner

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external; // onlyOwner

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external; // onlyOwner

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external; // validatePool(_pid);

    function deposit(uint256 _pid, uint256 _amount) external; // validatePool(_pid);

    function withdraw(uint256 _pid, uint256 _amount) external; // validatePool(_pid);

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function dev(address _devaddr) external;

    function totalAllocPoint() external view returns (uint256);

    function BONUS_MULTIPLIER() external view returns (uint256);

    function cakePerBlock() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function checkPoolDuplicate(address _lpToken) external view;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function syrup() external view returns (address);

    function getPoolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );
}