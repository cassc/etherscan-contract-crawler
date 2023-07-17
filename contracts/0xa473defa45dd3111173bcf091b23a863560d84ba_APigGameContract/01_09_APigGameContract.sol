// SPDX-License-Identifier: MIT

/*
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES  
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 
DON'T BUY THIS TOKEN UNTIL YOU READ THE RULES 

RULES: https://pignomic.com/

TWITTER: @PIGNOMICS
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BurnContract {
    IERC20 public token;

    constructor(address _contract) {
        token = IERC20(_contract);
    }

    function getSupplyLeft() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

contract APigGameContract is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 1e18;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public zoneLimit;
    uint256 public winThreshold;
    uint256 public winBlockNumber;

    bool public tradingEnabled;
    bool internal _hasBegun;
    bool public winnerFound = false;
    bool public isRewardClaimed = false;

    //5% tax on buy/sell
    uint256 public transactionFee = 500;
    uint256 public burnPerTransaction = 4000;

    mapping(address => bool) internal _exempt;
    mapping(address => uint256) internal _timeExpiration;

    address payable internal _vault;
    address public burnAddress;
    address payable internal winner;

    error AlreadyInitialized();
    error AlreadyBegun();

    event AddressInRed(address account, uint256 timestamp);
    event AddressInRedExpired(address account, uint256 amount);
    event TradingBegins(uint256 timestamp);
    event GameBegins(uint256 timestamp);
    event FeesBurned(uint256 amount);
    event AddressEscapedZone(address account);

    modifier _onlyWinner() {
        require(winner == _msgSender(), "winners only");
        _;
    }

    modifier _isGameStart() {
        require(_hasBegun == true, "game has not start");
        _;
    }

    constructor() ERC20("A Pig Game", "PIG") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _vault = payable(address(this));
        BurnContract burn = new BurnContract(address(this));
        burnAddress = address(burn);

        _exempt[owner()] = true;
        _exempt[address(this)] = true;
        _exempt[burnAddress] = true;
        _mint(address(this), _applyBasisPoints(TOTAL_SUPPLY, 1000));
        _mint(burnAddress, _applyBasisPoints(TOTAL_SUPPLY, 9000));
    }

    function openTrading() external onlyOwner {
        if (tradingEnabled) revert AlreadyInitialized();

        _approve(address(this), address(uniswapV2Router), TOTAL_SUPPLY);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).transfer(
            owner(),
            IERC20(uniswapV2Pair).balanceOf(address(this))
        );

        tradingEnabled = true;
    }

    function begin() external onlyOwner {
        if (_hasBegun) revert AlreadyBegun();

        renounceOwnership();
        winThreshold = 15;
        zoneLimit = _applyBasisPoints(totalSupply(), 100);
        _hasBegun = true;
        emit GameBegins(block.timestamp);
    }

    function huntPig(address account) external _isGameStart {
        if (_exempt[account] || account == address(uniswapV2Pair)) {
            return;
        }

        if (
            balanceOf(account) < totalSupply() / 100 ||
            _timeExpiration[account] > 0
        ) {
            return;
        }
        _timeExpiration[account] = block.number + 10000;
        emit AddressInRed(account, _timeExpiration[account]);
    }

    function killPig(address account) external _isGameStart {
        if (_exempt[account] || account == address(uniswapV2Pair)) {
            return;
        }

        if (
            _timeExpiration[account] == 0 ||
            block.number <= _timeExpiration[account]
        ) {
            return;
        }
        uint256 amount = balanceOf(account);
        _burnFees(account, amount, 10000);
        emit AddressInRedExpired(account, block.timestamp);
    }

    function escape() external _isGameStart {
        if (_timeExpiration[msg.sender] == 0) {
            return;
        }

        if (balanceOf(msg.sender) < totalSupply() / 100) {
            _timeExpiration[msg.sender] = 0;
            emit AddressEscapedZone(msg.sender);
        }
    }

    function checkIsWinner() external _isGameStart {
        if (
            balanceOf(msg.sender) < ((totalSupply() * winThreshold) / 100) ||
            winnerFound
        ) {
            return;
        }
        winner = payable(msg.sender);
        winnerFound = true;
        winBlockNumber = block.number;
    }

    function rewardWinner() external _onlyWinner {
        if (block.number <= winBlockNumber + 2) {
            return;
        }

        uint256 vaultBalance = balanceOf(address(_vault));
        super._transfer(_vault, winner, vaultBalance);
        isRewardClaimed = true;
        _exempt[msg.sender] = true;
        _timeExpiration[msg.sender] = 0;
        emit AddressEscapedZone(msg.sender);
    }

    receive() external payable {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0) || to == address(0)) return;

        if (_timeExpiration[from] > 0 && to != address(this)) {
            revert(
                "LOCKED: address has been hunted and cannot sell. RULES-> https://pignomic.com/"
            );
        }

        if (winnerFound && from == winner && !isRewardClaimed) {
            revert("Winner must claim reward before selling.");
        }
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

        uint256 finalAmount = _chargeFees(from, to, amount);

        if (_hasBegun) {
            _burnFees(burnAddress, finalAmount, burnPerTransaction);
        }

        super._transfer(from, to, finalAmount);
    }

    function _applyBasisPoints(uint256 amount, uint256 basisPoints)
        internal
        pure
        returns (uint256)
    {
        return (amount * basisPoints) / 10_000;
    }

    function _burnFees(
        address account,
        uint256 amount,
        uint256 basis
    ) internal {
        if (balanceOf(account) == 0) {
            emit FeesBurned(0);
            return;
        }
        uint256 burnAmount = _applyBasisPoints(amount, basis);
        if (balanceOf(account) < burnAmount) {
            _burn(account, balanceOf(account));
        } else {
            _burn(account, burnAmount);
        }
        zoneLimit = _applyBasisPoints(totalSupply(), 100); // .1% into the zone
        emit FeesBurned(burnAmount);
    }

    function _chargeFees(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (_exempt[from] || _exempt[to]) {
            return amount;
        }

        uint256 fees = _applyBasisPoints(amount, transactionFee);
        super._transfer(from, _vault, fees);

        return amount - fees;
    }

    function getExpirationFromAddress(address account)
        public
        view
        returns (uint256)
    {
        return _timeExpiration[account];
    }
}