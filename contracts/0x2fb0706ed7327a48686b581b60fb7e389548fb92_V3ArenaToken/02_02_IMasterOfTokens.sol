// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMasterOfTokens {
    struct TokenDeployed {
        string ticker;
        uint256 blockNumber;
        uint256 decimals;
        uint256 initialLiq;
        address pairAddress;
        address tokenAddress;
        address refAddress;
        address taxWallet;
    }

    event NewToken(
        uint256 deploymentBlockNumber,
        uint256 initialLPValueETH,
        address liquidityPool,
        string symbol,
        uint256 decimals,
        address tokenAddress,
        address referral,
        address taxWallet
    );

    function nonce() external returns (uint256);
    function addNewToken(TokenDeployed memory _token) external returns (uint256);
    function getToken(uint256 _nonce) external view returns (TokenDeployed memory);
}