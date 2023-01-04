// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../oracle/IOracle.sol";

interface IPigletWallet {
    struct TokenData {
        address token;
        uint256 balance;
    }

    function init(IOracle oracle) external;

    event TokenTransferError(address token, address recipient, string reason);

    event TokenTransfered(address token, address recipient, uint256 amount);

    event Destroyed(address wallet);

    function getBalanceInUSD() external view returns (uint256);

    function maxTokenTypes() external view returns (uint256);

    function listTokens() external view returns (TokenData[] memory);

    function destroy(address recipient) external;

    function registerDeposit(address token) external;

    function deposit(
        address token,
        address sender,
        uint256 amount
    ) external returns (bool);
}