/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// interface IUniswapV2Factory   : Interface of Uniswap Router

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// interface IUniswapV2Router02  : Interface of Uniswap

interface IUniswapV2Router02 {
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
    returns (uint256 amountToken, uint256 amountETH, uint256 _liquedity);

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

// interface IERC20 : IERC20 Token Interface which would be used in calling token contract
interface IERC20 {
    function totalSupply() external view returns (uint256); //Total Supply of Token

    function decimals() external view returns (uint8); // Decimal of TOken

    function symbol() external view returns (string memory); // Symbol of Token

    function name() external view returns (string memory); // Name of Token

    function balanceOf(address account) external view returns (uint256); // Balance of TOken

    //Transfer token from one address to another

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Get allowance to the spacific users

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    // Give approval to spend token to another addresses

    function approve(address spender, uint256 amount) external returns (bool);

    // Transfer token from one address to another

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //Trasfer Event
    event Transfer(address indexed from, address indexed to, uint256 value);

    event CheckSwap(address weth, uint256 totalFee);

    event Log(string message);
    event LogBytes(bytes data);

    //Approval Event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// This contract helps to add Owners
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Library used to perform math operations
library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

// main contract of Token
contract bageth is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "bageth"; //Token Name
    string private constant _symbol = "GET"; //Token Symbol
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 200_000_000 * 10 ** _decimals; //Token Decimals

    uint256 maxTxnLimit = _totalSupply;
    uint256 maxHoldLimit = _totalSupply;

    IUniswapV2Router02 public router; //Router
    address public uniPair; //Uniswap token Pair

    uint256 public totalBuyFee = 3; //Total Buy Fee - 3%
    uint256 public totalSellFee = 3; //Total Sell Fee - 3%
    uint256 public feeDivider = 100; // Number denominator

    // 3% on Buying Tax
    uint256 _reflectionBuyFee = 3; // 3% on Buying Reflection = total buy fee
    // 3% on Selling Tax
    uint256 _reflectionSellFee = 3; // 3% on Selling Reflection = total sell fee

    struct Share {
        uint256 amount;
        bool isShare;
    }
    // reflection setting
    uint256 public shareHoldersCount;
    uint256 public totalOfShares;
    uint256 public totalOfFees;
    address[] public shareHolderList;
    mapping(address => Share) public shares;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isRewardExempt;
    mapping(address => bool) public _isExcludedFromMaxTxn;
    mapping(address => bool) public _isExcludedMaxHolding;

    //whitelisted address
    mapping(address => bool) public whitelists;

    bool public enableTrading;
    uint256 public tradingLimit = _totalSupply;
    uint256 public minTokenHoldingForReward;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyWhitelist {
        require(whitelists[msg.sender], "This is not whitelisted address");
        _;
    }

    constructor() {
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        // uniswap v2 router address here - you don't need to change it.

        minTokenHoldingForReward = 50000;
        //at least 5k token holding needed for get reflection
        // min token holding for reflection reward
        router = IUniswapV2Router02(_router);
        uniPair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        //exclude uniPair, contract, router from max txn limit
        isRewardExempt[uniPair] = true;
        isRewardExempt[address(this)] = true;
        isFeeExempt[owner()] = true;

        _isExcludedFromMaxTxn[owner()] = true;
        _isExcludedFromMaxTxn[uniPair] = true;
        _isExcludedFromMaxTxn[address(this)] = true;
        _isExcludedFromMaxTxn[address(router)] = true;

        _isExcludedMaxHolding[address(this)] = true;
        _isExcludedMaxHolding[owner()] = true;
        _isExcludedMaxHolding[uniPair] = true;
        _isExcludedMaxHolding[address(router)] = true;

        _balances[owner()] = _totalSupply;

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(uniPair)] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {} //receiving eth in contract

    // _transfer() :   called by external transfer and transferFrom function
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!_isExcludedMaxHolding[recipient] && !whitelists[recipient]) {
            require(
                amount.add(balanceOf(recipient)) <= maxHoldLimit,
                "Max hold limit exceeds"
            );
        }
        if (
            !_isExcludedFromMaxTxn[sender] && !_isExcludedFromMaxTxn[recipient] && !whitelists[recipient] && !whitelists[sender]
        ) {
            require(amount <= maxTxnLimit, "BigBuy: max txn limit exceeds");
        }
        if (inSwap) {
            return _simpleTransfer(sender, recipient, amount);
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived;
        if (
            isFeeExempt[sender] ||
            isFeeExempt[recipient] ||
            (sender != uniPair && recipient != uniPair) ||
            whitelists[sender] ||
            whitelists[recipient]
        ) {
            amountReceived = amount;
        } else {
            require(enableTrading, "Token Trading is not started yet");
            uint256 feeAmount;
            if (sender == uniPair) {
                feeAmount = amount.mul(_reflectionBuyFee).div(feeDivider);
                amountReceived = amount.sub(feeAmount);
                _takeFee(sender, feeAmount);
            }
            if (recipient == uniPair) {
                feeAmount = amount.mul(_reflectionSellFee).div(feeDivider);
                amountReceived = amount.sub(feeAmount);
                _takeFee(sender, feeAmount);
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isRewardExempt[sender]) {
            if ((balanceOf(sender)) >= minTokenHoldingForReward) {
                setShare(sender, _balances[sender]);
            } else {
                setShare(sender, 0);
            }
        }
        if (!isRewardExempt[recipient]) {
            if ((balanceOf(recipient)) >= minTokenHoldingForReward) {
                setShare(recipient, _balances[recipient]);
            } else {
                setShare(recipient, 0);
            }
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    // _simpleTransfer() : Transfer basic token account to account

    function _simpleTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function airdrop(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(addresses.length == amounts.length, "Array sizes must be equal");
        uint256 i = 0;
        while (i < addresses.length) {
            uint256 _amount = amounts[i].mul(1e18);
            _simpleTransfer(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }


    // _takeFee() : This function get calls internally to take fee

    function _takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        totalOfFees = totalOfFees.add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    //shouldSwap() : To check swap should be done or not
    function shouldSwap(address sender, address recipient) public view returns (bool) {
        return (!inSwap && (enableTrading || !whitelists[sender] || !whitelists[recipient]));
    }

    // update shareholder list
    function setShare(address shareholder, uint256 amount) internal {
        if (amount > 0 && amount >= minTokenHoldingForReward) {
            if (shares[shareholder].isShare) {
                totalOfShares = totalOfShares.sub(shares[shareholder].amount).add(amount);
                shares[shareholder].amount = amount;
            } else {
                shares[shareholder] = Share(amount, true);
                totalOfShares = totalOfShares.add(amount);
                shareHoldersCount = shareHoldersCount.add(1);
                shareHolderList.push(shareholder);
            }
        } else {
            if (shares[shareholder].isShare) {
                totalOfShares = totalOfShares.sub(shares[shareholder].amount);
                shares[shareholder].amount = 0;
                shares[shareholder].isShare = false;
                shareHoldersCount = shareHoldersCount.sub(1);
                for (uint256 i = 0; i < shareHolderList.length; i++) {
                    if (shareHolderList[i] == shareholder) {
                        shareHolderList[i] = shareHolderList[shareHolderList.length - 1];
                        shareHolderList.pop();
                        break;
                    }
                }
            }
        }
    }

    // execute reflection distribution to all shareholders
    function runDistribution(uint256 amountEth) internal {
        if (shareHoldersCount > 0 && totalOfFees > 0) {
            for (uint i; i < shareHoldersCount; i++) {
                address shareholder = shareHolderList[i];
                if (shares[shareholder].isShare) {
                    uint256 amount = amountEth.mul(shares[shareholder].amount).div(totalOfShares);
                    if (amount > 0) {
                        payable(shareholder).transfer(amount);
                    }
                }
            }

            totalOfShares = 0;
            totalOfFees = 0;
        }
    }

    //Swapback() : To swap and liquify the token
    function swapBack() external swapping {
        uint256 amount = balanceOf(address(this));
        require(amount >= totalOfFees, "Not enough token for swap");
        if (totalOfFees > 0) {
            uint256 amountToSwap = totalOfFees;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();
            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp + 1500
            );

            uint256 amountEth = address(this).balance.sub(balanceBefore);

            runDistribution(amountEth);
        }
    }

    function MinTokenHoldingForReward(uint256 _minTokenHoldingForReward) public onlyOwner {
        minTokenHoldingForReward = _minTokenHoldingForReward;
    }

    //Once get wrong eth in contract, owner can withdraw it ===
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // setFeeExempt() : Function that Set Holders Fee Exempt
    //   ***          : It add user in fee exempt user list
    //   ***          : Owner & Authoized user Can set this
    function setFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    // includeOrExcludeFromMaxTxn() : Function that set users exclude from fee
    //   ***       : Owner & Authoized user Can set the fees
    function includeOrExcludeFromMaxTxn(
        address account,
        bool value
    ) external onlyOwner {
        _isExcludedFromMaxTxn[account] = value;
    }

    function includeOrExcludeFromMaxHolding(
        address account,
        bool value
    ) external onlyOwner {
        _isExcludedMaxHolding[account] = value;
    }

    function setMaxHoldLimit(uint256 _amount) external onlyOwner {
        maxHoldLimit = _amount * 1e18;
    }

    function setMaxTxnLimit(uint256 _amount) external onlyOwner {
        maxTxnLimit = _amount * 1e18;
    }

    // setBuyFee() : Function that set Buy Fee of token
    //   ***       : Owner & Authoized user Can set the fees
    function setBuyFee(
        uint256 _reflectionFee
    ) public onlyOwner {
        _reflectionBuyFee = _reflectionFee;
        totalBuyFee = (_reflectionFee);
        require(totalBuyFee <= feeDivider.div(4), "Can't be greater than 25%");
    }

    // setSellFee() : Function that set Sell Fee
    //    ***       : Owner & Authoized user Can set the fees

    function setSellFee(
        uint256 _reflectionFee
    ) public onlyOwner {
        _reflectionSellFee = _reflectionFee;
        totalSellFee = (_reflectionFee);
        require(totalSellFee <= feeDivider.div(4), "Can't be greater than 25%");
    }

    // setEnableTrading() : Function that enable of disable swapping functionality of token while transfer
    //     ***       : Swap Limit can be changed through this function
    //     ***       : Owner & Authorized user Can set the swapBack
    function setEnableTrading(bool _enabled) external onlyOwner {
        enableTrading = _enabled;
    }

    function setWhitelist(address[] memory addressList) external onlyOwner {
        require(addressList.length > 0, "Please Enter Address list");
        for (uint256 i; i < addressList.length; i++) {
            require(addressList[i] != address(0), "Can't add zero address");
            whitelists[addressList[i]] = true;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////
    ///////////// Overriding Libraries Functions //////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////

    // totalSupply() : Shows total Supply of token
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    //decimals() : Shows decimals of token
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    // symbol() : Shows symbol of function
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    // name() : Shows name of Token
    function name() external pure override returns (string memory) {
        return _name;
    }

    // balanceOf() : Shows balance of the user
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //allowance()  : Shows allowance of the address from another address
    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    // approve() : This function gives allowance of token from one address to another address
    //  ****     : Allowance is checked in TransferFrom() function.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // approveMax() : approves the token amount to the spender that is maximum amount of token
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    // transfer() : Transfers tokens  to another address
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    // transferFrom() : Transfers token from one address to another address by utilizing allowance
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }
}