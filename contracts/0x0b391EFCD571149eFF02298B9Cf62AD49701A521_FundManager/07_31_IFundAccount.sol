// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct Nav {
    // Net Asset Value, can't store as float
    uint256 totalValue;
    uint256 totalUnit;
}

struct LpAction {
    uint256 actionType; // 1. buy, 2. sell
    uint256 amount;
    uint256 unit;
    uint256 time;
    uint256 gain;
    uint256 loss;
    uint256 carry;
    uint256 dao;
}

struct LpDetail {
    uint256 totalAmount;
    uint256 totalUnit;
    LpAction[] lpActions;
}

struct FundCreateParams {
    string name;
    address gp;
    uint256 managementFee;
    uint256 carriedInterest;
    address underlyingToken;
    address initiator;
    uint256 initiatorAmount;
    address recipient;
    uint256 recipientMinAmount;
    address[] allowedProtocols;
    address[] allowedTokens;
}

interface IFundAccount {

    function since() external view returns (uint256);

    function closed() external view returns (uint256);

    function name() external view returns (string memory);

    function gp() external view returns (address);

    function managementFee() external view returns (uint256);

    function carriedInterest() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function ethBalance() external view returns (uint256);

    function initiator() external view returns (address);

    function initiatorAmount() external view returns (uint256);

    function recipient() external view returns (address);

    function recipientMinAmount() external view returns (uint256);

    function lpList() external view returns (address[] memory);

    function lpDetailInfo(address addr) external view returns (LpDetail memory);

    function allowedProtocols() external view returns (address[] memory);

    function allowedTokens() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function isTokenAllowed(address token) external view returns (bool);

    function totalUnit() external view returns (uint256);

    function totalManagementFeeAmount() external view returns (uint256);

    function lastUpdateManagementFeeAmount() external view returns (uint256);

    function totalCarryInterestAmount() external view returns (uint256);

    function initialize(FundCreateParams memory params) external;

    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function setTokenApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external;

    function execute(address target, bytes memory data, uint256 value) external returns (bytes memory);

    function buy(address lp, uint256 amount) external;

    function sell(address lp, uint256 ratio) external;

    function collect() external;

    function close() external;

    function updateName(string memory newName) external;

    function wrapWETH9() external;

    function unwrapWETH9() external;

}