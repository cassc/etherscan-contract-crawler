// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/ERC20.sol";

contract Token is ERC20, Ownable {
    using SafeMath for uint256;

    address public pool;
    address public liquidity;
    address public pair;
    address public feeTo;

    uint256 _startTime;

    mapping(address => bool) public notFromFee;
    mapping(address => bool) public notToFee;

    event TradeFee(
        address indexed user,
        uint256 amount,
        uint256 feeAmount,
        bool isBuy
    );

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_, 18)
    {
        uint256 initSupply = 21000000 * 10**uint256(decimals());
        _mint(address(this), initSupply);
    }

    function init(address _feeTo, address _pair) public onlyOwner {
        feeTo = _feeTo;
        pair = _pair;
    }

    function setNotFee(
        address account,
        bool from,
        bool to
    ) public onlyOwner {
        notFromFee[account] = from;
        notToFee[account] = to;
    }

    function setLiquidity(address _liquidity) public onlyOwner {
        require(liquidity == address(0), "already exists");
        liquidity = _liquidity;
        setNotFee(liquidity, true, true);
        super._transfer(
            address(this),
            liquidity,
            10000 * 10**uint256(decimals())
        );
    }

    function setPool(address _pool) public onlyOwner {
        require(pool == address(0), "already exists");
        pool = _pool;
        super._transfer(
            address(this),
            pool,
            20990000 * 10**uint256(decimals())
        );
    }

    function setStartTime(uint256 startTime) public onlyOwner {
        _startTime = startTime;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (notFromFee[sender] || notToFee[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }
        if (pair == sender || pair == recipient) {
            require(_startTime > 0 && block.timestamp > _startTime, "can not trade before start time");
            _feeTransfer(sender, recipient, amount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    // transfer fee
    function _feeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            amount <= 150000 * 10**uint256(decimals()),
            "can't transfer more than 150000 piece per transaction"
        );
        uint256 recipientAmount = _recipientAmountSubFee(
            sender,
            recipient,
            amount
        );
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(recipientAmount);
        emit Transfer(sender, recipient, recipientAmount);
    }

    function _recipientAmountSubFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        address user = sender;
        bool isBuy = false;
        uint256 feeAmount = amount.div(100);
        _balances[feeTo] = _balances[feeTo].add(feeAmount);
        emit Transfer(sender, feeTo, feeAmount);
        if (pair == sender) {
            isBuy = true;
            user = recipient;
        }
        emit TradeFee(user, amount, feeAmount, isBuy);
        return amount.sub(feeAmount);
    }
}