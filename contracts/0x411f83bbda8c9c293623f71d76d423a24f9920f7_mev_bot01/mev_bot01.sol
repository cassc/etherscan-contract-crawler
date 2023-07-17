/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

interface IUniswapV2Router02{

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

contract mev_bot01{

    address owner;
    address public constant UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    uint constant max_uint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

     // constructor
    constructor() {
        owner = address(tx.origin);
    }

     // fallback, receive ETH
    receive() external payable {}

    // modifier
    modifier onlyOwner(){
        require(address(msg.sender) == owner, "Not owner, fuck off!");
        _;
    }

     // read function
    function Owner() public view returns(address) {
        return owner;
    }

    function changeOwner(address newOwner) external onlyOwner
    {
        owner = newOwner;
    }

    function timestimp_ahead(uint ahead) public view returns(uint256 timestamp){

        timestamp = block.timestamp + ahead;
    }

    // write function
    function withdraw_eth(uint wad) public onlyOwner{

        TransferHelper.safeTransferETH(msg.sender, wad);
    }

    function withdraw_erc20(address token_withdraw, uint wad) public onlyOwner{

        TransferHelper.safeTransfer(token_withdraw, msg.sender, wad);
    }

    function approve(address token_address, address token_spender, uint256 tokens_amount) public onlyOwner{
        
        TransferHelper.safeApprove(token_address, token_spender, tokens_amount);
    }

    function check_allowance(address token_address, address token_owner, address token_spender) public view returns(uint allowance) {

        allowance = IERC20(token_address).allowance(token_owner, token_spender);
    }

    function swapExactETHForTokens_mevbot1(uint amountIn, uint amountOutMin, address[] calldata path) public onlyOwner{
        
        // to this bot address
        address to = address(this);
        // 10 mins deadline
        uint deadline = timestimp_ahead(600);

        IUniswapV2Router02(UniswapV2Router02).swapExactETHForTokens{value: amountIn}(amountOutMin, path, to, deadline);
    }

    function swapExactTokensForETH_mevbot1(uint amountIn, uint amountOutMin, address[] calldata path) public onlyOwner{

        // to this bot address
        address to = address(this);
        // 10 mins deadline
        uint deadline = timestimp_ahead(600);
        //approve allowance
        uint allowance_bot_to_router = check_allowance(path[0], address(this), UniswapV2Router02);
        if (allowance_bot_to_router < amountIn){approve(path[0], UniswapV2Router02, max_uint);}

        IUniswapV2Router02(UniswapV2Router02).swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}