// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IConvexStakingWrapperFrax {
    struct EarnedData {
        address token;
        uint256 amount;
    }

    function earned(address _account)
        external
        view
        returns (EarnedData[] memory);

    function deposit(uint256 _amount, address _to) external;

    function withdrawAndUnwrap(uint256 _amount) external;

    function getReward(address _account) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address _spender, uint256 value) external returns (bool);
}