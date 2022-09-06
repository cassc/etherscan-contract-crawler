// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _claim
    ) external returns (uint256, uint256 _index);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit(uint256 _index) external;

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function claimAll(address _recipient) external returns (uint256);

    function pushClaim(address _to, uint256 _index) external;

    function pullClaim(address _from, uint256 _index) external returns (uint256 newIndex_);

    function pushClaimForBond(address _to, uint256 _index) external returns (uint256 newIndex_);

    function basis() external view returns (address);
}