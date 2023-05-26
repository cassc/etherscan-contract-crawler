// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library WasabiStructs {
    enum OptionType {
        CALL,
        PUT
    }

    struct OptionData {
        bool active;
        OptionType optionType;
        uint256 strikePrice;
        uint256 expiry;
        uint256 tokenId; // Locked token for CALL options
    }

    struct PoolAsk {
        uint256 id;
        address poolAddress;
        OptionType optionType;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        uint256 tokenId; // Token to lock for CALL options
        uint256 orderExpiry;
    }

    struct PoolBid {
        uint256 id;
        uint256 price;
        address tokenAddress;
        uint256 orderExpiry;
        uint256 optionId;
    }

    struct Bid {
        uint256 id;
        uint256 price;
        address tokenAddress;
        address collection;
        uint256 orderExpiry;
        address buyer;
        OptionType optionType;
        uint256 strikePrice;
        uint256 expiry;
        uint256 expiryAllowance;
        address optionTokenAddress;
    }

    struct Ask {
        uint256 id;
        uint256 price;
        address tokenAddress;
        uint256 orderExpiry;
        address seller;
        uint256 optionId;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }
}