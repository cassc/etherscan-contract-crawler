pragma solidity ^0.6.12;

import "./lib/ERC20.sol";

// File: contracts/FarmToken.sol
contract FarmToken is ERC20 {

    address minter;
    uint256 tradingStart;
    mapping(address => uint256) public transferLogs;
    uint256 public maxSupply = 4500 * 1e18;
    uint256 public constant BUY_SELL_DELAY = 15 minutes;

    modifier onlyMinter {
        require(msg.sender == minter, 'Only minter can call this function.');
        _;
    }

    modifier limitEarlyBuy (uint256 _amount) {
        require(tradingStart <= now ||
            msg.sender == minter ||
            _amount <= (40 * 1e18), "ERC20: early buys limited");
        _;
    }

    constructor(address _minter, uint256 _tradingStart) public ERC20('Cocktails', 'CKTL') {
        tradingStart = _tradingStart;
        minter = _minter;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        require(_totalSupply.add(amount) <= maxSupply, "ERC20: max supply exceeded");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyMinter {
        require (_maxSupply >= (4250*1e18) && _maxSupply <= (10000*1e18), "Invalid max supply");
        maxSupply = _maxSupply;
    }

    function transfer(address recipient, uint256 amount) public virtual override limitEarlyBuy (amount) returns (bool) {
        require (
            (tradingStart > now && transferLogs[_msgSender()].add(BUY_SELL_DELAY) < now)
            || _msgSender() == minter 
            || tradingStart <= now,
            "ERC20: moving too fast"
        );
        _transfer(_msgSender(), recipient, amount);
        transferLogs[_msgSender()] = now;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override limitEarlyBuy (amount) returns (bool) {
        require (
            (tradingStart > now && transferLogs[sender].add(BUY_SELL_DELAY) < now)
            || sender == minter 
            || tradingStart <= now,
            "ERC20: moving too fast"
        );
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        transferLogs[sender] = now;
        return true;
    }
}