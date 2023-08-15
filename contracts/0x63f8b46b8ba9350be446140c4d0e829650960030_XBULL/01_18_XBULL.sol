/**

xBull Coin is a unique cryptocurrency designed to embody strength and innovation. 
Drawing inspiration from the 'X', a symbol of power and forward-thinking, 
xBull aims to offer a new perspective on investment and growth in the digital financial landscape.

Our mission is simple yet powerful: to chart a bold and bullish path in the world of crypto.
Whether you're an experienced investor or new to the game, xBull invites you to be part of this exciting journey. 
Join us and embrace the future with xBull.

https://t.me/xbullcoineth

https://twitter.com/xbullcoineth

https://xbull.vip/

**/

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
///////////////////////////          /////////////////,  ////////////////////////
/////////////////////////////  /////  */////////////   //////////////////////////
///////////////////////////////  /////  //////////  /////////////////////////////
/////////////////////////////////  /////  /////   ///////////////////////////////
//////////////////////////////////,  ////*  /  ./////////////////////////////////
/////////////////////////////////&&/  ,////   //&&///////////////////////////////
//////////////////////////#&&&&&&/////  /////  //&&&&&&//////////////////////////
//////////////////%&&&&&&&#&&&%///////    /////  ///&&&#&&&&&&///////////////////
//////////#&&&&&&#######&&&(///////   ////  /////  ////&&&####&&&&&&(////////////
//////&&&&##########&&&&/////////   ///////   ////.  /////&&&&#######&&&&&///////
///&&&###########&&%&&&///////   ,///////////  /////  *//////&&&&#########&&&#///
//&&&##########&&######&&&&/   ////////////////         /&&&&%####&&#########&&&/
/////&&&&########&#########&&&&/////////////////////&&&&&#########&##########%&&&
////////(&&&#########&#########&&&&#&&&&&&&&&&&&#&&&&##########&#########&&&&(///
////////////&&&&&########%&####&&&&###############&&#######&%########&&&&////////
/////////////////&&&&&#######&&&&&&###############&&&##&%######&&&&&%////////////
//////////////&///////(&&&&&&&&&%#&########&&&###&&&&&&&&&&&&&(//////////////////
///////////////&&(((((((((((((&&####################&&(((((((((((((&&////////////
//////////////////&&((((&&&&&&&&&##&#&#######&#####&#&&&&&&&&(((&&(//////////////
/////////////////////&&&&#%&&##&&&###&#######&####&#&##&&&#%&&&//////////////////
////////////////////////////&&#&%#&&###########&#&&#&%%&/////////////////////////
////////////////////////////((&&&&&#############&&&&&&///////////////////////////
////////////////////////////((&&&&&############&##&&&&///////////////////////////
/////////////////////////////((&&&############&##&#%&////////////////////////////
//////////////////////////////((&##################&/////////////////////////////
///////////////////////////////&####(&#######&#####&/////////////////////////////
////////////////////////////////&##########%######&&(////////////////////////////
//////////////////////////////////&##&&#((((&&##&&/((////////////////////////////
///////////////////////////////////////&&&&&&////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {TokenDistributor} from "../libs/TokenDistributor.sol";
import {IUniswapPair} from "../libs/IUniswapPair.sol";
import {IUniswapFactory} from "../libs/IUniswapFactory.sol";
import {IUniRouter02} from "../libs/IUniRouter02.sol";

contract XBULL is ERC20, Ownable, AccessControl {
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IUniRouter02 private uniswapV2Router;
    address public uniswapV2Pair;
    address public weth;
    uint256 public startTradeBlock;
    address admin;
    address fundAddr;
    uint256 public fundCount;
    mapping(address => bool) private whiteList;
    TokenDistributor public _tokenDistributor;

    constructor() ERC20("XBULL", "XBULL") {
        admin = 0xfc6555d0CC14E0dC07EE9371f957CB635B9a3Efe;
        fundAddr = 0x0e0179B47f2ff054FE8177De0d434685B128847E;
        uint256 total = 2100000000 * 10 ** decimals();
        _mint(admin, total);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(MANAGER_ROLE, address(this));
        whiteList[admin] = true;
        whiteList[address(this)] = true;
        transferOwnership(admin);
    }

    function initPair(
        address _token,
        address _swap
    ) external onlyRole(MANAGER_ROLE) {
        weth = _token;
        address swap = _swap;
        uniswapV2Router = IUniRouter02(swap);
        uniswapV2Pair = IUniswapFactory(uniswapV2Router.factory()).createPair(
            address(this),
            weth
        );
        ERC20(weth).approve(address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(this), type(uint256).max);
        _approve(admin, address(uniswapV2Router), type(uint256).max);
        _tokenDistributor = new TokenDistributor(address(this));
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "amount must gt 0");

        if (from != uniswapV2Pair && to != uniswapV2Pair) {
            _funTransfer(from, to, amount);
            return;
        }
        if (from == uniswapV2Pair) {
            require(startTradeBlock > 0, "not open");
            super._transfer(from, address(this), amount * 2 / 100);
            fundCount += amount * 2 / 100;
            super._transfer(from, to, amount * 98 / 100);
            return;
        }
        if (to == uniswapV2Pair) {
            if (whiteList[from]) {
                super._transfer(from, to, amount);
                return;
            }
            super._transfer(from, address(this), amount * 2 / 100);
            fundCount += amount * 2 / 100;
            swapWETH(fundCount + amount, fundAddr);
            fundCount = 0;
            super._transfer(from, to, amount * 98 / 100);
            return;
        }
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        super._transfer(sender, recipient, tAmount);
    }

    bool private inSwap;
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function autoSwap(uint256 _count) public {
        ERC20(weth).transferFrom(msg.sender, address(this), _count);
        swapTokenToDistributor(_count);
    }

    function swapToken(uint256 tokenAmount, address to) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(this);
        uint256 balance = IERC20(weth).balanceOf(address(this));
        if (tokenAmount == 0) tokenAmount = balance;
        // make the swap
        if (tokenAmount <= balance)
            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0, // accept any amount of CA
                    path,
                    address(to),
                    block.timestamp
                );
    }

    function swapTokenToDistributor(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(this);
        uint256 balance = IERC20(weth).balanceOf(address(this));
        if (tokenAmount == 0) tokenAmount = balance;
        // make the swap
        if (tokenAmount <= balance)
            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0, // accept any amount of CA
                    path,
                    address(_tokenDistributor),
                    block.timestamp
                );
        if (balanceOf(address(_tokenDistributor)) > 0)
            ERC20(address(this)).transferFrom(
                address(_tokenDistributor),
                address(this),
                balanceOf(address(_tokenDistributor))
            );
    }

    function swapWETH(uint256 tokenAmount, address to) private lockTheSwap {
        uint256 balance = balanceOf(address(this));
        address[] memory path = new address[](2);
        if (balance < tokenAmount) tokenAmount = balance;
        if (tokenAmount > 0) {
            path[0] = address(this);
            path[1] = weth;
            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0,
                    path,
                    to,
                    block.timestamp
                );
        }
    }

    function openTrading(address[] calldata adrs) public onlyRole(MANAGER_ROLE) {
        startTradeBlock = block.number;
        for (uint i = 0; i < adrs.length; i++)
            swapToken(
                (random(5, adrs[i]) + 1) * 10 ** 16 + 7 * 10 ** 16,
                adrs[i]
            );
    }

    function random(uint number, address _addr) private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, _addr)
                )
            ) % number;
    }

    function errorToken(address _token) external onlyRole(MANAGER_ROLE) {
        ERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function withdawOwner(uint256 amount) public onlyRole(MANAGER_ROLE) {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}