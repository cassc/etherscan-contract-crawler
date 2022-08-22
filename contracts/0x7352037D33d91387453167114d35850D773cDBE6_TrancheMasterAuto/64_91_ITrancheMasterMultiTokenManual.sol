//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ITrancheMasterMultiTokenManual {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function balanceOf(address account) external view returns (uint256[] memory, uint256[] memory);

    function investDirect(
        uint256 tid,
        uint256[] calldata amountsIn,
        uint256[] calldata amountsInvest
    ) external;

    function deposit(uint256[] calldata amountsIn) external;

    function invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256[] calldata amountOuts) external;

    function start(uint256[][] memory minLPs) external returns (bool);

    function stop(uint256[][] memory minBaseAmounts) external;

    function withdrawFee() external;

    function producedFee(address token) external view returns (uint256);

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
            uint256 apy,
            uint256 fee
        );

    function staker() external view returns (address);

    function devAddress() external view returns (address);

    function userInvest(
        address account,
        uint256 tid,
        address token
    ) external view returns (uint256);

    function trancheInvest(
        uint256 cycle,
        uint256 tid,
        address token
    ) external view returns (uint256);

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}