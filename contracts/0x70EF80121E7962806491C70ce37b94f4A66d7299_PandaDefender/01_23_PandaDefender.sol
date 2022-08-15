/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: GPL-2.0-or-laterPOOLFEE_DAI_ETH
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "./AccessControl.sol";
import "./IWETH9.sol";

contract PandaDefender is AccessControl {
    IV3SwapRouter public immutable swapRouter02 = IV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    IUniswapV3Factory public immutable factoryV3 = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant PANDA = 0x3cBb7f5d7499Af626026E96a2f05df806F2200DC; 
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; 
    address public constant TREASURY = 0x11517Ae3326667c350eff7Dcf9f220058617C665;
    address public constant CORE_TREASURY = 0xe19B5757B8C2dD0C9B0fC6D5df739d0d581D0c59;
    
    uint24 public constant POOLFEE_DAI_ETH = 500; //Pair DAI-WETH 0x60594a405d53811d3bc4766596efd80fd545a270
    uint24 public constant POOLFEE_PANDA_ETH = 10000; //Pair PANDA-WETH 0xB32fcfFF9616deec20DD44D664f490dEE7fE2c7a
    uint256 public maxDefendPrice = 0.005 * 10 ** 18;
    uint256 public defendPrice = 0.005 * 10 ** 18;

    modifier assertNotContract(
        address addr_
    ) {
        require (addr_ == tx.origin, "Smart contract caller not allowed");
        _;
    }


    constructor() {}

    /* ---------------------------- Views --------------------------------- */

    // balance of DAI
    function DAIBalance() external view returns (uint256){
        return IERC20(DAI).balanceOf(address(this));
    }

    // Uniswap v3 are always scaled up by 2⁹⁶ 
    function getTWAP(address uniswapV3Pool, uint32 twapInterval) public view returns (uint256 price) {
        uint160 sqrtPriceX96;
        
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval)
            );
        }

        price =  FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96) * 10 ** 18 >> 96;
    }

    // pos for fetching token0 / token1 * 10 ** 18
    function getWETHPos(address[] memory tokens) public pure returns(uint256[] memory WETHPos) {
        WETHPos = new uint256[](2);

        if (tokens[0] < tokens[1]) {
            WETHPos[0] = 1; // ETH < token0 > -> token0 / ETH -> 0
        } 

        if (tokens[2] > tokens[1]) {
             WETHPos[1] = 1; // token1 > ETH -> ETH / token1 -> 0
        }
    }

    // check both TWAP and current price of two pools
    function checkP(address[] memory tokens, uint24[] memory fees, uint32 twapInterval) public view returns (uint256, uint256) {
        require(1 < tokens.length && tokens.length < 4, "Max Two Pool Limited");

        address uniswapV3Pool0 = IUniswapV3Factory(factoryV3).getPool(tokens[0], tokens[1], fees[0]);
        uint256 cp0 = getTWAP(uniswapV3Pool0, 0);
        uint256 twap0 = getTWAP(uniswapV3Pool0, twapInterval);

        if (tokens.length == 2) {
            return (cp0, twap0);
        } else {
            address uniswapV3Pool1 = IUniswapV3Factory(factoryV3).getPool(tokens[1], tokens[2], fees[1]);
            uint256 cp1 = getTWAP(uniswapV3Pool1, 1);
            uint256 twap1 = getTWAP(uniswapV3Pool1, twapInterval);
            
            uint256[] memory WETHPos = getWETHPos(tokens);

            if (WETHPos[0] == 1) {
                cp0 = 10 ** 36 / cp0;
                twap0 = 10 ** 36 / twap0;
            }

            if (WETHPos[1] == 1) {
                cp1 = 10 ** 36 / cp1;
                twap1 = 10 ** 36 / twap1;
            }

            cp1 = cp0 * cp1 / 10 ** 18;
            twap1 = twap0 * twap1 / 10 ** 18;
            return (cp1, twap1);
        }  
    }

    function checkPANDAP(uint32 twapInterval) public view returns (uint256, uint256) {
        address[] memory tokenAddressArr = new address[](3);
        tokenAddressArr[0] = DAI;
        tokenAddressArr[1] = WETH9;
        tokenAddressArr[2] = PANDA;

        uint24[] memory feeArr = new uint24[](2);
        feeArr[0] = POOLFEE_DAI_ETH;
        feeArr[1] = POOLFEE_PANDA_ETH;

        return checkP(tokenAddressArr, feeArr, twapInterval);
    }

    /* ---------------------------- Writes --------------------------------- */

    // Fix exchange rate swap PANDA for DAI
    function fRSwapPANDAForDAI(uint256 amountIn, address receiver) external assertNotContract(msg.sender) nonReentrant onlyFRSwapOn {
        // msg.sender must approve this contract
        require(defendPrice <= maxDefendPrice, "Defend Price Over Max");

        // Transfer the specified amount of PANDA to this contract.
        TransferHelper.safeTransferFrom(PANDA, msg.sender, address(this), amountIn);

        uint256 amountOut = amountIn * defendPrice / 10 ** 18;

        TransferHelper.safeTransfer(DAI, receiver, amountOut);

        emit FRSwapPANDAForDAI(amountIn, amountOut, receiver);
    }

    // Swap DAI for PANDA
    function swapDAIForPANDA(uint256 amountIn) external payable onlySwapOn {
        address[] memory tokenAddressArr = new address[](3);
        tokenAddressArr[0] = DAI;
        tokenAddressArr[1] = WETH9;
        tokenAddressArr[2] = PANDA;

        uint24[] memory feeArr = new uint24[](2);
        feeArr[0] = POOLFEE_DAI_ETH;
        feeArr[1] = POOLFEE_PANDA_ETH;
        
        uint256 amountOut = swapExactInputMultihop(
            amountIn, 
            tokenAddressArr, 
            feeArr,
            0,
            false
        );

        emit SwapDAIForPANDA(msg.sender, amountIn, amountOut);
    }
    
    // Swap ETH for PANDA 
    function swapETHForPANDA() external payable onlySwapOn {
        address[] memory tokenAddressArr = new address[](2);
        tokenAddressArr[0] = WETH9;
        tokenAddressArr[1] = PANDA;

        uint24[] memory feeArr = new uint24[](1);
        feeArr[0] = POOLFEE_PANDA_ETH;

        uint256 amountOut = swapExactInputSingle02(
            msg.value, 
            tokenAddressArr,
            feeArr,
            0,
            false
        );

        emit SwapETHForPANDA(msg.sender, msg.value, amountOut);
    }

    // swaps a fixed amount of token0 for a maximum possible amount of token1 through an intermediary pool.
    function swapExactInputMultihop(
        uint256 amountIn, 
        address[] memory tokens, 
        uint24[] memory fees,
        uint32 twapInterval,
        bool isCheckDp
    ) public returns (uint256 amountOut) {
        // check Defend Price
        if (isCheckDp) {
            (uint256 p, uint256 twap) = checkPANDAP(twapInterval);
            require(p < defendPrice && twap < defendPrice, "Not Reach Defend Price");
        }

        // Transfer `amountIn` of DAI to this contract.
        TransferHelper.safeTransferFrom(tokens[0], msg.sender, address(this), amountIn);

        // // Approve the router to spend DAI.
        TransferHelper.safeApprove(tokens[0], address(swapRouter02), amountIn);

        // // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // // Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
        IV3SwapRouter.ExactInputParams memory params =
            IV3SwapRouter.ExactInputParams({
                path: abi.encodePacked(tokens[0], fees[0], tokens[1], fees[1], tokens[2]),
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // // Executes the swap.
        amountOut = swapRouter02.exactInput(params);
    }

    // swaps a fixed amount of token0 for a maximum possible amount of token1
    function swapExactInputSingle02(
        uint256 amountIn, 
        address[] memory tokens, 
        uint24[] memory fees,
        uint32 twapInterval,
        bool isCheckDp
    ) public payable returns (uint256 amountOut) 
    {
        // msg.sender must approve this contract

        // check Defend Price
        if (isCheckDp) {
            (uint256 p, uint256 twap) = checkPANDAP(twapInterval);
            require(p < defendPrice && twap < defendPrice, "Not Reach Defend Price");
        }

        if (tokens[0] != WETH9) {
            // Transfer the specified amount of DAI to this contract.
            TransferHelper.safeTransferFrom(tokens[0], msg.sender, address(this), amountIn);

            // Approve the router to spend DAI.
            TransferHelper.safeApprove(tokens[0], address(swapRouter02), amountIn);
        } else {
            amountIn = msg.value;
        }

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        IV3SwapRouter.ExactInputSingleParams memory params =
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: tokens[0],
                tokenOut: tokens[1],
                fee: fees[0],
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter02.exactInputSingle{value: msg.value}(params);

        // refund ETH as output
        if (tokens[1] == WETH9) {
            unwrapWETH9(1);
        }
    }

    // Unwrap WETH
    function unwrapWETH9(uint256 amountMinimum) internal {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
        }
    }

    function setMaxDefendPrice(uint256 newPrice) external {
        require(msg.sender == CORE_TREASURY, "Only Core Treasury Can Call");

        maxDefendPrice = newPrice;

        emit SetMaxDefendPrice(newPrice);
    }

    // Update states
    function setDefendPrice(uint256 newPrice) external onlyAdmin {
        require(newPrice > defendPrice, "Invalid Price");

        defendPrice = newPrice;

        emit SetDefendPrice(msg.sender, newPrice);
    }

    // WithdrawERC20 tokens.
    function withdrawERC20(
        address tokenAddress, 
        uint256 tokenAmount
    ) external onlyAdmin notZeroAddr(tokenAddress) 
    {
        TransferHelper.safeTransfer(tokenAddress, TREASURY, tokenAmount);

        emit WithdrawERC20(TREASURY, tokenAddress, tokenAmount);
    }

    // Withdraw Ether.
    function withdrawEther(uint256 amount) external onlyAdmin {
        (bool success,) = TREASURY.call{value:amount}("");
        require(success, "withdrawEther fail!");
        
        emit WithdrawEther(TREASURY, amount);
    }

    receive() external payable {}

    // ---------------------------- Events ---------------------------------

    event FRSwapPANDAForDAI(uint amountIn, uint amountOut, address receiver);
    event SwapDAIForPANDA(address swapper, uint amountIn, uint amountOut);
    event SwapETHForPANDA(address swapper, uint amountIn, uint amountOut);
    event SetMaxDefendPrice(uint newPrice);
    event SetDefendPrice(address setter, uint newPrice);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);

}