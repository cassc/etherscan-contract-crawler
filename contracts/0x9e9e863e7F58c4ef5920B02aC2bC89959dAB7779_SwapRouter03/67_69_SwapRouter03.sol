// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './SwapRouter02.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import '@uniswap/v3-periphery/contracts/libraries/Path.sol';

/// @dev build upon Uniswap V2 and V3 Swap Router
contract SwapRouter03 is SwapRouter02, Ownable {

    // @dev used for decoding swap paths
    using Path for bytes;

    // @dev address to send fees to
    address public flushAddress;   
    bool public flushOnTransaction;   

    // @dev fee schedule
    uint256 public feeSchedule = 50;

    // @dev fee basis (50 = 0.50%)
    uint256 private feeBasis = 10000;

    // @dev token to use to discount fees 
    address public discountToken;

    // @dev minimum amount of token to hold to exclude fee
    uint256 public discountMinimumAmount;

    event Fee(address token, uint256 amount);   

    constructor(
        address _factoryV2,
        address factoryV3,
        address _positionManager,
        address _WETH9,
        address _flush
    ) 
    SwapRouter02(_factoryV2, factoryV3, _positionManager, _WETH9) {
        flushAddress = _flush;
    }

    // @dev allow owner to set flush address
    function setFlushAddress(address to) external onlyOwner{
        flushAddress = to;
    }
    // @dev allow owner to set flush address
    function setFlushOnTransaction(bool immediately) external onlyOwner{
        flushOnTransaction = immediately;
    }

    // @dev allow owner to set fee schedule
    function setFieldSchedule(uint256 amount) external onlyOwner{
        if( amount < feeBasis ) {
            feeSchedule = amount;
        }
    }

    // @dev allow owner to set discount token
    function setDiscountToken(address token) external onlyOwner{
        discountToken = token;
    }

    // @dev allow owner to set discount minimum amount 
    function setDiscountMinimumAmount(uint256 amount) external onlyOwner{
        discountMinimumAmount = amount;
    }

    // @dev flush eth
    function flush() external onlyOwner {
        TransferHelper.safeTransferETH(flushAddress, address(this).balance);
    }

    // @dev flush token
    function flushToken(address token) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(token), flushAddress, IERC20(token).balanceOf(address(this)));
    }

    // @dev calculate fee (if any)
    function calculateFee(uint256 amount) external view returns (uint256) {
        return _calculateFee(amount);
    }
    
    // @dev these are handled by processAmountOut
    function refundETH() external payable override {}
    function sweepToken(address token, uint256 amountMinimum) public payable override {}
    function sweepToken(address token, uint256 amountMinimum, address recipient) public payable override {}
    function sweepTokenWithFee(address token, uint256 amountMinimum, uint256 feeBips, address feeRecipient) external payable override {}
    function sweepTokenWithFee(address token, uint256 amountMinimum, address recipient, uint256 feeBips, address feeRecipient) external payable override {}
    function unwrapWETH9(uint256 amountMinimum) public payable override {}
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override {}
    function unwrapWETH9WithFee(uint256 amountMinimum, uint256 feeBips, address feeRecipient) external payable override {}
    function unwrapWETH9WithFee(uint256 amountMinimum, address recipient, uint256 feeBips, address feeRecipient) external payable override {}

    // @dev calculate fee implementation 
    function _calculateFee(uint256 amount) private view returns (uint256) {

        // do nothing when no fee
        if( feeSchedule == 0 || amount == 0 ) {
            return 0;
        }
        
        // consider discount when present
        if( discountToken != address(0) && discountMinimumAmount > 0 ) {
            // if sender meets requirements then zero fees
            if( IERC20(discountToken).balanceOf(msg.sender) >= discountMinimumAmount ) {
                return 0;
            }
        }

        // return fee
        return (amount * feeSchedule) / feeBasis;
    }

    // @dev evalulates fees and delivers token
    function processAmountOut(address token, uint256 amount, address to) private returns(uint256 amountOut) {

        uint256 fee = _calculateFee(amount);
        amountOut = amount - fee;

        // Deal with constants
        to = processTo(to);

        // flush fees on transaction
        if( flushOnTransaction && fee > 0 ) {
            SafeERC20.safeTransfer(IERC20(token), flushAddress, fee);
        }
        
        if( token == WETH9 ) {
            // send ETH when WETH
            IWETH9(WETH9).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        }
        else {
            // return tokens 
            SafeERC20.safeTransfer(IERC20(token), to, amountOut);
        }

        // emit fee
        emit Fee(token, fee);

        return amountOut;
    }

    function processTo(address to) private view returns (address recipient) {
        if (to == Constants.MSG_SENDER) recipient = msg.sender;
        else if (to == Constants.ADDRESS_THIS) recipient = msg.sender;
        else recipient = to;
    }    

//////////////////////////////////////////////////////////////////////////////
//
//  OVERRIDE V2
//
//////////////////////////////////////////////////////////////////////////////

    // @dev override swap and take any fees
    // @inheritdoc IV2SwapRouter
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable virtual override returns(uint256 amountOut) {

        // return amount out less fees
        amountOut = processAmountOut(
            path[path.length - 1],
            super.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this)),
            to 
        );

        return amountOut;
    }
        
    // @dev override swap and take any fees
    // @inheritdoc IV2SwapRouter
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable virtual override returns (uint256 amountIn) {

        // consider fee with amount out
        uint256 amountOutWithFee = amountOut + _calculateFee(amountOut);

        // set amount in considering fee
        amountIn = super.swapTokensForExactTokens(amountOutWithFee, amountInMax, path, address(this));

        // process any fees
        processAmountOut(
            path[path.length - 1],
            amountOutWithFee,
            to 
        );

        // return total amount in
        return amountIn;
    }
    
//////////////////////////////////////////////////////////////////////////////
//
//  OVERRIDE V3
//
//////////////////////////////////////////////////////////////////////////////

    // @dev used to get the final token in a path
    function getFinalToken(bytes memory path) private pure returns (address) {
        while (true) {
            if (path.hasMultiplePools()) {
                path = path.skipToken();
            } else {
                (, address token1, ) = path.decodeFirstPool();
                return token1;
            }
        }
    }

    // @dev override swap and take any fees
    // @inheritdoc IV3SwapRouter
    function exactInputSingle(ExactInputSingleParams memory params)
        public
        payable
        virtual
        override
        returns (uint256 amountOut)
    {

        // Save recipient
        address to = params.recipient;

        // replace with self
        params.recipient = address(this);

        // return amount out less fees
        amountOut = processAmountOut(
            params.tokenOut,
            super.exactInputSingle(params),
            to 
        );

        return amountOut;
    }

    // @dev override swap and take any fees
    // @inheritdoc IV3SwapRouter
    function exactInput(ExactInputParams memory params) public payable virtual override returns (uint256 amountOut) {

        // Save recipient
        address to = params.recipient;

        // replace with self
        params.recipient = address(this);

        // return amount out less fees
        amountOut = processAmountOut(
            getFinalToken(params.path),
            super.exactInput(params),
            to
        );

        return amountOut; 
    }

    // @dev override swap and take any fees
    // @inheritdoc IV3SwapRouter
    function exactOutputSingle(ExactOutputSingleParams memory params)
        public
        payable
        virtual
        override
        returns (uint256 amountIn)
    {

        // Save recipient
        address to = params.recipient;

        // replace with self
        params.recipient = address(this);

        // consider fee with amountout
        uint256 amountOutWithFee = params.amountOut + _calculateFee(params.amountOut);

        // Include the fee with amountout 
        params.amountOut = amountOutWithFee;

        // set amount in considering fee
        amountIn = super.exactOutputSingle(params);

        // process any fees
        processAmountOut(
            params.tokenOut,
            amountOutWithFee,
            to
        );

        // return total amount in
        return amountIn;
    }

    // @dev override swap and take any fees
    // @inheritdoc IV3SwapRouter
    function exactOutput(ExactOutputParams memory params) public payable virtual override returns (uint256 amountIn) {

        // Save recipient
        address to = params.recipient;

        // replace with self
        params.recipient = address(this);

        // consider fee with amountout
        uint256 amountOutWithFee = params.amountOut + _calculateFee(params.amountOut);

        // Include the fee with amountout 
        params.amountOut = amountOutWithFee;

        // set amount in considering fee
        amountIn = super.exactOutput(params);        

        // Path is reversed in exact output
        (address token0, ,) = params.path.decodeFirstPool();

        // process any fees
        processAmountOut(
            token0,
            amountOutWithFee,
            to
        );
    }
}