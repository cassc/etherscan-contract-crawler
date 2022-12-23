// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IOneSplitWrap {
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) external view returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGasMulti(
        address[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        external
        view
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper
    ) external payable returns (uint256 returnAmount);

    function swapMulti(
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper
    ) external payable returns (uint256 returnAmount);
}