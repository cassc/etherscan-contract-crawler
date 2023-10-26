pragma solidity ^0.8.0;

import "contracts/Chainlink/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "contracts/Chainlink/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library UniswapV2Library {
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, address pair) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }
}

abstract contract SafeWithdrawals is Ownable {
  address private immutable _liquidityToken;

  constructor(address liquidityToken_) {
      _liquidityToken = liquidityToken_;
  }
  function _withdrawTokens(address tokenAddress, address receiver) internal {
    require(tokenAddress!=_liquidityToken, "X");
    IERC20 token = IERC20(tokenAddress);
    SafeERC20.safeTransfer(token, receiver, token.balanceOf(address(this)));
  }

  function withdrawTokens(address tokenAddress, address receiver) public onlyOwner {
    _withdrawTokens(tokenAddress, receiver);

  }

  function _withdrawETH(address receiver) internal {
    (bool sent, ) = receiver.call{value: address(this).balance}('');
    require(sent, 'Failed to send Ether');
  }

  function withdrawETH(address receiver) public onlyOwner {
    _withdrawETH(receiver);
  }
}

contract Lottery is VRFV2WrapperConsumerBase, Ownable, SafeWithdrawals {
    uint256 private current_points = 0;
    uint32[] public lucky_numbers;
    uint256 private rewardPool;

    uint256 constant private WINNER_COUNT = 21;
    
    uint8 constant private DEVELOPER_REWARD = 10; //10%

    uint32 constant private ADDITIONAL_REWARDS_1 = ((100<<12) + 0);
    uint32 constant private ADDITIONAL_REWARDS_2 = ((1000<<12) + 100); // +10% up to 1000$
    uint32 constant private ADDITIONAL_REWARDS_3 = 250; // +25% unlimited


    address constant private _pairAddress = 0x6b16CcD75cEB9e35221E1D3B604E8CE07c4Ea067; //to be changed for our addressed
    address immutable public tokenAddress;  
    
    address constant private _chainlinkProvider = 0x5A861794B927983406fCE1D062e00b9368d97Df6;
    address constant private _link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    uint32 constant private MAX32_INT = 2**32 - 1;
    uint32 constant private MAX12_INT = 2**12 - 1;
    uint32 constant private PERCENTAGE_BASE = 1000;
    

    uint256 constant private _blockNumber = 18587500;  //to be changed 
    bool private developersWithdrawed = false;
    

    modifier onlyToken() {
        require(msg.sender == tokenAddress, "A");
        _;
    }

    mapping(address => uint64[]) public ranges;

    constructor(address token_) VRFV2WrapperConsumerBase(_link, _chainlinkProvider) SafeWithdrawals(_pairAddress) {
        tokenAddress = token_;
    }

    function mint(address user, uint points) external onlyToken {
        if(luckyNumbersSet() || points == 0) {
            return;
        }
        points = (points * (PERCENTAGE_BASE+getPointsBonus(points))) / PERCENTAGE_BASE;
        ranges[user].push(uint64((current_points<<32)+(current_points+points)));
        current_points+=points;
    }

    function hasLotteryEnded() public view returns(bool) {
        if(!luckyNumbersSet()) {
            return false;
        }
        for(uint i;i<WINNER_COUNT;i++) {
            if(lucky_numbers[i]!= MAX32_INT)return false;     
        }
        return true;
    }

    function getPointsBonus(uint256 points) public pure returns(uint) {
        if(points < (ADDITIONAL_REWARDS_1>>12)) {
            return ADDITIONAL_REWARDS_1 & MAX12_INT;
        }
        if(points < (ADDITIONAL_REWARDS_2>>12)) {
            return ADDITIONAL_REWARDS_2 & MAX12_INT;
        }
        return ADDITIONAL_REWARDS_3 & MAX12_INT;

    }

    function win(address[] calldata user, uint[] calldata numbers) external { //anybody can trigger for himself or others

        uint8[WINNER_COUNT] memory WINNERS_SHARES = [70, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]; //must add up to 100 - DEVELOPER_REWARD

        uint32[] memory cur_lucky_numbers = lucky_numbers;
        for(uint i;i<user.length;i++){
            uint64[] memory userRanges = ranges[user[i]];
            for(uint j; j < cur_lucky_numbers.length; j++){
                    if(
                        uint32(userRanges[numbers[i]]>>32) <= cur_lucky_numbers[j] &&  
                        cur_lucky_numbers[j] < uint32(userRanges[numbers[i]]) &&
                        cur_lucky_numbers[j] != MAX32_INT
                    ) {
                        cur_lucky_numbers[j] = MAX32_INT;
                        _rewardWinner(user[i], WINNERS_SHARES[j]);
                        lucky_numbers[j] = MAX32_INT;
                    }
                }
            
        }        
    }

    function getChances(address user) external view returns(uint, uint) {
        uint64[] memory userRanges = ranges[user];
        uint chance = 0;
        for(uint i = 0;i<userRanges.length;i++){
            chance += (uint32(userRanges[i]) - uint32(userRanges[i]>>32));
        }
        return (chance, current_points);

    }

    function setByLiquidity() external onlyToken{
         _setByChainLink();
    }    

    function setByChainLink() external onlyOwner {
        require(_blockNumber < block.number, "E");
        _setByChainLink();

    }
    
    function fixRewardPool() external onlyToken {
        rewardPool = IUniswapPair(_pairAddress).balanceOf(address(this));
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override  {
        uint256 seed;
        unchecked {
            seed = uint256(randomWords[0] + uint256(blockhash(block.number-1)));
        }
        _setLuckyNumbers(seed);
    }

    function claimDevelopersReward(uint amount) external onlyOwner {
        uint MAX_REWARD = (rewardPool*DEVELOPER_REWARD)/100;
        require(lucky_numbers.length != 0 && !developersWithdrawed && amount <= MAX_REWARD , "N");
        IUniswapPair(_pairAddress)
            .transfer(_pairAddress, amount); // send liquidity to pair
        IUniswapPair(_pairAddress).burn(owner());
        developersWithdrawed = true;
    }

    function withdrawLiquidity(address newLottery) external onlyToken {
        require(hasLotteryEnded() , "N");
        IUniswapPair(_pairAddress).transfer(newLottery, IUniswapPair(_pairAddress).balanceOf(address(this)));
    }

    function luckyNumbersSet() public view returns(bool){
        return lucky_numbers.length != 0;
    }   

    function _rewardWinner(address winner, uint8 winnerShare) internal {
        IUniswapPair(_pairAddress)
            .transfer(_pairAddress, (rewardPool*winnerShare)/100); // send liquidity to pair
        IUniswapPair(_pairAddress).burn(winner);
    }

    function _setByChainLink() private {
        requestRandomness(
            uint32(50000 + 30000 * WINNER_COUNT),
            3,
            1
        );
    }
   
    function _setLuckyNumbers(uint seed) internal {
        if(luckyNumbersSet()) {
            return;
        }

        for(uint i;i<WINNER_COUNT;i++) {
            lucky_numbers.push(
                uint32(uint256(keccak256(abi.encodePacked(seed+i)))%(current_points))
            );
        }
    }
}