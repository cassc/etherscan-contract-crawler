// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract MOTHERDAY is Ownable, ERC20 {
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    bool public limited = true;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor() ERC20("Happy Mothers Day!", "MOTHERDAY") {
        uint256 _totalSupply = 10_000_000 * 10 ** 18;
        _mint(msg.sender, _totalSupply);
        maxHoldingAmount = _totalSupply;
        minHoldingAmount = 0;
    }

    function init(address _uniswapAddress) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _uniswapAddress
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(
        bool _limited,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(!blacklists[sender] && !blacklists[recipient], "Blacklisted");

        if (limited && sender == uniswapV2Pair) {
            require(
                balanceOf(recipient) + amount <= maxHoldingAmount &&
                    balanceOf(recipient) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
        super._transfer(sender, recipient, amount);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}