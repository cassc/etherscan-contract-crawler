// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {DataTypes} from "../libraries/DataTypes.sol";
import {IApeCoinStaking} from "./IApeCoinStaking.sol";
import {IBNFT} from "./IBNFT.sol";

interface IStakeProxy {
    function initialize(
        address owner_,
        address bayc_,
        address mayc_,
        address bakc_,
        address apeCoin_,
        address apeCoinStaking_
    ) external;

    function bayc() external view returns (IERC721);

    function mayc() external view returns (IERC721);

    function bakc() external view returns (IERC721);

    function apeCoin() external view returns (IERC20);

    function apeStaking() external view returns (IApeCoinStaking);

    function version() external view returns (uint256);

    function poolId() external view returns (uint256);

    function apeStaked() external view returns (DataTypes.ApeStaked memory);

    function bakcStaked() external view returns (DataTypes.BakcStaked memory);

    function coinStaked() external view returns (DataTypes.CoinStaked memory);

    function unStaked() external view returns (bool);

    function claimable(address staker, uint256 fee) external view returns (uint256);

    function withdrawable(address staker) external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function unStake() external;

    function stake(
        DataTypes.ApeStaked memory ape,
        DataTypes.BakcStaked memory bakc,
        DataTypes.CoinStaked memory coin
    ) external;

    function claim(
        address staker,
        uint256 fee,
        address feeRecipient
    ) external returns (uint256, uint256);

    function withdraw(address staker) external returns (uint256);

    function migrateERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function migrateERC721(
        address token,
        address to,
        uint256 tokenId
    ) external;
}