// SPDX-License-Identifier: MIT
// Creator: Debox Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ClubPayment is Ownable {

    using SafeMath for uint256;

    uint256 public constant MAX_AMOUNT_PER_MONTH = 10**19;  // 10 ethers
    uint256 public constant MIN_AMOUNT_PER_MONTH = 10**16;  // 0.01 ethers
    uint256 public constant SECONDS_OF_MONTH = 3600*24*30;  // 30 days

    enum RS { NORMAL, MEMBER_REFUND, OWNER_REFUND, EXPIRE }

    struct Club {
        uint256     id;
        address     owner;
        address     nftCA;
        uint256     tokenId;
        uint8       payMonths;
        uint256     amountPerMonth;
        uint256     createTime;
        uint256     balance;                // accumulative total, joined - refund
        uint256     surplus;                // refund surplus, pay_amount - refund_amount
        uint256     withdrawAmount;         // have withdrawn
        uint256     withdrawTime;
    }
    struct PayRecord {
        address     payAddr;
        uint256     payAmount;
        uint256     payTime;
        uint256     expireTime;
        uint256     refundAmount;
        RS          state;
    }

    address payable public _dAddr;
    uint256 public _incNO = 1;
    mapping(address => bool) public _stakedActive;
    mapping(address => mapping(uint256 => Club)) private _staking;
    mapping(uint256 => PayRecord[]) private _clubPayRecords;
    mapping(uint256 => mapping(address => uint256)) private _clubMemberPayIndex;

    event CreateClub(address indexed sender, address nft_ca, uint256 token_id, uint8 months, uint256 amount);
    event ModifyAmountPerMonth(address indexed sender, uint256 cid, uint256 amount);
    event JoinClub(address indexed sender, uint256 cid, uint8 pay_month, uint256 pay_amount);
    event ReleaseClub(address indexed sender, uint256 cid);
    event Refund(address indexed sender, uint256 cid, address indexed refund_addr, RS rs, uint256 amount);
    event Withdraw(address indexed sender, uint256 cid, uint256 withdraw_amount);
    event WithdrawExpire(address indexed sender, uint256 cid, uint256 withdraw_amount);
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() {
        _dAddr = payable(msg.sender);
    }

    function setAllowedContract(address nft_ca, bool state) external onlyOwner {
        _stakedActive[nft_ca] = state;
    }

    function modifyDAddr(address new_addr) external onlyOwner {
        require(new_addr != address(0), "invalid address");
        _dAddr = payable(new_addr);
    }

    function isExpire(uint256 pay_time, uint8 pay_months) internal view returns (bool) {
        return pay_time.add(SECONDS_OF_MONTH.mul(pay_months)) < block.timestamp;
    }

    // just for not expire case
    function calculateRemainMonths(uint256 pay_time, uint8 pay_months, RS rs) internal view returns (uint256) {
        uint256 months = block.timestamp.sub(pay_time).div(SECONDS_OF_MONTH);
        uint256 remain_months = pay_months - months;
        if (rs == RS.MEMBER_REFUND) {
            if (remain_months > 2) {
                remain_months = remain_months.sub(2);
            }
            else {
                remain_months = 0;
            }
        }
        return remain_months;
    }

    function getStakeInfo(address nft_ca, uint256 token_id) internal view returns (Club memory) {
        require(_staking[nft_ca][token_id].id > 0, "current nft is not staking");
        return _staking[nft_ca][token_id];
    }

    function getClubInfo(address nft_ca, uint256 token_id) external view returns (Club memory club) {
        return getStakeInfo(nft_ca, token_id);
    }

    function createClub(address nft_ca, uint256 token_id, uint8 months, uint256 amount) external callerIsUser {
        require(_stakedActive[nft_ca], "invalid contract address for staking");
        require(months == uint8(6) || months == uint8(12), "pay month just require 6 or 12");
        require(amount >= MIN_AMOUNT_PER_MONTH && amount <= MAX_AMOUNT_PER_MONTH, "amount_per_month out of range");
        require(msg.sender == IERC721(nft_ca).ownerOf(token_id), "invalid owner address for staking");
        // staking
        IERC721(nft_ca).transferFrom(msg.sender, address(this), token_id);
        Club memory club = Club(_incNO++, msg.sender, nft_ca, token_id, months, amount, block.timestamp, 0, 0, 0, block.timestamp);
        _staking[nft_ca][token_id] = club;
        _clubPayRecords[club.id].push(PayRecord(msg.sender, 0, 0, 0, 0, RS.OWNER_REFUND));
        emit CreateClub(msg.sender, nft_ca, token_id, months, amount);
    }

    function modifyAmountPerMonth(address nft_ca, uint256 token_id, uint256 amount) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        require(amount >= MIN_AMOUNT_PER_MONTH && amount <= MAX_AMOUNT_PER_MONTH, "amount_per_month out of range");
        require(amount > club.amountPerMonth, "amount_per_month less than original amount_per_month");
        club.amountPerMonth = amount;
        emit ModifyAmountPerMonth(msg.sender, club.id, amount);
    }

    function joinClub(address nft_ca, uint256 token_id) external payable callerIsUser {
        Club memory club = getStakeInfo(nft_ca, token_id);
        require(msg.sender != club.owner, "owner have joined current club");
        uint256 pay_amount = club.amountPerMonth.mul(club.payMonths);
        require(msg.value >= pay_amount, "send eth amount is less pay amount");
        uint256 member_idx = _clubMemberPayIndex[club.id][msg.sender];
        if (member_idx > 0) {
            PayRecord storage record = _clubPayRecords[club.id][member_idx];
            require(record.expireTime < block.timestamp, "have joined current club");
            if (record.state == RS.NORMAL) {
                _staking[nft_ca][token_id].surplus.add(record.payAmount);
                record.state = RS.EXPIRE;
            }
        }
        uint256 expire_time = block.timestamp.add(SECONDS_OF_MONTH.mul(club.payMonths));
        _clubPayRecords[club.id].push(PayRecord(msg.sender, pay_amount, block.timestamp, expire_time, 0, RS.NORMAL));
        _clubMemberPayIndex[club.id][msg.sender] = _clubPayRecords[club.id].length.sub(1);
        _staking[nft_ca][token_id].balance = _staking[nft_ca][token_id].balance.add(pay_amount);
        if (msg.value > pay_amount) {
            payable(msg.sender).transfer(msg.value.sub(pay_amount));
        }
        emit JoinClub(msg.sender, club.id, club.payMonths, pay_amount);
    }

    function releaseClub(address nft_ca, uint256 token_id) external callerIsUser {
        Club memory club = getStakeInfo(nft_ca, token_id);
        require(club.owner == msg.sender, "invalid owner address for current club");
        require(club.balance == club.withdrawAmount, "please to withdraw/refund before release");
        IERC721(nft_ca).transferFrom(address(this), msg.sender, token_id);
        delete _staking[nft_ca][token_id];
        delete _clubPayRecords[club.id];
        emit ReleaseClub(msg.sender, club.id);
    }

    function getBalance(address eoa, address nft_ca, uint256 token_id, RS st) internal view returns (uint256) {
        Club memory club = getStakeInfo(nft_ca, token_id);
        uint256 member_idx = _clubMemberPayIndex[club.id][eoa];
        if (member_idx > 0) {
            PayRecord memory record = _clubPayRecords[club.id][member_idx];
            if (record.state == RS.NORMAL && record.expireTime > block.timestamp) {
                uint256 remain_months = calculateRemainMonths(record.payTime, club.payMonths, st);
                return record.payAmount.mul(remain_months).div(club.payMonths);
            }
        }
        return 0;
    }

    function getBalanceByMember(address nft_ca, uint256 token_id) external view returns (uint256) {
        return getBalance(msg.sender, nft_ca, token_id, RS.MEMBER_REFUND);
    }

    function getBalanceByOwner(address eoa, address nft_ca, uint256 token_id) external view returns (uint256) {
        return getBalance(eoa, nft_ca, token_id, RS.OWNER_REFUND);
    }

    function refund(address eoa, address nft_ca, uint256 token_id, RS st) internal {
        Club storage club = _staking[nft_ca][token_id];
        uint256 member_idx = _clubMemberPayIndex[club.id][eoa];
        require(member_idx > 0, "invalid member address for current club");
        PayRecord storage record = _clubPayRecords[club.id][member_idx];
        if (record.state == RS.NORMAL && record.expireTime > block.timestamp) {
            uint256 remain_months = calculateRemainMonths(record.payTime, club.payMonths, st);
            uint256 amount = record.payAmount.mul(remain_months).div(club.payMonths);
            uint256 surplus = record.payAmount.sub(amount);
            club.balance = club.balance.sub(amount);
            club.surplus = club.surplus.add(surplus);
            record.state = st;
            record.refundAmount = amount;
            payable(eoa).transfer(amount);
            emit Refund(msg.sender, club.id, eoa, st, amount);
        }
    }

    function refundByMember(address nft_ca, uint256 token_id) external callerIsUser {
        return refund(msg.sender, nft_ca, token_id, RS.MEMBER_REFUND);
    }

    function refundByOwner(address eoa, address nft_ca, uint256 token_id) external callerIsUser {
        require(_staking[nft_ca][token_id].owner == msg.sender, "invalid owner address for current club");
        return refund(eoa, nft_ca, token_id, RS.OWNER_REFUND);
    }
    
    function batchRefund(address nft_ca, uint256 token_id, address[] calldata addrs) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        for (uint idx = 0; idx < addrs.length; ++idx) {
            uint256 member_idx = _clubMemberPayIndex[club.id][addrs[idx]];
            if (member_idx <= 0) {
                continue;
            }
            PayRecord storage record = _clubPayRecords[club.id][member_idx];
            if (record.state == RS.NORMAL && record.expireTime > block.timestamp) {
                uint256 remain_months = calculateRemainMonths(record.payTime, club.payMonths, RS.OWNER_REFUND);
                uint256 amount = record.payAmount.mul(remain_months).div(club.payMonths);
                uint256 surplus = record.payAmount.sub(amount);
                club.balance = club.balance.sub(amount);
                club.surplus = club.surplus.add(surplus);
                record.state = RS.OWNER_REFUND;
                record.refundAmount = amount;
                payable(record.payAddr).transfer(amount);
                emit Refund(msg.sender, club.id, record.payAddr, RS.OWNER_REFUND, amount);
            }
        }
    }

    function getWithdrawBalance(address nft_ca, uint256 token_id) public view returns (uint256) {
        Club memory club = getStakeInfo(nft_ca, token_id);
        uint256 amount = 0;
        PayRecord[] memory records = _clubPayRecords[club.id];
        for (uint idx = 1; idx < records.length; ++idx) {
            if (records[idx].state != RS.NORMAL) {
                continue;
            }
            if (records[idx].expireTime > block.timestamp) {
                uint256 stay_months = block.timestamp.sub(records[idx].payTime).div(SECONDS_OF_MONTH);
                amount = amount.add(records[idx].payAmount.mul(stay_months).div(club.payMonths));
            }
            else {
                amount = amount.add(records[idx].payAmount);
            }
        }
        return amount.add(club.surplus);
    }

    function withdraw(address nft_ca, uint256 token_id) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        uint256 receivable_amount = getWithdrawBalance(nft_ca, token_id);
        require(receivable_amount > club.withdrawAmount, "have no balance to withdraw");
        uint256 balance = receivable_amount.sub(club.withdrawAmount);
        club.withdrawAmount = receivable_amount;
        club.withdrawTime = block.timestamp;
        trans(balance);
        emit Withdraw(msg.sender, club.id, balance);
    }

    function withdrawExpire(address nft_ca, uint256 token_id, address[] calldata addrs) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        uint256 balance = 0;
        for (uint idx = 0; idx < addrs.length; ++idx) {
            uint256 member_idx = _clubMemberPayIndex[club.id][addrs[idx]];
            if (member_idx <= 0) {
                continue;
            }
            PayRecord storage record = _clubPayRecords[club.id][member_idx];
            if (record.state == RS.NORMAL && record.expireTime < block.timestamp) {
                record.state = RS.EXPIRE;
                if (club.withdrawTime > record.expireTime) {
                    continue;
                }
                uint256 remain_months = 0;
                if (club.withdrawTime < record.payTime) {
                    remain_months = club.payMonths;
                }
                else {
                    remain_months = club.payMonths - club.withdrawTime.sub(record.payTime).div(SECONDS_OF_MONTH);
                }
                uint256 remain_amount = record.payAmount.mul(remain_months).div(club.payMonths);
                balance = balance.add(remain_amount);
            }
        }
        club.surplus = club.surplus.add(balance);
        club.withdrawAmount = club.withdrawAmount.add(balance);
        trans(balance);
        emit WithdrawExpire(msg.sender, club.id, balance);
    }

    function trans(uint256 balance) internal {
        uint256 fees = balance.div(20);
        _dAddr.transfer(fees);
        payable(msg.sender).transfer(balance.sub(fees));
    }
}