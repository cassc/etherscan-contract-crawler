// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IFundFilter} from "./IFundFilter.sol";
import {IPaymentGateway} from "./IPaymentGateway.sol";

interface IFundManager is IPaymentGateway {
    struct AccountCloseParams {
        address account;
        bytes[] paths;
    }

    function owner() external view returns (address);
    function fundFilter() external view returns (IFundFilter);

    function getAccountsCount(address) external view returns (uint256);
    function getAccounts(address) external view returns (address[] memory);

    function buyFund(address, uint256) external payable;
    function sellFund(address, uint256) external;
    function unwrapWETH9(address) external;

    function calcTotalValue(address account) external view returns (uint256 total);

    function lpTokensOfAccount(address account) external view returns (uint256[] memory);

    function provideAccountAllowance(
        address account,
        address token,
        address protocol,
        uint256 amount
    ) external;

    function executeOrder(
        address account,
        address protocol,
        bytes calldata data,
        uint256 value
    ) external returns (bytes memory);

    function onMint(
        address account,
        uint256 tokenId
    ) external;

    function onCollect(
        address account,
        uint256 tokenId
    ) external;

    function onIncrease(
        address account,
        uint256 tokenId
    ) external;

    // @dev Emit an event when new account is created
    // @param account The fund account address
    // @param initiator The initiator address
    // @param recipient The recipient address
    event AccountCreated(address indexed account, address indexed initiator, address indexed recipient);
}