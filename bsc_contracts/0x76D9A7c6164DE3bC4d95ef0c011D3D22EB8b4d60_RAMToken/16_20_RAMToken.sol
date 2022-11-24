// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract RAMVaultTmp {

    function withdraw(address token) external {
        SafeERC20.safeTransfer(
            IERC20(token),
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

}

contract RAMToken is Ownable, ERC20 {

    address public immutable USDTAddress;
    RAMVaultTmp public immutable LPVaultTmp;
    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;

    address public LPTokenRecipient;

    uint256 public taxFee;
    uint256 public liquidityFee;
    address public treasuryAddress;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    uint256 public numTokensSellToAddToLiquidity;
    mapping (address => bool) private _isExcludedFromFee;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 usdtReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address _USDTAddress,
        address _uniswapV2Router,
        address[] memory _args
    ) ERC20('RAM TOKEN', 'RAM') {
        USDTAddress = _USDTAddress;
        LPVaultTmp = new RAMVaultTmp();
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), USDTAddress);

        require(_args.length == 9);

        LPTokenRecipient = msg.sender;
        _isExcludedFromFee[address(this)] = true;

        // The IDO recipient
        ERC20._mint(_args[0], 60_000_000 ether);

        // The LP recipient
        _isExcludedFromFee[_args[1]] = true;
        ERC20._mint(_args[1], 300_000_000 ether);

        // The NFT Staking recipient
        ERC20._mint(_args[2], 2_400_000_000 ether);

        // The RAM Staking recipient
        ERC20._mint(_args[3], 900_000_000 ether);

        // The agency recipient
        ERC20._mint(_args[4], 900_000_000 ether);

        // The ecology recipient
        ERC20._mint(_args[5], 240_000_000 ether);

        // The airdrop recipient
        ERC20._mint(_args[6], 300_000_000 ether);

        // The team recipient
        ERC20._mint(_args[7], 900_000_000 ether);

        treasuryAddress = _args[8];
        taxFee = 0.01 ether;
        liquidityFee = 0.7 ether;

        swapAndLiquifyEnabled = true;
        numTokensSellToAddToLiquidity = 500 ether;
    }

    function setLPTokenRecipient(address _LPTokenRecipient) external {
        require(msg.sender == LPTokenRecipient, 'RAMToken: caller is not the recipient.');
        LPTokenRecipient = _LPTokenRecipient;
    }

    function setTreasuryAddress(address _treasuryAddress) external {
        require(msg.sender == treasuryAddress, 'RAMToken: caller is not the treasury.');
        treasuryAddress = _treasuryAddress;
    }

    function excludeFromFee(address _account) external onlyOwner {
        _isExcludedFromFee[_account] = true;
    }

    function includeInFee(address _account) external onlyOwner {
        _isExcludedFromFee[_account] = false;
    }

    function setTaxFee(uint256 _taxFee) external onlyOwner {
        taxFee = _taxFee;
    }

    function setLiquidityFee(uint256 _liquidityFee) external onlyOwner {
        liquidityFee = _liquidityFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity) external onlyOwner {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(amount > 0, "RAMToken: Transfer amount must be greater than zero");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = ERC20.balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            // add liquidity
            _swapAndLiquify(contractTokenBalance);
        }

        if (from == uniswapV2Pair || to == uniswapV2Pair) {
            if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                uint256 _fee = amount * taxFee / 1 ether;
                uint256 _liquidityFee = _fee * liquidityFee / 1 ether;
                super._transfer(from, address(this), _liquidityFee);
                super._transfer(from, treasuryAddress, _fee - _liquidityFee);

                amount = amount - _fee;
            }
        }

        super._transfer(from, to, amount);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current USDT balance.
        // this is so that we can capture exactly the amount of USDT that the
        // swap creates, and not make the liquidity event include any USDT that
        // has been manually sent to the contract
        uint256 initialBalance = IERC20(USDTAddress).balanceOf(address(this));

        // swap tokens for USDT
        _swapTokensForUSDT(half); // <- this breaks the USDT -> HATE swap when swap+liquify is triggered

        // how much USDT did we just swap into?
        uint256 newBalance = IERC20(USDTAddress).balanceOf(address(this)) - initialBalance;

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForUSDT(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> USDT
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDTAddress;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDT
            path,
            address(LPVaultTmp),
            block.timestamp
        );
        LPVaultTmp.withdraw(path[1]);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20(USDTAddress).approve(address(uniswapV2Router), usdtAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            USDTAddress,
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            LPTokenRecipient,
            block.timestamp
        );
    }

}