//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import {
    ERC20BurnMiningV1 as _ERC20BurnMiningV1
} from "../../../core/emission/pools/ERC20BurnMiningV1.sol";
import {
    ERC20StakeMiningV1 as _ERC20StakeMiningV1
} from "../../../core/emission/pools/ERC20StakeMiningV1.sol";
import {
    ERC721StakeMiningV1 as _ERC721StakeMiningV1
} from "../../../core/emission/pools/ERC721StakeMiningV1.sol";
import {
    ERC1155StakeMiningV1 as _ERC1155StakeMiningV1
} from "../../../core/emission/pools/ERC1155StakeMiningV1.sol";
import {
    ERC1155BurnMiningV1 as _ERC1155BurnMiningV1
} from "../../../core/emission/pools/ERC1155BurnMiningV1.sol";
import {
    InitialContributorShare as _InitialContributorShare
} from "../../../core/emission/pools/InitialContributorShare.sol";

library PoolType {
    bytes4 public constant ERC20BurnMiningV1 =
        _ERC20BurnMiningV1(0).erc20BurnMiningV1.selector;
    bytes4 public constant ERC20StakeMiningV1 =
        _ERC20StakeMiningV1(0).erc20StakeMiningV1.selector;
    bytes4 public constant ERC721StakeMiningV1 =
        _ERC721StakeMiningV1(0).erc721StakeMiningV1.selector;
    bytes4 public constant ERC1155StakeMiningV1 =
        _ERC1155StakeMiningV1(0).erc1155StakeMiningV1.selector;
    bytes4 public constant ERC1155BurnMiningV1 =
        _ERC1155BurnMiningV1(0).erc1155BurnMiningV1.selector;
    bytes4 public constant InitialContributorShare =
        _InitialContributorShare(0).initialContributorShare.selector;
}