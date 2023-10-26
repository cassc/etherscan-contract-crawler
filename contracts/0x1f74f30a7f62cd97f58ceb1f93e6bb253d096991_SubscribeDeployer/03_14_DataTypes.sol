// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    enum Category {
        Essence,
        Content,
        W3ST,
        Subscribe
    }

    enum ContentType {
        Content,
        Comment,
        Share
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct RegisterEssenceParams {
        address account;
        string name;
        string symbol;
        string tokenURI;
        address mw;
        bool transferable;
    }

    struct RegisterSubscriptionParams {
        address account;
        string name;
        string symbol;
        string tokenURI;
        uint256 dayPerSub;
        uint256 pricePerSub;
        address recipient;
    }

    struct PublishContentParams {
        address account;
        string tokenURI;
        address mw;
        bool transferable;
    }

    struct ShareParams {
        address account;
        address accountShared;
        uint256 idShared;
    }

    struct InitParams {
        address soulAddr;
        address mwManagerAddr;
        address essImpl;
        address contentImpl;
        address w3stImpl;
        address subImpl;
        address adminAddr;
    }

    struct CommentParams {
        address account;
        string tokenURI;
        address mw;
        bool transferable;
        address accountCommented;
        uint256 idCommented;
    }

    struct IssueW3stParams {
        address account;
        string tokenURI;
        address mw;
        bool transferable;
    }

    struct EssenceStruct {
        address essence;
        address mw;
        string name;
        string symbol;
        string tokenURI;
        bool transferable;
    }

    struct SubscribeStruct {
        address subscribe;
        string name;
        string symbol;
        string tokenURI;
        uint256 dayPerSub;
        uint256 pricePerSub;
        address recipient;
    }

    struct AccountStruct {
        uint256 essenceCount;
        address w3st;
        uint256 w3stCount;
        address content;
        uint256 contentCount;
    }

    struct ContentStruct {
        address mw;
        string tokenURI;
        bool transferable;
        address srcAccount;
        uint256 srcId;
        ContentType contentType;
    }

    struct W3stStruct {
        address mw;
        string tokenURI;
        bool transferable;
    }

    struct CollectParams {
        address account;
        uint256 id;
        uint256 amount;
        address to;
        Category category;
    }

    struct MwParams {
        address account;
        Category category;
        uint256 id;
        uint256 amount;
        address from;
        address to;
        address referrerAccount;
        bytes data;
    }

    struct DeployParameters {
        address engine;
    }

    struct MetadataPair {
        string key;
        string value;
    }
}