pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract CSGO is ERC20, Ownable {
    string private constant _name = "CounterStrike";
    string private constant _symbol = "CSGO";
    uint8 private constant _decimals = 9;

    mapping (address => bool) private _excludedFromMevProtection;
    mapping (address => uint) private _lastTx;

    uint256 public constant MAX_SUPPLY = 100000000000;
    
    address private _uniswapV2Router;
    address private _uniswapV2Pool;

    bool public mevProtection = false;

    constructor(
        address uniswapV2Router_
    ) ERC20(_name, _symbol) {
        _uniswapV2Router = uniswapV2Router_;
        _uniswapV2Pool = IUniswapV2Factory(IUniswapV2Router02(_uniswapV2Router).factory()).createPair(address(this), IUniswapV2Router02(_uniswapV2Router).WETH());
        _excludedFromMevProtection[owner()] = true;
        _mint(owner(), MAX_SUPPLY * 10 ** uint256(_decimals));
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (mevProtection) {
            if (_uniswapV2Pool == to && !_excludedFromMevProtection[from]) {
                require(_lastTx[from] < block.number, "BOT: Cheater detected");
                _lastTx[from] = block.number;
            } else if (_uniswapV2Pool == from && !_excludedFromMevProtection[to]) {
                require(_lastTx[to] < block.number, "BOT: Cheater detected");
                _lastTx[to] = block.number;
            }
        }
        
        super._transfer(from, to, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function setBotProtection(bool mevProtection_) public onlyOwner {
        mevProtection = mevProtection_;
    }

    function excludeFromBotProtection(address account) public onlyOwner {
        _excludedFromMevProtection[account] = true;
    }

    function includeInBotProtection(address account) public onlyOwner {
        _excludedFromMevProtection[account] = false;
    }
}