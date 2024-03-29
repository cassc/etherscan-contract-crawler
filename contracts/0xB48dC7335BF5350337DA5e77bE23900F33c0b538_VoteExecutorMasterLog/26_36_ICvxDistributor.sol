// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity ^0.8.11;

interface ICvxDistributor {
    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event CvxClaimed(uint256 amount, uint256 time, address indexed sender);
    event Initialized(uint8 version);
    event RewardAmountUpdated(uint256 amount, uint256 produced);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event StakeInfoReceived(
        uint256 amount,
        uint256 time,
        address indexed sender
    );
    event UnstakeInfoReceived(
        uint256 amount,
        uint256 time,
        address indexed sender
    );
    event Upgraded(address indexed implementation);

    function CRV_CVX_ETH() external view returns (address);

    function CRV_REWARDS() external view returns (address);

    function CURVE_CVX_ETH() external view returns (address);

    function CVX_REWARDS() external view returns (address);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DISTRIBUTION_TIME() external view returns (uint256);

    function PROTOCOL_ROLE() external view returns (bytes32);

    function UPGRADER_ROLE() external view returns (bytes32);

    function WETH() external view returns (address);

    function _stakers(
        address
    )
        external
        view
        returns (
            uint256 amount,
            uint256 rewardAllowed,
            uint256 rewardDebt,
            uint256 distributed
        );

    function accruedRewards()
        external
        view
        returns (
            IAlluoVaultInternal.RewardData[] memory,
            IAlluoVaultInternal.RewardData[] memory
        );

    function addCvxVault(address _alluoCvxVault) external;

    function addExchange(address _exchangeAddress) external;

    function addStrategyHandler(address _strategyHandler) external;

    function allProduced() external view returns (uint256);

    function alluoCvxVault() external view returns (address);

    function changeUpgradeStatus(bool _status) external;

    function claim(address user) external;

    function exchangeAddress() external view returns (address);

    function exchangePrimaryTokens() external;

    function getClaim(address _staker) external view returns (uint256 reward);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function initialize(
        address _multiSigWallet,
        address vlAlluo,
        address rewardTokenAddress,
        address _exchangeAddress
    ) external;

    function migrate() external;

    function multicall(
        address[] memory destinations,
        bytes[] memory calldatas
    ) external;

    function producedTime() external view returns (uint256);

    function proxiableUUID() external view returns (bytes32);

    function receiveStakeInfo(address user, uint256 _amount) external;

    function receiveUnstakeInfo(address user, uint256 _amount) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function rewardProduced() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewardTotal() external view returns (uint256);

    function rewards() external view returns (address);

    function stakerAccruedRewards(
        address _staker
    )
        external
        view
        returns (
            IAlluoVaultInternal.RewardData[] memory,
            IAlluoVaultInternal.RewardData[] memory
        );

    function strategyHandler() external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function tokensPerStake() external view returns (uint256);

    function totalDistributed() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function update() external;

    function updateReward(bool exchangePrimary, bool claimBooster) external;

    function upgradeStatus() external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable;

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external;
}

interface IAlluoVaultInternal {
    struct RewardData {
        address token;
        uint256 amount;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"CvxClaimed","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"version","type":"uint8"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"produced","type":"uint256"}],"name":"RewardAmountUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"previousAdminRole","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"newAdminRole","type":"bytes32"}],"name":"RoleAdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleGranted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleRevoked","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"StakeInfoReceived","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"UnstakeInfoReceived","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"inputs":[],"name":"CRV_CVX_ETH","outputs":[{"internalType":"contract IERC20MetadataUpgradeable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"CRV_REWARDS","outputs":[{"internalType":"contract IERC20MetadataUpgradeable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"CURVE_CVX_ETH","outputs":[{"internalType":"contract ICurveCVXETH","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"CVX_REWARDS","outputs":[{"internalType":"contract IERC20MetadataUpgradeable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DEFAULT_ADMIN_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DISTRIBUTION_TIME","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PROTOCOL_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"UPGRADER_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"WETH","outputs":[{"internalType":"contract IERC20MetadataUpgradeable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"_stakers","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"rewardAllowed","type":"uint256"},{"internalType":"uint256","name":"rewardDebt","type":"uint256"},{"internalType":"uint256","name":"distributed","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"accruedRewards","outputs":[{"components":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"internalType":"struct IAlluoVault.RewardData[]","name":"","type":"tuple[]"},{"components":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"internalType":"struct IAlluoVault.RewardData[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_alluoCvxVault","type":"address"}],"name":"addCvxVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_exchangeAddress","type":"address"}],"name":"addExchange","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategyHandler","type":"address"}],"name":"addStrategyHandler","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"allProduced","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"alluoCvxVault","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bool","name":"_status","type":"bool"}],"name":"changeUpgradeStatus","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"claim","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"exchangeAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"exchangePrimaryTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_staker","type":"address"}],"name":"getClaim","outputs":[{"internalType":"uint256","name":"reward","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"getRoleAdmin","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"grantRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"hasRole","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_multiSigWallet","type":"address"},{"internalType":"address","name":"vlAlluo","type":"address"},{"internalType":"address","name":"rewardTokenAddress","type":"address"},{"internalType":"address","name":"_exchangeAddress","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"migrate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"destinations","type":"address[]"},{"internalType":"bytes[]","name":"calldatas","type":"bytes[]"}],"name":"multicall","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"producedTime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proxiableUUID","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"receiveStakeInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"receiveUnstakeInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"renounceRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"revokeRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"rewardProduced","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewardToken","outputs":[{"internalType":"contract IERC20MetadataUpgradeable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewardTotal","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewards","outputs":[{"internalType":"contract ICvxBaseRewardPool","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_staker","type":"address"}],"name":"stakerAccruedRewards","outputs":[{"components":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"internalType":"struct IAlluoVault.RewardData[]","name":"","type":"tuple[]"},{"components":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"internalType":"struct IAlluoVault.RewardData[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"strategyHandler","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"tokensPerStake","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalDistributed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalStaked","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"update","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"exchangePrimary","type":"bool"},{"internalType":"bool","name":"claimBooster","type":"bool"}],"name":"updateReward","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"upgradeStatus","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"withdrawToken","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdrawTokens","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/