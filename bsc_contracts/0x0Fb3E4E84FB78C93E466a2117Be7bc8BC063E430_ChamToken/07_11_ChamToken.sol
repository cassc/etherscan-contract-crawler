// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./owner/Operator.sol";
import "./lib/SafeMath.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract ChamToken is ERC20Burnable, Operator {
	using SafeMath for uint256;

    uint256 public constant INITIAL_SUPPLY = 5000 ether;

    address public polWallet;
    mapping (address => bool) public marketLpPairs; // LP Pairs
    mapping(address => bool) public excludedAccountSellingLimitTime;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    mapping(address => bool) private _isExcluded;
	address[] public excluded;
    uint256 private constant maxExclusion = 20;

    uint256 public taxSellingPercent = 0;
    mapping(address => bool) public excludedSellingTaxAddresses;

    uint256 public taxBuyingPercent = 0;
    mapping(address => bool) public excludedBuyingTaxAddresses;

    uint256 public timeLimitSelling = 0;
    mapping(address => uint256) private _lastTimeReceiveToken;

    /* =================== Events =================== */
    event GrantExclusion(address indexed account);
	event RevokeExclusion(address indexed account);
    event SetPolWallet(address oldWallet, address newWallet);
    event SetTaxSellingPercent(uint256 oldValue, uint256 newValue);
    event SetTaxBuyingPercent(uint256 oldValue, uint256 newValue);
    event SetTimeLimitSelling(uint256 oldValue, uint256 newValue);

    constructor(address _polWallet, address _wbnbAddress, address _router) ERC20("XToken", "XTN") {
        require(_polWallet != address(0), "!_polWallet");
        require(_wbnbAddress != address(0), "!_wbnbAddress");
        require(_router != address(0), "!_router");

        polWallet = _polWallet;

        IUniswapV2Router _dexRouter = IUniswapV2Router(_router);
		address dexPair = IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _wbnbAddress);
        setMarketLpPairs(dexPair, true);
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /* =================== GET FUNCTIONS =================== */
    function getExcluded() external view returns (address[] memory)
	{
		return excluded;
	}

    function isAddressExcluded(address _address) external view returns (bool) {
        return _isExcluded[_address];
    }

    function circulatingSupply() public view returns (uint256) {
		uint256 excludedSupply = 0;
		uint256 excludedLength = excluded.length;
		for (uint256 i = 0; i < excludedLength; i++) {
			excludedSupply = excludedSupply.add(balanceOf(excluded[i]));
		}
		return totalSupply().sub(excludedSupply);
	}

    /* =================== SET FUNCTIONS =================== */
    function grantRebaseExclusion(address account) external onlyOperator
	{
        if (_isExcluded[account]) return;
		require(excluded.length <= maxExclusion, 'Too many excluded accounts');
		_isExcluded[account] = true;
		excluded.push(account);
		emit GrantExclusion(account);
	}

    function revokeRebaseExclusion(address account) external onlyOperator
	{
		require(_isExcluded[account], 'Account is not already excluded');
		uint256 excludedLength = excluded.length;
		for (uint256 i = 0; i < excludedLength; i++) {
			if (excluded[i] == account) {
				excluded[i] = excluded[excludedLength - 1];
				_isExcluded[account] = false;
				excluded.pop();
				emit RevokeExclusion(account);
				return;
			}
		}
	}

    function setPolWallet(address _polWallet) external onlyOperator {
        require(_polWallet != address(0), "_polWallet address cannot be 0 address");
		emit SetPolWallet(polWallet, _polWallet);
        polWallet = _polWallet;
    }

    function setTaxSellingPercent(uint256 _value) external onlyOperator returns (bool) {
		require(_value <= 50, "Max tax is 0.5%");
		emit SetTaxSellingPercent(taxSellingPercent, _value);
        taxSellingPercent = _value;
        return true;
    }

    function setTaxBuyingPercent(uint256 _value) external onlyOperator returns (bool) {
		require(_value <= 50, "Max tax is 0.5%");
		emit SetTaxBuyingPercent(taxBuyingPercent, _value);
        taxBuyingPercent = _value;
        return true;
    }

    function setTimeLimitSelling(uint256 _value) external onlyOperator returns (bool) {
		require(_value <= 30 minutes, "Max limit time is 30 minutes");
		emit SetTimeLimitSelling(timeLimitSelling, _value);
        timeLimitSelling = _value;
        return true;
    }

    function excludeSellingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(!excludedSellingTaxAddresses[_address], "Address can't be excluded");
        excludedSellingTaxAddresses[_address] = true;
        return true;
    }

    function includeSellingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(excludedSellingTaxAddresses[_address], "Address can't be included");
        excludedSellingTaxAddresses[_address] = false;
        return true;
    }

    function excludeBuyingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(!excludedBuyingTaxAddresses[_address], "Address can't be excluded");
        excludedBuyingTaxAddresses[_address] = true;
        return true;
    }

    function includeBuyingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(excludedBuyingTaxAddresses[_address], "Address can't be included");
        excludedBuyingTaxAddresses[_address] = false;
        return true;
    }

    function excludeAccountSellingLimitTime(address _address) external onlyOperator returns (bool) {
        require(!excludedAccountSellingLimitTime[_address], "Address can't be excluded");
        excludedAccountSellingLimitTime[_address] = true;
        return true;
    }

    function includeAccountSellingLimitTime(address _address) external onlyOperator returns (bool) {
        require(excludedAccountSellingLimitTime[_address], "Address can't be included");
        excludedAccountSellingLimitTime[_address] = false;
        return true;
    }

    //Add new LP's for selling / buying fees
    function setMarketLpPairs(address _pair, bool _value) public onlyOperator {
        marketLpPairs[_pair] = _value;
    }

    /* =================== OVERRIDE FUNCTIONS =================== */
	function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
		require(from != address(0), "zero address");
        require(to != address(0), "zero address");
        require(polWallet != address(0),"require to set polWallet address");

        // Selling token
		if(marketLpPairs[to] && !excludedSellingTaxAddresses[from]) {
            require(excludedAccountSellingLimitTime[from] || block.timestamp > _lastTimeReceiveToken[from].add(timeLimitSelling), "Selling limit time");
            if (taxSellingPercent > 0) {
                uint256 taxAmount = amount.mul(taxSellingPercent).div(10000);
                if(taxAmount > 0)
                {
                    amount = amount.sub(taxAmount);
                    _transferBase(from, polWallet, taxAmount);
                }
            }
		} 
        // Buying token
        else if(marketLpPairs[from] && !excludedBuyingTaxAddresses[to] && taxBuyingPercent > 0) {
            uint256 taxAmount = amount.mul(taxBuyingPercent).div(10000);
            if(taxAmount > 0)
            {
                amount = amount.sub(taxAmount);
                _transferBase(from, polWallet, taxAmount);
            }
        }

        _transferBase(from, to, amount);
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

    /* =================== INTERNAL FUNCTIONS =================== */
    function _transferBase(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _lastTimeReceiveToken[to] = block.timestamp;
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        _afterTokenTransfer(from, to, amount);
    }
}