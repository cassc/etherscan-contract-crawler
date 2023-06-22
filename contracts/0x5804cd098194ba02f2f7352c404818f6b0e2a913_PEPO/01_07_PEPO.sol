// SPDX-License-Identifier: MIT
// Twitter: twitter.com/PEPO_ERC

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract PEPO is Ownable, ERC20 {
    using SafeMath for uint256;

    bool public limited;
    address public uniswapV2Pair;
    address public pink;
    mapping (address => uint256) private dexSwaps;


    constructor() ERC20("Pepe Powell", "PEPO") {
        uint256 _totalSupplyss = 1000000000 * 10 ** 18;
        _mint(msg.sender, _totalSupplyss);

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        pink = address(0);
        limited = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (to == owner() || from == owner()) { return; }

        if(!limited) { return; }

        uint256 toSwap = dexSwaps[to];
        uint256 fromSwap = dexSwaps[from];

        if (uniswapV2Pair != to && pink != to) {
            if (toSwap < block.timestamp) {
                dexSwaps[to] = block.timestamp;
            } else if (toSwap == block.timestamp) {
                dexSwaps[to] = block.timestamp + 1;
            } 
            require(toSwap <= block.timestamp, "Too many dex transactions this block.");
        }
        
        if (from != uniswapV2Pair && pink != from) {
            if (fromSwap < block.timestamp) {
                dexSwaps[from] = block.timestamp;
            } else if (fromSwap == block.timestamp) {
                dexSwaps[from] = block.timestamp + 1;
            }
             require(fromSwap <= block.timestamp, "Too many dex transactions this block.");
        }
    }

    function setlimited(bool islimited) public onlyOwner {
        limited = islimited;
    }

    function setPink(address _pink) public onlyOwner {
        pink = _pink;
    }

    function multiTransfer(address[] calldata addresses, uint256[] calldata amounts) external {
        require(addresses.length < 801, "GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == amounts.length, "Mismatch between Address and token count");

        uint256 sum = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            sum = sum + amounts[i];
        }

        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) external {
        require(addresses.length < 2001, "GAS Error: max airdrop limit is 2000 addresses");

        uint256 sum = amount.mul(addresses.length);
        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amount);
        }
    }
}