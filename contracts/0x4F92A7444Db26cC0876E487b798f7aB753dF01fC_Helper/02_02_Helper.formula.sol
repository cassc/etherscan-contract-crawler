// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "../EIP2771Recipient.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function WETH() external view returns (address);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IFactory {
    function router() external view returns (address);
    function poolExist(address) external view returns (bool);
    function tokenToPool(address, address) external view returns (address);
}

interface IExchange {
    function estimatePos(address, uint) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getCurrentPool() external view returns (uint, uint);
    function fee() external view returns (uint);
    function addTokenLiquidityWithLimit(uint amount0, uint amount1, uint minAmount0, uint minAmount1, address user) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract Helper is EIP2771Recipient {
    using SafeMath for uint256;

    string public constant version = "SingleSideHelper20221125";
    address public factory;
    address public router;
    address public withdraw;

    constructor(address _factory, address _router, address _withdraw, address _forwarder) public {
        require(_factory != address(0));
        require(_router != address(0));
        require(_withdraw != address(0));
        require(_forwarder != address(0));

        factory = _factory;
        router = _router;
        withdraw = _withdraw;
        _setTrustedForwarder(_forwarder);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3){
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) /2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getSwapAmt(address lp, address token, uint256 amtA) public view returns (uint maxSwap, uint estimateTarget) {
        IExchange pool = IExchange(lp);

        uint fee = pool.fee();
        require(fee < 10000);

        uint resA = 0;
        bool exist = false;
        if (token == pool.token0()) {
            exist = true;
            (resA, ) = pool.getCurrentPool();
        }
        if (token == pool.token1()) {
            exist = true;
            (, resA) = pool.getCurrentPool();
        }
        require(exist);

        uint addA = (20000 - fee).mul(20000 - fee).mul(resA);
        uint addB = (10000 - fee).mul(40000).mul(amtA);
        uint sqrtRes = sqrt(resA.mul(addA.add(addB)));
        uint subRes = resA.mul(20000 - fee);
        uint divRes = (10000 - fee).mul(2);

        maxSwap = (sqrtRes.sub(subRes)).div(divRes);
        estimateTarget = pool.estimatePos(token, maxSwap);
    }

    event AddLiquidityWithHelper(address user, address lp, address token, uint amount, address refundToken, uint refundAmount, uint liquidity);

    function addLiquidityWithETH(address lp, uint inputForLiquidity, uint targetForLiquidity) public payable {
        IRouter Router = IRouter(router);
        IExchange pool = IExchange(lp);
        address WETH = Router.WETH();

        require(IFactory(factory).poolExist(lp));
        require(pool.token0() == WETH);

        uint amount = msg.value;

        (uint maxSwap, ) = getSwapAmt(lp, WETH, amount);
        address target = pool.token1();

        uint balanceTarget = balanceOf(target);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = target;

        IWETH(WETH).deposit.value(msg.value)();
        approve(WETH, router, maxSwap);

        Router.swapExactTokensForTokens(maxSwap, 1, path, address(this), block.timestamp + 600);
        balanceTarget = (balanceOf(target)).sub(balanceTarget);

        uint inputRemained = (amount).sub(maxSwap);
        require(targetForLiquidity <= balanceTarget);
        require(inputForLiquidity <= inputRemained);

        addLiquidity(lp, inputRemained, balanceTarget, true, WETH, msg.value);
    }

    function addLiquidityWithToken(address lp, address token, uint amount, uint inputForLiquidity, uint targetForLiquidity) public {
        IExchange pool = IExchange(lp);

        require(IFactory(factory).poolExist(lp));
        require(token != address(0));

        require(IERC20(token).transferFrom(_msgSender(), address(this), amount));

        address token0 = pool.token0();
        address token1 = pool.token1();

        (uint maxSwap,) = getSwapAmt(lp, token, amount);
        address target = token == token0 ? token1 : token0;

        approve(token, router, maxSwap);

        uint balanceTarget = balanceOf(target);

        {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = target;

            IRouter(router).swapExactTokensForTokens(maxSwap, 1, path, address(this), block.timestamp + 600);
        }
        balanceTarget = (balanceOf(target)).sub(balanceTarget);

        uint inputRemained = (amount).sub(maxSwap);
        require(targetForLiquidity <= balanceTarget);
        require(inputForLiquidity <= inputRemained);

        if (token == token0) {
            addLiquidity(lp, inputRemained, balanceTarget, false, token, amount);
        } else {
            addLiquidity(lp, balanceTarget, inputRemained, false, token, amount);
        }
    }

    struct TokenDiffVar {
        address token0;
        address token1;
        uint diffA;
        uint diffB;
    }

    function addLiquidity(address lp, uint inputA, uint inputB, bool isETH, address token, uint amount) private {
        IExchange pool = IExchange(lp);

        TokenDiffVar memory p;

        p.token0 = pool.token0();
        p.token1 = pool.token1();

        p.diffA = balanceOf(p.token0);
        p.diffB = balanceOf(p.token1);

        approve(p.token0, lp, inputA);
        approve(p.token1, lp, inputB);

        pool.addTokenLiquidityWithLimit(inputA, inputB, 1, 1, address(this));

        p.diffA = (p.diffA).sub(balanceOf(p.token0));
        p.diffB = (p.diffB).sub(balanceOf(p.token1));

        uint liquidity = balanceOf(lp);
        transfer(lp, _msgSender(), liquidity);

        if (inputA > p.diffA) {
            if (isETH) {
                IWETH(IRouter(router).WETH()).withdraw(inputA.sub(p.diffA));
                (bool success, ) = _msgSender().call.value(inputA.sub(p.diffA))("");
                require(success, 'Helper: ETH transfer failed');
            } else {
                transfer(p.token0, _msgSender(), (inputA).sub(p.diffA));
            }

            emit AddLiquidityWithHelper(_msgSender(), lp, token, amount, p.token0, inputA.sub(p.diffA), liquidity);
        } else {
            transfer(p.token1, _msgSender(), (inputB).sub(p.diffB));

            emit AddLiquidityWithHelper(_msgSender(), lp, token, amount, p.token1, inputB.sub(p.diffB), liquidity);
        }

    }

    function balanceOf(address token) private view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function approve(address token, address spender, uint amount) private {
        require(IERC20(token).approve(spender, amount));
    }

    function transfer(address token, address to, uint amount) private {
        if (amount == 0) return;

        if (token == address(0)) {
            (bool success, ) = to.call.value(amount)("");
            require(success, "Transfer failed.");
        }
        else{
            require(IERC20(token).transfer(to, amount));
        }
    }

    function inCaseTokensGetStuck(address token) public {
        require(msg.sender == withdraw);

        transfer(token, withdraw, balanceOf(token));
    }

    function () external payable {}
}