// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAlluoVault {
    event AdminChanged(address previousAdmin, address newAdmin);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event BeaconUpgraded(address indexed beacon);
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Initialized(uint8 version);
    event Paused(address account);
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Unpaused(address account);
    event Upgraded(address indexed implementation);
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    struct RewardData {
        address token;
        uint256 amount;
    }

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function UPGRADER_ROLE() external view returns (bytes32);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function alluoPool() external view returns (address);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (address);
    function accruedRewards (  ) external view returns ( RewardData[] memory);
    function shareholderAccruedRewards ( address shareholder ) external view returns ( RewardData[] memory, RewardData[] memory);

    function balanceOf(address account) external view returns (uint256);

    function changeUpgradeStatus(bool _status) external;

    function claimRewards() external;

    function claimRewardsFromPool() external;

    function convertToAssets(uint256 shares)
        external
        view
        returns (uint256 assets);

    function convertToShares(uint256 assets)
        external
        view
        returns (uint256 shares);

    function cvxBooster() external view returns (address);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _underlying,
        address _rewardToken,
        address _alluoPool,
        address _multiSigWallet,
        address _trustedForwarder,
        address[] memory _yieldTokens,
        uint256 _poolId
    ) external;

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function loopRewards() external;

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256);

    function name() external view returns (string memory);

    function pause() external;

    function paused() external view returns (bool);

    function poolId() external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function proxiableUUID() external view returns (bytes32);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function rewards(address) external view returns (uint256);

    function rewardsPerShareAccumulated() external view returns (uint256);

    function setPool(address _pool) external;

    function setTrustedForwarder(address newTrustedForwarder) external;

    function stakeUnderlying() external;

    function stakedBalanceOf() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function trustedForwarder() external view returns (address);

    function unpause() external;

    function upgradeStatus() external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;

    function userRewardPaid(address) external view returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);

    function claimAndConvertToPoolEntryToken(address entryToken) external returns (uint256);
}