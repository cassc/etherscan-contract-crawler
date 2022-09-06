//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICheapSwapFactory.sol";
import "./lib/ISwapRouter.sol";
import "./lib/IWETH.sol";
import "./CheapSwapTokenOutAddress.sol";
import "./CheapSwapTargetAddress.sol";

contract CheapSwapFactory is ICheapSwapFactory, Ownable {
    ISwapRouter public Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWETH9 public WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    mapping(address => bytes) public pathMap;
    mapping(address => uint256) public oneETHAmountOutMinMap;
    mapping(address => mapping(address => address)) public tokenOutAddressMap;
    mapping(address => mapping(address => address)) public targetAddressMap;

    uint256 public fee = 0.001 ether;

    constructor() {
        WETH.approve(address(Router), type(uint256).max);
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function createTokenOutAddress(address tokenOut) external {
        CheapSwapTokenOutAddress cheapSwapTokenOutAddress = new CheapSwapTokenOutAddress(msg.sender, tokenOut);
        tokenOutAddressMap[msg.sender][tokenOut] = address(cheapSwapTokenOutAddress);
    }

    function createTargetAddress(
        address target,
        uint256 value,
        bytes calldata data
    ) external {
        CheapSwapTargetAddress cheapSwapTargetAddress = new CheapSwapTargetAddress(msg.sender, target, value, data);
        targetAddressMap[msg.sender][target] = address(cheapSwapTargetAddress);
    }

    function amountInETH_amountOutMin(address tokenOut, address recipient) external payable {
        require(msg.value > fee, "CheapSwapFactory: value too low");
        require(pathMap[tokenOut].length != 0, "CheapSwapFactory: empty path");
        uint256 amountIn = msg.value - fee;
        WETH.deposit{value: amountIn}();
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: pathMap[tokenOut],
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: (amountIn * oneETHAmountOutMinMap[tokenOut]) / 10**18
        });
        Router.exactInput(params);
    }

    /* ================ ADMIN FUNCTIONS ================ */

    function getFee(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setPath(address tokenOut, bytes calldata path) external onlyOwner {
        pathMap[tokenOut] = path;
    }

    function setOneETHAmountOutMin(address tokenOut, uint256 oneETHAmountOutMin) external onlyOwner {
        oneETHAmountOutMinMap[tokenOut] = oneETHAmountOutMin;
    }
}