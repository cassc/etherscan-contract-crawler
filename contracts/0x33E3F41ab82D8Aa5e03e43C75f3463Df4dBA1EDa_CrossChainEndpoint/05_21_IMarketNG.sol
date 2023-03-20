// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMarketNG {
    struct Settlement {
        uint256[] coupons;
        uint256 feeRate;
        uint256 royaltyRate;
        uint256 buyerCashbackRate;
        address feeAddress;
        address royaltyAddress;
    }

    struct TokenPair {
        address token; // token contract address
        uint256 tokenId; // token id (if applicable)
        uint256 amount; // token amount (if applicable)
        uint8 kind; // token kind (721/1151/mint)
        bytes mintData; // mint data (if applicable)
    }

    struct Intention {
        address user;
        TokenPair[] bundle;
        IERC20 currency;
        uint256 price;
        uint256 deadline;
        bytes32 salt;
        uint8 kind;
    }

    struct Detail {
        bytes32 intentionHash;
        address signer;
        uint256 txDeadline; // deadline for the transaction
        bytes32 salt;
        uint256 id; // inventory id
        uint8 opcode; // OP_*
        address caller;
        IERC20 currency;
        uint256 price;
        uint256 incentiveRate;
        Settlement settlement;
        TokenPair[] bundle;
        uint256 deadline; // deadline for buy offer
    }

    function run(
        Intention calldata intent,
        Detail calldata detail,
        bytes calldata sigIntent,
        bytes calldata sigDetail
    ) external payable;
}