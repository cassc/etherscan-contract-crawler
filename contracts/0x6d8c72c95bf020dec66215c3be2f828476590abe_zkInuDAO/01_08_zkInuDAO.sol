// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap-v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract zkInuDAO is IERC20, IERC20Metadata, Ownable {
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string constant _name = "zkInu DAO";
    string constant _symbol = "zkInu";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100_000_000_000_000 * (10 **_decimals);
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    IUniswapV2Router02 public router;
    address public pair;
    uint256 public tgeAt;
    uint256 public nonFeeBlocks;
    bool public feesEnabled = false;

    bool hossaStarted = false;
    bool inSwap;
    address teamWallet;
    uint256 totalFee = 500;
    uint256 sellBias = 0;
    uint256 feeDenominator = 10000;

    mapping(address => bool) isFreeFromFee;
    mapping(address => bool) liquidityCreator;
    mapping(address => bool) liquidityPools;

    event FundsDistributed(uint256 amount);

    modifier duringSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyTeam() {
        require(_msgSender() == teamWallet, "Caller is not a team member");
        _;
    }

    constructor() {        
        router = IUniswapV2Router02(ROUTER);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        liquidityPools[pair] = true;
        _allowances[owner()][ROUTER] = type(uint256).max;
        _allowances[address(this)][ROUTER] = type(uint256).max;
        isFreeFromFee[owner()] = true;
        liquidityCreator[owner()] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function balanceOf(
        address account
    ) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder, 
        address spender
    )
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(
        address spender, 
        uint256 amount
    )
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(
        address recipient, 
        uint256 amount
    )
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "ERC20: transfer from 0x0");
        require(recipient != address(0), "ERC20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        require(_balances[sender] >= amount, "Insufficient balance");
        if (!launched() && liquidityPools[recipient]) {
            require(liquidityCreator[sender], "Liquidity not added yet.");
            launch();
        }
        if (!hossaStarted) {
            require(
                liquidityCreator[sender] || liquidityCreator[recipient],
                "Trading not open yet."
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = freeFromFee(sender)
            ? takeFee(recipient, amount)
            : amount;

        if (shouldSwapBack(recipient)) {
            if (amount > 0) swapBack();
        }

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function setTeamWallet(
        address _team
    ) external onlyOwner {
        teamWallet = _team;
    }

    function feeWithdrawal(
        uint256 amount
    ) external onlyTeam {
        uint256 amountETH = address(this).balance;
        payable(teamWallet).transfer((amountETH * amount) / 100);
    }

    function launchTrading(
        uint256 _nonFeeBlocks
    ) external onlyOwner {
        require(!hossaStarted && _nonFeeBlocks < 10);
        nonFeeBlocks = _nonFeeBlocks;
        hossaStarted = true;
        tgeAt = block.number;
    }

    function totalFeeAmount() public view returns (uint256) {
        return address(this).balance;
    }

    function launched() internal view returns (bool) {
        return tgeAt != 0;
    }

    function launch() internal {
        tgeAt = block.number;
        feesEnabled = true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function currentFees() public view returns (uint256) {
        return totalFee;
    }

    function setIsFreeFromFee(
        address holder, 
        bool exempt
    ) external onlyOwner {
        isFreeFromFee[holder] = exempt;
    }

    function enableFees(
        bool _feesEnabled
    ) external onlyOwner {
        feesEnabled = _feesEnabled;
    }

    function freeFromFee(
        address sender
    ) internal view returns (bool) {
        return !isFreeFromFee[sender];
    }

    function getCurrentSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    function takeFee(
        address recipient, 
        uint256 amount
    )
        internal
        returns (uint256)
    {
        bool selling = liquidityPools[recipient];
        uint256 feeAmount = (amount * getTotalFee(selling)) / feeDenominator;

        _balances[address(this)] += feeAmount;

        return amount - feeAmount;
    }

    function getTotalFee(
        bool isSelling
    ) public view returns (uint256) {
        if (tgeAt + nonFeeBlocks >= block.number) {
            return feeDenominator;
        }
        if (isSelling) return totalFee + sellBias;
        return totalFee - sellBias;
    }

    function shouldSwapBack(
        address recipient
    ) internal view returns (bool) {
        return
            !liquidityPools[msg.sender] &&
            !inSwap &&
            feesEnabled &&
            liquidityPools[recipient];
    }

    function swapBack() internal duringSwap {
        if (_balances[address(this)] > 0) {
            uint256 amountToSwap = _balances[address(this)];

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );

            emit FundsDistributed(amountToSwap);
        }
    }
}