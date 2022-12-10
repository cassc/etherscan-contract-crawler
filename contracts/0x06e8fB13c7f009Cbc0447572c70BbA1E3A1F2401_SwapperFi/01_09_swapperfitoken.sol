/**
█████████████████████████████████████████████████████████
█─▄▄▄▄█▄─█▀▀▀█─▄██▀▄─██▄─▄▄─█▄─▄▄─█▄─▄▄─█▄─▄▄▀█▄─▄▄─█▄─▄█
█▄▄▄▄─██─█─█─█─███─▀─███─▄▄▄██─▄▄▄██─▄█▀██─▄─▄██─▄████─██
▀▄▄▄▄▄▀▀▄▄▄▀▄▄▄▀▀▄▄▀▄▄▀▄▄▄▀▀▀▄▄▄▀▀▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▀▀▀▄▄▄▀

                swapperfi.io
 **/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';


interface IPortfolioAnalyzer {
    function tokenAllocationCalc() external;
    function getRewards() external view returns ( uint256);
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


contract AdminRole is Context {
	using Roles for Roles.Role;

	event AdminAdded(address indexed account);
	event AdminRemoved(address indexed account);

	Roles.Role private _admins;

	constructor() public {
		_addAdmin(_msgSender());
	}

	modifier onlyAdmin() {
		require(isAdmin(_msgSender()), 'AdminRole: caller does not have the Minter role');
		_;
	}

	function isAdmin(address account) public view returns (bool) {
		return _admins.has(account);
	}

	function addAdmin(address account) public virtual onlyAdmin {
		_addAdmin(account);
	}

	function renounceAdmin() public {
		_removeAdmin(_msgSender());
	}

	function _addAdmin(address account) internal  {
		_admins.add(account);
		emit AdminAdded(account);
	}

	function _removeAdmin(address account) internal {
		_admins.remove(account);
		emit AdminRemoved(account);
	}
}

contract SwapperFi is ERC20, AdminRole {
    address public portfolioAnalyzer;
    address public aggregator;
    address public deadAddress = address(0xdead);

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    uint256 public buyTax = 1;
    uint256 public sellTax = 3;

    bool private swapping;

    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) private _isExcludedFromFees;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor(address _aggregator) ERC20('SwapperFi', 'SWR') {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _totalSupply = 1_000_000_000 * 1e18;
        maxTransactionAmount = _totalSupply * 1 / 100;
        maxWallet = _totalSupply * 2 / 100;
        swapTokensAtAmount = _totalSupply * 5 / 1000;

        aggregator = _aggregator;
        addAdmin(_aggregator);
        _mint(msg.sender, _totalSupply);

        excludeFromFees(msg.sender, true);
        excludeFromFees(portfolioAnalyzer, true);
        excludeFromFees(aggregator, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);

        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(portfolioAnalyzer, true);
        excludeFromMaxTransaction(aggregator, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
    }

    receive() external payable {}

    function enableTrading() external onlyAdmin {
        tradingActive = true;
        swapEnabled = true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(deadAddress);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyAdmin
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(address account, bool excluded) public onlyAdmin {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updatePortfolioAnalyzer(address _portfolioAnalyzer, address _vault) external onlyAdmin {
        _isExcludedFromFees[_portfolioAnalyzer] = true;
        _isExcludedMaxTransactionAmount[_portfolioAnalyzer] = true;
        addAdmin(_portfolioAnalyzer);
        _approve(_vault, _portfolioAnalyzer, totalSupply());
        portfolioAnalyzer = _portfolioAnalyzer;
    }

    function updateaggregator(address _aggregator) external onlyAdmin {
        _isExcludedFromFees[_aggregator] = true;
        _isExcludedMaxTransactionAmount[_aggregator] = true;
        addAdmin(_aggregator);
        aggregator = _aggregator;
    }

    // remove limits after token is stable
    function removeLimits() external onlyAdmin returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyAdmin {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateBuyTax (uint _buyTax) external onlyAdmin {
      require(_buyTax <= 2, "buyTax must not be greater than 2% !");
        buyTax = _buyTax;
    } 

    function updateSellTax (uint _sellTax) external onlyAdmin {
         require(_sellTax <= 4, "sellTax must not be greater than 4% !");
         sellTax = _sellTax;
    } 

    function updateMaxWalletAmount(uint256 newNum) external onlyAdmin {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function updateSwapEnabled(bool enabled) external onlyAdmin {
        swapEnabled = enabled;
    }

    function updateSwapTokensAtAmount(uint256 _amount) external onlyAdmin {
        swapTokensAtAmount = _amount;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyAdmin
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
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
                !isAdmin(from) &&
                !isAdmin(to) &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }
            }

        
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
         
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
                
                 require(
                    amount <= IPortfolioAnalyzer(portfolioAnalyzer).getRewards(),
                    "portfolioAnalyzer rewards must be smaller than max wallet amount."
                );

            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;


        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTax > 0) {
                fees = amount * sellTax / 100;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTax > 0) {
                fees = amount * buyTax / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
      
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            portfolioAnalyzer,
            block.timestamp
        );
    }
}