// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ICerosRouter {
    /**
     * Events
     */

    event Deposit(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 profit
    );

    event Claim(
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    event Withdrawal(
        address indexed owner,
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    event ChangeVault(address vault);

    event ChangeDex(address dex);

    event ChangePool(address pool);

    event ChangeDao(address dao);

    event ChangeCeToken(address ceToken);

    event ChangeCeTokenJoin(address ceTokenJoin);

    event ChangeCertToken(address certToken);

    event ChangeCollateralToken(address collateralToken);

    event ChangeProvider(address provider);

    /**
     * Methods
     */

    /**
     * Deposit
     */

    // in BNB
    function deposit() external payable returns (uint256);

    // in aBNBc
    function depositABNBcFrom(address owner, uint256 amount)
    external
    returns (uint256);

    function depositABNBc(uint256 amount) external returns (uint256);

    /**
     * Claim
     */

    // claim in aBNBc
    function claim(address recipient) external returns (uint256);

    /**
     * Withdrawal
     */

    // BNB
    function withdraw(address recipient, uint256 amount)
    external
    returns (uint256);

    // BNB
    function withdrawFor(address recipient, uint256 amount)
    external
    returns (uint256);

    // BNB
    function withdrawWithSlippage(
        address recipient,
        uint256 amount,
        uint256 slippage
    ) external returns (uint256);

    // aBNBc
    function withdrawABNBc(address recipient, uint256 amount)
    external
    returns (uint256);
}