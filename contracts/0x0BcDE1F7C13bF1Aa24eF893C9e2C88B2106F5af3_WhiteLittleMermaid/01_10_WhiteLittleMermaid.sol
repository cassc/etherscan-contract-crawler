//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract WhiteLittleMermaid is ERC20, Ownable {

    string constant _name = "White Little Mermaid";
    string constant _symbol = "WLM";

    constructor() ERC20(_name, _symbol) {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        feeExempt[owner()] = true;
        feeExempt[address(this)] = true;
        feeExempt[address(0xdead)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    uint256 fees = 3;
    bool private tradingOpen;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public rt;
    address public pair;
    uint256 _totalSupply = 1_000_000_000 * (10 ** decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    mapping(address => bool) feeExempt;

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!tradingOpen) {
            require(
                feeExempt[sender] || feeExempt[recipient],
                "Trading is not active!"
            );
        }
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size!"
            );
        }
        uint256 taxed = needTakeFee(sender) ? getFee(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    receive() external payable {}

    function getFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fees) / 100;
        return feeAmount;
    }

    function setLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function needTakeFee(address sender) internal view returns (bool) {
        return !feeExempt[sender];
    }

}