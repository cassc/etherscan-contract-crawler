// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library DataType {
    // example: bytes4(keccak256("safeMint(address,uint256)"))
    uint256 internal constant ABI_IDX_BUY_SELECTOR = 0;
    // buy param example:
    // 0x00000000 - (address sender, uint256 tokenId),
    // 0x00000001 - (address sender, uint256 tokenId, uint256 quantity)
    // 0x00000002 - (address sourceAddress, address sender, uint256 tokenId)
    // 0x00000003 - (address sourceAddress, address sender, uint256 tokenId, uint256 quantity)
    uint256 internal constant ABI_IDX_BUY_PARAM_TABLE = 1;
    // example: bytes4(keccak256("setBaseURI(uint256)"))
    uint256 internal constant ABI_IDX_BASEURI_SELECTOR = 2;
    // setBaseURI param example:
    // 0x00000000 - (uint256 baseURI), default setBaseURI(uint256)
    uint256 internal constant ABI_IDX_BASEURI_PARAM_TABLE = 3;
    uint256 internal constant ABI_IDX_MAX = 4;
    // whiteListModel
    enum WhiteListModel {
        NONE, // 0 - No White List
        CHECK // 1 - Check address
    }

    // launchpad 1
    struct Launchpad {
        // id of launchpad
        bytes4 id;
        // target contract of 3rd project,
        address targetContract;
        // 0-buy abi, 1-buy param, 2-setBaseURI abi, 3-setBaseURI param
        bytes4[ABI_IDX_MAX] abiSelectorAndParam;
        // enable
        bool enable;
        // lock the launchpad param, can't change except owner
        bool lockParam;
        // admin to config this launchpad params
        address controllerAdmin;
        // receipts address
        address receipts;
        // launchpad rounds info detail
        LaunchpadRounds[] roundss;
        // launchpad nftType 0:721/ 1:1155
        uint256 nftType;
        // launchpad sourceAddress transfer use
        address sourceAddress;
    }

    // 1 launchpad have N rounds
    struct LaunchpadRounds {
        // price of normal user account, > 8888 * 10**18 means
        uint128 price;
        // start token id, most from 0
        uint128 startTokenId;
        // buy token
        address buyToken;
        // white list model
        WhiteListModel whiteListModel;
        // buy start time, seconds UTC±0
        uint32 saleStart;
        // buy end time, seconds UTC±0
        uint32 saleEnd;
        // whitelist start time, seconds UTC±0
        uint32 whiteListSaleStart;
        // perIdQuantity 721:1 , 1155:n
        uint32 perIdQuantity;
        // max supply of this rounds
        uint32 maxSupply;
        // current sale number, must from 0
        uint32 saleQuantity;
        // max buy qty per address
        uint32 maxBuyQtyPerAccount;
        // max buy num one tx
        uint32 maxBuyNumOnce;
        // next buy time till last buy, seconds
        uint32 buyInterval;
        // number can buy of whitelist
        uint32 whiteListBuyNum;
    }

    // stats info for buyer account
    struct AccountRoundsStats {
        // last buy seconds,
        uint32 lastBuyTime;
        // total buy num already
        uint32 totalBuyQty;
    }

    // status info for launchpad
    struct LaunchpadVar {
        // account<->rounds stats； key: roundsIdx(96) + address(160), use genRoundsAddressKey()
        mapping(uint256 => AccountRoundsStats) accountRoundsStats;
    }
}