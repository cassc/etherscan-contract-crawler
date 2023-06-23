/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface Token {
    function transferFrom(address, address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETCSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForROSESupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function WETC() external pure returns (address);

    function WHT() external pure returns (address);

    function WROSE() external pure returns (address);

    function WAVAX() external pure returns (address);
}

contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0x0),
            "call the renounceOwnership for zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract BaseToken {
    event TokenCreated(
        address indexed owner,
        address indexed token,
        string tokenType,
        uint256 version
    );
}

abstract contract CoinscopeBuyback {
    address public constant COINSCOPE_ADDRESS =
        0xD41C4805A9A3128f9F7A7074Da25965371Ba50d5;

    IUniswapV2Router02 public constant BSC_PANCAKE_ROUTER =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    event CoinscopeBuybackRejectedSwapBalance();
    event CoinscopeBuybackApproved(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity,
        uint256 ownerAmountReceiveed
    );
    event CoinscopeBuybackRejectedLiquidity();
    event CoinscopeBuybackRejectedSwap();

    function coinscopeBuyback(
        address recepient,
        address platformFeeReceiver,
        uint8 feeShare
    ) internal {
        if (block.chainid != 56 || address(this).balance == 0 || feeShare > 100)
            return;

        address[] memory path = new address[](2);
        path[0] = BSC_PANCAKE_ROUTER.WETH();
        path[1] = COINSCOPE_ADDRESS;

        uint256 swapAmount = (address(this).balance * feeShare) / 100;

        try
            BSC_PANCAKE_ROUTER.swapExactETHForTokens{value: swapAmount}(
                0,
                path,
                address(this),
                block.timestamp
            )
        returns (uint256[] memory amounts) {
            uint256 coinscopeBalance = amounts[amounts.length - 1];

            if (coinscopeBalance == 0) {
                emit CoinscopeBuybackRejectedSwapBalance();
                return;
            }

            uint256 ownerTokens = coinscopeBalance / 100;

            IERC20 coinscopeToken = IERC20(COINSCOPE_ADDRESS);

            require(
                coinscopeToken.transfer(recepient, ownerTokens),
                "Coinscope tokens should transferred to owner"
            );

            coinscopeBalance = coinscopeToken.balanceOf(address(this));

            require(
                coinscopeToken.approve(
                    address(BSC_PANCAKE_ROUTER),
                    coinscopeBalance
                ),
                "Coinscope allowance should be approved"
            );

            try
                BSC_PANCAKE_ROUTER.addLiquidityETH{
                    value: address(this).balance
                }(
                    COINSCOPE_ADDRESS,
                    coinscopeBalance,
                    0,
                    0,
                    platformFeeReceiver,
                    block.timestamp
                )
            returns (
                uint256 amountToken,
                uint256 amountETH,
                uint256 liquidity
            ) {
                emit CoinscopeBuybackApproved(
                    amountToken,
                    amountETH,
                    liquidity,
                    ownerTokens
                );
            } catch {
                emit CoinscopeBuybackRejectedLiquidity();
            }
        } catch {
            emit CoinscopeBuybackRejectedSwap();
        }
    }
}

contract Redis is IERC20, Ownable, BaseToken, CoinscopeBuyback {
    uint256 public constant VERSION = 1;

    mapping(address => uint256) private rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private immutable tTotal;
    uint256 private rTotal;

    uint16 public reflectionTax;
    uint16 public treasuryTax;

    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    address payable public treasuryAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private inSwap = false;
    bool public swapEnabled = true;

    event UpdatedTreasuryWallet(address indexed account);
    event ChangedFees(uint16 reflectionTax, uint16 treasuryTax);
    event ChangedSwapEnable(bool enable);
    event ExcludedAccountsFromFees(address[] accounts, bool excluded);
    event WithdrawedTokens(
        address indexed token,
        address indexed to,
        uint amount
    );
    event SwapError(uint256 amount);
    event Reflected(address sender, uint256 amount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address router_,
        address treasuryAddress_,
        uint16 reflectionTax_,
        uint16 treasuryTax_,
        address feeReceiver,
        uint8 feeShare
    ) payable {
        require(
            treasuryAddress_ != address(0x0),
            "treasury address cannot be zero"
        );

        require(decimals_ != 0, "decimals should not be zero");
        validateFees(reflectionTax_, treasuryTax_);

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        tTotal = totalSupply_;
        rTotal = (MAX - (MAX % totalSupply_));

        rOwned[msg.sender] = rTotal;

        uniswapV2Router = IUniswapV2Router02(router_);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            getNativeCurrency()
        );

        treasuryAddress = payable(treasuryAddress_);

        reflectionTax = reflectionTax_;
        treasuryTax = treasuryTax_;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasuryAddress_] = true;

        emit Transfer(address(0x0), msg.sender, totalSupply_);

        emit TokenCreated(owner(), address(this), "redis", VERSION);

        if (feeReceiver == address(0x0)) return;

        coinscopeBuyback(owner(), feeReceiver, feeShare);
        payable(feeReceiver).transfer(address(this).balance);
    }

    function getNativeCurrency() internal view returns (address) {
        if (block.chainid == 61) {
            //etc
            return uniswapV2Router.WETC();
        } else if (block.chainid == 128) {
            //heco chain
            return uniswapV2Router.WHT();
        } else if (block.chainid == 42262) {
            //oasis
            return uniswapV2Router.WROSE();
        } else if (block.chainid == 43114 || block.chainid == 43113) {
            //avalance
            return uniswapV2Router.WAVAX();
        } else {
            return uniswapV2Router.WETH();
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address account,
        address spender
    ) public view override returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 senderAllowance = _allowances[sender][msg.sender];

        require(senderAllowance >= amount, "insufficient allowance");

        _approve(sender, msg.sender, senderAllowance - amount);

        _transfer(sender, recipient, amount);

        return true;
    }

    function tokenFromReflection(
        uint256 rAmount
    ) private view returns (uint256) {
        require(
            rAmount <= rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _approve(
        address account,
        address spender,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (
            from != owner() &&
            to != owner() &&
            !inSwap &&
            from != uniswapV2Pair &&
            swapEnabled
        ) {
            uint256 contractTokenBalance = balanceOf(address(this));

            if (contractTokenBalance > 0)
                swapTokensForEth(contractTokenBalance);
        }

        _transferStandard(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = getNativeCurrency();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        if (block.chainid == 61) {
            //etc
            try
                uniswapV2Router
                    .swapExactTokensForETCSupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        treasuryAddress,
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        } else if (block.chainid == 42262) {
            //oasis
            try
                uniswapV2Router
                    .swapExactTokensForROSESupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        treasuryAddress,
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        } else if (block.chainid == 43114 || block.chainid == 43113) {
            //avalance
            try
                uniswapV2Router
                    .swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        treasuryAddress,
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        } else {
            try
                uniswapV2Router
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        treasuryAddress,
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        }
    }

    function withdrawETH() external onlyOwner {
        treasuryAddress.transfer(address(this).balance);
    }

    function withdrawTokens(
        address token,
        address to,
        uint amount
    ) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "transfer rejected");

        emit WithdrawedTokens(token, to, amount);
    }

    function setTreasuryAddress(address payable account) external onlyOwner {
        require(account != address(0x0), "treasury address cannot be zero");

        treasuryAddress = account;
        _isExcludedFromFee[account] = true;

        emit UpdatedTreasuryWallet(account);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        bool takeFee = !_isExcludedFromFee[sender] &&
            !_isExcludedFromFee[recipient] &&
            (sender == uniswapV2Pair || recipient == uniswapV2Pair) &&
            !inSwap;

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReflection,
            uint256 rTreasury,
            uint256 tTransferAmount,
            uint256 tReflection,
            uint256 tTreasury
        ) = _getValues(takeFee, tAmount);

        rOwned[sender] = rOwned[sender] - rAmount;
        rOwned[recipient] = rOwned[recipient] + rTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        if (rTreasury > 0) {
            rOwned[address(this)] = rOwned[address(this)] + rTreasury;
            emit Transfer(sender, address(this), tTreasury);
        }

        if (rReflection > 0) {
            rTotal = rTotal - rReflection;
            emit Reflected(sender, tReflection);
        }
    }

    receive() external payable {}

    function _getValues(
        bool takeFees,
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (
            uint256 tTransferAmount,
            uint256 tReflection,
            uint256 tTreasury
        ) = _getTValues(takeFees, tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReflection,
            uint256 rTreasury
        ) = _getRValues(tAmount, tReflection, tTreasury);

        return (
            rAmount,
            rTransferAmount,
            rReflection,
            rTreasury,
            tTransferAmount,
            tReflection,
            tTreasury
        );
    }

    function _getTValues(
        bool takeFees,
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256) {
        if (!takeFees) return (tAmount, 0, 0);

        uint256 tReflection = (tAmount * reflectionTax) / 100;
        uint256 tTreasury = (tAmount * treasuryTax) / 100;
        uint256 tTransferAmount = tAmount - tReflection - tTreasury;
        return (tTransferAmount, tReflection, tTreasury);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tReflection,
        uint256 tTreasury
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 rate = _getRate();

        uint256 rAmount = tAmount * rate;
        uint256 rReflection = tReflection * rate;
        uint256 rTreasury = tTreasury * rate;
        uint256 rTransferAmount = rAmount - rReflection - rTreasury;

        return (rAmount, rTransferAmount, rReflection, rTreasury);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;
        if (rSupply < rTotal / tTotal) return (rTotal, tTotal);
        return (rSupply, tSupply);
    }

    function manualSwap() external onlyOwner {
        swapTokensForEth(balanceOf(address(this)));
    }

    function setFee(
        uint16 reflectionTax_,
        uint16 treasuryTax_
    ) public onlyOwner {
        validateFees(reflectionTax_, treasuryTax_);

        reflectionTax = reflectionTax_;
        treasuryTax = treasuryTax_;

        emit ChangedFees(reflectionTax_, treasuryTax_);
    }

    function validateFees(
        uint16 reflectionTax_,
        uint16 treasuryTax_
    ) internal pure {
        require(
            reflectionTax_ + treasuryTax_ <= 20,
            "Fees cannot be greater than 20%"
        );
    }

    function toggleSwap(bool enable) external onlyOwner {
        swapEnabled = enable;

        emit ChangedSwapEnable(enable);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }

        emit ExcludedAccountsFromFees(accounts, excluded);
    }

    function getExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }
}