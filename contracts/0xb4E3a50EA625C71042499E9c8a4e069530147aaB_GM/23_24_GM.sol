//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@layerzerolabs/solidity-examples/contracts/token/oft/OFT.sol";

import "hardhat/console.sol";

// Telegram: https://t.me/guardiansofthememes
// Website: https://www.guardians-of-the-memes.xyz/
// Twitter: https://twitter.com/gotmCoinETH
//
//
//
//            ,.-·^*ª'` ·,            ,·'´¨;.  '
//         .·´ ,·'´:¯'`·,  '\‘         ;   ';:\           .·´¨';\
//       ,´  ,'\:::::::::\,.·\'       ;     ';:'\      .'´     ;:'\
//      /   /:::\;·'´¯'`·;\:::\°     ;   ,  '·:;  .·´,.´';  ,'::;'
//     ;   ;:::;'          '\;:·´    ;   ;'`.    ¨,.·´::;'  ;:::;
//    ';   ;::/      ,·´¯';  °      ;  ';::; \*´\:::::;  ,':::;‘
//    ';   '·;'   ,.·´,    ;'\       ';  ,'::;   \::\;:·';  ;:::; '
//    \'·.    `'´,.·:´';   ;::\'     ;  ';::;     '*´  ;',·':::;‘
//     '\::\¯::::::::';   ;::'; ‘   \´¨\::;          \¨\::::;
//       `·:\:::;:·´';.·´\::;'       '\::\;            \:\;·'
//           ¯      \::::\;'‚         '´¨               ¨'
//                    '\:·´'
//
//
//
contract GM is OFT {
    // ===================================
    // ERROR DEFINITIONS
    // ===================================
    error TradingNotOpen();
    error TradingAlreadyOpen();
    error TransferLimitReach();
    error BalancesNotExisting();

    // ===================================
    // CONSTANTS and IMMUTABLES
    // ===================================
    uint16 public constant BASIS_POINTS = 10000;

    // ===================================
    // STORAGE
    // ===================================
    IUniswapV2Router02 public router;
    address public routerAddress;
    address public pairAddress;
    address public marketingAddress;
    address public airdropAddress;
    address public wethAddress;

    bool public tradingOpen = false;
    bool public skipChecks = false;

    uint256 public tradingOpenedAtBlock = 0;
    uint256 public limitedBlocks = 5;
    mapping(address => uint256) private holderLastTransferTimestamp;

    // ===================================
    // CONSTRUCTOR
    // ===================================
    constructor(
        address _lzEndpoint,
        address _routerAddress,
        address _marketingAddress,
        address _airdropAddress,
        address _wethAddress
    ) OFT("Guardians", "GM", _lzEndpoint) {
        router = IUniswapV2Router02(_routerAddress);
        routerAddress = _routerAddress;
        marketingAddress = _marketingAddress;
        airdropAddress = _airdropAddress;
        wethAddress = _wethAddress;

        pairAddress = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _approve(address(this), routerAddress, type(uint256).max);
        _approve(address(this), pairAddress, type(uint256).max);

        // contract tokens for liquidity 80%
        _mint(address(this), 336_552_000_000_000 ether);
        // liquidity providers tokens sent to deployer 10%
        _mint(msg.sender, 42_069_000_000_000 ether);
        // marketing tokens 7%
        _mint(marketingAddress, 29_448_300_000_000 ether);
        // airdrop tokens 3%
        _mint(airdropAddress, 12_620_700_000_000 ether);
    }

    // ===================================
    // SETTERS (owner only)
    // ===================================
    function setSkipChecks(bool _skipChecks) external onlyOwner {
        skipChecks = _skipChecks;
    }

    // ===================================
    // OPERATIONAL
    // ===================================

    function blockDiffFromTradingOpen() public view returns (uint256) {
        return block.number - tradingOpenedAtBlock;
    }

    function calculateMaxTxAmount() public view returns (uint256) {
        uint256 percentageIncrease = 50 + (5 * (blockDiffFromTradingOpen()));
        return ((totalSupply() * percentageIncrease) / BASIS_POINTS);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (skipChecks) {
            super._transfer(from, to, amount);
            return;
        }

        if (
            from == owner() ||
            to == owner() ||
            from == address(this) ||
            to == address(this)
        ) {
            super._transfer(from, to, amount);
            return;
        }

        if (!tradingOpen) {
            revert TradingNotOpen();
        }

        // limit transfers to 1 per block
        // gradually increasing the max tx amount
        // txs will be will be more gas intensive during the first blocks
        if (blockDiffFromTradingOpen() < limitedBlocks) {
            if (to != routerAddress && to != pairAddress) {
                if (
                    holderLastTransferTimestamp[tx.origin] + 1 ==
                    block.number ||
                    holderLastTransferTimestamp[msg.sender] + 1 == block.number
                ) {
                    revert TransferLimitReach();
                }

                holderLastTransferTimestamp[tx.origin] = block.number;
                holderLastTransferTimestamp[msg.sender] = block.number;
            }

            if (calculateMaxTxAmount() < amount) {
                revert TransferLimitReach();
            }
        }

        super._transfer(from, to, amount);
    }

    function openTrading() external onlyOwner {
        if (tradingOpen) {
            revert TradingAlreadyOpen();
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractETHBalance = address(this).balance;

        if (contractTokenBalance == 0 || contractETHBalance == 0) {
            revert BalancesNotExisting();
        }

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        tradingOpen = true;
        tradingOpenedAtBlock = block.number;
    }

    // ===================================
    // ESCAPE functionalities
    // ===================================
    function escapeETH() public onlyOwner returns (bool) {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        return success;
    }

    receive() external payable {}
}