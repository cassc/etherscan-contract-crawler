// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {DefiOp} from "../DefiOp.sol";
import {Bridge} from "./Bridge.sol";
import {IStargate} from "../interfaces/external/IStargate.sol";

contract Stargate is Bridge, DefiOp {
    using SafeERC20 for IERC20;

    uint8 constant TYPE_SWAP_REMOTE = 1;

    IStargate public immutable stargate;

    constructor(IStargate stargate_) {
        stargate = stargate_;
    }

    /**
     * @notice Bridge ERC20 token to another chain
     * @dev This function bridge all token on balance to owner address
     * @param token ERC20 token address
     * @param slippage Max slippage, * 1M, eg. 0.5% -> 5000
     * @param chainId Destination chain id.
     */
    function useStargate(
        IERC20 token,
        uint32 slippage,
        uint64 chainId
    ) external payable checkChainId(chainId) onlyOwner {
        uint16 stargateChainId = getStargateChainId(chainId);
        IStargate.lzTxObj memory lzTxParams = IStargate.lzTxObj({
            dstGasForCall: 0,
            dstNativeAmount: 0,
            dstNativeAddr: abi.encodePacked(owner)
        });

        (uint256 lzFee, ) = stargate.quoteLayerZeroFee(
            stargateChainId,
            TYPE_SWAP_REMOTE,
            abi.encodePacked(owner),
            bytes(""),
            lzTxParams
        );

        {
            uint256 contractBalance = address(this).balance;
            if (contractBalance < lzFee) {
                revert NotEnougthNativeBalance(contractBalance, lzFee);
            }
        }

        uint256 tokenAmount = token.balanceOf(address(this));
        token.safeApprove(address(stargate), tokenAmount);
        stargate.swap{value: lzFee}(
            stargateChainId,
            getStargatePoolId(currentChainId(), address(token)),
            getStargatePoolId(currentChainId(), address(token)),
            payable(this),
            tokenAmount,
            (tokenAmount * (1e6 - slippage)) / 1e6,
            lzTxParams,
            abi.encodePacked(owner),
            bytes("")
        );
    }

    function getStargateChainId(uint64 chainId) public pure returns (uint16) {
        if (chainId == ETHEREUM_CHAIN_ID) return 101;
        if (chainId == BSC_CHAIN_ID) return 102;
        if (chainId == AVALANCHE_CHAIN_ID) return 106;
        if (chainId == POLYGON_CHAIN_ID) return 109;
        if (chainId == ARBITRUM_ONE_CHAIN_ID) return 110;
        if (chainId == OPTIMISM_CHAIN_ID) return 111;
        if (chainId == FANTOM_CHAIN_ID) return 112;
        revert UnsupportedDestinationChain(chainId);
    }

    function getStargatePoolId(uint64 chainId, address token)
        public
        pure
        returns (uint256)
    {
        if (chainId == ETHEREUM_CHAIN_ID) {
            if (token == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 1; // USDC
            if (token == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 2; // USDT
            if (token == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 3; // DAI
            if (token == 0x853d955aCEf822Db058eb8505911ED77F175b99e) return 7; // FRAX
            if (token == 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6) return 11; // USDD
            if (token == 0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c) return 13; // SGETH
            if (token == 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51) return 14; // sUSD
            if (token == 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0) return 15; // LUSD
            if (token == 0x8D6CeBD76f18E1558D4DB88138e2DeFB3909fAD6) return 16; // MAI
            revert UnsupportedToken();
        }
        if (chainId == BSC_CHAIN_ID) {
            if (token == 0x55d398326f99059fF775485246999027B3197955) return 2; // USDT
            if (token == 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) return 5; // BUSD
            if (token == 0xd17479997F34dd9156Deef8F95A52D81D265be9c) return 11; // USDD
            if (token == 0x3F56e0c36d275367b8C502090EDF38289b3dEa0d) return 16; // MAI
            revert UnsupportedToken();
        }
        if (chainId == AVALANCHE_CHAIN_ID) {
            if (token == 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E) return 1; // USDC
            if (token == 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7) return 2; // USDT
            if (token == 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64) return 7; // FRAX
            if (token == 0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b) return 16; // MAI
            revert UnsupportedToken();
        }
        if (chainId == POLYGON_CHAIN_ID) {
            if (token == 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174) return 1; // USDC
            if (token == 0xc2132D05D31c914a87C6611C10748AEb04B58e8F) return 2; // USDT
            if (token == 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063) return 3; // DAI
            if (token == 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1) return 16; // MAI
            revert UnsupportedToken();
        }
        if (chainId == ARBITRUM_ONE_CHAIN_ID) {
            if (token == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) return 1; // USDC
            if (token == 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9) return 2; // USDT
            if (token == 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F) return 7; // FRAX
            if (token == 0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0) return 13; // SGETH
            if (token == 0x3F56e0c36d275367b8C502090EDF38289b3dEa0d) return 16; // MAI
            revert UnsupportedToken();
        }
        if (chainId == OPTIMISM_CHAIN_ID) {
            if (token == 0x7F5c764cBc14f9669B88837ca1490cCa17c31607) return 1; // USDC
            if (token == 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1) return 3; // DAI
            if (token == 0x2E3D870790dC77A83DD1d18184Acc7439A53f475) return 7; // FRAX
            if (token == 0xb69c8CBCD90A39D8D3d3ccf0a3E968511C3856A0) return 13; // SGETH
            if (token == 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9) return 14; // sUSD
            if (token == 0xc40F949F8a4e094D1b49a23ea9241D289B7b2819) return 15; // LUSD
            if (token == 0xdFA46478F9e5EA86d57387849598dbFB2e964b02) return 16; // MAI
            revert UnsupportedToken();
        }
        if (chainId == FANTOM_CHAIN_ID) {
            if (token == 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75) return 1; // USDC
            revert UnsupportedToken();
        }
        revert UnsupportedDestinationChain(chainId);
    }
}