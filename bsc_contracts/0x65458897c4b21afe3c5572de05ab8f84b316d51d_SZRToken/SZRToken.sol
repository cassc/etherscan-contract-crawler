/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract SZRToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    struct InviteFeeTier {
        uint256 inviteFee_1;
        uint256 inviteFee_2;
        uint256 inviteFee_3;
        uint256 inviteFee_4;
        uint256 inviteFee_5;
        uint256 inviteFee_6;
        uint256 inviteFee_7;
    }

    struct TFeeTier {
        uint256 holderFee;
        uint256 liquidityFee;
        uint256 nodeFee;
        uint256 baseFee;
        uint256 tecFee;
        uint256 burnFee;
        uint256 taxFee;
    }

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    mapping(address => bool) private _whiteList;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 private _previousTaxFee;
    uint256 private _previousSellBuyFee;

    bool private _isSellOrBuy;
    uint256 public baseRate = 10000;

    uint256 public _maxTxAmount;
    address public BurnAddr = 0x000000000000000000000000000000000000dEaD;
    address public LpAddr = 0xb9f6b1D72b56C36beF343199eBbB6D809B78efDf;
    address public TecAddr = 0x727046cFf075522d21E155eAF310921b5936B20B;
    address public DefRelationAddr = 0x09aC9c0dA9d69013A807845d8DB3C2a65B85d8Ea;

    uint256 public minRelationAmount = 1e14;

    mapping(address => bool) public pairs;

    address[] public nodes;
    address[] public base;

    mapping(address => address) public _recommerMapping;
    mapping(address => bool) public notBind;

    InviteFeeTier public inviteFees;
    TFeeTier public tFees;
    TFeeTier public tradeFees;

    event BindRelation(address recommer, address who, uint256 amount, uint256 timestamp);

    constructor() public {
        _name = "SZR";
        _symbol = "SZR";
        _decimals = 18;

        _tTotal = 21000000 * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));

        _maxTxAmount = _tTotal;

        address tokenOwner = msg.sender;
        _rOwned[tokenOwner] = _rTotal;
        _tOwned[tokenOwner] = _tTotal;

        _whiteList[tokenOwner] = true;

        fees_init();

        _owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }

    function fees_init() private {

        inviteFees = InviteFeeTier(500, 500, 1000, 300, 300, 300, 300);

        tradeFees = TFeeTier(1000, 1500, 2000, 1500, 300, 500, 1000);

        tFees = TFeeTier(1000, 4000, 2000, 3000, 0, 0, 100);

        _previousTaxFee = tFees.taxFee;
        _previousSellBuyFee = tradeFees.taxFee;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 allTaxFee = _taxAllFee(tAmount);
        (uint256 tTransferAmount, uint256 tFee,) = _getTValues(tAmount, allTaxFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, allTaxFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, allTaxFee);
    }

    function _getTValues(uint256 tAmount, uint256 allTxFee) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(allTxFee);
        uint256 tTransferAmount = tAmount.sub(allTxFee);
        return (tTransferAmount, tFee, 0);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 allTxFee, uint256 currentRate)
        private
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(allTxFee.mul(currentRate));
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeBurn(address sender, uint256 tBurn) private {
        if (tBurn > 0) {
            uint256 currentRate = _getRate();
            uint256 rBurn = tBurn.mul(currentRate);
            _rOwned[BurnAddr] = _rOwned[BurnAddr].add(rBurn);
            if (_isExcluded[BurnAddr]) {
                _tOwned[BurnAddr] = _tOwned[BurnAddr].add(tBurn);
            }
            _tBurnTotal = _tBurnTotal.add(tBurn);
            _rTotal = _rTotal.sub(rBurn);
            _tTotal = _tTotal.sub(tBurn);
            emit Transfer(sender, BurnAddr, tBurn);
        }
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_isSellOrBuy ? tradeFees.holderFee : tFees.holderFee).div(baseRate);
    }

    function _taxAllFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_isSellOrBuy ? tradeFees.taxFee : tFees.taxFee).div(baseRate);
    }

    function removeAllFee() private {
        if (tFees.taxFee == 0 && tradeFees.taxFee == 0) return;

        _previousTaxFee = tFees.taxFee;
        _previousSellBuyFee = tradeFees.taxFee;

        tFees.taxFee = 0;
        tradeFees.taxFee = 0;
    }

    function restoreAllFee() private {
        tFees.taxFee = _previousTaxFee;
        tradeFees.taxFee = _previousSellBuyFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        bool takeFee = true;

        if (_whiteList[from] || _whiteList[to]) {
            takeFee = false;
        }

        if (pairs[from] || pairs[to]) {
            _isSellOrBuy = true;
            _sellOrBuyTransfer(from, to, amount, takeFee);
        } else {
            if (!takeFee) {
                removeAllFee();
            }

            _isSellOrBuy = false;
            uint256 taxFee = _tokenTransfer(from, to, amount, takeFee);
            _takeTaxFees(from, taxFee);

            if (!takeFee) {
                restoreAllFee();
            }

            if (
                !isContract(from) && !isContract(to) && _recommerMapping[to] == address(0)
                    && amount >= minRelationAmount && !notBind[to] && _isCanBind(to)
            ) {
                _recommerMapping[to] = from;
                emit BindRelation(from, to, amount, block.timestamp);
            }
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee)
        private
        returns (uint256)
    {
        if (!takeFee) {
            removeAllFee();
        }

        uint256 taxFee;
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            taxFee = _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            taxFee = _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            taxFee = _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            taxFee = _transferBothExcluded(sender, recipient, amount);
        } else {
            taxFee = _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            restoreAllFee();
        }

        return taxFee;
    }

    function _sellOrBuyTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();

        (uint256[] memory lelFees,, uint256 burnFee, uint256 lpFee, uint256 nodeFee, uint256 baseFee, uint256 tecFee) =
            _getTradeFees(amount);

        _tokenTransfer(sender, recipient, amount, takeFee);

        if (takeFee) {
            removeAllFee();
            takeToRelations(sender, lelFees);
            if (nodes.length > 0) {
                takeToNodes(sender, nodeFee.div(nodes.length));
            }
            if (base.length > 0) {
                takeToBases(sender, baseFee.div(base.length));
            }

            _transferFee(sender, LpAddr, lpFee);
            _transferFee(sender, TecAddr, tecFee);

            _takeBurn(sender, burnFee);
            restoreAllFee();
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        if (tAmount > 0) {
            (
                uint256 rAmount,
                uint256 rTransferAmount,
                uint256 rFee,
                uint256 tTransferAmount,
                uint256 tFee,
                uint256 tTaxFee
            ) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
            return tTaxFee;
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTaxFee)
        = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        return tTaxFee;
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTaxFee)
        = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        return tTaxFee;
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTaxFee)
        = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        return tTaxFee;
    }

    function _transferFee(address sender, address recipient, uint256 tAmount) private {
        (, uint256 rTransferAmount,, uint256 tTransferAmount,,) = _getValues(tAmount);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        } else {
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTaxFees(address sender, uint256 taxFee) private {
        if (taxFee > 0) {
            removeAllFee();
            if (nodes.length > 0) {
                takeToNodes(sender, taxFee.mul(tFees.nodeFee).div(baseRate).div(nodes.length));
            }
            if (base.length > 0) {
                takeToBases(sender, taxFee.mul(tFees.baseFee).div(baseRate).div(base.length));
            }

            _transferFee(sender, LpAddr, taxFee.mul(tFees.liquidityFee).div(baseRate));
            restoreAllFee();
        }
    }

    function takeToNodes(address sender, uint256 amount) private {
        for (uint256 i = 0; i < nodes.length; i++) {
            _transferFee(sender, nodes[i], amount);
        }
    }

    function takeToBases(address sender, uint256 amount) private {
        for (uint256 i = 0; i < base.length; i++) {
            _transferFee(sender, base[i], amount);
        }
    }

    function takeToRelations(address sender, uint256[] memory lelFees) private {
        uint256 defFee = 0;
        address _recommer = tx.origin;
        for (uint8 i = 0; i < lelFees.length; i++) {
            _recommer = _recommerMapping[_recommer];
            uint256 lelFee = lelFees[i];
            if (_recommer != address(0)) {
                _transferFee(sender, _recommer, lelFee);
            } else {
                defFee = defFee.add(lelFee);
            }
        }
        if (defFee > 0) {
            _transferFee(sender, DefRelationAddr, defFee);
        }
    }

    /// setting

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function removeNode(address _node) external onlyOwner {
        require(_node != address(0), "zero address");
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i] == _node) {
                nodes[i] = nodes[nodes.length - 1];
                nodes.pop();
            }
        }
    }

    function removeBase(address _node) external onlyOwner {
        require(_node != address(0), "zero address");
        for (uint256 i = 0; i < base.length; i++) {
            if (base[i] == _node) {
                base[i] = base[base.length - 1];
                base.pop();
            }
        }
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = maxTxPercent * 10 ** _decimals;
    }

    function setNodes(address[] calldata _nodes) external onlyOwner {
        for (uint256 i = 0; i < _nodes.length; i++) {
            nodes.push(_nodes[i]);
        }
    }

    function setBase(address[] calldata _base) external onlyOwner {
        for (uint256 i = 0; i < _base.length; i++) {
            base.push(_base[i]);
        }
    }

    function setPair(address _pair, bool val) external onlyOwner {
        pairs[_pair] = val;
    }

    function setWhiteList(address account, bool v) external onlyOwner {
        _whiteList[account] = v;
    }

    function isWhiteList(address account) external view returns (bool) {
        return _whiteList[account];
    }

    function setTfees(TFeeTier memory _tFees) external onlyOwner {
        require(_checkTFees(_tFees, baseRate), "Tfees params error");
        tFees = _tFees;
    }

    function setTradeFees(InviteFeeTier memory _inviteFees, TFeeTier memory _tradeFees) external onlyOwner {
        require(checkTradeFees(_inviteFees, _tradeFees, baseRate), "Tfees params error");
        inviteFees = _inviteFees;
        tradeFees = _tradeFees;
    }

    function setTradeTaxFee(uint256 _val) external onlyOwner {
        _previousSellBuyFee = _val;
        tradeFees.taxFee = _val;
    }

    function setTTaxFee(uint256 _val) external onlyOwner {
        _previousTaxFee = _val;
        tFees.taxFee = _val;
    }

    function setMinRelationAmount(uint256 _val) external onlyOwner {
        minRelationAmount = _val;
    }

    function setLiquidityAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "zero address");
        LpAddr = _addr;
    }

    function setTecAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "zero address");
        TecAddr = _addr;
    }

    function setDefRelationAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "zero address");
        DefRelationAddr = _addr;
    }

    function setNotBind(address _addr, bool _val) external onlyOwner {
        notBind[_addr] = _val;
    }

    function fixRecommer(address _recommer, address _who) external onlyOwner {
        _recommerMapping[_recommer] = _who;
    }

    /// get

    function _getTradeFees(uint256 _amount)
        private
        view
        returns (
            uint256[] memory lelFees,
            uint256 holderFee,
            uint256 burnFee,
            uint256 lpFee,
            uint256 nodeFee,
            uint256 baseFee,
            uint256 tecFee
        )
    {
        if (tradeFees.taxFee == 0) {
            return (lelFees, holderFee, burnFee, lpFee, nodeFee, baseFee, tecFee);
        }
        uint256 allTxFee = _taxAllFee(_amount);
        uint256 bs = baseRate;
        //
        lelFees = new uint[](7);
        lelFees[0] = allTxFee.mul(inviteFees.inviteFee_1).div(bs);
        lelFees[1] = allTxFee.mul(inviteFees.inviteFee_2).div(bs);
        lelFees[2] = allTxFee.mul(inviteFees.inviteFee_3).div(bs);
        lelFees[3] = allTxFee.mul(inviteFees.inviteFee_4).div(bs);
        lelFees[4] = allTxFee.mul(inviteFees.inviteFee_5).div(bs);
        lelFees[5] = allTxFee.mul(inviteFees.inviteFee_6).div(bs);
        lelFees[6] = allTxFee.mul(inviteFees.inviteFee_7).div(bs);
        //
        holderFee = allTxFee.mul(tradeFees.holderFee).div(bs);
        //
        burnFee = allTxFee.mul(tradeFees.burnFee).div(bs);
        //
        lpFee = allTxFee.mul(tradeFees.liquidityFee).div(bs);
        //
        nodeFee = allTxFee.mul(tradeFees.nodeFee).div(bs);
        //
        baseFee = allTxFee.mul(tradeFees.baseFee).div(bs);
        //
        tecFee = allTxFee.mul(tradeFees.tecFee).div(bs);
    }

    function _checkTFees(TFeeTier memory _tFees, uint256 _baseRate) internal pure returns (bool) {
        uint256 all =
            _tFees.holderFee + _tFees.liquidityFee + _tFees.burnFee + _tFees.nodeFee + _tFees.baseFee + _tFees.tecFee;
        return all == _baseRate;
    }

    function checkTradeFees(InviteFeeTier memory _inviteFees, TFeeTier memory _tradeFees, uint256 _baseRate)
        internal
        pure
        returns (bool)
    {
        uint256 all = _inviteFees.inviteFee_1 + _inviteFees.inviteFee_2 + _inviteFees.inviteFee_3
            + _inviteFees.inviteFee_4 + _inviteFees.inviteFee_5 + _inviteFees.inviteFee_6 + _inviteFees.inviteFee_7;
        all += _tradeFees.holderFee + _tradeFees.liquidityFee + _tradeFees.burnFee + _tradeFees.nodeFee
            + _tradeFees.baseFee + _tradeFees.tecFee;
        return all == _baseRate;
    }

    function _isCanBind(address _to) internal view returns(bool) {
         address _recommer = tx.origin;
        for (uint8 i = 0; i < 7; i++) {
            _recommer = _recommerMapping[_recommer];
            if (_recommer == address(0)) {
                return true;
            } 
            if (_recommer == _to) {
                return false;
            }
        }
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}