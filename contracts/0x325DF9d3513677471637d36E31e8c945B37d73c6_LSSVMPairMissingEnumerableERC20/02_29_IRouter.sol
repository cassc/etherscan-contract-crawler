// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";

interface IRouter {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20_IN_SUDO
    }

    function pairTransferNFTFrom(
        IERC721 nft,
        address _rc,
        address _ar,
        uint256 ids,
        PairVariant pairVariant
    ) external;

    function pairTransferERC20From(
        ERC20 _token,
        address routerCaller,
        address _assetRecipient,
        uint256 inputAmount,
        PairVariant pairVariant
    ) external;
}