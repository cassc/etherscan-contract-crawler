// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IMediator.sol";

interface IVault {
    struct Beneficiary {
        address to;
        uint256 rate;
    }

    struct Deposit {
        address from;
        address token;
        uint256 amount;
    }

    function DIVIDER() external view returns (uint256);
    function depositIdToRecipient(uint256 id) external view returns (address, address, uint256);
    function beneficiariesList(uint256 offset, uint256 limit) external view returns (Beneficiary[] memory output);
    function beneficiariesLength() external view returns (uint256);
    function depositIds(uint256 index) external view returns (uint256);
    function depositIdsLength() external view returns (uint256);
    function depositIdsContains(uint256 id) external view returns (bool);
    function depositIdsList(uint256 offset, uint256 limit) external view returns (uint256[] memory output);
    function mediator() external view returns (IMediator);
    function paymentTokens(uint256 index) external view returns (address);
    function paymentTokensLength() external view returns (uint256);
    function paymentTokensContains(address token) external view returns (bool);
    function paymentTokensList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    event BeneficiariesListUpdated(Beneficiary[] beneficiaries);
    event Deposited(uint256 indexed id, Deposit data);
    event MediatorUpdated(address mediator);
    event PaymentTokenAdded(address indexed token);
    event PaymentTokenRemoved(address indexed token);
    event Withdrawal(address indexed token, address indexed to, uint256 share);

    function deposit(uint256 id, address token, uint256 amount) external payable;
    function depositWithTokenize(IMediator.ERC721Data memory data) external payable;
}