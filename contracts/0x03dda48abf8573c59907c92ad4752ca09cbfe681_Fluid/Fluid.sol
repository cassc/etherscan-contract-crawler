/**
 *Submitted for verification at Etherscan.io on 2023-09-23
*/

/**
    Fluid Trade
    Website: https://fluid.trade/
    Twitter: https://twitter.com/FluidToken
    Telegram: https://fluid.trade/
    Medium: https://medium.com/@fluidtrade
    Docs: https://fluidtrade.gitbook.io/docs/
**/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
pragma experimental ABIEncoderV2;

abstract contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
    }
}

library SafeERC20 {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: INTERNAL TRANSFER_FAILED');
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Fluid is Ownable {
    string private constant _name = unicode"Fluid";
    string private constant _symbol = unicode"FLUID";
    uint256 private constant _totalSupply = 10_000_000 * 1e18;

    uint256 public maxTransactionAmount = 30_000 * 1e18; // 0.3% maxWallet
    uint256 public maxWallet = 30_000 * 1e18; //  0.3% maxWallet
    uint256 public swapTokensAtAmount = (_totalSupply * 2) / 10000;

    address private revWallet = 0x41290754162AF2abcc9e4151b17fF8c36CDeF968;
    address private treasuryWallet = 0xaBb444A6BB7fe3ceA830F7D6b28Bb19D5ad0f12C;
    address private teamWallet = 0x55f90250458ee41db46B192e812E3741EbeaB942;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint8 public buyTotalFees = 5;
    uint8 public sellTotalFees = 5;

    uint8 public revFee = 40; // 2% Token Holders
    uint8 public treasuryFee = 40; // 2% Development / Marketing    
    uint8 public teamFee = 20; // 1% Foundation / Operational Expenses

    bool private swapping;
    bool public limitsInEffect = true;
    bool private launched;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 teamETH, uint256 revETH, uint256 TreasuryETH);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        address airdropWallet = 0x7B2df6546FEee36c13291717691BdAE4E885ed2C;

        setExcludedFromFees(owner(), true);
        setExcludedFromFees(address(this), true);
        setExcludedFromFees(address(0xdead), true);
        setExcludedFromFees(teamWallet, true);
        setExcludedFromFees(revWallet, true);
        setExcludedFromFees(treasuryWallet, true);
        setExcludedFromFees(0x7B2df6546FEee36c13291717691BdAE4E885ed2C, true);
        setExcludedFromFees(0xD8b7bDC37C474AfCb43D2a9d74b89C484Eb7d72e, true);
        setExcludedFromFees(0x04ca7a6Bccf3595dee52500Ea2907d258a692328, true);
        setExcludedFromFees(0x216396A2f42647399c33C6D2AFaE4f70E79cA638, true);
        setExcludedFromFees(0x3D6e81228bA0367b5E5a8b94b71d3568B0ded996, true);
        setExcludedFromFees(0x1C57e308f7f6ddb97759c46147FcDa8172fb6ac8, true);
        setExcludedFromFees(0x4800f7db2876bA3Dd78753F9F554F56f2F40191A, true);
        setExcludedFromFees(0xAa3fb318b6ca797A9fA1ef93B84cBD283403cc08, true);
        setExcludedFromFees(0x83619E5C898492B068A93D7c9C154D23002877C7, true);
        setExcludedFromFees(0xa4F5CB040533C6ee72DA44B090bCd97C8D84C7F3, true);

        setExcludedFromMaxTransaction(owner(), true);
        setExcludedFromMaxTransaction(address(uniswapV2Router), true);
        setExcludedFromMaxTransaction(address(this), true);
        setExcludedFromMaxTransaction(address(0xdead), true);
        setExcludedFromMaxTransaction(address(uniswapV2Pair), true);
        setExcludedFromMaxTransaction(teamWallet, true);
        setExcludedFromMaxTransaction(revWallet, true);
        setExcludedFromMaxTransaction(treasuryWallet, true);
        setExcludedFromMaxTransaction(0x7B2df6546FEee36c13291717691BdAE4E885ed2C, true);
        setExcludedFromMaxTransaction(0xD8b7bDC37C474AfCb43D2a9d74b89C484Eb7d72e, true);
        setExcludedFromMaxTransaction(0x04ca7a6Bccf3595dee52500Ea2907d258a692328, true);
        setExcludedFromMaxTransaction(0x216396A2f42647399c33C6D2AFaE4f70E79cA638, true);
        setExcludedFromMaxTransaction(0x3D6e81228bA0367b5E5a8b94b71d3568B0ded996, true);
        setExcludedFromMaxTransaction(0x1C57e308f7f6ddb97759c46147FcDa8172fb6ac8, true);
        setExcludedFromMaxTransaction(0x4800f7db2876bA3Dd78753F9F554F56f2F40191A, true);
        setExcludedFromMaxTransaction(0xAa3fb318b6ca797A9fA1ef93B84cBD283403cc08, true);
        setExcludedFromMaxTransaction(0x83619E5C898492B068A93D7c9C154D23002877C7, true);
        setExcludedFromMaxTransaction(0xa4F5CB040533C6ee72DA44B090bCd97C8D84C7F3, true);

        _balances[msg.sender] = 1_000_000 * 1e18;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        _balances[treasuryWallet] = 1_000_000 * 1e18;
        emit Transfer(address(0), treasuryWallet, _balances[treasuryWallet]);
        _balances[airdropWallet] = 6_000_000 * 1e18;
        emit Transfer(address(0), airdropWallet, _balances[airdropWallet]);
        _balances[address(this)] = 2_000_000 * 1e18;
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!launched && (from != owner() && from != address(this) && to != owner())) {
            revert("Trading not enabled");
        }

        if (limitsInEffect) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTx");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount,"Sell transfer amount exceeds the maxTx");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 1000;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 1000;
            }

            if (fees > 0) {
                unchecked {
                    amount = amount - fees;
                    _balances[from] -= fees;
                    _balances[address(this)] += fees;
                }
                emit Transfer(from, address(this), fees);
            }
        }
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function setDistributionFees(uint8 _RevFee, uint8 _TreasuryFee, uint8 _teamFee) external onlyOwner {
        revFee = _RevFee;
        treasuryFee = _TreasuryFee;
        teamFee = _teamFee;
        require((revFee + treasuryFee + teamFee) == 100, "Distribution have to be equal to 100%");
    }

    function setFees(uint8 _buyTotalFees, uint8 _sellTotalFees) external onlyOwner {
        require(_buyTotalFees <= 40, "Buy fees must be less than or equal to 4%");
        require(_sellTotalFees <= 40, "Sell fees must be less than or equal to 4%");
        buyTotalFees = _buyTotalFees;
        sellTotalFees = _sellTotalFees;
    }

    function setExcludedFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setExcludedFromMaxTransaction(address account, bool excluded) public onlyOwner {
        _isExcludedMaxTransactionAmount[account] = excluded;
    }

    function airdropWallets(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(!launched, "Already launched");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(_balances[msg.sender] >= amounts[i], "ERC20: transfer amount exceeds balance");
            _balances[addresses[i]] += amounts[i];
            _balances[msg.sender] -= amounts[i];
            emit Transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function openTrade() external onlyOwner {
        require(!launched, "Already launched");
        launched = true;
    }

    function AddingLPtoFluidTrade() external payable onlyOwner {
        require(!launched, "Already launched");
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            _balances[address(this)],
            0,
            0,
            teamWallet,
            block.timestamp
        );
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed");
        automatedMarketMakerPairs[pair] = value;
    }

    function setSwapAtAmount(uint256 newSwapAmount) external onlyOwner {
        require(newSwapAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% of the supply");
        require(newSwapAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% of the supply");
        swapTokensAtAmount = newSwapAmount;
    }

    function setMaxTxnAmount(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set max transaction lower than 0.1%");
        maxTransactionAmount = newMaxTx * (10**18);
    }

    function setMaxWalletAmount(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set max wallet lower than 0.1%");
        maxWallet = newMaxWallet * (10**18);
    }

    function updateRevWallet(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        revWallet = newAddress;
    }

    function updateTreasuryWallet(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        treasuryWallet = newAddress;
    }

    function updateTeamWallet(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        teamWallet = newAddress;
    }

    function excludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawStuckToken(address token, address to) external onlyOwner {
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransfer(token, to, _contractBalance); // Use safeTransfer
    }

    function withdrawStuckETH(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");

        (bool success, ) = addr.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function swapBack() private {
        uint256 swapThreshold = swapTokensAtAmount;
        bool success;

        if (balanceOf(address(this)) > swapTokensAtAmount * 20) {
            swapThreshold = swapTokensAtAmount * 20;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapThreshold, 0, path, address(this), block.timestamp);

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            uint256 ethForRev = (ethBalance * revFee) / 100;
            uint256 ethForTeam = (ethBalance * teamFee) / 100;
            uint256 ethForTreasury = ethBalance - ethForRev - ethForTeam;

            (success, ) = address(teamWallet).call{value: ethForTeam}("");
            (success, ) = address(treasuryWallet).call{value: ethForTreasury}("");
            (success, ) = address(revWallet).call{value: ethForRev}("");

            emit SwapAndLiquify(swapThreshold, ethForTeam, ethForRev, ethForTreasury);
        }
    }
}