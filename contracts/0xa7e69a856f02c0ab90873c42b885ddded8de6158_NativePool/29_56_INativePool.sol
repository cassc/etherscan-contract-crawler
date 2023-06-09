// SPDX-License-Identifier: GPL-3.0

import {Orders} from "../libraries/Order.sol";
pragma solidity ^0.8.0;

interface INativePool {
    struct Pair {
        uint256 fee;
        bool isExist;
        uint256 pricingModelId;
    }

    struct SwapParam {
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;
        Orders.Order _order;
        address recipient;
        bytes callback;
        uint256 pricingModelId;
    }

    function initialize(
        address _treasury,
        address _treasuryOwner,
        address _signer,
        address _pricingModelRegistry,
        address _router,
        uint256[] memory _fees,
        address[] memory _tokenAs,
        address[] memory _tokenBs,
        uint256[] memory _pricingModelIds,
        bool _isTreasuryContract,
        bool _isPublicTreasury
    ) external;

    function addSigner(address _signer) external;

    function removeSigner(address _signer) external;

    function swap(
        bytes memory _order,
        bytes calldata signature,
        uint256 flexibleAmount,
        address recipient,
        bytes calldata callback
    ) external returns (int256, int256);

    event Swap(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        uint256 fee,
        bytes16 quoteId
    );

    event UpdatePair(
        address indexed tokenA,
        address indexed tokenB,
        uint256 feeOld,
        uint256 feeNew,
        uint256 pricingModelIdOld,
        uint256 pricingModelIdNew
    );

    event RemovePair(
        address tokenA,
        address tokenB
    );


    event AddSigner(
        address signer
    );

    event RemoveSigner(
        address signer
    );

    event SetRouter(
        address router
    );

    event SetTreasury(
        address treasury
    );

    event SetTreasuryOwner(
        address treasuryOwner
    );

    error TokenArrayLengthExceedLimit(uint arrayLength);
}