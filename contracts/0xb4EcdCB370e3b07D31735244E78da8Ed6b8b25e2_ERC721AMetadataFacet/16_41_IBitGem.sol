//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./IToken.sol";
import "./ITokenPrice.sol";
import "../libraries/UInt256Set.sol";

struct BitGemSettings {
    address owner;
    string symbol;
    string name;
    string description;
    string imageName;
    string externalUrl;
}

// contract storage for a bitgem contract
struct BitGemContract {
    address wrappedToken;
    // minted tokens
    uint256[] mintedTokens;
}

struct BitGemFactoryContract {
    mapping(string => address) _bitgems;
    string[] _bitgemSymbols;
    mapping(address => bool) allowedReporters;
    address wrappedToken_;
}

/// @notice check the balance of earnings and collect earnings
interface IBitGem {  
    function initialize(
        address _wrappedToken
    ) external;
    /// @notice get the member gems of this pool
    function settings() external view returns (BitGemSettings memory);
}