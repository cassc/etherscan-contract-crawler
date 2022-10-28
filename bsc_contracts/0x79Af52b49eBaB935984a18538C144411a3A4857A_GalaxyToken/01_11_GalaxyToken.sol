// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../lib/IUniswapV2Pair.sol";
import "../lib/IUniswapV2Factory.sol";
import "../lib/IUniswapV2Router.sol";

// No reflections
// Just regular token with tax.

contract GalaxyToken is ERC20Upgradeable, OwnableUpgradeable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    uint256 public _totalSupply;
    uint256 public maxWalletHoldings;

    address public swapVaultAddress;

    uint256 public totalBuyFee;
    uint256 public totalSellFee;

    bool public _hasLiqBeenAdded;

    uint256 public launchedAt;
    uint256 public snipersCaught;
    bool public paused;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) public isBlacklisted;

    bool private swapping;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event AddToWhitelist(address indexed account, bool isWhitelisted);
    event AddToBlacklist(address indexed account, bool isBlacklisted);
    event SwapVaultAddressUpdated(
        address indexed newAddress
    );
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    receive() external payable {}

    function initialize(
        address _swapVaultAddress,
        address _uniswapAddress,
        string memory _name,
        string memory _ticker
    ) public initializer {
        __ERC20_init(_name, _ticker);
        __Ownable_init();

        swapVaultAddress = _swapVaultAddress;

        _totalSupply = 700e12 * 1e18; // 700T
        maxWalletHoldings = _totalSupply; // 66; No threshold for max walet.

        totalBuyFee = 1000; // basis points
        totalSellFee = 1000;

        launchedAt = 0;
        snipersCaught = 0;
        paused = false;

        _hasLiqBeenAdded = false;

        // Set Uniswap Address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(_uniswapAddress)
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        whitelist(address(this), true);
        whitelist(owner(), true);
        super._mint(owner(), _totalSupply);
    }

    /******
     * ADMIN SETTINGS
     ******/
    function updateSwapVaultAddress(address _swapVaultAddress)
        public
        onlyOwner
    {   
        swapVaultAddress = _swapVaultAddress;
        whitelist(swapVaultAddress, true);
        emit SwapVaultAddressUpdated(swapVaultAddress);
    }

    function updateMarketingVariables(
        uint256 _totalBuyFee,
        uint256 _totalSellFee
    ) public onlyOwner {
        totalBuyFee = _totalBuyFee;
        totalSellFee = _totalSellFee;
    }

    function setPaused(bool _isPaused) public onlyOwner {
        paused = _isPaused;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "TOKEN: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!(isBlacklisted[from] && !whitelisted[from]), "TOKEN: BLOCKED TRANSFER");
        require(!paused, "TOKEN: PAUSED");

        // prevents premature launch exploit
        require(amount > 0, "TOKEN: Amount Must be greater than zero");

        // Sniper Protection
        if (!_hasLiqBeenAdded) {
            // If no liquidity yet, allow owner to add liquidity
            _checkLiquidityAdd(from, to);
        } else {
            // if liquidity has already been added.
            if (
                launchedAt > 0 &&
                from == uniswapV2Pair &&
                owner() != from &&
                owner() != to
            ) {
                if (block.number - launchedAt < 10) {
                    _blacklist(to, true);
                    snipersCaught = snipersCaught + 1;
                }
            }
        }

        
        bool takeFee = true;
        // if any account is whitelisted account then remove the fee

        if (whitelisted[from] || whitelisted[to]) {
            takeFee = false;
        }

        // To disable tradingEnabled, set max wallet holdings to something super low.
        if (takeFee) {
            // define default fees as sells
            uint256 fees = (amount * totalSellFee) / (10000);

            if (!automatedMarketMakerPairs[to]) {
                // if we're not sending to uniswap - ie we're sending to someone else aka a buy,
                // set fees for buys
                fees = (amount * totalBuyFee) / (10000);
                
                require(
                    balanceOf(address(to)) + (amount) < maxWalletHoldings,
                    "Max Wallet Limit"
                );
            }
            
            amount = amount - (fees);
            super._transfer(from, swapVaultAddress, fees);
        }
        super._transfer(from, to, amount);
    }

    // sniper stuff.
    function _checkLiquidityAdd(address from, address to) private {
        // if liquidity is added by the _liquidityholders set
        // trading enables to true and start the anti sniper timer
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        // require liquidity has been added == false (not added).
        // This is basically only called when owner is adding liquidity.

        if (from == owner() && to == uniswapV2Pair) {
            _hasLiqBeenAdded = true;
            launchedAt = block.number;
        }
    }

    function whitelist(address account, bool isWhitelisted) public onlyOwner {
        whitelisted[account] = isWhitelisted;
        emit AddToWhitelist(account, isWhitelisted);
        (account, isWhitelisted);
    }

    function blacklist(address account, bool _isBlacklisted) public onlyOwner{
        _blacklist(account, _isBlacklisted);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        launchedAt = block.number;
        _hasLiqBeenAdded = true;
    }

    /**********/
    /* PRIVATE FUNCTIONS */
    /**********/

    function _blacklist(address account, bool _isBlacklisted) private {
        isBlacklisted[account] = _isBlacklisted;
        emit AddToBlacklist(account, _isBlacklisted);
        (account, _isBlacklisted);
    }


    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "TOKEN: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TOKEN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
}