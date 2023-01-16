// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//// Do not define "state variables" in this contract！
contract Constants {
    //`constant`和`immutable`变量不占用存储槽，因此不会影响delegatecall时slot的读取
    // market id
    uint256 public constant SEAPORT_MARKET_ID = 0;
    uint256 public constant DEFAULT_MARKET_ID = 1;

    //market address(seaport looksrare x2y2 cryptopunk mooncat)
    address public constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;

    address public constant LOOKSRARE =
        0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address public constant LOOKSRARE_REWARDS_DISTRIBUTOR =
        0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72; // 领取LOOKS代币奖励
    address public constant LOOKSRARE_TOKEN =
        0xf4d2888d29D722226FafA5d9B24F9164c092421E; //LOOKS代币地址

    address public constant X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3; //单个购买时的market合约
    address public constant X2Y2_REWARDS_DISTRIBUTOR =
        0x897249FEf87Fa6D1E7FeDCB960c2A01Ec99ecC6C; // 领取X2Y2代币奖励
    address public constant X2Y2_TOKEN =
        0x1E4EDE388cbc9F4b5c79681B7f94d36a11ABEBC9; //X2Y2代币地址
    // address public constant X2Y2_BATCH =
    //     0x56Dd5bbEDE9BFDB10a2845c4D70d4a2950163044; // 批量购买时的market合约--参考用

    address public constant CRYPTOPUNK =
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    address public constant MOONCAT =
        0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;

    address public constant NFTX = 0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d;

    address public constant FOUNDATION =
        0xcDA72070E455bb31C7690a170224Ce43623d0B6f;

    address public constant SUDOSWAP =
        0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    address public constant NFT20 = 0xA42f6cADa809Bcf417DeefbdD69C5C5A909249C0;

    address public constant BLUR = 0x000000000000Ad05Ccc4F10045630fb830B95127;

    struct ERC20Detail {
        address tokenAddr;
        uint256 amount;
    }

    struct ERC721Detail {
        address tokenAddr;
        uint256 id;
    }

    struct ERC1155Detail {
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }

    enum ItemType {
        INVALID,
        NATIVE,
        ERC20,
        ERC721,
        ERC1155
    }
    struct OrderItem {
        ItemType itemType;
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }

    struct TradeInput {
        //单次调用某一market
        uint256 value; // 此次调用x2y2\looksrare\..需传递的主网币数量
        bytes inputData; //此次调用的input data
        OrderItem[] tokens; // 本次调用要购买的NFT信息,可能会有多个（例如捆绑销售时）
    }
    struct TradeDetail {
        //批量调用同一个market
        uint256 marketId;
        uint256 value;
        bytes tradeData; //包含多个TradeInput信息
    }
}