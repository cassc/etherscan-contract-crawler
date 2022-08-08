//SPDX-License-Identifier: MIT
/*
  /_\  ___  __ _  __ _  __ ___   ____ _ 
 //_\\/ __|/ _` |/ _` |/ _` \ \ / / _` |
/  _  \__ \ (_| | (_| | (_| |\ V / (_| |
\_/ \_/___/\__,_|\__, |\__,_| \_/ \__,_|
                 |___/                  ⠀⠀⠀⠀
*/

pragma solidity ^0.8.5;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Asagava is ERC20, Ownable {
    bool private trading;
    mapping(address => bool) limitExempt;
    IUniswapV2Router02 public rt;
    address public pair;
    uint256 fee = 4;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 _totalSupply = 9000000000 * (10**decimals());
    uint256 public _maxW = (_totalSupply * 4) / 100;
    mapping(address => bool) isFeeExempt;

    constructor() ERC20("Asagava", "$ASA") {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(0xdead)] = true;

        limitExempt[owner()] = true;
        limitExempt[address(0xdead)] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!trading) {
            require(
                isFeeExempt[sender] || isFeeExempt[recipient],
                "Trading is not active."
            );
        }
        if (recipient != pair && recipient != DEAD) {
            require(
                limitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxW,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFee(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    receive() external payable {}

    function openTrading() external onlyOwner {
        trading = true;
    }

    function getFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fee) / 100;
        return feeAmount;
    }

    function setLimit(uint256 amount) external onlyOwner {
        _maxW = (_totalSupply * amount) / 100;
    }

    function teamMessage(string memory input) external onlyOwner {}
}