// SPDX-License-Identifier: MIT

/**
██████╗ ███████╗██████╗     ██╗     ██╗ ██████╗ ██╗  ██╗████████╗    ██████╗ ██╗███████╗████████╗██████╗ ██╗ ██████╗████████╗
██╔══██╗██╔════╝██╔══██╗    ██║     ██║██╔════╝ ██║  ██║╚══██╔══╝    ██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗██║██╔════╝╚══██╔══╝
██████╔╝█████╗  ██║  ██║    ██║     ██║██║  ███╗███████║   ██║       ██║  ██║██║███████╗   ██║   ██████╔╝██║██║        ██║   
██╔══██╗██╔══╝  ██║  ██║    ██║     ██║██║   ██║██╔══██║   ██║       ██║  ██║██║╚════██║   ██║   ██╔══██╗██║██║        ██║   
██║  ██║███████╗██████╔╝    ███████╗██║╚██████╔╝██║  ██║   ██║       ██████╔╝██║███████║   ██║   ██║  ██║██║╚██████╗   ██║   
╚═╝  ╚═╝╚══════╝╚═════╝     ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝       ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝   ╚═╝   
*/

pragma solidity 0.8.15;

// Using OpenZeppelin Implementation for security
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IUniswapV2Factory} from "./utils/IUniswapV2Factory.sol";
import {IUniswapV2Router01} from "./utils/IUniswapV2Router01.sol";
import {IUniswapV2Router02} from "./utils/IUniswapV2Router02.sol";

contract Token is Context, IERC20, ReentrancyGuard {
    using Address for address;

    string private constant _name = "Red Light District Metaverse";
    string private constant _symbol = "RLDM";
    uint256 private constant _totalSupply = 10 * 10**9 * 10**_decimals; // 10,000,000,000
    uint8 private constant _decimals = 18;

    address private _owner;

    uint256 public transferOwnershipLockedTime;
    uint256 public constant transferOwnershipLockPeriod = 120; // 48 hours
    bool public isTransferOwnershipLocked = false;

    address public requestedNewOwner;

    address public constant gnosisSafeProxy =
        0x1F7F07864A9349ED94BFe518f6374d744bA9D1ad;
    address public constant deadAddress = address(0xdead);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isMarketPair;

    uint256 public buyTax = 5;
    uint256 public constant maxBuyTax = 5;

    uint256 public sellTax = 5;
    uint256 public constant maxSellTax = 5;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public numTokensSellToAddToLiquidity = 5 * 10**6 * 10**_decimals; // 0,05% of _totalSupply

    event OwnershipTransferRequested(
        address indexed newOwner,
        uint256 releaseTime
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapTokensForBnb(uint256 amountIn, address[] path);
    event SetNumTokensSellToAddToLiquidity(uint256 newValue);

    event Airdrop(address[] recipients, uint256[] amounts);
    event SetMarketPairStatus(address account, bool newValue);
    event SetIsExcludedFromFee(address account, bool newValue);
    event SetBuyTax(uint256 newValue);
    event SetSellTax(uint256 newValue);
    event ChangeRouterVersion(address newRouterAddress, address newPairAddress);

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        // Transfer ownership to Gnosis Safe Proxy contract
        _initTransferOwnership(gnosisSafeProxy);

        // Mint tokens to Gnosis Safe Proxy contract
        _balances[gnosisSafeProxy] = _totalSupply;
        emit Transfer(address(0), gnosisSafeProxy, _totalSupply);

        /**
         * @dev Routers config for PancakeSwap
         *
         * PancakeSwap v2 Mainnet Router Address: 0x10ED43C718714eb63d5aA57B78B54704E256024E
         * PancakeSwap v2 Testnet Router Address: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
         */
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            (_allowances[_msgSender()][spender] + addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        require(
            subtractedValue <= _allowances[_msgSender()][spender],
            "Token: decreased allowance below zero!"
        );

        _approve(
            _msgSender(),
            spender,
            (_allowances[_msgSender()][spender] - subtractedValue)
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        require(owner_ != address(0), "Token: approve from the zero address");
        require(spender != address(0), "Token: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyOwner
        returns (bool)
    {
        require(
            recipients.length == amounts.length,
            "Token: recipients and amounts must be the same length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            _basicTransfer(_msgSender(), recipients[i], amounts[i]);
        }

        emit Airdrop(recipients, amounts);

        return true;
    }

    function setMarketPairStatus(address account, bool newValue)
        external
        onlyOwner
    {
        isMarketPair[account] = newValue;
        emit SetMarketPairStatus(account, newValue);
    }

    function setIsExcludedFromFee(address account, bool newValue)
        external
        onlyOwner
    {
        isExcludedFromFee[account] = newValue;
        emit SetIsExcludedFromFee(account, newValue);
    }

    function setBuyTax(uint256 newValue) external onlyOwner {
        require(newValue <= maxBuyTax, "Token: buyTax exceeds maximum value!");

        buyTax = newValue;

        emit SetBuyTax(buyTax);
    }

    function setSellTax(uint256 newValue) external onlyOwner {
        require(
            newValue <= maxSellTax,
            "Token: sellTax exceeds maximum value!"
        );

        sellTax = newValue;

        emit SetSellTax(sellTax);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensSellToAddToLiquidity(uint256 newValue)
        public
        onlyOwner
    {
        require(
            newValue > 0,
            "Token: setNumTokensSellToAddToLiquidity value must be greater than zero!"
        );
        numTokensSellToAddToLiquidity = newValue * 10**_decimals;
        emit SetNumTokensSellToAddToLiquidity(newValue);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(deadAddress);
    }

    function changeRouterVersion(address newRouterAddress)
        external
        onlyOwner
        nonReentrant
        returns (address newPairAddress)
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            newRouterAddress
        );

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        if (newPairAddress == address(0)) {
            //Create If Doesnt exist
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address

        isMarketPair[address(uniswapPair)] = true;

        emit ChangeRouterVersion(newRouterAddress, newPairAddress);
    }

    // to recieve BNB from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        require(
            amount <= _allowances[sender][_msgSender()],
            "Token: transfer amount exceeds allowance!"
        );

        _approve(
            sender,
            _msgSender(),
            (_allowances[sender][_msgSender()] - amount)
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {
        require(sender != address(0), "Token: transfer from the zero address");
        require(recipient != address(0), "Token: transfer to the zero address");
        require(amount > 0, "Token: transfer amount must be greater than zero");

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            uint256 tokenBalance = balanceOf(address(this));
            if (
                tokenBalance >= numTokensSellToAddToLiquidity &&
                !inSwapAndLiquify &&
                !isMarketPair[sender] &&
                swapAndLiquifyEnabled
            ) {
                _swapAndLiquify(tokenBalance);
            }

            _balances[sender] = _balances[sender] - amount;

            uint256 finalAmount = (isExcludedFromFee[sender] ||
                isExcludedFromFee[recipient])
                ? amount
                : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient] + finalAmount;

            emit Transfer(sender, recipient, finalAmount);

            return true;
        }
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

    function _swapAndLiquify(uint256 tokenBalance) private lockTheSwap {
        require(
            msg.sender == tx.origin,
            "Token: msg.sender does not match with tx.origin"
        );

        // split the contract balance into halves
        uint256 half = tokenBalance / 2;
        uint256 otherHalf = tokenBalance - half;

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        _swapTokensForBnb(half); // <- this breaks the BNB -> RLDM swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForBnb(tokenAmount, path);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;

        if (buyTax > 0 && isMarketPair[sender]) {
            feeAmount = (amount * buyTax) / 100;
        } else if (sellTax > 0 && isMarketPair[recipient]) {
            feeAmount = (amount * sellTax) / 100;
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner)
        public
        virtual
        onlyOwner
        nonReentrant
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        require(
            newOwner != owner(),
            "Ownable: new owner is same with current owner"
        );

        require(
            !isTransferOwnershipLocked ||
                (isTransferOwnershipLocked &&
                    (transferOwnershipLockedTime +
                        transferOwnershipLockPeriod) <=
                    block.timestamp),
            "Ownable: transferOwnership is locked"
        );

        if (isTransferOwnershipLocked) {
            _transferOwnership(newOwner);
            isTransferOwnershipLocked = false;
        } else {
            isTransferOwnershipLocked = true;
            transferOwnershipLockedTime = block.timestamp;
            requestedNewOwner = newOwner;
            emit OwnershipTransferRequested(
                newOwner,
                (transferOwnershipLockedTime + transferOwnershipLockPeriod)
            );
        }
    }

    function _initTransferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        require(
            requestedNewOwner == newOwner,
            "Ownable: new owner does not match with the requested new owner"
        );

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}