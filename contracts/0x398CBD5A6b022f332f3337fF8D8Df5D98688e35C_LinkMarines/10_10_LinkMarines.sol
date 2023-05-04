pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswap.sol";

// https://www.linkmarine.vip/
contract LinkMarines is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant INITIAL_SUPPLY = 7125712571257 * (10 ** 18);
    uint256 public tradeLimitPercentage;
    uint256 public maxWalletLimitPercentage;
    mapping(address => bool) public blacklisted;
    bool public tradingLimitRemoved;
    bool public maxWalletLimitRemoved;
    address public uniswapV2Pair;

    constructor() ERC20("Link Marines", "MARINE") {
        _mint(address(this), INITIAL_SUPPLY);
        tradeLimitPercentage = 100;
        maxWalletLimitPercentage = 2;
        tradingLimitRemoved = false;
        maxWalletLimitRemoved = false;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        notBlacklisted(msg.sender, recipient)
        limitedTransfer(msg.sender, amount)
        maxWallet(recipient, amount)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        notBlacklisted(sender, recipient)
        limitedTransfer(sender, amount)
        maxWallet(recipient, amount)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function listOnUniswapV2(address uniswapV2Router) public payable onlyOwner {
        require(uniswapV2Router != address(0), "Invalid Uniswap V2 Router address");

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);
        _approve(address(this), address(_uniswapV2Router), INITIAL_SUPPLY);

        _uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this), INITIAL_SUPPLY, 0, 0, owner(), block.timestamp
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
    }

    function removeTradingLimit() public onlyOwner {
        tradingLimitRemoved = true;
    }

    function removeMaxWalletLimit() public onlyOwner {
        tradingLimitRemoved = true;
    }

    function blacklistBotAddress(address _address, bool _blacklisted) public onlyOwner {
        require(!tradingLimitRemoved || !_blacklisted, "Can only blacklist addresses before trading limit is removed");
        blacklisted[_address] = _blacklisted;
    }

    function blacklistMultipleBotAddresses(address[] memory _addresses, bool _blacklisted) public onlyOwner {
        require(!tradingLimitRemoved || !_blacklisted, "Can only blacklist addresses before trading limit is removed");
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklisted[_addresses[i]] = _blacklisted;
        }
    }

    function rescueERC20(IERC20 token) public onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    modifier notBlacklisted(address sender, address recipient) {
        require(!blacklisted[sender] && !blacklisted[recipient] && !blacklisted[tx.origin], "Address is blacklisted");
        _;
    }

    modifier limitedTransfer(address sender, uint256 amount) {
        if (!tradingLimitRemoved && sender != owner() && tx.origin != owner() && sender != address(this)) {
            uint256 limit = totalSupply() * tradeLimitPercentage / 100;
            require(amount <= limit, "Transfer amount exceeds transfer limit");
        }
        _;
    }

    modifier maxWallet(address recipient, uint256 amount) {
        if (!maxWalletLimitRemoved && recipient != owner() && recipient != uniswapV2Pair && tx.origin != owner() && recipient != address(this)) {
            uint256 limit = totalSupply() * maxWalletLimitPercentage / 100;
            require(balanceOf(recipient) + amount <= limit, "Balance exceeds max wallet limit");
        }
        _;
    }
}