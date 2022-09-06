pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

/**
    La mitad no va ser WPE sino ETH
    Hay que agregar un tercer lugar a donde se va la lana que es un DAO
    Del 80% > 30% se va a la tesorería > 20% honeyopts > 30% al nuevo DAO
 */

interface swapRouterInterface {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;
}

contract HoneyToLPControl is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IUniswapV2Pair;

    IUniswapV2Pair public lpToken;
    swapRouterInterface swapRouter =
        swapRouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public firstToken;
    IERC20 public secondToken;
    IERC721 public nftToken;

    uint128 public bp = 1000;

    struct lpReciever {
        address receiver;
        uint256 weight;
    }
    uint256 public totalWeight;
    address public treasury;
    address public lockUp;

    uint256 public permaLockPeriod;
    bool public permaLock = false;

    bool public paused;
    lpReciever[] _list;

    constructor(
        IERC20 _firstToken,
        IERC20 _secondToken,
        IERC721 _nftToken,
        address[] memory _addresses,
        uint256[] memory _weights, 
        uint256 _permaLockPeriod
    ) public {
        firstToken = _firstToken;
        secondToken = _secondToken;
        nftToken = _nftToken;
        permaLockPeriod = _permaLockPeriod * 1 days;

        _firstToken.safeApprove(address(swapRouter), 2**256 - 1);
        _secondToken.safeApprove(address(swapRouter), 2**256 - 1);

        uint256 _totalWeight = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            _list.push(lpReciever(_addresses[i], _weights[i]));
            _totalWeight += _weights[i];
        }
        totalWeight = _totalWeight;
    }

    function beeHolder() public view returns (bool) {
        if (nftToken.balanceOf(msg.sender) > 0) {
            return true;
        } else {
            return false;
        }
    }


    function setPause(bool _value) external onlyOwner {
        paused = _value;
    }

    function run() external {
        require(!permaLock, "LOCKED");
        require(!paused, "Paused contract");
        require(beeHolder(), "not a Bee Holder");

        uint256 honeyAmount = firstToken.balanceOf(address(this)); //rateCalculation();
        console.log("firstToken", address(firstToken));
        console.log("honeyAmount", honeyAmount);

        //createLPToken
        (
            uint256 atokenCreate,
            uint256 btokenCreate,
            uint256 lpCreate
        ) = createLPToken(honeyAmount);

        uint256 lpAmount = lpToken.balanceOf(address(this));

        //send reward
        for (uint256 i = 0; i < _list.length; i++) {
            uint256 sendAmount = (lpAmount * _list[i].weight) / totalWeight;
            IERC20(address(lpToken)).safeTransfer(
                _list[i].receiver,
                sendAmount
            );
        }
    }

    function deconstructLPToken(uint256 amount)
        internal
        returns (uint256 atoken, uint256 btoken)
    {
        (atoken, btoken) = swapRouter.removeLiquidity(
            address(firstToken),
            address(secondToken),
            amount,
            0,
            0,
            address(this),
            block.timestamp + 100
        );
    }

    function createLPToken(uint256 tokenIn)
        internal
        returns (
            uint256 atoken,
            uint256 btoken,
            uint256 liquidity
        )
    {
        uint256 halfToken = tokenIn / 2;
        uint256 amountToSecondToken = tokenIn - halfToken;

        address[] memory pathSecondToken = new address[](2);
        pathSecondToken[0] = address(firstToken);
        pathSecondToken[1] = address(secondToken);

        (uint256 r0, uint256 r1, uint32 ts) = lpToken.getReserves();
        (r0, r1) = address(firstToken) == lpToken.token0()
            ? (r0, r1)
            : (r1, r0);

        uint256 amountOut = getAmountOut(amountToSecondToken, r0, r1);
        uint256 percent = (amountOut * bp) / 10000;
        amountOut = amountOut - percent;

        console.log("amountOut0", amountOut);

        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSecondToken,
            amountOut,
            pathSecondToken,
            address(this),
            block.timestamp + 100
        );


        uint256 tokensBought = secondToken.balanceOf(address(this));
        console.log("tokensBought", tokensBought);

        (atoken, btoken, liquidity) = swapRouter.addLiquidity(
            address(firstToken),
            address(secondToken),
            halfToken,
            tokensBought,
            0,
            0,
            address(this),
            block.timestamp + 100
        );

        console.log("atoken", atoken);
        console.log("btoken", atoken);
        console.log("liquidity", liquidity);
        if (atoken < tokenIn) {
            firstToken.safeTransfer(msg.sender, halfToken - atoken);
        }
        if (btoken < tokensBought) {
            secondToken.safeTransfer(msg.sender, tokensBought - btoken);
        }
    }

    function setTokens() external onlyOwner {
        IERC20 temp0 = firstToken;
        IERC20 temp1 = secondToken;
        firstToken = temp1;
        secondToken = temp0;
    }

    function setPermaLock() external onlyOwner {
        require(block.timestamp < permaLockPeriod, "Time lock in place");
        permaLock = true;
    }

    function setBp(uint128 _amount) external onlyOwner {
        bp = _amount;
    }

    function migrationFailsafe(address _escrow) external onlyOwner {
        require(block.timestamp < permaLockPeriod, "Time lock in place");
        require(!permaLock, "LOCKED");
        IERC20(address(lpToken)).safeTransfer(
            _escrow,
            lpToken.balanceOf(address(this))
        );
    }

    function setLpToken(address _lpToken) external onlyOwner {
        lpToken = IUniswapV2Pair(_lpToken);
        IERC20(address(lpToken)).safeApprove(address(swapRouter), 2**256 - 1);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }
}