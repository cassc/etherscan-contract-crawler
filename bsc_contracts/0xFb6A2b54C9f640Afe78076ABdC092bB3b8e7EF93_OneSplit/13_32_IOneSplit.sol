// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract IOneSplitConsts {
    // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
    uint256 internal constant FLAG_DISABLE_UNISWAP = 0x400;
    uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
    uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400;
    uint256 internal constant FLAG_DISABLE_EMPTY = 0x100000000000;

    uint256 internal constant FLAG_DISABLE_DFYN = 0x800;
    uint256 internal constant FLAG_DISABLE_PANCAKESWAP = 0x80;
    uint256 internal constant FLAG_DISABLE_QUICKSWAP = 0x40000000000;
    uint256 internal constant FLAG_DISABLE_SUSHISWAP = 0x1000000;
    uint256 internal constant FLAG_DISABLE_ONEINCH = 0x100000;
}

abstract contract IOneSplit is IOneSplitConsts {
    function getExpectedReturn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) public view virtual returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGasMulti(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        virtual
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGas(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        virtual
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function setHandlerAddress(address _handlerAddress) external virtual returns (bool);

    function setReserveAddress(address _reserveAddress) external virtual returns (bool);

    function setBridgeAddress(address _bridgeAddress) external virtual returns (bool);

    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public payable virtual returns (bool);

    function swap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper
    ) public payable virtual returns (uint256 returnAmount);

    function swapWithRecipient(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper,
        address recipient
    ) public payable virtual returns (uint256 returnAmount);

    function swapMulti(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper
    ) public payable virtual returns (uint256 returnAmount);

    function swapMultiWithRecipient(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper,
        address recipient
    ) public payable virtual returns (uint256 returnAmount);

    function getExpectedReturnETH(
        IERC20Upgradeable srcStablefromtoken,
        uint256 srcStableFromTokenAmount,
        uint256 parts,
        uint256 flags
    ) public view virtual returns (uint256 returnAmount);
}