// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";

interface ILSSVMPair {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function bondingCurve() external view returns (ICurve);

    function getAllHeldIds() external view returns (uint256[] memory);

    function delta() external view returns (uint128);

    function fee() external view returns (uint96);

    function nft() external view returns (IERC721);

    function spotPrice() external view returns (uint128);

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    function withdrawERC20(IERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;
}

interface ILSSVMPairETH is ILSSVMPair {
    function withdrawAllETH() external;
}