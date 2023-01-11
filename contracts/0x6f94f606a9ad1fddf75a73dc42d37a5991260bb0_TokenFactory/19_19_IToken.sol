//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IToken {
    struct TokenInfo {
        string name;
        string symbol;
        string description;
        address fundsRecipent;
        uint256 maxSupply;
    }

    error FactoryMustInitilize();
    error SenderNotMinter();
    error FundsSendFailure();
    error MaxSupplyReached();

    /// @notice returns the total supply of tokens
    function totalSupply() external returns (uint256);

    /// @notice withdraws the funds from the contract
    function withdraw() external returns (bool);

    /// @notice mint a token for the given address
    function safeMint(address to) external;

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external;

    /// @notice sets the minter status for the given user
    function setMinter(address user, bool isAllowed) external;
}