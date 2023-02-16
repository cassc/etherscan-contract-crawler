// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../lib/SafeMath.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../owner/Operator.sol";

contract ShareToken is ERC20, Operator {
    using SafeMath for uint256;
	
	uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant FARMING_POOL_REWARD_ALLOCATION = 18000 ether;

    bool public rewardPoolDistributed = false;

	mapping(address => uint256) private _balances;
	address[] public excluded;
	address public polWallet;
	uint256 private _totalSupply;
	uint256 private constant maxExclusion = 20;

	// Tax
	mapping (address => bool) public marketLpPairs; // LP Pairs
    bool public enabledTax;

	uint256 public taxSellingPercent = 0;
	mapping(address => bool) public excludedTaxAddresses;

    /* =================== Events =================== */
    event GrantExclusion(address indexed account);
	event RevokeExclusion(address indexed account);
	event EnableCalculateTax();
	event DisableCalculateTax();
	event SetPolWallet(address oldWallet, address newWallet);
	event SetTaxSellingPercent(uint256 oldValue, uint256 newValue);
	event SetTimeLimitSelling(uint256 oldValue, uint256 newValue);
	event SetMaximumAmountSellPercent(uint256 oldValue, uint256 newValue);

    constructor(address _polWallet, address _ethAddress, address _router) ERC20("SHIELD TOKEN", "SHDB") {
		require(_polWallet != address(0), "!_polWallet");
		require(_ethAddress != address(0), "!_ethAddress");
		require(_router != address(0), "!_router");
		_totalSupply = 0;
		polWallet = _polWallet;
		IUniswapV2Router _dexRouter = IUniswapV2Router(_router);
		address dexPair = IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _ethAddress);
        setMarketLpPairs(dexPair, true);

        _mint(msg.sender, INITIAL_SUPPLY);
    }

	function getExcluded() external view returns (address[] memory)
	{
		return excluded;
	}

	function circulatingSupply() public view returns (uint256) {
		uint256 excludedSupply = 0;
		uint256 excludedLength = excluded.length;
		for (uint256 i = 0; i < excludedLength; i++) {
			excludedSupply = excludedSupply.add(balanceOf(excluded[i]));
		}
		return _totalSupply.sub(excludedSupply);
	}

	function grantRebaseExclusion(address account) external onlyOperator
	{
		require(excluded.length <= maxExclusion, 'Too many excluded accounts');
		excluded.push(account);
		emit GrantExclusion(account);
	}

	function revokeRebaseExclusion(address account) external onlyOperator
	{
		uint256 excludedLength = excluded.length;
		for (uint256 i = 0; i < excludedLength; i++) {
			if (excluded[i] == account) {
				excluded[i] = excluded[excludedLength - 1];
				excluded.pop();
				emit RevokeExclusion(account);
				return;
			}
		}
	}

    //---OVERRIDE FUNCTION---
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        address sender = _msgSender();
        // Selling token
		if(marketLpPairs[to] && !excludedTaxAddresses[sender]) {
			if (enabledTax) {
				if (taxSellingPercent > 0) {
					uint256 taxAmount = amount.mul(taxSellingPercent).div(10000);
					if(taxAmount > 0)
					{
						amount = amount.sub(taxAmount);
						_transfer(sender, polWallet, taxAmount);
					}
				}
			}
		}
        _transfer(sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        // Selling token
		if(marketLpPairs[to] && !excludedTaxAddresses[from]) {
			if (enabledTax) {
				if (taxSellingPercent > 0) {
					uint256 taxAmount = amount.mul(taxSellingPercent).div(10000);
					if(taxAmount > 0)
					{
						amount = amount.sub(taxAmount);
						_transfer(from, polWallet, taxAmount);
					}
				}
			}
		}

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
		require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
        
	function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

	function burn(uint256 amount) external {
		if (amount > 0) _burn(_msgSender(), amount);
    }

    //---END OVERRIDE FUNCTION---

	function isPolWallet(address _address) external view returns (bool) {
		return _address == polWallet;
	}
	
	function setPolWallet(address _polWallet) external onlyOperator {
        require(_polWallet != address(0), "_polWallet address cannot be 0 address");
		emit SetPolWallet(polWallet, _polWallet);
        polWallet = _polWallet;
    }

	function excludeTaxAddress(address _address) external onlyOperator returns (bool) {
        require(!excludedTaxAddresses[_address], "Address can't be excluded");
        excludedTaxAddresses[_address] = true;
        return true;
    }

    function includeTaxAddress(address _address) external onlyOperator returns (bool) {
        require(excludedTaxAddresses[_address], "Address can't be included");
        excludedTaxAddresses[_address] = false;
        return true;
    }

	function enableCalculateTax() external onlyOperator {
        enabledTax = true;
		emit EnableCalculateTax();
    }

    function disableCalculateTax() external onlyOperator {
        enabledTax = false;
		emit DisableCalculateTax();
    }

	function setTaxSellingPercent(uint256 _value) external onlyOperator returns (bool) {
		require(_value <= 50, "Max tax is 0.5%");
		emit SetTaxSellingPercent(taxSellingPercent, _value);
        taxSellingPercent = _value;
        return true;
    }

	//Add new LP's for selling / buying fees
    function setMarketLpPairs(address _pair, bool _value) public onlyOperator {
        marketLpPairs[_pair] = _value;
    }

    function distributeReward(address _farmingPoolAddress) external onlyOperator {
        require(!rewardPoolDistributed, "only can distribute once");
        require(_farmingPoolAddress != address(0), "!_farmingPoolAddress");
        rewardPoolDistributed = true;
        _mint(_farmingPoolAddress, FARMING_POOL_REWARD_ALLOCATION);
    }
}