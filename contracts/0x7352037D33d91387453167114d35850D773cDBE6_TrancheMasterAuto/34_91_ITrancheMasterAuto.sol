//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMasterAuto {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) external;

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested);

    function switchAuto(bool _auto) external;

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) external payable;

    function deposit(uint256 amount) external payable;

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256 amount) external;

    function stop() external;

    function setStaker(address _staker) external;

    function setStrategy(address _strategy) external;

    function withdrawFee(uint256 amount) external;

    function transferFeeToStaking(uint256 _amount, address _pool) external;

    function producedFee() external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 autoPrincipal,
            uint256 validPercent,
            uint256 apy,
            uint256 fee,
            uint256 autoValid,
            bool principalFee
        );

    function currency() external view returns (address);

    function staker() external view returns (address);

    function strategy() external view returns (address);

    function devAddress() external view returns (address);

    function userInfo(address account) external view returns (uint256, bool);

    function userInvest(address account, uint256 tid)
        external
        view
        returns (
            uint256 cycle,
            uint256 principal,
            bool rebalanced
        );

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 capital,
            uint256 validPercent,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}