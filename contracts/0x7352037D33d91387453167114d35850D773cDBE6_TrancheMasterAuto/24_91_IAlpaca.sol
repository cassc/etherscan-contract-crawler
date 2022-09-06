//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface Vault {
    function balanceOf(address account) external view returns (uint256);

    function nextPositionID() external view returns (uint256);

    function totalToken() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function deposit(uint256 amountToken) external payable;

    function withdraw(uint256 share) external;

    function work(
        uint256 id,
        address worker,
        uint256 principalAmount,
        uint256 loan,
        uint256 maxReturn,
        bytes memory data
    ) external payable;
}

interface FairLaunch {
    function deposit(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external; // staking

    function withdraw(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external; // unstaking

    function harvest(uint256 _pid) external;

    function pendingAlpaca(uint256 _pid, address _user) external returns (uint256);

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 bonusDebt,
            uint256 fundedBy
        );
}