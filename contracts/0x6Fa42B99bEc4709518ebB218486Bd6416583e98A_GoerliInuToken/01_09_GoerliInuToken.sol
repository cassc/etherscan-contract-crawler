// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "ERC20.sol";
import "Ownable.sol";

import "IUniswapV2Router02.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Router02.sol";


contract GoerliInuToken is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;

    bool private swapping;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    uint256 public supply;
    uint256 public delayDigit = 2;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    bool public limitsInEffect = true;

    constructor() ERC20("Goerli Inu", "GNU") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                                                          .createPair(address(this), _uniswapV2Router.WETH());
        uint256 totalSupply = 5.555_555_555_555e12 * 1e18;
        supply = totalSupply;
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function updateDelayDigit(uint256 newNum) external onlyOwner {
        delayDigit = newNum;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() && to != owner() &&
                to != address(0) && to != address(0xdead) && !swapping
            ) {
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] < block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number + delayDigit;
                    }
                }
            }
        }

        super._transfer(from, to, amount);
    }
}