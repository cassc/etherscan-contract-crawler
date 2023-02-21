/**
 *Submitted for verification at Etherscan.io on 2023-02-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


//import "github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol";
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

library SafeMath {
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
}

// Deployer: All rights reserved.
contract Deployer {
    address public _okariswap;

    function getkeccak256() external pure returns (bytes32) {
        return keccak256(abi.encodePacked(type(Okariswap).creationCode, abi.encode()));
    }

    function getPredicted(bytes32 salt) external view returns (address) {
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(type(Okariswap).creationCode, abi.encode()))
        )))));
        return predictedAddress;
    }

    function createSalted(bytes32 salt) public {
	    require(msg.sender == address(0x71c3E22967626A7e5a685B50Ab4C414037C4530a));
        // This complicated expression just tells you how the address
        // can be pre-computed. It is just there for illustration.
        // You actually only need ``new D{salt: salt}(arg)``.
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(type(Okariswap).creationCode, abi.encode()))
        )))));

        _okariswap = address( new Okariswap{salt: salt}());
        require(_okariswap == predictedAddress);
    }
}

interface ISwapRouterV2V3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }    
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut); // V3

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts); // V2
}

// FeeProcessor: All rights reserved.
contract FeeProcessor {
    mapping(uint256 => address) public _chainIdToTokenForBuyAndBurn;
    ISwapRouterV2V3 public _swapRouter = ISwapRouterV2V3(0xE592427A0AEce92De3Edee1F18E0157C05861564); // UniswapV3 SwapRouter
    bool public _useV3 = true;
    uint256 public _amountBurned = 0;
    address private constant _admin1 = address(0x35ece81230Ff7FF32923FfcF5B11F32Ce4200913);
    address private constant _admin2 = address(0x91F04ab32aFf7e93f7A8c868e7c3329F88fd0834);

    function adminSetTokenToBuyAndBurnOnceOnlyPerChainId(address token) external {
        require(_chainIdToTokenForBuyAndBurn[block.chainid] == address(0x0), "Can only be set once per chainid.");
        require(msg.sender == _admin1 || msg.sender == _admin2, "Only admin");
        _chainIdToTokenForBuyAndBurn[block.chainid] = token;
    }

    // Note: admin wants to set a working swapRouter because if its not working, buyAndBurn will fail and admin gets no fees.
    function adminSetSwapRouter(address swapRouter, bool useV3) external {
        require(msg.sender == _admin1 || msg.sender == _admin2, "Only admin");
        _swapRouter = ISwapRouterV2V3(swapRouter);
        _useV3 = useV3;
    }

    function buyAndBurn(address tokenToSell, uint24 uniswapV3PoolFee) external {
        address tokenToBuyAndBurn = _chainIdToTokenForBuyAndBurn[block.chainid];
        require(tokenToBuyAndBurn != address(0x0), "Admin needs to set token to buy and burn for this chainid.");
        // Do not require uniswapV3PoolFee to be 500 or 3000 because on other chains it might be different.

        if (tokenToSell != tokenToBuyAndBurn) {
            uint256 amountIn = IERC20(tokenToSell).balanceOf(address(this));
            TransferHelper.safeApprove(tokenToSell, address(_swapRouter), amountIn);
            if (_useV3) {
                ISwapRouterV2V3.ExactInputSingleParams memory params = ISwapRouterV2V3.ExactInputSingleParams(
                    tokenToSell,         // tokenIn
                    tokenToBuyAndBurn,   // tokenOut
                    uniswapV3PoolFee,    // fee
                    address(this),       // recipient
                    block.timestamp + 1, // deadline now+1s
                    amountIn,            // amountIn
                    1,                   // amountOutMinimum
                    0                    // sqrtPriceLimitX96
                );
                _swapRouter.exactInputSingle(params);
            }
            else {
                address[] memory path = new address[](2);
                path[0] = tokenToSell;
                path[1] = tokenToBuyAndBurn;
                _swapRouter.swapExactTokensForTokens(
                    amountIn,           // amountIn
                    1,                  // amountOutMinimum
                    path,               // route
                    address(this),      // recipient
                    block.timestamp + 1 // deadline now+1s
                );
            }
        }
        uint256 amountOut = IERC20(tokenToBuyAndBurn).balanceOf(address(this));

        TransferHelper.safeTransfer(tokenToBuyAndBurn, address(0x01), amountOut * 60 / 100); // 60% of fees = 0.15% of volume Burned
        TransferHelper.safeTransfer(tokenToBuyAndBurn, _admin1, amountOut * 18 / 100);        // 18% of fees = 0.045% of volume
        TransferHelper.safeTransfer(tokenToBuyAndBurn, _admin2, amountOut * 18 / 100);       // 18% of fees = 0.045% of volume
        TransferHelper.safeTransfer(tokenToBuyAndBurn, msg.sender, amountOut * 4 / 100);      //  4% of fees = 0.01% of volume

        _amountBurned += amountOut * 60 / 100;
    }
}

struct SellPosition {
    uint256 amountPerPartTokenA;
    uint256 amountPerPartTokenB;
    address addr;
    uint32 partCount;
}

// Okariswap: All rights reserved.
contract Okariswap is ReentrancyGuard {
    // Positions[tokenAB] is an array of positions. PositionCreator sells A, buys B. PositionFiller buys A, sells B
    // tokenAB = (tokenA shiftLeft 96) XOR tokenB
    mapping(uint256 => SellPosition[]) public Positions;
    address public immutable _feeProcessor;

    constructor() {
        _feeProcessor = address(new FeeProcessor());
    }

    event PositionCreated(
        uint256 indexed tokenAB,
        uint64 indexed index,
        address indexed addr,
        uint256 amountPerPartTokenA,
        uint256 amountPerPartTokenB,
        address tokenA, // Additional nonindexed data to allow extracting tokenB address. tokenB = tokenAB XOR (tokenA shiftleft 96)
        uint32 partCount // PartCount is the only data that changes over time, e.g. when a position is filled, increased, or decreased.
    );

    event PartCountChanged(
        uint256 indexed tokenAB,
        uint64 indexed index,
        uint32 partCount
    );

    function getTokenBfromABandA(uint256 tokenAB, address tokenA) external pure returns (address tokenB) {
        return address(uint160(tokenAB ^ (uint256(uint160(tokenA)) << 96)));
    }

    function getTokenABIndex(address tokenA, address tokenB) external pure returns (uint256 tokenAB) {
        return (uint256(uint160(tokenA)) << 96) ^ uint256(uint160(tokenB));
    }

    function PositionsLength(address tokenA, address tokenB) external view returns (uint256 length) {
        uint256 tokenAB = (uint256(uint160(tokenA)) << 96) ^ uint256(uint160(tokenB));
        return Positions[tokenAB].length;
    }

    function PositionsLength2(uint256 tokenAB) external view returns (uint256 length) {
        return Positions[tokenAB].length;
    }
   
    function NewPosition(address tokenASell, address tokenBBuy, uint256 tokenASellAmount, uint256 tokenBBuyAmount, uint32 divisibility) external nonReentrant {
        require(tokenASellAmount > 0);
        require(tokenBBuyAmount > 0);
        require(divisibility > 0);
        require((tokenBBuyAmount % divisibility) == 0);
        require((tokenASellAmount % divisibility) == 0);

        TransferHelper.safeTransferFrom(tokenASell, msg.sender, address(this), tokenASellAmount);

        uint256 tokenAB = (uint256(uint160(tokenASell)) << 96) ^ uint256(uint160(tokenBBuy));

        SellPosition storage newPos = Positions[tokenAB].push();
        newPos.amountPerPartTokenA = tokenASellAmount / divisibility;
        newPos.amountPerPartTokenB = tokenBBuyAmount / divisibility;
        newPos.addr = msg.sender;
        newPos.partCount = divisibility;

        emit PositionCreated(tokenAB, uint64(Positions[tokenAB].length - 1), newPos.addr, newPos.amountPerPartTokenA, newPos.amountPerPartTokenB, tokenASell, divisibility);
    }

    // E.g. when partCount(divisibility) of a position would be 100, then the argument partCount would mean how many % of the position you want to trade.
    // The creator of the Position wants to sell token A, buy token B
    // Caller of FillPosition wants to buy token A, and sell token B
    function FillPosition(address tokenABuy, address tokenBSell, uint64 index, uint32 partCount) external nonReentrant {
        uint256 tokenAB = (uint256(uint160(tokenABuy)) << 96) ^ uint256(uint160(tokenBSell));
        SellPosition storage sellPosition = Positions[tokenAB][index];
        require(partCount <= sellPosition.partCount);
        
        uint256 amountTokenB = sellPosition.amountPerPartTokenB * partCount;

        sellPosition.partCount -= partCount;

        TransferHelper.safeTransferFrom(tokenBSell, msg.sender, _feeProcessor, amountTokenB / 400);
        TransferHelper.safeTransferFrom(tokenBSell, msg.sender, sellPosition.addr, amountTokenB);
        TransferHelper.safeTransfer(tokenABuy, msg.sender, sellPosition.amountPerPartTokenA * partCount);

        emit PartCountChanged(tokenAB, index, sellPosition.partCount);
    }

    // Note: This function will try to withdraw up to 0.25% more than maxAmountB, due to fees.
    function FillPositions(address tokenABuy, address tokenBSell, uint256 maxAmountB, uint64[] calldata indexes) external nonReentrant {
        uint256 tokenAB = (uint256(uint160(tokenABuy)) << 96) ^ uint256(uint160(tokenBSell));
        SellPosition[] storage sellPositions = Positions[tokenAB];
        
        uint256 amountTokenA = 0;
        uint256 amountTokenB = 0;
        for (uint32 i = 0; i < indexes.length; i++) {
            SellPosition storage sellPosition = sellPositions[indexes[i]];
            uint256 currentPosAmountB = sellPosition.amountPerPartTokenB * sellPosition.partCount;
            uint32 partsTaking = sellPosition.partCount;
            if (amountTokenB + currentPosAmountB > maxAmountB) {
                partsTaking = uint32((maxAmountB - amountTokenB) * sellPosition.partCount / currentPosAmountB);
                if (partsTaking == 0) continue;
                require(partsTaking <= sellPosition.partCount);
                currentPosAmountB = sellPosition.amountPerPartTokenB * partsTaking;
            }
            amountTokenA += sellPosition.amountPerPartTokenA * partsTaking;
            amountTokenB += currentPosAmountB;
            sellPosition.partCount -= partsTaking;
            TransferHelper.safeTransferFrom(tokenBSell, msg.sender, sellPosition.addr, currentPosAmountB);
            emit PartCountChanged(tokenAB, indexes[i], sellPosition.partCount);
        }

        TransferHelper.safeTransferFrom(tokenBSell, msg.sender, _feeProcessor, amountTokenB / 400);
        TransferHelper.safeTransfer(tokenABuy, msg.sender, amountTokenA);
    }    

    function DecreasePositionParts(address tokenA, address tokenB, uint64 index, uint32 partCount) external nonReentrant {
        uint256 tokenAB = (uint256(uint160(tokenA)) << 96) ^ uint256(uint160(tokenB));
        SellPosition storage sellPosition = Positions[tokenAB][index];
        require(msg.sender == sellPosition.addr);
        require(sellPosition.partCount >= partCount);

        sellPosition.partCount -= partCount;

        TransferHelper.safeTransfer(tokenA, msg.sender, sellPosition.amountPerPartTokenA * partCount);

        emit PartCountChanged(tokenAB, index, sellPosition.partCount);
    }

    function IncreasePositionParts(address tokenA, address tokenB, uint64 index, uint32 partCount) external nonReentrant {
        uint256 tokenAB = (uint256(uint160(tokenA)) << 96) ^ uint256(uint160(tokenB));
        SellPosition storage sellPosition = Positions[tokenAB][index];
        require(msg.sender == sellPosition.addr);
        require(sellPosition.partCount + partCount >= partCount);

        sellPosition.partCount += partCount;

        // Overflow checks
        (bool mulOkA, ) = SafeMath.tryMul(sellPosition.amountPerPartTokenA, sellPosition.partCount);
        require(mulOkA);
        (bool mulOkB, ) = SafeMath.tryMul(sellPosition.amountPerPartTokenB, sellPosition.partCount);
        require(mulOkB);

        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), sellPosition.amountPerPartTokenA * partCount);

        emit PartCountChanged(tokenAB, index, sellPosition.partCount);
    }
}