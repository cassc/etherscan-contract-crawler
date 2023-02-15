// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFound is IERC20 {}

struct CoinVote {
    address payer;
    address minter;
    uint artId;
    uint amount;
}

struct MintCoin {
    address payer;
    address minter;
    uint coinId;
    uint amount;
}

struct ClaimCoin {
    address minter;
    uint coinId;
    uint amount;
}

struct CreateNote {
    address payer;
    address minter;
    address delegate;
    address payee;
    uint fund;
    uint amount;
    uint duration;
    string memo;
    bytes data;
}

struct Note {
    uint id;
    uint artId;
    uint coinId;
    uint fund;
    uint reward;
    uint expiresAt;
    uint createdAt;
    uint collectedAt;
    uint shares;
    uint principal;
    uint penalty;
    uint earnings;
    uint funding;
    uint duration;
    uint dailyBonus;
    address delegate;
    address payee;
    bool closed;
    string memo;
    bytes data;
}

struct WithdrawNote {
    address payee;
    uint noteId;
    uint target;
}

struct DelegateNote {
    uint noteId;
    address delegate;
    address payee;
    string memo;
}

interface IFoundBank is IERC721 {
    function money() external view returns (IFound);
    function tokenCount() external view returns (uint);

    function vote(CoinVote calldata params) external;
    function mint(MintCoin calldata params) external;
    function claim(ClaimCoin calldata params) external;
    function lock(uint coinId, uint amount) external;

    function deposit(CreateNote calldata params) external returns (uint);
    function withdraw(WithdrawNote calldata params) external;
    function delegate(DelegateNote calldata params) external;
    function close(uint noteId) external;
}