// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
// FOX BLOCKCHAIN \\

FoxChain works to connect all Blockchains in one platform with one click access to any network.

Website     : https://foxchain.app/
Dex         : https://foxdex.finance/
Telegram    : https://t.me/FOXCHAINNEWS
Twitter     : https://twitter.com/FoxchainLabs
Github      : https://github.com/FoxChainLabs

*/


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@fox.chain/contracts/contracts/v0.8/interfaces/IContractWhitelist.sol";
import "./IRewarderV2.sol";


interface IMasterFoxV2 is IContractWhitelist {
    function updateEmissionRate(uint256 _foxlayerPerSecond, bool _withUpdate) external; // onlyOwner

    function updateHardCap(uint256 _hardCap) external; // onlyOwner

    function setFeeAddress(address _feeAddress) external; // onlyOwner

    function add(
        uint256 _allocPoint,
        IERC20 _stakeToken,
        bool _withUpdate,
        uint16 _depositFeeBP,
        IRewarderV2 _rewarder
    ) external; // onlyOwner

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate,
        uint16 _depositFeeBP,
        IRewarderV2 _rewarder
    ) external; // onlyOwner

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external; // validatePool(_pid);

    function depositTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external; // validatePool(_pid);

    function deposit(uint256 _pid, uint256 _amount) external; // validatePool(_pid);

    function withdraw(uint256 _pid, uint256 _amount) external; // validatePool(_pid);

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external; // validatePool(_pid);

    function emergencyWithdraw(uint256 _pid) external;

    function setPendingMasterFoxV1Owner(address _pendingMasterFoxV1Owner) external;

    function acceptMasterFoxV1Ownership() external;

    function foxlayerPerSecond() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingFoxlayer(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function getPoolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            IRewarderV2 rewarder,
            uint256 lastRewardBlock,
            uint256 accFoxlayerPerShare,
            uint256 totalStaked,
            uint16 depositFeeBP
        );
}