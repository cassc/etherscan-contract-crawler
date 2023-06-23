// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//                                      /(((,
//                                     (((((((
//                                      ((((*
//                       ((/        .&&* ((( %&&         (((
//                      ((((((.  &&&& && ((/ && &&&&  *((((((
//                             (((*  & & ((/ &,&  ((((
//                                ((((   (((   ((((
//                   ,(##/         ((, ((((((( /((         /##(,
//               ##############    .(((((((((((((     ##############
//             ####,   *@@,   ###  ##  #######  ## ,###   /@&    /####
//            ###   @@@@@@@@@@  ### ############( ###  @@@@@@@@@@   ###
//            ##   @@#      #@@  ### ########### ###  @@*      @@@   ##
//            ###  @@.%@@@@@ #@(  ## ##########(,##  &@. @@@@@#*@@ .##
//              ##  @@@@@@@@@@@   #################   @@@@@@@@@@@  ##
//          (*#####(  @@@@@@   #######################   @@@@@@  #######*
//         ######  /####.  ###############################  .####, ,######
//        #      *################(    ,,,,,,,    #################       #
//         /##. . ###########    ,,.             ,,,    ###########   (##. .
//      #  ##  ,  ,####    .,,,          .,.         .,,,.   .####  ,,  ##  #
//      #  ##  .  ,,,,,,,,,      ,,,,,,      .,,,,,,      ,,,,,,,,,  , *##  #
//      #  /##. .,.        ,,,,,,.   /#########,   .,,,,,,        ,,  (##  *#
//      ###  ####    ,,,,,,     ### .###########  ###     ,,,,,,    ####  ###
//       ####    ####################/         (###################(    ####
//         ###############################################################
//           ##########################################################(
//              ####################################################/
//                  ############################################(
//                        #################################
//                                 ,############/.
//
// twitter:   twitter.com/fwogoeth
// site:      www.fwogo.vip
// telegram:  https://t.me/FWOGOKingdom

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract FwogoCoin is ERC20, Ownable {
    IUniswapV2Router02 private uniswapRouter;

    address public immutable uniswapV2Pair;
    address public teamWallet;
    uint256 public _totalSupply = 420_000_000_000 * 10**18; // 420 billions token


    constructor() ERC20("FwogoCoin", "$FWOGO") {
        // Set the router address
        uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create the token pair for this token and WETH
        uniswapV2Pair = IUniswapV2Factory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        teamWallet = address(0x73B8434eA85FC76909eA56a62C98B91992042bd5);
        uint256 teamAmount = (_totalSupply * 6) / 100;
        uint256 remainingAmount = _totalSupply - teamAmount;

        approve(address(uniswapRouter), type(uint256).max);

        _mint(teamWallet, teamAmount);
        _mint(msg.sender, remainingAmount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        external
        payable
    {
        require(msg.value == ethAmount, "Incorrect ETH amount");

        _approve(msg.sender, address(uniswapRouter), tokenAmount);

        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) external {
        _transfer(msg.sender, address(this), tokenAmount);
        _approve(address(this), address(uniswapRouter), tokenAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            msg.sender,
            block.timestamp
        );
    }
}