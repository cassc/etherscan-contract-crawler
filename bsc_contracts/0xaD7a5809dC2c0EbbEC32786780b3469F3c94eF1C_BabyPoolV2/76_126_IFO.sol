// SPDX-License-Identifier: MIT

pragma solidity =0.7.4;
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IBEP20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has ids similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract IFO is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    struct IFOInfo {
        uint256 id;
        IBEP20 exhibits;
        IBEP20 currency;
        address recipient;
        uint256 price;
        uint256 totalSupply;
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
        uint256 hardcap;
        uint256 incomeTotal;
        mapping(address => uint256) payAmount;
        mapping(address => bool) isCollected;
    }
    uint256 public constant MAX = uint256(-1);
    uint256 public constant ROUND = 10**18;
    uint256 public idIncrement = 0;
    mapping(uint256 => IFOInfo) public ifoInfos;
    mapping(uint256 => bool) private isWithdraw;
    event IFOLaunch(
        uint256 id,
        address exhibits,
        address currency,
        address recipient,
        uint256 price,
        uint256 hardcap,
        uint256 totalSupply,
        uint256 totalAmount,
        uint256 startTime,
        uint256 duration
    );
    event Staked(uint256 id, address account, uint256 value);
    event Collected(
        uint256 id,
        address account,
        uint256 ifoValue,
        uint256 fee,
        uint256 backValue
    );
    event IFOWithdraw(uint256 id, uint256 receiveValue, uint256 leftValue);

    event IFORemove(uint256 id);

    function launch(
        IBEP20 exhibits,
        IBEP20 currency,
        address recipient,
        uint256 totalAmount,
        uint256 totalSupply,
        uint256 hardcap,
        uint256 startTime,
        uint256 duration
    ) external onlyOwner {
        require(
            address(recipient) != address(0),
            "IFO: recipient address cannot be 0"
        );
        require(
            startTime > block.timestamp,
            "IFO: startTime should be later than now"
        );
        require(
            block.timestamp >
                ifoInfos[idIncrement].startTime.add(
                    ifoInfos[idIncrement].duration
                ),
            "IFO: ifo is not over yet."
        );
        require(
            address(exhibits) != address(0),
            "IFO: exhibits address cannot be 0"
        );
        require(
            address(currency) != address(0),
            "IFO: currency address cannot be 0"
        );
  

        idIncrement = idIncrement.add(1);
        IFOInfo storage ifo = ifoInfos[idIncrement];
        ifo.id = idIncrement;
        ifo.exhibits = exhibits;
        ifo.currency = currency;
        ifo.recipient = recipient;
        ifo.totalAmount = totalAmount;
        ifo.price = totalAmount.mul(ROUND).div(totalSupply);
        ifo.hardcap = hardcap;
        ifo.totalSupply = totalSupply;
        ifo.startTime = startTime;
        ifo.duration = duration;

        exhibits.safeTransferFrom(msg.sender, address(this), totalSupply);
        emit IFOLaunch(
            idIncrement,
            address(exhibits),
            address(currency),
            recipient,
            ifo.price,
            hardcap,
            totalSupply,
            totalAmount,
            startTime,
            duration
        );
    }

    function removeIFO() external onlyOwner {
        require(
            ifoInfos[idIncrement].startTime > block.timestamp,
            "IFO: there is no ifo that can be deleted"
        );
        ifoInfos[idIncrement].exhibits.safeTransfer(
            msg.sender,
            ifoInfos[idIncrement].totalSupply
        );
        delete ifoInfos[idIncrement];
        emit IFORemove(idIncrement);
        idIncrement = idIncrement.sub(1);
    }

    function withdraw(uint256 id) external onlyOwner {
        IFOInfo storage record = ifoInfos[id];
        require(id <= idIncrement && id > 0, "IFO: ifo that does not exist.");
        require(!isWithdraw[id], "IFO: cannot claim repeatedly.");
        require(
            block.timestamp > record.startTime.add(record.duration),
            "IFO: ifo is not over yet."
        );

        uint256 receiveValue;
        uint256 backValue;

        isWithdraw[id] = true;

        uint256 prop = record.incomeTotal.mul(ROUND).mul(ROUND).div(
            record.totalSupply.mul(record.price)
        );
        if (prop >= ROUND) {
            receiveValue = record.totalSupply.mul(record.price).div(ROUND);
            record.currency.safeTransfer(record.recipient, receiveValue);
        } else {
            receiveValue = record.incomeTotal;
            record.currency.safeTransfer(record.recipient, receiveValue);
            backValue = record.totalSupply.sub(
                record.totalSupply.mul(prop).div(ROUND)
            );
            record.exhibits.safeTransfer(record.recipient, backValue);
        }

        emit IFOWithdraw(id, receiveValue, backValue);
    }

    function stake(uint256 value) external {
        require(idIncrement > 0, "IFO: ifo that does not exist.");
        IFOInfo storage record = ifoInfos[idIncrement];
        require(
            block.timestamp > record.startTime &&
                block.timestamp < record.startTime.add(record.duration),
            "IFO: ifo is not in progress."
        );
        require(
            record.payAmount[msg.sender].add(value) <= record.hardcap,
            "IFO: limit exceeded"
        );

        record.payAmount[msg.sender] = record.payAmount[msg.sender].add(value);
        record.incomeTotal = record.incomeTotal.add(value);
        record.currency.safeTransferFrom(msg.sender, address(this), value);
        emit Staked(idIncrement, msg.sender, value);
    }

    function available(address account, uint256 id)
        public
        view
        returns (uint256 _ifoAmount, uint256 _sendBack)
    {
        IFOInfo storage record = ifoInfos[id];
        require(id <= idIncrement && id > 0, "IFO: ifo that does not exist.");

        uint256 prop = record.incomeTotal.mul(ROUND).mul(ROUND).div(
            record.totalSupply.mul(record.price)
        );

        if (prop > ROUND) {
            _ifoAmount = record
                .payAmount[account]
                .mul(ROUND)
                .mul(ROUND)
                .div(prop)
                .div(record.price);
            _sendBack = record
                .payAmount[account]
                .mul(ROUND.sub(ROUND.mul(ROUND).add(prop).sub(1).div(prop)))
                .div(ROUND);
        } else {
            _ifoAmount = record.payAmount[account].mul(ROUND).div(record.price);
        }
    }

    function userPayValue(uint256 id, address account)
        public
        view
        returns (uint256)
    {
        return ifoInfos[id].payAmount[account];
    }

    function isCollected(uint256 id, address account)
        public
        view
        returns (bool)
    {
        return ifoInfos[id].isCollected[account];
    }

    function collect(uint256 id) external {
        require(id <= idIncrement && id > 0, "IFO: ifo that does not exist.");
        IFOInfo storage record = ifoInfos[id];
        require(
            block.timestamp > ifoInfos[id].startTime.add(record.duration),
            "IFO: ifo is not over yet."
        );
        require(
            !record.isCollected[msg.sender],
            "IFO: cannot claim repeatedly."
        );

        uint256 ifoAmount;
        uint256 sendBack;

        record.isCollected[msg.sender] = true;

        (ifoAmount, sendBack) = available(msg.sender, id);

        record.exhibits.safeTransfer(msg.sender, ifoAmount);
        uint256 fee;
        if (sendBack > 0) {
            uint256 rateFee = getFeeRate(id);
            fee = sendBack.mul(rateFee).div(ROUND);
            if (fee > 0) {
                record.currency.safeTransfer(owner(), fee);
                sendBack = sendBack.sub(fee);
            }
            record.currency.safeTransfer(msg.sender, sendBack);
        }

        emit Collected(id, msg.sender, ifoAmount, fee, sendBack);
    }

    function getFeeRate(uint256 id) public view returns (uint256) {
        if (ifoInfos[id].hardcap != MAX) {
            return 0;
        }
        uint256 x = ifoInfos[id].incomeTotal.div(ifoInfos[id].totalAmount);
        if (x >= 500) {
            return ROUND.mul(20).div(10000);
        } else if (x >= 250) {
            return ROUND.mul(25).div(10000);
        } else if (x >= 100) {
            return ROUND.mul(30).div(10000);
        } else if (x >= 50) {
            return ROUND.mul(50).div(10000);
        } else {
            return ROUND.mul(100).div(10000);
        }
    }
}