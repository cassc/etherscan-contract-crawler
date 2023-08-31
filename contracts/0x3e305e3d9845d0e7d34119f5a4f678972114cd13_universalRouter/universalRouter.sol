/**
 *Submitted for verification at Etherscan.io on 2023-08-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

contract universalRouter {
    address public immutable DEV;

    address payable private administrator;

    mapping(address => bool) private whiteList;

    receive() external payable {}

    modifier onlyAdmin() {
        require(msg.sender == DEV, "admin: wut do you try?");
        _;
    }

    constructor() public {
        DEV = administrator = payable(msg.sender);
        whiteList[msg.sender] = true;
    }

    function sendTokenBack(address token, uint256 amount) external virtual onlyAdmin {
        TransferHelper.safeTransfer(token, DEV, amount);
    }

    function sendTokenBackAll(address token) external virtual onlyAdmin {
        TransferHelper.safeTransfer(token, DEV, IERC20(token).balanceOf(address(this)));
    }

    function sendEthBack() external virtual onlyAdmin {
        administrator.transfer(address(this).balance);
    }

    function setWhite(address account) external virtual onlyAdmin {
        whiteList[account] = true;
    }

    function balanceOf(address _token, address tokenOwner) public view returns (uint balance) {
      return IERC20(_token).balanceOf(tokenOwner);
    }

    function decimals(address _token) public view returns (uint8 decimal) {
      return IERC20(_token).decimals();
    }

    function getAmountsOut(address _router, uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return IUniswapV2Router02(_router).getAmountsOut(amountIn, path);
    }

    function execute(address _router, address tokenA, address tokenB, uint amountIn, uint amountOutMin, uint deadline, uint swapFee) external virtual {
        require(whiteList[msg.sender], "not on the white list");
        address[] memory _path = new address[](2);
        _path[0] = tokenA;
        _path[1] = tokenB;
        IERC20(_path[0]).approve(_router, amountIn);
        if(swapFee==0){
            IUniswapV2Router02(_router).swapExactTokensForTokens(amountIn, amountOutMin, _path, address(this), deadline);
        }else{
            IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, _path, address(this), deadline);
        }
        
    }

    function multicall(address _router, address tokenA, address tokenB, uint amountIn, uint amountOutMin, uint deadline, uint swapFee) external virtual {
        require(whiteList[msg.sender], "not on the white list");
        address[] memory _path = new address[](2);
        _path[0] = tokenA;
        _path[1] = tokenB;
        IERC20(_path[0]).approve(_router, amountIn);
        if(swapFee==0){
            IUniswapV2Router02(_router).swapExactTokensForTokens(amountIn, amountOutMin, _path, address(this), deadline);
        }else{
            IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, _path, address(this), deadline);
        }
    }


}