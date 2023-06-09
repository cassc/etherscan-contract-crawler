// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "DEXBaseACL.sol";
import "ACLUtils.sol";
import "ParaswapUtils.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

// Authorizer For AugustusSwapper 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57
contract ParaswapBotAuthorizer is DEXBaseACL {
    bytes32 public constant NAME = "ParaswapBotAuthorizer";
    uint256 public constant VERSION = 1;

    // Paraswap treat 0xee.ee as ETH.
    uint256 private constant DIRECTION_FLAG = 0x0000000000000000000000010000000000000000000000000000000000000000;

    // Same address across multi chains.
    address public immutable ROUTER = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address public immutable WETH = getWrappedTokenAddress();

    constructor(address _owner, address _caller) DEXBaseACL(_owner, _caller) {}

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = ROUTER;
    }

    // Internal functions.

    function _checkBeneficiary(address to) internal view {
        require(to == address(0) || to == _txn().from, "Invalid beneficiary");
    }

    // ACL functions.

    // SimpleSwap https://etherscan.io/address/0x6e8b66CC92fCD7fE1332664182BEB1161DBFc82d#code

    // tx https://etherscan.io/tx/0x5307ce12e6252aaea5cd40b845bf0a10ecdfdb3849a5cf388c67e285379e54cf
    function simpleSwap(Utils.SimpleData calldata data) external view {
        _swapInOutTokenCheck(data.fromToken, data.toToken);
        _checkBeneficiary(data.beneficiary);
    }

    // tx https://etherscan.io/tx/0xafcdfda106f18a61339630f0475164dcb478bc7e1956c27a1013238f1a29b7ac
    function simpleBuy(Utils.SimpleData calldata data) external view {
        _swapInOutTokenCheck(data.fromToken, data.toToken);
        _checkBeneficiary(data.beneficiary);
    }

    // MultiPath https://etherscan.io/address/0xb41Ec6e014e2AD12Ae8514216EAb2592b74F19e7#code

    // tx https://etherscan.io/tx/0x931f1ace658a3b788f2954bf76d03fd75fa6ec0728e7f7994d84b16a7f10a4a0
    function multiSwap(Utils.SellData calldata data) external view {
        address fromToken = data.fromToken;
        Utils.Path[] memory path = data.path;
        address toToken = path[path.length - 1].to;
        _swapInOutTokenCheck(fromToken, toToken);
        _checkBeneficiary(data.beneficiary);
    }

    // tx https://etherscan.io/tx/0x3e0ab6db5ec3c8f05a80ddab6857d97b5c4154a37879564930004c462e949071
    function megaSwap(Utils.MegaSwapSellData calldata data) external view {
        address fromToken = data.fromToken;
        address toToken;
        Utils.MegaSwapPath[] calldata path = data.path;
        toToken = path[0].path[path[0].path.length - 1].to;
        _swapInOutTokenCheck(fromToken, toToken);
        _checkBeneficiary(data.beneficiary);
    }

    // NewUniswapV2Router https://etherscan.io/address/0x4FF0dEC5f9a763Aa1E5C2a962aa6f4eDFeE4f9eA#code

    // tx https://etherscan.io/tx/0xdeefd143100d096eb9402b2ff89764a4bf18a106d38dfe60b34ca7fd4159560a

    function swapOnUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    ) external view {
        _checkUniV2Fork(tokenIn, weth, pools);
    }

    // tx https://etherscan.io/tx/0x7b0c3f245834edbe867325dda781a1820e7dfe3a7a0f93e9704f0b7cf03808f3
    function buyOnUniswapV2Fork(
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut,
        address weth,
        uint256[] calldata pools
    ) external view {
        _checkUniV2Fork(tokenIn, weth, pools);
    }

    function _checkUniV2Fork(address tokenIn, address weth, uint256[] calldata pools) internal view {
        bool tokensBoughtEth;
        if (tokenIn == ETH_ADDRESS) {
            require(weth == WETH, "Invalid WETH");
        } else {
            require(weth == WETH || weth == address(0), "Invalid WETH");
            tokensBoughtEth = weth != address(0);
        }

        uint256 lastPool = pools[pools.length - 1];
        address lastPair = address(uint160(lastPool));
        bool direction = lastPool & DIRECTION_FLAG == 0;
        address tokenOut = direction ? IUniswapV2Pair(lastPair).token1() : IUniswapV2Pair(lastPair).token0();
        if (tokensBoughtEth) {
            require(tokenOut == WETH, "Invalid pool");
            tokenOut = ETH_ADDRESS;
        }
        _swapInOutTokenCheck(tokenIn, tokenOut);
    }
}