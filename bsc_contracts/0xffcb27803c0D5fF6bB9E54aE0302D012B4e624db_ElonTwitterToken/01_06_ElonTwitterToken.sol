// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solady/src/utils/FixedPointMathLib.sol";
import "solady/src/auth/OwnableRoles.sol";

import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";

struct TValues {
    uint256 transferAmount;
    uint256 burnFee;
    uint256 liquidityFee;
    uint256 marketingFee;
}

contract ElonTwitterToken is OwnableRoles {
    /*//////////////////////////////////////////////////////////////
                                 LIBS
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error KingChalesInu__InvalidFee();

    error KingCharlesInu__MaxTransferAmount();

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name = "Elon Twitter Token";

    string public symbol = "ETT";

    uint8 public constant decimals = 9;

    address public marketingAddress;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private immutable INITIAL_CHAIN_ID;

    bytes32 private immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                           REFLECTION LOGIC
    //////////////////////////////////////////////////////////////*/

    IPancakeRouter02 private immutable PCS_ROUTER =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address public immutable PCS_PAIR;

    bool private _startTrading;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private _tTotal = 42 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX_UINT256 - (MAX_UINT256 % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private _burnFee = 0.01e18;
    uint256 private _marketingFee = 0.01e18;
    uint256 private _liquidityFee = 0.02e18;

    uint256 private _numTokensSellToAddToLiquidity = 2 * 10**4 * 10**9;
    uint256 private _maxTransferAmount = 2 * 10**5 * 10**9;

    mapping(address => uint256) private _rOwned;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _noMaxTransfer;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _marketingAddress) {
        _initializeOwner(msg.sender);

        _rOwned[msg.sender] = _rTotal;

        // Create a uniswap pair for this new token
        PCS_PAIR = IPancakeFactory(PCS_ROUTER.factory()).createPair(
            address(this),
            PCS_ROUTER.WETH()
        );

        marketingAddress = _marketingAddress;

        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _noMaxTransfer[msg.sender] = true;
        _noMaxTransfer[_marketingAddress] = true;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /*//////////////////////////////////////////////////////////////
                             ERC20
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address account) public view returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        uint256 allowed = allowance[sender][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max)
            _approve(sender, msg.sender, allowed - amount);

        _transfer(sender, recipient, amount);
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        (uint256 rAmount, uint256 rTransferAmount, , , , , ) = _getValues(
            tAmount
        );

        return deductTransferFee ? rAmount : rTransferAmount;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function hasNoMaxTransfer(address account) external view returns (bool) {
        return _noMaxTransfer[account];
    }

    //to recieve BNB from PCS ROUTER when swaping
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        TValues memory tValues = _getTValues(tAmount);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rBurnFee,
            uint256 rLiquidityFee,
            uint256 rMarketingFee
        ) = _getRValues(tAmount, tValues, _getRate());
        return (
            rAmount,
            rTransferAmount,
            tValues.transferAmount,
            rBurnFee,
            rLiquidityFee,
            rMarketingFee,
            tValues.burnFee + tValues.liquidityFee + tValues.marketingFee
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (TValues memory)
    {
        uint256 burnFee = _calculateBurnFee(tAmount);
        uint256 liquidityFee = _calculateLiquidityFee(tAmount);
        uint256 marketingFee = _calculateMarketingFee(tAmount);
        return
            TValues(
                tAmount - burnFee - liquidityFee - marketingFee,
                burnFee,
                liquidityFee,
                marketingFee
            );
    }

    function _getRValues(
        uint256 tAmount,
        TValues memory tValues,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rBurnFee,
            uint256 rLiquidityFee,
            uint256 rMarketingFee
        )
    {
        rAmount = tAmount * currentRate;
        rBurnFee = tValues.burnFee * currentRate;
        rLiquidityFee = tValues.liquidityFee * currentRate;
        rMarketingFee = tValues.marketingFee * currentRate;
        rTransferAmount = rAmount - rBurnFee - rLiquidityFee - rMarketingFee;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if (!_noMaxTransfer[from] && !_noMaxTransfer[to])
            if (amount > _maxTransferAmount)
                revert KingCharlesInu__MaxTransferAmount();

        if (from != owner() && !_startTrading) revert();

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance > _maxTransferAmount) {
            contractTokenBalance = _maxTransferAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != PCS_PAIR &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PCS_ROUTER.WETH();

        _approve(address(this), address(PCS_ROUTER), tokenAmount);

        // make the swap
        PCS_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(PCS_ROUTER), tokenAmount);

        // add the liquidity
        PCS_ROUTER.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (takeFee) {
            (
                uint256 rAmount,
                uint256 rTransferAmount,
                uint256 tTransferAmount,
                uint256 rBurnFee,
                uint256 rLiquidityFee,
                uint256 rMarketingFee,
                uint256 tAllFees
            ) = _getValues(amount);

            _rOwned[sender] -= rAmount;
            _rOwned[recipient] += rTransferAmount;

            _rOwned[address(this)] += rLiquidityFee;
            _rOwned[marketingAddress] += rMarketingFee;
            _rTotal -= rBurnFee;

            _tFeeTotal += tAllFees;

            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            uint256 rAmount = amount * _getRate();

            _rOwned[sender] -= rAmount;

            unchecked {
                _rOwned[recipient] += rAmount;
            }

            emit Transfer(sender, recipient, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              CALCULATE FEES
    //////////////////////////////////////////////////////////////*/

    function _calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mulWadUp(_liquidityFee);
    }

    function _calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mulWadUp(_burnFee);
    }

    function _calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mulWadUp(_marketingFee);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNER
    //////////////////////////////////////////////////////////////*/

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBurnFeePercent(uint256 taxFee) external onlyOwner {
        if (taxFee > 0.05e18) revert KingChalesInu__InvalidFee();
        _burnFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        if (liquidityFee > 0.05e18) revert KingChalesInu__InvalidFee();
        _liquidityFee = liquidityFee;
    }

    function setMarketingFee(uint256 marketingFee) external onlyOwner {
        if (marketingFee > 0.05e18) revert KingChalesInu__InvalidFee();
        _marketingFee = marketingFee;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setNoMaxTransfer(address account, bool state) external onlyOwner {
        _noMaxTransfer[account] = state;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function startTrading() external onlyOwner {
        _startTrading = true;
    }
}