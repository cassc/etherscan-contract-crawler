/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

interface iERC20 {
    function getOwner() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

interface IUniswapERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IUniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getamountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getamountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getamountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getamountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
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
}

library Listables {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "Listables: index out of bounds"
        );
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    struct ActorSet {
        Set _inner;
    }

    function add(ActorSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(ActorSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(ActorSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(ActorSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(ActorSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}


contract Modern {
    mapping(address => bool) isAuthorized;

    function authorized(address ADDRESS) public view returns (bool) {
        return isAuthorized[ADDRESS];
    }

    function set_authorized(address ADDRESS, bool BOOLEAN) public onlyAuth {
        isAuthorized[ADDRESS] = BOOLEAN;
    }

    modifier onlyAuth() {
        require(isAuthorized[msg.sender] || msg.sender == owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    bool inUse;
    modifier safe() {
        require(!inUse, "reentrant");
        inUse = true;
        _;
        inUse = false;
    }

    function change_owner(address _new) public onlyAuth {
        owner = _new;
    }

    receive() external payable {}

    fallback() external payable {}
}

contract DoomerGirl is iERC20, Modern {

    // BEGINNING OF THE CONTRACT //

    using Listables for Listables.ActorSet;

    string public constant _name = "Doomer Girl";
    string public constant _symbol = "GURL";
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply = 100 * 10**6 * 10**_decimals;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    Listables.ActorSet private _excluded;

    uint256 swapTreshold = InitialSupply / 200; // 0.5%

    bool isSwapPegged = true;

    uint16 public BuyBarrierDenominator = 25; // 4%

    uint8 public BalanceBarrierDenominator = 25; // 4%

    uint16 public SellBarrierDenominator = 50; // 2%

    bool public manualConversion;

    address public constant UniswapRouter =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public _circulatingSupply = InitialSupply;
    uint256 public balanceBarrier = _circulatingSupply;
    uint256 public sellBarrier = _circulatingSupply;
    uint256 public buyBarrier = _circulatingSupply;

    uint8 public _buyTax = 10;
    uint8 public _sellTax = 30;
    uint8 public _transferTax = 5;

    // Shares
    uint8 public _liquidityTax = 10;
    uint8 public _marketingTax = 90;

    bool isTokenSwapManual;
    bool public botProtect;
    bool public tradingEnabled;

    address public _UniswapPairAddress;

    IUniswapRouter02 public _UniswapRouter;

    uint256 public marketingBalance;

    bool private _isSwappingContractModifier;
    
    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    constructor() {
        // Ownership
        owner = msg.sender;
        isAuthorized[msg.sender] = true;
        uint contractSupply = (InitialSupply / 100) * 10;
        uint deployerSupply = InitialSupply - contractSupply;
        _balances[msg.sender] = deployerSupply;
        emit Transfer(address(0), msg.sender, deployerSupply);
        _balances[address(this)] = contractSupply;
        emit Transfer(address(0), address(this), contractSupply);
        // Defining the Uniswap Router and the Uniswap Pair
        _UniswapRouter = IUniswapRouter02(UniswapRouter);
        _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory())
            .createPair(address(this), _UniswapRouter.WETH());

        // Barriers
        balanceBarrier = InitialSupply / BalanceBarrierDenominator;
        sellBarrier = InitialSupply / SellBarrierDenominator;
        buyBarrier = InitialSupply / BuyBarrierDenominator;

        _excluded.add(msg.sender);
    }

    // Public transfer method
    function _transfer(
        address fromaddress,
        address receiver,
        uint256 amount
    ) private {
        require(fromaddress != address(0), "Transfer from zero");

        // Check if the transfer is to be excluded from cooldown and taxes
        bool isExcluded = (_excluded.contains(fromaddress) ||
            _excluded.contains(receiver) ||
            isAuthorized[fromaddress] ||
            isAuthorized[receiver]);

        bool isContractTransfer = (fromaddress == address(this) ||
            receiver == address(this));

        bool isLiquidityTransfer = ((fromaddress == _UniswapPairAddress &&
            receiver == UniswapRouter) ||
            (receiver == _UniswapPairAddress && fromaddress == UniswapRouter));
        if (
            isContractTransfer || isLiquidityTransfer || isExcluded
        ) {
            _specialTransfer(fromaddress, receiver, amount);
        } else {
            // If not, check if trading is enabled
            if (!tradingEnabled) {
                // except for the owner
                if (fromaddress != owner && receiver != owner) {
                    // and apply anti-snipe if enabled
                    if (botProtect) {
                        emit Transfer(fromaddress, receiver, 0);
                        return;
                    } else {
                        // or revert if not
                        require(tradingEnabled, "trading not yet enabled");
                    }
                }
            }

            // If trading is enabled, check if the transfer is a buy or a sell
            bool isBuy = fromaddress == _UniswapPairAddress ||
                fromaddress == UniswapRouter;
            bool isSell = receiver == _UniswapPairAddress ||
                receiver == UniswapRouter;
            // and initiate the transfer accordingly
            _justTransfer(fromaddress, receiver, amount, isBuy, isSell);

        }
    }

    // Transfer method for everyone
    function _justTransfer(
        address fromaddress,
        address receiver,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) private {

        uint256 receiverBalance = _balances[receiver];

        require(_balances[fromaddress] >= amount, "Transfer exceeds balance");

        uint8 tax;
        if (isSell) {
            // Sell limit check
            require(amount <= sellBarrier, "Dump protection");
            tax = _sellTax;
        } else if (isBuy) {
            // Balance limit check
            require(
                receiverBalance + amount <= balanceBarrier,
                "whale protection"
            );
            // Buy limit check
            require(amount <= buyBarrier, "whale protection");
            tax = _buyTax;
        } else {
            require(

                receiverBalance + amount <= balanceBarrier,
                "whale protection"
            );
            tax = _transferTax;
        }


        if (
            (fromaddress != _UniswapPairAddress) &&
            (!manualConversion) &&
            (!_isSwappingContractModifier)
        ) _swapContractToken(amount);


        uint256 contractToken = _calculateFee(
            amount,
            tax,
            _liquidityTax + _marketingTax 
        );

        uint256 taxedAmount = amount - (contractToken);
        _removeToken(fromaddress, amount);
        _addToken(address(this), contractToken);
        emit Transfer(fromaddress, address(this), contractToken);
        _addToken(receiver, taxedAmount);
        emit Transfer(fromaddress, receiver, taxedAmount);
    }

    function _specialTransfer(
        address fromaddress,
        address receiver,
        uint256 amount
    ) private {

        require(_balances[fromaddress] >= amount, "Transfer exceeds balance");

        _removeToken(fromaddress, amount);
        _addToken(receiver, amount);

        emit Transfer(fromaddress, receiver, amount);
    }


    function _calculateFee(
        uint256 amount,
        uint8 tax,
        uint8 taxPercent
    ) private pure returns (uint256) {
        require(taxPercent == 100, "Tax percent is not 100");
        return (amount * tax) / 100;
    }

    function _addToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] + amount;
        _balances[addr] = newAmount;
    }

    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] - amount;
        _balances[addr] = newAmount;
    }

    // Swap tokens on sells to create liquidity
    function _swapContractToken(uint256 totalMax) private lockTheSwap {
        uint256 contractBalance = _balances[address(this)];
        // Do not swap if the contract balance is lower than the swap treshold
        if (contractBalance < swapTreshold) {
            return;
        }

        uint16 totalTaxes = _liquidityTax;
        uint256 tokenToSwap = swapTreshold;

        // PEG THE SWAP TO THE MAXIMUM IF THE MAXIMUM IS LOWER THAN THE SWAP TRESHOLD
        if (swapTreshold > totalMax) {
            if (isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }
        // DO NOT SWAP WITHOUT TAXES TO SWAP
        if (totalTaxes == 0) {
            return;
        }

        uint256 tokenForLiquidity = (tokenToSwap * _liquidityTax) / totalTaxes;
        uint256 tokenFormarketing = (tokenToSwap * _marketingTax) / totalTaxes;

        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqETHToken = tokenForLiquidity - liqToken;

        uint256 swapToken = liqETHToken +
            tokenFormarketing;

        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);

        uint256 newETH = (address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH * liqETHToken) / swapToken;

        _addLiquidity(liqToken, liqETH);

        uint256 generatedETH = (address(this).balance - initialETHBalance);
        marketingBalance += generatedETH;
    }

    // Basic swap function for swapping tokens on Uniswap-v2 compatible routers
    function _swapTokenForETH(uint256 amount) private {
        // Preapprove the router to spend the tokens
        _approve(address(this), address(_UniswapRouter), amount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UniswapRouter.WETH();

        _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Basic add liquidity function for adding liquidity on Uniswap-v2 compatible routers
    function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
        // Approve the router to spend the tokens
        _approve(address(this), address(_UniswapRouter), tokenamount);

        _UniswapRouter.addLiquidityETH{value: ETHamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function getBarriers()
        public
        view
        returns (uint256 balance, uint256 sell)
    {
        return (balanceBarrier, sellBarrier);
    }

    function getTaxes()
        public
        view
        returns (
            uint256 marketingShare,
            uint256 liquidityShare,
            uint256 buyTax,
            uint256 sellTax,
            uint256 transferTax
        )
    {
        return (
            _marketingTax,
            _liquidityTax,
            _buyTax,
            _sellTax,
            _transferTax
        );
    }

    // Pegged swap means that the contract won't dump when the swap treshold is reached
    function SetPeggedSwap(bool isPegged) public onlyAuth {
        isSwapPegged = isPegged;
    }

    // The token amount that triggers swap on sells
    function SetSwapTreshold(uint256 max) public onlyAuth {
        swapTreshold = max;
    }

    function ExcludeAccountFromFees(address account) public onlyAuth {
        _excluded.add(account);
    }

    function IncludeAccountToFees(address account) public onlyAuth {
        _excluded.remove(account);
    }

    function WithdrawmarketingETH() public onlyAuth {
        uint256 amount = marketingBalance;
        marketingBalance = 0;
        address fromaddress = msg.sender;
        (bool sent, ) = fromaddress.call{value: (amount)}("");
        require(sent, "withdraw failed");
    }

    function withdrawTaxes() public onlyAuth {
        uint256 amount = address(this).balance;
        address fromaddress = msg.sender;
        (bool sent, ) = fromaddress.call{value: (amount)}("");
        require(sent, "withdraw failed");
        marketingBalance = 0;
    }

    function SwitchManualETHConversion(bool manual) public onlyAuth {
        manualConversion = manual;
    }


    function SetTaxes(
        uint8 marketingTaxes,
        uint8 liquidityTaxes,
        uint8 buyTax,
        uint8 sellTax,
        uint8 transferTax
    ) public onlyAuth {
        uint8 totalTax =
            marketingTaxes +
            liquidityTaxes;
        require(totalTax == 100, "marketing + Liquidity taxes needs to equal 100%");
        _marketingTax = marketingTaxes;
        _liquidityTax = liquidityTaxes;

        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
    }

    function ManualGenerateTokenSwapBalance(uint256 _qty)
        public
        onlyAuth
    {
        _swapContractToken(_qty * 10**9);
    }

    function UpdateBarriers(uint256 newBalanceBarrier, uint256 newSellBarrier)
        public
        onlyAuth
    {
        newBalanceBarrier = newBalanceBarrier * 10**_decimals;
        newSellBarrier = newSellBarrier * 10**_decimals;
        balanceBarrier = newBalanceBarrier;
        sellBarrier = newSellBarrier;
    }

    function EnableTrading(bool BOOLEAN) public onlyAuth {
        tradingEnabled = BOOLEAN;
    }

    function LiquidityTokenAddress(address liquidityTokenAddress)
        public
        onlyAuth
    {
        _UniswapPairAddress = liquidityTokenAddress;
    }

    function RescueTokens(address tknAddress) public onlyAuth {
        iERC20 token = iERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance > 0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function setContractTokenSwapManual(bool manual) public onlyAuth {
        isTokenSwapManual = manual;
    }

    function getFeesValue() public onlyAuth {
        (bool sent, ) = msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address receiver, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, receiver, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transferFrom(
        address fromaddress,
        address receiver,
        uint256 amount
    ) external override returns (bool) {
        _transfer(fromaddress, receiver, amount);

        uint256 currentAllowance = _allowances[fromaddress][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(fromaddress, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}