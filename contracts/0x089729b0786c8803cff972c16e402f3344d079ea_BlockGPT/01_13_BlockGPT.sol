// SPDX-License-Identifier: MIT

/*
======================================
$BGPT
BlockGPT
Crypto companion AI
- https://blockgpt.app
- https://twitter.com/BlockGPT_erc20
======================================
*/
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BlockGPT is ERC20, Ownable {
    using SafeERC20 for IERC20;

    enum SupplyType {
        Seed,
        Team,
        CEX,
        Taxes
    }

    event ClaimSupply(
        address indexed to,
        uint256 amount,
        SupplyType indexed supplyType
    );

    // 1bn total supply
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    uint256 public constant SEED_SUPPLY = 150_000_000 * 10 ** 18;
    uint256 public constant TEAM_SUPPLY = 100_000_000 * 10 ** 18;
    uint256 public constant CEX_SUPPLY = 100_000_000 * 10 ** 18;

    uint256 public constant LIQUIDITY_SUPPLY = 650_000_000 * 10 ** 18;

    uint256 public constant SELL_FEE = 300; // 3%
    uint256 public constant BUY_FEE = 300; // 3%

    address private deployer;

    address public pair;
    address public feeWallet = 0xa8f9AfFAc2633fe0657B168DC5eaCcB7ab72FB7B;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Anti-bot and limitations
    uint256 public startBlock = 0;
    uint256 public deadBlocks = 5;
    uint256 public maxWallet = (TOTAL_SUPPLY * 1) / 100;
    mapping(address => bool) public isBlacklisted;

    address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool public tradingEnabled = false;

    constructor() ERC20("BlockGPT", "BGPT") {
        _mint(msg.sender, LIQUIDITY_SUPPLY);
        _mint(address(this), SEED_SUPPLY + TEAM_SUPPLY + CEX_SUPPLY);

        pair = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory())
            .createPair(
                address(this),
                IUniswapV2Router02(uniswapRouter).WETH()
            );

        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;
    }

    function setWhitelistStatus(
        address _wallet,
        bool _status
    ) external onlyOwner {
        whitelisted[_wallet] = _status;
    }

    function setFeeWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "address-is-0");
        feeWallet = _wallet;
    }

    function blacklistAddress(
        address _target,
        bool _status
    ) external onlyOwner {
        if (_status) {
            require(_target != pair, "Can't blacklist liquidity pool");
            require(_target != address(this), "Can't blacklisted the token");
        }
        isBlacklisted[_target] = _status;
    }

    function startTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        startBlock = block.number;
    }

    function removeLimits() external onlyOwner {
        maxWallet = TOTAL_SUPPLY;
    }

    function claimSupply(
        address _to,
        uint256 _amount,
        SupplyType _type
    ) external {
        require(
            msg.sender == owner() || msg.sender == deployer,
            "Only owner or deployer"
        );
        _transfer(address(this), _to, _amount);
        emit ClaimSupply(_to, _amount, _type);
    }

    function sweep(address _token) external {
        require(_token != address(this), "Cannot sweep this token");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(deployer, balance);
    }

    function sweepEth() external {
        uint256 balance = address(this).balance;
        payable(deployer).transfer(balance);
    }

    function _antiBot(address from, address to) internal {
        if (block.number <= startBlock + deadBlocks) {
            if (from == pair) {
                isBlacklisted[to] = true;
            }
            if (to == pair) {
                isBlacklisted[from] = true;
            }
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (sender != address(0) && recipient != address(0)) {
            require(!isBlacklisted[sender], "blacklisted");
            require(
                tradingEnabled || whitelisted[sender],
                "trading-not-enabled"
            );

            if (sender == pair && !whitelisted[recipient]) {
                // sell
                uint256 fee = (amount * SELL_FEE) / 10000;
                super._transfer(sender, feeWallet, fee);
                _antiBot(sender, recipient);

                amount -= fee;
            } else if (recipient == pair && !whitelisted[sender]) {
                // buy
                uint256 fee = (amount * BUY_FEE) / 10000;
                super._transfer(sender, feeWallet, fee);
                amount -= fee;
                _antiBot(sender, recipient);
            }
        }
        if (recipient != pair && !whitelisted[recipient]) {
            require(
                amount + balanceOf(recipient) <= maxWallet,
                "max-wallet-reached"
            );
        }
        super._transfer(sender, recipient, amount);
    }
}