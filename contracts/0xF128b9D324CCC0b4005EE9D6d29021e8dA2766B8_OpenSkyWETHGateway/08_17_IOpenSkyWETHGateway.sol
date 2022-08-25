// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyWETHGateway {
    event AuthorizeLendingPoolWETH(address indexed operator);
    event AuthorizeLendingPoolNFT(address indexed operator, address[] nftAssets);
    event EmergencyTokenTransfer(address indexed operator, address indexed token, address indexed to, uint256 amount);
    event EmergencyEtherTransfer(address indexed operator, address indexed to, uint256 amount);

    event Deposit(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);
    event Withdraw(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);
    event Borrow(uint256 indexed reserveId, address indexed onBehalfOf, uint256 indexed loanId);
    event Repay(uint256 indexed loanId);
    event Extend(uint256 indexed loanId);

    event Received(address, uint256);

    function authorizeLendingPoolWETH() external;

    function authorizeLendingPoolNFT(address[] calldata nftAssets) external;

    function deposit(
        uint256 reserveId,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdraw(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf
    ) external;

    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external;

    function repay(uint256 loanId) external payable;

    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration
    ) external payable;

    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function emergencyEtherTransfer(address to, uint256 amount) external;
}