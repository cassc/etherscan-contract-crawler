// SPDX-License-Identifier: BSD 3-Clause
/*
 * https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
 */
pragma solidity 0.6.11;

interface CTokenInterface {
    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function totalSupply() external returns (uint256);

    function isCToken() external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}