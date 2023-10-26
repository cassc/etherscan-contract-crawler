// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IAllowanceTransfer} from '../permit2/src/interfaces/IAllowanceTransfer.sol';
import {ERC20} from 'solmate/src/tokens/ERC20.sol';
import {IWETH9} from '../interfaces/external/IWETH9.sol';

struct RouterParameters {
    address permit2;
    address weth9;
    address seaportV1_5;
    address seaportV1_4;
    address openseaConduit;
    address nftxZap;
    address x2y2;
    address foundation;
    address sudoswap;
    address elementMarket;
    address nft20Zap;
    address cryptopunks;
    address looksRareV2;
    address routerRewardsDistributor;
    address looksRareRewardsDistributor;
    address looksRareToken;
    address v2Factory;
    address v3Factory;
    bytes32 pairInitCodeHash;
    bytes32 poolInitCodeHash;
}

/// @title Router Immutable Storage contract
/// @notice Used along with the `RouterParameters` struct for ease of cross-chain deployment
contract RouterImmutables {
    /// @dev WETH9 address
    IWETH9 internal WETH9;

    /// @dev Permit2 address
    IAllowanceTransfer internal PERMIT2;

    /// @dev Seaport 1.5 address
    address internal SEAPORT_V1_5;

    /// @dev Seaport 1.4 address
    address internal  SEAPORT_V1_4;

    /// @dev The address of OpenSea's conduit used in both Seaport 1.4 and Seaport 1.5
    address internal  OPENSEA_CONDUIT;

    /// @dev The address of NFTX zap contract for interfacing with vaults
    address internal  NFTX_ZAP;

    /// @dev The address of X2Y2
    address internal  X2Y2;

    // @dev The address of Foundation
    address internal  FOUNDATION;

    // @dev The address of Sudoswap's router
    address internal  SUDOSWAP;

    // @dev The address of Element Market
    address internal  ELEMENT_MARKET;

    // @dev the address of NFT20's zap contract
    address internal  NFT20_ZAP;

    // @dev the address of Larva Lab's cryptopunks marketplace
    address internal  CRYPTOPUNKS;

    /// @dev The address of LooksRareV2
    address internal  LOOKS_RARE_V2;

    /// @dev The address of LooksRare token
    ERC20 internal  LOOKS_RARE_TOKEN;

    /// @dev The address of LooksRare rewards distributor
    address internal  LOOKS_RARE_REWARDS_DISTRIBUTOR;

    /// @dev The address of router rewards distributor
    address internal  ROUTER_REWARDS_DISTRIBUTOR;

    /// @dev The address of UniswapV2Factory
    address internal  UNISWAP_V2_FACTORY;

    /// @dev The UniswapV2Pair initcodehash
    bytes32 internal  UNISWAP_V2_PAIR_INIT_CODE_HASH;

    /// @dev The address of UniswapV3Factory
    address internal  UNISWAP_V3_FACTORY;

    /// @dev The UniswapV3Pool initcodehash
    bytes32 internal  UNISWAP_V3_POOL_INIT_CODE_HASH;

    enum Spenders {
        OSConduit,
        Sudoswap
    }

    function setRouterImmutables() public{
        PERMIT2 = IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);
        WETH9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        SEAPORT_V1_5 = 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC;
        SEAPORT_V1_4 = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
        OPENSEA_CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;
        NFTX_ZAP = 0x941A6d105802CCCaa06DE58a13a6F49ebDCD481C;
        X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;
        FOUNDATION = 0xcDA72070E455bb31C7690a170224Ce43623d0B6f;
        SUDOSWAP = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
        ELEMENT_MARKET = 0x20F780A973856B93f63670377900C1d2a50a77c4;
        NFT20_ZAP = 0xA42f6cADa809Bcf417DeefbdD69C5C5A909249C0;
        CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
        LOOKS_RARE_V2 = 0x0000000000E655fAe4d56241588680F86E3b2377;
        LOOKS_RARE_TOKEN = ERC20(0xf4d2888d29D722226FafA5d9B24F9164c092421E);
        LOOKS_RARE_REWARDS_DISTRIBUTOR = 0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72;
        ROUTER_REWARDS_DISTRIBUTOR = 0xea37093ce161f090e443f304e1bF3a8f14D7bb40;
        UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        UNISWAP_V2_PAIR_INIT_CODE_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
        UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        UNISWAP_V3_POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    }
    // constructor(RouterParameters memory params) {
    //     PERMIT2 = IAllowanceTransfer(params.permit2);
    //     WETH9 = IWETH9(params.weth9);
    //     SEAPORT_V1_5 = params.seaportV1_5;
    //     SEAPORT_V1_4 = params.seaportV1_4;
    //     OPENSEA_CONDUIT = params.openseaConduit;
    //     NFTX_ZAP = params.nftxZap;
    //     X2Y2 = params.x2y2;
    //     FOUNDATION = params.foundation;
    //     SUDOSWAP = params.sudoswap;
    //     ELEMENT_MARKET = params.elementMarket;
    //     NFT20_ZAP = params.nft20Zap;
    //     CRYPTOPUNKS = params.cryptopunks;
    //     LOOKS_RARE_V2 = params.looksRareV2;
    //     LOOKS_RARE_TOKEN = ERC20(params.looksRareToken);
    //     LOOKS_RARE_REWARDS_DISTRIBUTOR = params.looksRareRewardsDistributor;
    //     ROUTER_REWARDS_DISTRIBUTOR = params.routerRewardsDistributor;
    //     UNISWAP_V2_FACTORY = params.v2Factory;
    //     UNISWAP_V2_PAIR_INIT_CODE_HASH = params.pairInitCodeHash;
    //     UNISWAP_V3_FACTORY = params.v3Factory;
    //     UNISWAP_V3_POOL_INIT_CODE_HASH = params.poolInitCodeHash;
    // }
}