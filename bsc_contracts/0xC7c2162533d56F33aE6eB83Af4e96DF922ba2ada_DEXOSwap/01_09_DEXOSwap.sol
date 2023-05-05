// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./utils/Ownable.sol";
import "./utils/Pausable.sol";
import "./utils/ReentrancyGuard.sol";
import "./IERC20.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";

contract DEXOSwap is Ownable, Pausable, ReentrancyGuard {

    IPancakeRouter02 public dexRouter_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event LogReceived(address indexed, uint);
    event LogFallback(address indexed, uint);
    event LogSetSwapFee(address indexed, uint256);
    event LogSetSwapFee0x(address indexed, uint256);
    event LogSetDexRouter(address indexed, address indexed);
    event LogSwapExactTokensForTokens(address indexed, address indexed, uint256, uint256);
    event LogSwapExactETHForTokens(address indexed, uint256, uint256);
    event LogSwapExactTokenForETH(address indexed, uint256, uint256);
    event LogSwapExactTokensForTokensOn0x(address indexed, address indexed, uint256, uint256);
    event LogSwapExactETHForTokensOn0x(address indexed, uint256, uint256);
    event LogSwapExactTokenForETHOn0x(address indexed, uint256, uint256);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    /**
     * @param   _router: router address
     */
    constructor(address _router) 
    {
        dexRouter_ = IPancakeRouter02(_router);
    }

    /**
     * @param   _tokenA: tokenA contract address
     * @param   _tokenB: tokenB contract address
     * @return  bool: if pair is in DEX, return true, else, return false.
     */
    function isPairExists(address _tokenA, address _tokenB) public view returns(bool){        
        return IPancakeFactory(dexRouter_.factory()).getPair(_tokenA, _tokenB) != address(0);
    }

    /**
     * @param   _tokenA: tokenA contract address
     * @param   _tokenB: tokenB contract address
     * @return  bool: if path is in DEX, return true, else, return false.
     */
    function isPathExists(address _tokenA, address _tokenB) public view returns(bool){        
        return IPancakeFactory(dexRouter_.factory()).getPair(_tokenA, _tokenB) != address(0) || 
            (IPancakeFactory(dexRouter_.factory()).getPair(_tokenA, dexRouter_.WETH()) != address(0) && 
            IPancakeFactory(dexRouter_.factory()).getPair(dexRouter_.WETH(), _tokenB) != address(0));
    }

    /**
     * @param   path: path
     * @param   _amountIn: amount of input token
     * @return  uint256: Given an input asset amount, returns the maximum output amount of the other asset.
     */
    function getAmountOut(address[] memory path, uint256 _amountIn) external view returns(uint256) { 
        uint256[] memory amountOutMaxs = dexRouter_.getAmountsOut(_amountIn, path);
        return amountOutMaxs[path.length - 1];  
    }

    /**
     * @param   path: path
     * @param   _amountOut: amount of output token
     * @return  uint256: Returns the minimum input asset amount required to buy the given output asset amount.
     */
    function getAmountIn(address[] memory path, uint256 _amountOut) external view returns(uint256) { 
        uint256[] memory amountInMins = dexRouter_.getAmountsIn(_amountOut, path);
        return amountInMins[0];
    }

    function isContract(address _addr) private returns (bool isContract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    
    function getSwapTargetAddress(bytes calldata swapCalldata) public view returns (address) {
        (bool success, bytes memory returnData) = address(this).staticcall(swapCalldata);
        if (success) {
            (address targetAddress, ) = abi.decode(returnData, (address, uint256));
            return targetAddress;
        } else {
            revert("Could not retrieve swap target address");
        }
    }

    /**
     * @param   tokenA: InputToken Address to swap on Pancake
     * @param   tokenB: OutputToken Address to swap on Pancake
     * @param   _amountIn: Amount of InputToken to swap on Pancake
     * @param   _amountOutMin: The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ERC20 token on Pancake
     */
    function swapExactTokensForTokens(
        address tokenA, 
        address tokenB, 
        uint256 _amountIn, 
        uint256 _amountOutMin, 
        address to, 
        uint deadline
    ) external whenNotPaused nonReentrant {
        require(isPathExists(tokenA, tokenB), "Invalid path");
        require(_amountIn > 0 , "Invalid amount");

        require(IERC20(tokenA).transferFrom(_msgSender(), address(this), _amountIn), "Faild TransferFrom");

        require(IERC20(tokenA).approve(address(dexRouter_), _amountIn));

        address[] memory path;
        if (isPairExists(tokenA, tokenB)) 
        {
            path = new address[](2);
            path[0] = tokenA;
            path[1] = tokenB;
        }         
        else {
            path = new address[](3);
            path[0] = tokenA;
            path[1] = dexRouter_.WETH();
            path[2] = tokenB;
        }
        
        uint256 boughtAmount = IERC20(tokenB).balanceOf(to);
        dexRouter_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOutMin,  
            path,
            to,
            deadline
        );
        boughtAmount = IERC20(tokenB).balanceOf(to) - boughtAmount;
        emit LogSwapExactTokensForTokens(tokenA, tokenB, _amountIn, boughtAmount);
    }

    /**
     * @param   tokenA: InputToken Address to swap on 0x, The `sellTokenAddress` field from the API response
     * @param   tokenB: OutputToken Address to swap on 0x, The `buyTokenAddress` field from the API response
     * @param   _amountIn: Amount of InputToken to swap on 0x, The `sellAmount` field from the API response
     * @param   spender: Spender to approve the amount of InputToken, The `allowanceTarget` field from the API response
     * @param   swapTarget: SwapTarget contract address, The `to` field from the API response
     * @param   swapCallData: CallData, The `data` field from the API response
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ERC20 token by using 0x protocol
     */
    function swapExactTokensForTokensOn0x(
        address tokenA,
        address tokenB,
        uint256 _amountIn,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        address to,
        uint deadline
    ) external whenNotPaused nonReentrant {

        require(!isContract(_msgSender()), "msg sender should be wallet");
        require(swapTarget == getSwapTargetAddress(swapCallData), "wrong target address");
        require(deadline >= block.timestamp, 'DEXManagement: EXPIRED');
        require(_amountIn > 0 , "Invalid amount");
        require(address(swapTarget) != address(0), "Zero address");

        require(IERC20(tokenA).transferFrom(_msgSender(), address(this), _amountIn), "Faild TransferFrom");
        
        require(IERC20(tokenA).approve(spender, _amountIn));
        
        uint256 boughtAmount = IERC20(tokenB).balanceOf(address(this));

        (bool success,) = swapTarget.call(swapCallData);
        require(success, 'SWAP_CALL_FAILED');

        boughtAmount = IERC20(tokenB).balanceOf(address(this)) - boughtAmount;

        require(IERC20(tokenB).transfer(to, boughtAmount), "Faild Transfer");

        emit LogSwapExactTokensForTokensOn0x(tokenA, tokenB, _amountIn, boughtAmount);
    }

    /**
     * @param   token: OutputToken Address to swap on Pancake
     * @param   _amountOutMin: The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ETH to ERC20 token on Pancake
     */
    function swapExactETHForTokens(
        address token, 
        uint256 _amountOutMin, 
        address to, 
        uint deadline
    ) external payable whenNotPaused nonReentrant {
        require(isPathExists(token, dexRouter_.WETH()), "Invalid path");
        require(msg.value > 0 , "Invalid amount");

        address[] memory path = new address[](2);
        path[0] = dexRouter_.WETH();
        path[1] = token;

        uint256 boughtAmount = IERC20(token).balanceOf(to);
        dexRouter_.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(                
            _amountOutMin,
            path,
            to,
            deadline
        );
        boughtAmount = IERC20(token).balanceOf(to) - boughtAmount;

        emit LogSwapExactETHForTokens(token, msg.value, boughtAmount);
    }

    /**
     * @param   token: OutputToken Address to swap on 0x, The `buyTokenAddress` field from the API response
     * @param   swapTarget: SwapTarget contract address, The `to` field from the API response
     * @param   swapCallData: CallData, The `data` field from the API response
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ETH to ERC20 token by using 0x protocol
     */
    function swapExactETHForTokensOn0x(
        address token, 
        address payable swapTarget, 
        bytes calldata swapCallData, 
        address to,
        uint deadline
    ) external payable whenNotPaused nonReentrant {
        require(!isContract(_msgSender()), "msg sender should be wallet");
        require(swapTarget == getSwapTargetAddress(swapCallData), "wrong target address");
        require(deadline >= block.timestamp, 'DEXManagement: EXPIRED');
        require(msg.value > 0 , "Invalid amount");
        require(address(swapTarget) != address(0), "Zero address");

        uint256 boughtAmount = IERC20(token).balanceOf(address(this));

        (bool success,) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, 'SWAP_CALL_FAILED');

        boughtAmount = IERC20(token).balanceOf(address(this)) - boughtAmount;

        require(IERC20(token).transfer(msg.sender, boughtAmount), "Faild Transfer");

        emit LogSwapExactETHForTokensOn0x(token, msg.value, boughtAmount);
    }

    /**
     * @param   token: InputToken Address to swap on Pancake
     * @param   _amountIn: Amount of InputToken to swap on Pancake
     * @param   _amountOutMin: The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ETH on Pancake
     */
    function swapExactTokenForETH(
        address token, 
        uint256 _amountIn, 
        uint256 _amountOutMin, 
        address to, 
        uint deadline
    ) external whenNotPaused nonReentrant {
        require(isPathExists(token, dexRouter_.WETH()), "Invalid path");
        require(_amountIn > 0 , "Invalid amount");

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = dexRouter_.WETH();
        
        require(IERC20(token).transferFrom(_msgSender(), address(this), _amountIn), "Faild TransferFrom");
        require(IERC20(token).approve(address(dexRouter_), _amountIn));

        uint256 boughtAmount = address(to).balance;
        dexRouter_.swapExactTokensForETHSupportingFeeOnTransferTokens(   
            _amountIn,         
            _amountOutMin,         
            path,
            to,
            deadline
        );
        boughtAmount = address(to).balance - boughtAmount;

        emit LogSwapExactTokenForETH(token, _amountIn, boughtAmount);
    }

    /**
     * @param   token: InputToken Address to swap on 0x, The `sellTokenAddress` field from the API response
     * @param   _amountIn: Amount of InputToken to swap on 0x, The `sellAmount` field from the API response
     * @param   spender: Spender to approve the amount of InputToken, The `allowanceTarget` field from the API response
     * @param   swapTarget: SwapTarget contract address, The `to` field from the API response
     * @param   swapCallData: CallData, The `data` field from the API response
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ETH by using 0x protocol
     */
    function swapExactTokenForETHOn0x(
        address token,
        uint256 _amountIn,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        address to,
        uint deadline
    ) external whenNotPaused nonReentrant {
        require(!isContract(_msgSender()), "msg sender should be wallet");
        require(swapTarget == getSwapTargetAddress(swapCallData), "wrong target address");
        require(deadline >= block.timestamp, 'DEXManagement: EXPIRED');
        require(_amountIn > 0 , "Invalid amount");
        require(address(swapTarget) != address(0), "Zero address");
        require(to != address(0), "'to' is Zero address");

        require(IERC20(token).transferFrom(_msgSender(), address(this), _amountIn), "Faild TransferFrom");
        
        require(IERC20(token).approve(spender, _amountIn));
        
        uint256 boughtAmount = address(this).balance;

        (bool success,) = swapTarget.call(swapCallData);
        require(success, 'SWAP_CALL_FAILED');

        boughtAmount = address(this).balance - boughtAmount;

        payable(to).transfer(boughtAmount);

        emit LogSwapExactTokenForETHOn0x(token, _amountIn, boughtAmount);
    }
    
    receive() external payable {
        emit LogReceived(_msgSender(), msg.value);
    }

    fallback() external payable { 
        emit LogFallback(_msgSender(), msg.value);
    }

    //-------------------------------------------------------------------------
    // set functions
    //-------------------------------------------------------------------------

    function setPause() external onlyMultiSig {
        _pause();
    }

    function setUnpause() external onlyMultiSig {
        _unpause();
    }

    function setDexRouter(address _newRouter) external onlyMultiSig whenNotPaused {
        require(address(dexRouter_) != _newRouter, "Same router!");
        dexRouter_ = IPancakeRouter02(_newRouter);
        
        emit LogSetDexRouter(_msgSender(), address(dexRouter_));
    }
}