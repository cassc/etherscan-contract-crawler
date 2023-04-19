// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRouter {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);

    function factory() external pure returns (address);
}

interface IFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IWKDRaffleTopCadre {
    function totals()
        external
        view
        returns (
            uint256 kimoyo,
            uint256 doramilaje,
            uint256 taifaNagao,
            uint negus
        );

    function getPendingFor(
        address account,
        uint256 tokenId
    ) external view returns (uint256);

    function onTransferHook(address account, uint256[] calldata ids) external;

    // function setDeprecated(bool deprecatedStatus) external;

    function version() external view returns (string memory);

    function claim(uint256 id) external;
}


interface IWKDNFT {
    function totalSupply(uint256) external view returns (uint256);

    function balanceOf(address, uint256) external view returns (uint256);

    function KIMOYO() external view returns (uint256);

    function DORA_MILAJ_E() external view returns (uint256);

    function TAIFA_NAGA_O() external view returns (uint256);

    function NEGUS() external view returns (uint256);
}

interface ITopCadre {
    function onTransferHook(
        address account,
        uint256[] calldata tokenIds
    ) external;
}