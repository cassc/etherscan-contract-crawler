/**
        BUY, HOLD, EARN, BURN!
        Telegram: https://t.me/buyholdearn
        Website: http://buyholdearn.com
        X: https://twitter.com/buyholdearn
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev This contract is derived from the ERC20.sol by openzeppelin and the
 reflection token contract by CoinTools. The contract removes liquidity and
 burn fee and only redistributes tokens to holders. This contract has improvements
 in terms of gas efficiency, security, and readibility.
 */
contract ERC20Reflections is Context, IERC20, IERC20Metadata, Ownable {
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotalSupply; // total supply in r-space
    uint256 private immutable _tTotalSupply; // total supply in t-space
    string private _name;
    string private _symbol;
    address[] private _excludedFromReward;

    uint256 public txFee = 200; // 200 => 2%
    uint256 public accumulatedFees;

    mapping(address => uint256) private _rBalances; // balances in r-space
    mapping(address => uint256) private _tBalances; // balances in t-space
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromReward;

    event SetFee(uint256 value);

    constructor(string memory name_, string memory symbol_, address owner_) {
        _name = name_;
        _symbol = symbol_;
        _tTotalSupply = 1_000_000_000 * 10 ** decimals();
        excludeFromFee(owner_);
        excludeFromFee(address(this));
        _mint(owner_, _tTotalSupply); // for deployer use msg.sender
        _transferOwnership(owner_);
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
        return _tTotalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        uint256 rate = _conversionRate();
        return _rBalances[account] / rate;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(
        address account,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            allowance(msg.sender, spender) + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setTransactionFee(uint256 newTxFee) public onlyOwner {
        txFee = newTxFee;
        emit SetFee(txFee);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!isExcludedFromReward[account], "Address already excluded");
        require(_excludedFromReward.length < 100, "Excluded list is too long");

        if (_rBalances[account] > 0) {
            uint256 rate = _conversionRate();
            _tBalances[account] = _rBalances[account] / rate;
        }
        isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(isExcludedFromReward[account], "Account is already included");
        uint256 nExcluded = _excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[
                    _excludedFromReward.length - 1
                ];
                _tBalances[account] = 0;
                isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    // withdraw tokens from contract (only owner)
    function withdrawTokens(
        address tokenAddress,
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        return tokenContract.transfer(receiverAddress, amount);
    }

    function _conversionRate() private view returns (uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;

        uint256 nExcluded = _excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded; i++) {
            rSupply = rSupply - _rBalances[_excludedFromReward[i]];
            tSupply = tSupply - _tBalances[_excludedFromReward[i]];
        }
        if (rSupply < _rTotalSupply / _tTotalSupply) {
            rSupply = _rTotalSupply;
            tSupply = _tTotalSupply;
        }
        // rSupply always > tSupply (no precision loss)
        uint256 rate = rSupply / tSupply;
        return rate;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _beforeTokenTransfer(from, to, amount);

        uint256 _txFee;
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _txFee = 0;
        } else {
            _txFee = txFee;
        }

        // calc t-values
        uint256 tAmount = amount;
        uint256 tTxFee = (tAmount * _txFee) / 10000;
        uint256 tTransferAmount = tAmount - tTxFee;

        // calc r-values
        uint256 rate = _conversionRate();
        uint256 rTxFee = tTxFee * rate;
        uint256 rAmount = tAmount * rate;
        uint256 rTransferAmount = rAmount - rTxFee;

        // check balances
        uint256 rFromBalance = _rBalances[from];
        uint256 tFromBalance = _tBalances[from];

        if (isExcludedFromReward[from]) {
            require(
                tFromBalance >= tAmount,
                "ERC20: transfer amount exceeds balance"
            );
        } else {
            require(
                rFromBalance >= rAmount,
                "ERC20: transfer amount exceeds balance"
            );
        }

        // Overflow not possible: the sum of all balances is capped by
        // rTotalSupply and tTotalSupply, and the sum is preserved by
        // decrementing then incrementing.
        unchecked {
            // udpate balances in r-space
            _rBalances[from] = rFromBalance - rAmount;
            _rBalances[to] += rTransferAmount;

            // update balances in t-space
            if (isExcludedFromReward[from] && isExcludedFromReward[to]) {
                _tBalances[from] = tFromBalance - tAmount;
                _tBalances[to] += tTransferAmount;
            } else if (
                isExcludedFromReward[from] && !isExcludedFromReward[to]
            ) {
                _tBalances[from] = tFromBalance - tAmount;
            } else if (
                !isExcludedFromReward[from] && isExcludedFromReward[to]
            ) {
                _tBalances[to] += tTransferAmount;
            }

            // reflect fee
            // can never go below zero because rTxFee percentage of
            // _rTotalSupply
            _rTotalSupply = _rTotalSupply - rTxFee;
            accumulatedFees += tTxFee;
        }

        emit Transfer(from, to, tTransferAmount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _rTotalSupply += (MAX - (MAX % amount));
        unchecked {
            _rBalances[account] += _rTotalSupply;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _approve(
        address account,
        address spender,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function _spendAllowance(
        address account,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(account, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(account, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}