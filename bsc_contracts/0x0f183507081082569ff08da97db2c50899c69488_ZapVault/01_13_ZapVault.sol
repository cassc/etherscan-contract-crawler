// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
000000d:clooodxkxccloooolllllllloxdolcllllllllccllloolcoOOOkkdlccccclllldoc::cc::::cclllllccc:codoc::cc:::cccllldk000000
00000x;ckkxkkxdoloOOxddooooddkOkdoodxkkxdddddxk000xoodollllllcccloxkdllllcllllooddxxddoldkOOOkdooooxOkocccllooolc:ok0000
0000Oc;xd:;:oO00000d;,,,,,,,;;lk000Odc:;,;;,;:lxO0xc;;lkOOOO0kl;,:xx:,,cx00d;,,;;;;;;;,:xOdlxO0000000d:,,,,,,;;lxdc:dO00
0000x:lkl;,,:x0000Oo;;:c;;;;;,;oO0xl;,::;,',,;,;lk0Oo;;oO00kxl;,;lkOl,;:x00d;,;lddoooodxOOo;lO0000000d:,,,,,,,,;:dkl;oO0
0000l:dd:,;,;oO000Oo,;c;...,:;;lOkl;;:c,.....,;;;lk0Oo;;oOOo:;;:;:x0o;,cx00d;,:x000000000Oo;ck0000000x:;,;::;;;,;:oko;oO
000k:cxl;:c;,ck000Oo;,:,...;c;,lOd:,;:'.......;:;;o00Ol;:oo;,,::':k0o;,ck00x:,;coddooook0Oo;:x0000000x:,;loc:cc:;,:dOl;d
000d;od;;ldc;;oO00Ol;,::,,;::;;oOd;,;,........,c:,lO00x:,;,,;;;'.:kOo;;oO00x:,,;;;;,,,;d00d;;d0000000x:,;l;...,cc;;ckk:;
00Oc:oc,;;:c;,cx00Ol,,,;;;;,,;lk0d;,;,........'::,lk00Od;,,;:;,co;lkl,:d000d;,:okxoloodO00d;;d0000000kc,:c,....'cc;:d0o,
00x:cl;;c;'cc,;oO0kl,,;:ccc:cdO00d;,;;'.......':;;lO000Ol;;co::kOc:dc,:x000d;,:x0000000000d;;d0000000kc,;:'.....:l;;oOx,
0Ol:lc,;l:,ol;;lO0Oo;,:xOOOxoodk0x:,,;;.......,;,;oO0000d;;co:cOOc:o:,:x000o;,;dO000000000o;;d0000000k:,;:'.....,l:,lOx;
0k:co;,;llcl:,,ck00d;,clllolclooxxc,,,:;....',,,,:x00000d;;co:cO0l:l:,:x00Oo;,;:cllllllokOl,;d0000000x:,;:'.....,c:,ckk;
0o;ol;,,,,,,,,,:x00d:;::cxkOO00dllc,,,;c:,,,,;;;cxO0OO00d;;cl;cO0o:l:;:d00Oo;,,,,,,,,,,;dOl,:x0000000x:,::'.....'c:,ckk;
Occdc,,,,,,,;,,;dO0d:;c:o00000Oo:c:,,,,,,,,,;:lxOkocc:lkd:cll:lO0dcdkxxxxxxdoooolcccllldkOl,:d0000000x:,::'.....,c:,ckx;
x:ld:,;coodddl;;ck0d;;c:o00000Oc;c;,,;:lllclc:coocloxo:dOkxoccd00xlldxdoooooloxoccclcoO00kc,;:oxkkO00x:,:c'.....,c:,ckd;
o:do;,cdxxolooc,;oOd;;c:o00000k::xdooloOOkdlcoo::d000OlldolooxO000kdocoO000Oocc:oxkOd:oO0kc,,,;;;:lxOd:,cc'.....;c;;lOo,
clxc,;:;:ldxlll;,:xo;:lco00000Occkkxl::oolodkOl,:x0000kl:oO000000000kloO0000kl;ck000Oo:dkkdolc:;;,,ckd:,cl'....'c:,;oOl,
:dx:,:;;d00Ollxc:okdlxocx00000Oo:c:cldxl:d000Ol'lO00000dcx0000000000OodO00000kxk00000d::ccllloxxoc;ckd:,;cc,'';cc;,:xOc;
:xd;;cc;d00Oolxxk00xolcdO000000d;ck000OdoO0000kdk000000kxO00000000000OO00000000000000xc;oOOkxccoddoxOd:,,;::ccc:;,;lOO:;
ckd:cdl;d00OocccoxdclxO00000000x:l000000000000000000000000000000000000000000000000000Oc;x0000kdlllccdxl:;,;,,,,,,;cx0k::
cOdlddc:x000dclxocclk0000000000Odk000000000000000000000000000000000000000000000000000Odok000000000Odcdkxdc;;,,;,;cxO0k::
cOko:,;oO000kcoOkl:oO000000000000000000000000000000000000000000000000000000000000000000000000000000klcc:lllccclodk000k::
lxo::dO00000OkO0Oo;lO000000000000000000000000000000000000000000000000000000000000000000000000000000Ol::odlcllldO00O00Oc:
olcdO000000000000d;o0000000000000000000000000000000000000000000000000000000000000000000000000000000Oo;ck00OOOd:oxl:dOOcc
olx00000000000000Oxk00000000000000000000000000000000000000000000000000000000000000000000000000000000kxk000000Ol::c:ckkcl
old00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000kddkxldocx
lcdO00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000Oc:clO
ddk000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000Oo;:oO
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000kl,lO
*
* MIT License
* ===========
*
* Copyright (c) 2020 Me
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

interface IVault {
    // Transfer want tokens zap -> autoFarm ->
    function deposit(
        uint16 _pid,
        uint256 _wantAmt,
        address _to
    ) external;

    // Transfer want tokens autoFarm -> zap
    function withdraw(
        uint16 _pid,
        uint256 _wantAmt,
        address _to
    ) external;

    struct PoolInfo {
        address want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. PIXEL to distribute per block.
        uint256 lastRewardBlock; // Last block number that PIXEL distribution occurs.
        uint256 accPIXELPerShare; // Accumulated PIXEL per share, times 1e12. See below.
        address strat; // Strategy address that will auto compound want tokens
        uint16 depositFeeBP; // Deposit fee in basis points. Only for non vault farms/pools
        uint256 totalBoostedShares; // Represents the shares of the users, with according boosts.
    }

    // Vault pool info to get want address
    function poolInfo(uint16 _pid)
        external
        view
        returns (
            address want, // Address of the want token.
            uint256 allocPoint, // How many allocation points assigned to this pool. PIXEL to distribute per block.
            uint256 lastRewardBlock, // Last block number that PIXEL distribution occurs.
            uint256 accPIXELPerShare, // Accumulated PIXEL per share, times 1e12. See below.
            address strat, // Strategy address that will auto compound want tokens
            uint16 depositFeeBP, // Deposit fee in basis points. Only for non vault farms/pools
            uint256 totalBoostedShares // Represents the shares of the users, with according boosts.
        );
}

contract ZapVault is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant DSL = 0x72FEAC4C0887c12db21CEB161533Fd8467469e6b;
    address private constant SOUL = 0x67d012F731c23F0313CEA1186d0121779c77fcFE;
    // 0x094616f0bdfb0b526bd735bf66eca0ad254ca81f main:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address private constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
    address private constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;

    address public pixelFarm = 0x021EcE112FD0E64d344583F8463177DFE996E8E5;

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notFlip;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;
    uint256 _taxFactor = 999;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");

        setNotLp(CAKE);
        setNotLp(DSL);
        setNotLp(SOUL);
        setNotLp(WBNB);
        setNotLp(BUSD);
        setNotLp(USDT);
        setNotLp(DAI);
        setNotLp(USDC);
        setNotLp(VAI);
        setNotLp(BTCB);
        setNotLp(ETH);
    }

    receive() external payable {}

    /* ========== View Functions ========== */

    function isLp(address _address) public view returns (bool) {
        return !notFlip[_address];
    }

    function routePair(address _address) external view returns (address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */

    struct ZapIn {
        address _to;
        address _from;
        address _router;
        uint16 _pid;
        uint256 amount;
    }
    struct ZapInBnb {
        address _to;
        address _router;
        uint16 _pid;
    }
    struct ZapOut {
        address _from;
        address _router;
        uint16 _pid;
        uint256 amount;
    }

    function zapInToken(ZapIn memory a) external {
        IUniswapV2Router02 ROUTER = IUniswapV2Router02(a._router);
        IERC20(a._from).safeTransferFrom(msg.sender, address(this), a.amount);
        a.amount = IERC20(a._from).balanceOf(address(this));
        _approveTokenIfNeeded(a._from, ROUTER);

        if (isLp(a._to)) {
            IUniswapV2Pair pair = IUniswapV2Pair(a._to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (a._from == token0 || a._from == token1) {
                // swap half amount for other
                address other = a._from == token0 ? token1 : token0;
                _approveTokenIfNeeded(other, ROUTER);
                uint256 sellAmount = a.amount / 2;
                uint256 otherAmount = _swap(
                    a._from,
                    sellAmount,
                    other,
                    address(this),
                    ROUTER
                );

                uint256 _beforeZap = IERC20(a._to).balanceOf(address(this));

                ROUTER.addLiquidity(
                    a._from,
                    other,
                    a.amount - sellAmount,
                    otherAmount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
                uint256 _afterZap = IERC20(a._to).balanceOf(address(this));
                _approveTokenIfNeededVault(a._to);
                IVault(pixelFarm).deposit(
                    a._pid,
                    _afterZap - _beforeZap,
                    msg.sender
                );
            } else {
                uint256 bnbAmount = _swapTokenForBNB(
                    a._from,
                    a.amount,
                    address(this),
                    ROUTER
                );

                uint256 _beforeZap = IERC20(a._to).balanceOf(address(this));
                _swapBNBToFlip(a._to, bnbAmount, address(this), ROUTER);
                uint256 _afterZap = IERC20(a._to).balanceOf(address(this));
                _approveTokenIfNeededVault(a._to);
                IVault(pixelFarm).deposit(
                    a._pid,
                    _afterZap - _beforeZap,
                    msg.sender
                );
            }
        } else {
            _swap(a._from, a.amount, a._to, msg.sender, ROUTER);
        }
    }

    function zapIn(ZapInBnb memory a) external payable {
        IUniswapV2Router02 ROUTER = IUniswapV2Router02(a._router);

        uint256 _beforeZap = IERC20(a._to).balanceOf(address(this));
        uint256 taxedValue = (msg.value * (_taxFactor)) / (1000);
        _swapBNBToFlip(a._to, taxedValue, address(this), ROUTER);
        uint256 _afterZap = IERC20(a._to).balanceOf(address(this));
        _approveTokenIfNeededVault(a._to);
        IVault(pixelFarm).deposit(a._pid, _afterZap - _beforeZap, msg.sender);
    }

    function zapOut(ZapOut memory a) external {
        uint256 _beforeWithdraw = IERC20(a._from).balanceOf(address(this));
        IVault(pixelFarm).withdraw(a._pid, a.amount, msg.sender);
        a.amount = IERC20(a._from).balanceOf(address(this)) - _beforeWithdraw;
        IUniswapV2Router02 ROUTER = IUniswapV2Router02(a._router);
        _approveTokenIfNeeded(a._from, ROUTER);

        if (!isLp(a._from)) {
            _swapTokenForBNB(a._from, a.amount, msg.sender, ROUTER);
        } else {
            IUniswapV2Pair pair = IUniswapV2Pair(a._from);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WBNB || token1 == WBNB) {
                ROUTER.removeLiquidityETH(
                    token0 != WBNB ? token0 : token1,
                    a.amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            } else {
                ROUTER.removeLiquidity(
                    token0,
                    token1,
                    a.amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            }
        }
    }

    function getBalanceOfToken(address token) internal view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        return balance;
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token, IUniswapV2Router02 ROUTER)
        private
    {
        if (IERC20(token).allowance(address(this), address(ROUTER)) == 0) {
            IERC20(token).safeApprove(address(ROUTER), type(uint256).max);
        }
    }

    function _approveTokenIfNeededVault(address token) private {
        if (IERC20(token).allowance(address(this), pixelFarm) == 0) {
            IERC20(token).safeApprove(pixelFarm, type(uint256).max);
        }
    }

    function _swapBNBToFlip(
        address flip,
        uint256 amount,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private {
        if (!isLp(flip)) {
            _swapBNBForToken(flip, amount, receiver, ROUTER);
        } else {
            // flip
            IUniswapV2Pair pair = IUniswapV2Pair(flip);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WBNB || token1 == WBNB) {
                address token = token0 == WBNB ? token1 : token0;
                uint256 swapValue = amount / 2;
                uint256 tokenAmount = _swapBNBForToken(
                    token,
                    swapValue,
                    address(this),
                    ROUTER
                );

                _approveTokenIfNeeded(token, ROUTER);
                ROUTER.addLiquidityETH{value: amount - swapValue}(
                    token,
                    tokenAmount,
                    0,
                    0,
                    receiver,
                    block.timestamp
                );
            } else {
                uint256 swapValue = amount / 2;
                uint256 token0Amount = _swapBNBForToken(
                    token0,
                    swapValue,
                    address(this),
                    ROUTER
                );
                uint256 token1Amount = _swapBNBForToken(
                    token1,
                    amount - swapValue,
                    address(this),
                    ROUTER
                );

                _approveTokenIfNeeded(token0, ROUTER);
                _approveTokenIfNeeded(token1, ROUTER);
                ROUTER.addLiquidity(
                    token0,
                    token1,
                    token0Amount,
                    token1Amount,
                    0,
                    0,
                    receiver,
                    block.timestamp
                );
            }
        }
    }

    function _swapBNBForToken(
        address token,
        uint256 value,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private returns (uint256) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WBNB;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WBNB;
            path[1] = token;
        }
        uint256 _beforeSwap = IERC20(token).balanceOf(address(this));
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: value}(
            0,
            path,
            receiver,
            block.timestamp
        );
        uint256 _afterSwap = IERC20(token).balanceOf(address(this));
        uint256 amounts = _afterSwap - _beforeSwap;
        return amounts;
    }

    function _swapTokenForBNB(
        address token,
        uint256 amount,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private returns (uint256) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WBNB;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WBNB;
        }
        uint256 _beforeSwap = IERC20(WBNB).balanceOf(address(this));

        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            receiver,
            block.timestamp
        );
        uint256 _afterSwap = IERC20(WBNB).balanceOf(address(this));
        uint256 amounts = _afterSwap - _beforeSwap;
        return amounts;
    }

    function _swap(
        address _from,
        uint256 amount,
        address _to,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private returns (uint256) {
        address intermediate = routePairAddresses[_from];
        if (intermediate == address(0)) {
            intermediate = routePairAddresses[_to];
        }

        address[] memory path;
        if (intermediate != address(0) && (_from == WBNB || _to == WBNB)) {
            // [WBNB, BUSD, VAI] or [VAI, BUSD, WBNB]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (
            intermediate != address(0) &&
            (_from == intermediate || _to == intermediate)
        ) {
            // [VAI, BUSD] or [BUSD, VAI]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (
            intermediate != address(0) &&
            routePairAddresses[_from] == routePairAddresses[_to]
        ) {
            // [VAI, DAI] or [VAI, USDC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (
            routePairAddresses[_from] != address(0) &&
            routePairAddresses[_to] != address(0) &&
            routePairAddresses[_from] != routePairAddresses[_to]
        ) {
            // routePairAddresses[xToken] = xRoute
            // [VAI, BUSD, WBNB, xRoute, xToken]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WBNB;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (
            intermediate != address(0) &&
            routePairAddresses[_from] != address(0)
        ) {
            // [VAI, BUSD, WBNB, DSL]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WBNB;
            path[3] = _to;
        } else if (
            intermediate != address(0) && routePairAddresses[_to] != address(0)
        ) {
            // [DSL, WBNB, BUSD, VAI]
            path = new address[](4);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WBNB || _to == WBNB) {
            // [WBNB, DSL] or [DSL, WBNB]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [USDT, DSL] or [DSL, USDT]
            path = new address[](3);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = _to;
        }
        uint256 _beforeSwap = IERC20(_to).balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            receiver,
            block.timestamp
        );
        uint256 _afterSwap = IERC20(_to).balanceOf(address(this));
        uint256 amounts = _afterSwap - _beforeSwap;

        return amounts;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route)
        external
        onlyOwner
    {
        routePairAddresses[asset] = route;
    }

    // TODO: move to constructor
    function setFarmAddress(address _farm) external onlyOwner {
        pixelFarm = _farm;
    }

    function setNotLp(address token) public onlyOwner {
        bool needPush = notFlip[token] == false;
        notFlip[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    /*     function removeToken(uint256 i) external onlyOwner {
        address token = tokens[i];
        notFlip[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep(address _router) external onlyOwner {
        IUniswapV2Router02 ROUTER = IUniswapV2Router02(_router);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForBNB(token, amount, owner(), ROUTER);
            }
        }
    } */
    /* 
    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(token).safeTransfer(
            owner(),
            IERC20(token).balanceOf(address(this))
        );
    } */
}