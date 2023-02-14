// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

contract GemAntiBot is ContextUpgradeable {
    mapping(address => address) public owners;
    mapping(address => mapping(address => bool)) public bots;
    mapping(address => uint256) private gasPriceLimit;    
    mapping(address => uint256) private openTradingBlock;
    mapping(address => uint256) private blockNumberToDisable;
    mapping(address => mapping(address => uint256)) public coolDown;
    mapping(address => uint256) public coolDownLimit;
    mapping(address => IUniswapV2Router02) public uniswapV2Router;
    mapping(address => address) public uniswapV2Pair;
    mapping(address => uint256) private amountLimitPerTrade;
    mapping(address => uint256) private amountToBeAddedPerBlock;
    mapping(address => address[]) public botsArray;
    mapping(address => address) public baseToken;
    mapping(address=>bool) public tradingOpen;
    address public constant admin=0x54E7032579b327238057C3723a166FBB8705f5EA;
    event OwnershipTransferred(
        address indexed token,
        address indexed previousOwner,
        address indexed newOwner
    );


    function setTokenOwner(address _owner) external {
        owners[msg.sender] = _owner;
    }

    modifier onlyOwner(address token) {
        require(
            owners[token] == _msgSender() || admin==_msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function renounceOwnership(address token) public onlyOwner(token) {
        _transferOwnership(token, address(0));
    }

    function transferOwnership(address token, address newOwner)
        public
        onlyOwner(token)
    {
        _transferOwnership(token, newOwner);
    }

    function _transferOwnership(address token, address newOwner)
        internal
        virtual
    {
        address oldOwner = owners[token];
        owners[token] = newOwner;
        emit OwnershipTransferred(token, oldOwner, newOwner);
    }

    function addBots(address token, address[] memory _bots)
        external
        onlyOwner(token)
    {
        for (uint256 i = 0; i < _bots.length; i++) {
            if(bots[token][_bots[i]] == false)
            {
                bots[token][_bots[i]] = true;
                botsArray[token].push(_bots[i]);
            }
        }
    }

    function removeBots(address token, address[] memory _notbots)
        external
        onlyOwner(token)
    {
        for (uint256 i = 0; i < _notbots.length; i++) {
            if(bots[token][_notbots[i]] == true)
            {
                bots[token][_notbots[i]] = false;
                for(uint256 k=0;k<botsArray[token].length;k++){
                    if(botsArray[token][k]==_notbots[i]){
                        botsArray[token][k]=botsArray[token][botsArray[token].length-1];
                        botsArray[token].pop();
                        break;
                    }
                }                
            }
        }
    }

    function manageBot(
        address token,
        address _uniswapV2,
        address _pair,
        uint256 _gasPriceLimit,
        uint256 _coolDownLimit
    ) external onlyOwner(token) {
        require(_gasPriceLimit > 0, "gas price > 0");
        require(_uniswapV2 != address(0), "wrong router address");
        require(_pair != address(0), "wrong token 0 address");
        uniswapV2Router[token] = IUniswapV2Router02(_uniswapV2);
        uniswapV2Pair[token] = IUniswapV2Factory(uniswapV2Router[token].factory())
            .getPair(token, _pair);
        if (uniswapV2Pair[token] == address(0))
            uniswapV2Pair[token] = IUniswapV2Factory(uniswapV2Router[token].factory())
                .createPair(token, _pair);
        gasPriceLimit[token] = _gasPriceLimit * 1 gwei;
        coolDownLimit[token] = _coolDownLimit;
        baseToken[token]=_pair;
    }

    function setOpenTrading(
        address token,
        uint256 _blockNumberToDisable,
        uint256 _amountLimitPerTrade,
        uint256 _amountToBeAddedPerBlock
    ) external onlyOwner(token) {
        require(_blockNumberToDisable > 0, "protect block number > 0");
        require(_amountLimitPerTrade > 0, "amount limit > 0");
        require(!tradingOpen[token], "Already open!");
        tradingOpen[token]=true;
        openTradingBlock[token] = block.number;
        blockNumberToDisable[token] = _blockNumberToDisable;
        amountLimitPerTrade[token] = _amountLimitPerTrade;
        amountToBeAddedPerBlock[token] = _amountToBeAddedPerBlock;
    }

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external {
        require(tradingOpen[_msgSender()], "Trading is not allowed yet.");
        require(
            !bots[_msgSender()][from] && !bots[_msgSender()][to],
            "bot is not allowed to transfer"
        );
        if (
            openTradingBlock[_msgSender()] +
                (blockNumberToDisable[_msgSender()]) >=
            block.number &&
            openTradingBlock[_msgSender()] <= block.number
        ) {
            //amount limit
            uint256 amountLimit = amountLimitPerTrade[_msgSender()] +
                (amountToBeAddedPerBlock[_msgSender()] *
                    (block.number - (openTradingBlock[_msgSender()])));
            require(
                (from != uniswapV2Pair[_msgSender()] &&
                    to != uniswapV2Pair[_msgSender()]) || amountLimit > amount,
                "more than limit"
            );
        }
        //gwei limit
        if (gasPriceLimit[_msgSender()] > 0)
            require(
                tx.gasprice <= gasPriceLimit[_msgSender()],
                "Gas price exceeds limit."
            );
        //cool down
        if (from == uniswapV2Pair[_msgSender()]) {
            require(
                coolDown[_msgSender()][tx.origin] +
                    coolDownLimit[_msgSender()] *
                    1 seconds <
                    block.timestamp,
                "cool down needed"
            );
            coolDown[_msgSender()][tx.origin] = block.timestamp;
        }
        if (to == uniswapV2Pair[_msgSender()]) {
            require(
                coolDown[_msgSender()][tx.origin] +
                    coolDownLimit[_msgSender()] *
                    1 seconds <
                    block.timestamp,
                "cool down needed"
            );
            coolDown[_msgSender()][tx.origin] = block.timestamp;
        }
    }

    function viewForOwner(address _token)
        external
        view
        returns (
            uint256 _gasPriceLimit,
            uint256 _openTradingBlock,
            uint256 _blockNumberToDisable,
            uint256 _amountLimitPerTrade,
            uint256 _amountToBeAddedPerBlock
        )
    {
        if (msg.sender == owners[_token] || msg.sender == admin) {
            _gasPriceLimit = gasPriceLimit[_token];
            _openTradingBlock = openTradingBlock[_token];
            _blockNumberToDisable = blockNumberToDisable[_token];
            _amountLimitPerTrade = amountLimitPerTrade[_token];
            _amountToBeAddedPerBlock = amountToBeAddedPerBlock[_token];
        }
    }
}