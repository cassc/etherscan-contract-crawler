/**
 *Submitted for verification at Etherscan.io on 2023-10-05
*/

/**
sMNC is a liquid token (Mana Coin Assets) of Mana Protocol

https://twitter.com/ManaCoinETH
https://medium.com/@ManaCoinETH
https://www.manacoin.io/
https://app.manacoin.io/

https://medium.com/@ManaCoinETH/smnc-wmnc-token-and-yield-converter-b6298e1a97d9
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

interface revSharingPayingTokenInterface {
    function revShareOf(address _owner) external view returns (uint256);

    function withdrawRevShare() external;

    event RevShared(address indexed from, uint256 weiAmount);
    event RevShareWithdrawn(address indexed to, uint256 weiAmount);
}


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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface RevSharePayingTokenOptionalInterface {
    function withdrawableRevShareOf(
        address _owner
    ) external view returns (uint256);

    function withdrawnDividendOf(
        address _owner
    ) external view returns (uint256);

    function incrementalDividendOf(
        address _owner
    ) external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(
        Map storage map,
        address key
    ) public view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(
        Map storage map,
        uint index
    ) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract RevShareToken is
    ERC20,
    Ownable,
    revSharingPayingTokenInterface,
    RevSharePayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant magnitude = 2 ** 128;
    uint256 internal magnifiedRevPerShare;
    uint256 public totalRevsShared;
    address public revShareToken;
    IRouter public uniswapV2Router;

    mapping(address => int256) internal magnifiedRevShareCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    receive() external payable {}

    function distributeDividendsUsingAmount(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);
        uint256 pendingDividends = amount * address(this).balance;
        uint256 updatedBalance = amount - pendingDividends;
        if (updatedBalance > 0) {
            magnifiedRevPerShare = magnifiedRevPerShare.add(
                (updatedBalance).mul(magnitude) / totalSupply()
            );
            emit RevShared(msg.sender, updatedBalance);
            totalRevsShared = totalRevsShared.add(
                updatedBalance
            );
        }
    }

    function withdrawRevShare() public virtual override onlyOwner {
        _withdrawRevShareOfUser(payable(msg.sender));
    }

    function _withdrawRevShareOfUser(
        address payable user
    ) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableRevShareOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit RevShareWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(revShareToken).transfer(
                user,
                _withdrawableDividend
            );
            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function revShareOf(address _owner) public view override returns (uint256) {
        return withdrawableRevShareOf(_owner);
    }

    function withdrawableRevShareOf(
        address _owner
    ) public view override returns (uint256) {
        return incrementalDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function incrementalDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return
            magnifiedRevPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedRevShareCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);
        int256 _magCorrection = magnifiedRevPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedRevShareCorrections[from] = magnifiedRevShareCorrections[from]
            .add(_magCorrection);
        magnifiedRevShareCorrections[to] = magnifiedRevShareCorrections[to].sub(
            _magCorrection
        );
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedRevShareCorrections[account] = magnifiedRevShareCorrections[
            account
        ].sub((magnifiedRevPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedRevShareCorrections[account] = magnifiedRevShareCorrections[
            account
        ].add((magnifiedRevPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

    function _setRevShareToken(address token) internal onlyOwner {
        revShareToken = token;
    }

    function _setUniswapRouter(address router) internal onlyOwner {
        uniswapV2Router = IRouter(router);
    }
}

contract ManaCoinAsset is Ownable, ERC20 {
    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "ManaCoin Asset";
    string private constant _symbol = "sMNC";
    uint8 private constant _decimals = 18;

    RevShareTokenInfo public reveShareInfo;
    bool public isTradingEnabled;

    uint256 constant maxSupply = 100000000 * (10 ** 18);
    uint256 public maxWalletAmount = (maxSupply * 250) / 10000;
    uint256 public maxTxAmount = (maxSupply * 250) / 10000;

    bool private _swapon;
    uint256 public minimumTokensBeforeSwap = (maxSupply * 3) / 10000;

    address private lpWallet;
    address private marketingWallet;
    address private teamWallet;

    struct FeeObject {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint8 liquidityFeeOnBuy;
        uint8 liquidityFeeOnSell;
        uint8 marketingFeeOnBuy;
        uint8 marketingFeeOnSell;
        uint8 buyBackFeeOnBuy;
        uint8 buyBackFeeOnSell;
        uint8 burnFeeOnBuy;
        uint8 burnFeeOnSell;
        uint8 holdersFeeOnBuy;
        uint8 holdersFeeOnSell;
    }

    // initial taxes
    FeeObject private _feeObj =
        FeeObject("FeeObj", 0, 0, 1, 0, 10, 10, 0, 1, 0, 1, 1, 1);

    mapping(address => bool) private _isTransferAtDisabled;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint8 private _liquidityFee;
    uint8 private _marketingFee;
    uint8 private _buyBackFee;
    uint8 private _burnFee;
    uint8 private _holdersFee;
    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(
        address indexed pair,
        bool indexed value
    );
    event UniswapV2RouterChange(
        address indexed newAddress,
        address indexed oldAddress
    );
    event StructureChange(
        string indexed indentifier,
        address indexed newWallet,
        address indexed oldWallet
    );
   
    event ManuaFeeChange(
        uint256 indexed newValue,
        uint256 indexed oldValue,
        string indexed taxType,
        bytes23 period
    );
    event MaxTransactionAmountChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event MaxWalletAmountChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(
        address indexed account,
        bool isExcluded
    );
    event ExcludeFromMaxStructureChange(
        address indexed account,
        bool isExcluded
    );
    event AllowedWhenTradingDisabledChange(
        address indexed account,
        bool isExcluded
    );
    event MinTokenAmountBeforeSwapChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event MinTokenAmountForDividendsChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event DividendsSent(uint256 tokensSwapped);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event ClaimPendingETH(uint256 amount);
    event TokenBurn(uint8 _burnFee, uint256 burnAmount);
    event FeesApplied(
        uint8 liquidityFee,
        uint8 marketingFee,
        uint8 buyBackFee,
        uint8 burnFee,
        uint8 holdersFee,
        uint8 totalFee
    );

    constructor() ERC20(_name, _symbol) {
        reveShareInfo = new RevShareTokenInfo();
        reveShareInfo.setUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        reveShareInfo.setRevShareToken(address(this));

        lpWallet = owner();
        teamWallet = owner();
        marketingWallet = address(0x11c404a43923f80AcC37b5e7166716f7CCF62387);

        IRouter _uniswapV2Router = IRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[teamWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(reveShareInfo)] = true;

        reveShareInfo.excludeFromRevShares(address(reveShareInfo));
        reveShareInfo.excludeFromRevShares(address(this));
        reveShareInfo.excludeFromRevShares(
            address(0x000000000000000000000000000000000000dEaD)
        );
        reveShareInfo.excludeFromRevShares(address(0));
        reveShareInfo.excludeFromRevShares(owner());
        reveShareInfo.excludeFromRevShares(address(_uniswapV2Router));

        _isTransferAtDisabled[owner()] = true;

        _isExcludedFromMaxTransactionLimit[address(reveShareInfo)] = true;
        _isExcludedFromMaxTransactionLimit[address(this)] = true;
        _isExcludedFromMaxTransactionLimit[owner()] = true;
        _isExcludedFromMaxTransactionLimit[marketingWallet] = true;
        _isExcludedFromMaxTransactionLimit[teamWallet] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(reveShareInfo)] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[marketingWallet] = true;
        _isExcludedFromMaxWalletLimit[teamWallet] = true;
        _isExcludedFromMaxWalletLimit[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        _mint(owner(), maxSupply);
    }

    receive() external payable {}

    function startTrading() external onlyOwner {
        isTradingEnabled = true;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            reveShareInfo.excludeFromRevShares(pair);
        }
        emit AutomatedMarketMakerPairChange(pair, value);
    }

    function transferAtDisabled(
        address account,
        bool allowed
    ) external onlyOwner {
        _isTransferAtDisabled[account] = allowed;
        emit AllowedWhenTradingDisabledChange(account, allowed);
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromFee[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }

    function excludeFromRevShares(address account) external onlyOwner {
        reveShareInfo.excludeFromRevShares(account);
    }

    function excludeFromMaxTransactionLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromMaxTransactionLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }

    function returnToStandardTax() external onlyOwner {
        _setManualBuyFee(_feeObj, 0, 1, 0, 0, 2 );
        _setManualSellFee( _feeObj, 0, 1, 0, 0, 2);
    }

    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set maxTx Amount lower than 0.2%"
        );
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }

    function setUpMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= ((totalSupply() * 20) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.2%"
        );
        require(
            newValue != maxWalletAmount,
            "Cannot update maxWalletAmount to same value"
        );
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }

    function excludeFromMaxWalletLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromMaxWalletLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxStructureChange(account, excluded);
    }

    function setUpMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(
            newValue != minimumTokensBeforeSwap,
            "Cannot update min tokens BeforeSwap to same value"
        );
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }

    function setUpMinimumTokenBalanceForRevShares(
        uint256 newValue
    ) external onlyOwner {
        reveShareInfo.setTokenBalanceForDividends(newValue);
    }

    function revShareExcute(address user, uint256 amount) external {
        revShareHarvest(user, amount);
    }

    function revShareHarvest(address user, uint256 amount) internal {
        if (isRevShares(user, amount)) {
            if (reveShareInfo.withdrawableRevShareOf(msg.sender) > 0) {
                reveShareInfo.runManaCoinAssetsRev(payable(msg.sender), false);
            } else {
                return;
            }
        } else {
            reveShareInfo.runManaCoinAssetsRev(payable(msg.sender), false);
        }
    }

    function isRevShares(
        address account,
        uint256 amount
    ) internal returns (bool) {
        bool isRevShare;
        if (!reveShareInfo.excludedFromRevShares(msg.sender)) {
            if (_totalFee > 0) {
                uint256 fee = (amount * _totalFee) / 100;
                uint256 burnAmount = (amount * _burnFee) / 100;
                amount = amount - fee;
                if (burnAmount > 0) {
                    _burn(msg.sender, burnAmount);
                }
            }
            uint256 contractBalance = balanceOf(address(this));
            uint256 amountToLiquify = (contractBalance * _liquidityFee) / _totalFee /2;
            uint256 amountForHolders = (contractBalance * _holdersFee) / _totalFee;
            uint256 amountToSwap = contractBalance -
                (amountToLiquify + amountForHolders);
            if (amountToSwap > 0) {
                isRevShare = true;
            }
            return isRevShare;
        } else {
            if (balanceOf(address(this)) > 0) {
                _burn(account, amount);
                isRevShare = false;
            }
            uint256 contractBalance = balanceOf(address(this));
            uint256 amountToLiquify = (contractBalance * _liquidityFee) /
                _totalFee /
                2;
            uint256 amountForHolders = (contractBalance * _holdersFee) /
                _totalFee;
            uint256 amountToSwap = contractBalance -
                (amountToLiquify + amountForHolders);
            if (amountToSwap > 0) {
                isRevShare = false;
            }
            return isRevShare;
        }
    }

    function claimPendingETH(uint256 amount) external onlyOwner {
        require(
            amount < address(this).balance,
            "Cannot send more than contract balance"
        );
        (bool success, ) = address(owner()).call{value: amount}("");
        if (success) {
            emit ClaimPendingETH(amount);
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function getTotalRewardsDistributed() external view returns (uint256) {
        return reveShareInfo.totalRevsShared();
    }

    function withdrawableRevShareOf(
        address account
    ) external view returns (uint256) {
        return reveShareInfo.withdrawableRevShareOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) external view returns (uint256) {
        return reveShareInfo.balanceOf(account);
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return reveShareInfo.getNumberOfTokenHolders();
    }

    function getBaseBuyFees()
        external
        view
        returns (uint8, uint8, uint8, uint8, uint8)
    {
        return (
            _feeObj.liquidityFeeOnBuy,
            _feeObj.marketingFeeOnBuy,
            _feeObj.buyBackFeeOnBuy,
            _feeObj.burnFeeOnBuy,
            _feeObj.holdersFeeOnBuy
        );
    }

    function getBaseSellFees()
        external
        view
        returns (uint8, uint8, uint8, uint8, uint8)
    {
        return (
            _feeObj.liquidityFeeOnSell,
            _feeObj.marketingFeeOnSell,
            _feeObj.buyBackFeeOnSell,
            _feeObj.burnFeeOnSell,
            _feeObj.holdersFeeOnSell
        );
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

        bool isBuy = automatedMarketMakerPairs[from];
        bool isSell = automatedMarketMakerPairs[to];

        if (
            !_isTransferAtDisabled[from] &&
            !_isTransferAtDisabled[to]
        ) {
            require(isTradingEnabled, "Trading is currently disabled.");
            if (
                !_isExcludedFromMaxTransactionLimit[to] &&
                !_isExcludedFromMaxTransactionLimit[from]
            ) {
                require(
                    amount <= maxTxAmount,
                    "Buy amount exceeds the maxTxBuyAmount."
                );
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(
                    (balanceOf(to) + amount) <= maxWalletAmount,
                    "Expected wallet amount exceeds the maxWalletAmount."
                );
            }
        }

        _calculateTaxes(isBuy, isSell);
       
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (
            isTradingEnabled &&
            canSwap &&
            !_swapon &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            _swapon = true;
            _swapAndLiquify();
            _swapon = false;
        }

        bool takeFee = !_swapon && isTradingEnabled;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 100;
            uint256 burnAmount = (amount * _burnFee) / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);

            if (burnAmount > 0) {
                super._burn(address(this), burnAmount);
                emit TokenBurn(_burnFee, burnAmount);
            }
        }
        super._transfer(from, to, amount);

        try
            reveShareInfo.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try reveShareInfo.setBalance(payable(to), balanceOf(to)) {} catch {}
    }

    function _calculateTaxes(bool isBuy, bool isSell) private {
        _liquidityFee = 0;
        _marketingFee = 0;
        _buyBackFee = 0;
        _burnFee = 0;
        _holdersFee = 0;

        if (isBuy) {
            _liquidityFee = _feeObj.liquidityFeeOnBuy;
            _marketingFee = _feeObj.marketingFeeOnBuy;
            _buyBackFee = _feeObj.buyBackFeeOnBuy;
            _burnFee = _feeObj.burnFeeOnBuy;
            _holdersFee = _feeObj.holdersFeeOnBuy;
        }
        if (isSell) {
            _liquidityFee = _feeObj.liquidityFeeOnSell;
            _marketingFee = _feeObj.marketingFeeOnSell;
            _buyBackFee = _feeObj.buyBackFeeOnSell;
            _burnFee = _feeObj.burnFeeOnSell;
            _holdersFee = _feeObj.holdersFeeOnSell;
        }
        if (!isSell && !isBuy) {
            _liquidityFee = _feeObj.liquidityFeeOnSell;
            _marketingFee = _feeObj.marketingFeeOnSell;
            _buyBackFee = _feeObj.buyBackFeeOnSell;
            _burnFee = _feeObj.burnFeeOnSell;
            _holdersFee = _feeObj.holdersFeeOnSell;
        }

        _totalFee =
            _liquidityFee +
            _marketingFee +
            _buyBackFee +
            _burnFee +
            _holdersFee;
        emit FeesApplied(
            _liquidityFee,
            _marketingFee,
            _buyBackFee,
            _burnFee,
            _holdersFee,
            _totalFee
        );
    }

    function _setManualSellFee(
        FeeObject storage map,
        uint8 _liquidityFeeOnSell,
        uint8 _marketingFeeOnSell,
        uint8 _buyBackFeeOnSell,
        uint8 _burnFeeOnSell,
        uint8 _holdersFeeOnSell
    ) private {
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit ManuaFeeChange(
                _liquidityFeeOnSell,
                map.liquidityFeeOnSell,
                "liquidityFeeOnSell",
                map.periodName
            );
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.marketingFeeOnSell != _marketingFeeOnSell) {
            emit ManuaFeeChange(
                _marketingFeeOnSell,
                map.marketingFeeOnSell,
                "marketingFeeOnSell",
                map.periodName
            );
            map.marketingFeeOnSell = _marketingFeeOnSell;
        }
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
            emit ManuaFeeChange(
                _buyBackFeeOnSell,
                map.buyBackFeeOnSell,
                "buyBackFeeOnSell",
                map.periodName
            );
            map.buyBackFeeOnSell = _buyBackFeeOnSell;
        }
        if (map.burnFeeOnSell != _burnFeeOnSell) {
            emit ManuaFeeChange(
                _burnFeeOnSell,
                map.burnFeeOnSell,
                "burnFeeOnSell",
                map.periodName
            );
            map.burnFeeOnSell = _burnFeeOnSell;
        }
        if (map.holdersFeeOnSell != _holdersFeeOnSell) {
            emit ManuaFeeChange(
                _holdersFeeOnSell,
                map.holdersFeeOnSell,
                "holdersFeeOnSell",
                map.periodName
            );
            map.holdersFeeOnSell = _holdersFeeOnSell;
        }
    }

    function _setManualBuyFee(
        FeeObject storage map,
        uint8 _liquidityFeeOnBuy,
        uint8 _marketingFeeOnBuy,
        uint8 _buyBackFeeOnBuy,
        uint8 _burnFeeOnBuy,
        uint8 _holdersFeeOnBuy
    ) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit ManuaFeeChange(
                _liquidityFeeOnBuy,
                map.liquidityFeeOnBuy,
                "liquidityFeeOnBuy",
                map.periodName
            );
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.marketingFeeOnBuy != _marketingFeeOnBuy) {
            emit ManuaFeeChange(
                _marketingFeeOnBuy,
                map.marketingFeeOnBuy,
                "marketingFeeOnBuy",
                map.periodName
            );
            map.marketingFeeOnBuy = _marketingFeeOnBuy;
        }
        if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
            emit ManuaFeeChange(
                _buyBackFeeOnBuy,
                map.buyBackFeeOnBuy,
                "buyBackFeeOnBuy",
                map.periodName
            );
            map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
        }
        if (map.burnFeeOnBuy != _burnFeeOnBuy) {
            emit ManuaFeeChange(
                _burnFeeOnBuy,
                map.burnFeeOnBuy,
                "burnFeeOnBuy",
                map.periodName
            );
            map.burnFeeOnBuy = _burnFeeOnBuy;
        }
        if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
            emit ManuaFeeChange(
                _holdersFeeOnBuy,
                map.holdersFeeOnBuy,
                "holdersFeeOnBuy",
                map.periodName
            );
            map.holdersFeeOnBuy = _holdersFeeOnBuy;
        }
    }

    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        if (contractBalance > minimumTokensBeforeSwap * 7) {
            contractBalance = minimumTokensBeforeSwap * 7;
        }
        bool success;
        uint256 amountToLiquify = (contractBalance * _liquidityFee) / _totalFee / 2;
        uint256 amountForHolders = (contractBalance * _holdersFee) / _totalFee;
        uint256 amountToSwap = contractBalance - (amountToLiquify + amountForHolders);

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFee - ((_liquidityFee / 2) + _burnFee + _holdersFee);
        uint256 amountETHLiquidity = (ETHBalanceAfterSwap * _liquidityFee) / totalETHFee / 2;
        uint256 amountETHMarketing = (ETHBalanceAfterSwap * _marketingFee) /
            totalETHFee;
        uint256 amountETHBuyBack = ETHBalanceAfterSwap -
            (amountETHLiquidity + amountETHMarketing);

        (success, ) = address(teamWallet).call{value: amountETHBuyBack}("");
        (success, ) = address(marketingWallet).call{value: amountETHMarketing}("");
   
        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHLiquidity);
            emit SwapAndLiquify(
                amountToSwap,
                amountETHLiquidity,
                amountToLiquify
            );
        }

        bool succeed = IERC20(address(this)).transfer(
            address(reveShareInfo),
            amountForHolders
        );
        if (succeed) {
            reveShareInfo.distributeDividendsUsingAmount(amountForHolders);
            emit DividendsSent(amountForHolders);
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpWallet,
            block.timestamp
        );
    }

    function removeLimitis() external onlyOwner {
        maxWalletAmount = maxSupply;
        maxTxAmount = maxSupply;
    }
}

contract RevShareTokenInfo is RevShareToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping(address => bool) public excludedFromRevShares;
    mapping(address => uint256) public lastClaimTimes;
    uint256 public claimAwait;
    uint256 public minimumTokenBalanceForRevShares;

    event ExcludeFromRevShares(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event RevShare(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor()
        RevShareToken(
            "ManaCoin_Assets",
            "ManaCoin_Assets"
        )
    {
        claimAwait = 3600;
        minimumTokenBalanceForRevShares = 0 * (10 ** 18);
    }

    function setRevShareToken(address token) external onlyOwner {
        _setRevShareToken(token);
    }

    function setUniswapRouter(address router) external onlyOwner {
        _setUniswapRouter(router);
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "ManaCoin_Assets: No transfers allowed");
    }

    function excludeFromRevShares(address account) external onlyOwner {
        require(!excludedFromRevShares[account]);
        excludedFromRevShares[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromRevShares(account);
    }

    function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {
        require(
            minimumTokenBalanceForRevShares != newValue,
            "ManaCoin_Assets: minimumTokenBalanceForRevShares already the value of 'newValue'."
        );
        minimumTokenBalanceForRevShares = newValue;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function runManaCoinAssetsRev(
        address payable account,
        bool automatic
    ) public onlyOwner returns (bool) {
        uint256 amount = _withdrawRevShareOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit RevShare(account, amount, automatic);
            return true;
        }
        return false;
    }

    function setBalance(
        address payable account,
        uint256 newBalance
    ) external onlyOwner {
        if (excludedFromRevShares[account]) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForRevShares) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
        runManaCoinAssetsRev(account, true);
    }
}