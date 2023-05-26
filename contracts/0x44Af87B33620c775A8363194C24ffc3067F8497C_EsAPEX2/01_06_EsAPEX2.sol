// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IEsAPEX2.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/FullMath.sol";

contract EsAPEX2 is IEsAPEX2, Ownable {
    using FullMath for uint256;

    string public constant override name = "esApeX";
    string public constant override symbol = "esAPEX";
    uint8 public constant override decimals = 18;

    address public immutable override apeXToken;
    address public override treasury;

    uint256 public override forceWithdrawMinRemainRatio; // max:10000, default:1666
    uint256 public override vestTime;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => bool) public isMinter;
    mapping(address => VestInfo[]) public userVestInfos;

    constructor(
        address owner_,
        address apeXToken_,
        address treasury_,
        uint256 vestTime_,
        uint256 forceWithdrawMinRemainRatio_
    ) {
        owner = owner_;
        apeXToken = apeXToken_;
        treasury = treasury_;
        vestTime = vestTime_;
        forceWithdrawMinRemainRatio = forceWithdrawMinRemainRatio_;
        isMinter[owner] = true;
    }

    function addMinter(address minter) external onlyOwner {
        require(!isMinter[minter], "minter already exist");
        isMinter[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        require(isMinter[minter], "minter not found");
        isMinter[minter] = false;
    }

    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "zero address");
        treasury = newTreasury;
    }

    function updateVestTime(uint256 newVestTime) external onlyOwner {
        emit VestTimeChanged(vestTime, newVestTime);
        vestTime = newVestTime;
    }

    function updateForceWithdrawMinRemainRatio(uint256 newRatio) external onlyOwner {
        require(newRatio <= 10000, "newRatio > 10000");
        emit ForceWithdrawMinRemainRatioChanged(forceWithdrawMinRemainRatio, newRatio);
        forceWithdrawMinRemainRatio = newRatio;
    }

    function mint(address to, uint256 amount) external override returns (bool) {
        require(isMinter[msg.sender], "not minter");
        require(amount > 0, "zero amount");
        TransferHelper.safeTransferFrom(apeXToken, msg.sender, address(this), amount);
        _mint(to, amount);
        return true;
    }

    function vest(uint256 amount) external override {
        require(amount > 0, "zero amount");
        uint256 fromBalance = balanceOf[msg.sender];
        require(fromBalance >= amount, "not enough balance to be vest");
        _transfer(msg.sender, address(this), amount);

        VestInfo memory info = VestInfo({
            startTime: block.timestamp,
            endTime: block.timestamp + vestTime,
            vestAmount: amount,
            claimedAmount: 0,
            forceWithdrawn: false
        });

        uint256 vestId = userVestInfos[msg.sender].length;
        userVestInfos[msg.sender].push(info);

        emit Vest(msg.sender, amount, info.endTime, vestId);
    }

    function withdraw(address to, uint256 vestId, uint256 amount) external override {
        _withdraw(to, vestId, amount);
    }

    function batchWithdraw(address to, uint256[] memory vestIds, uint256[] memory amounts) external override {
        require(vestIds.length == amounts.length, "two arrays' length not the same");
        for (uint256 i = 0; i < vestIds.length; i++) {
            _withdraw(to, vestIds[i], amounts[i]);
        }
    }

    function forceWithdraw(
        address to,
        uint256 vestId
    ) external override returns (uint256 withdrawAmount, uint256 penalty) {
        return _forceWithdraw(to, vestId);
    }

    function batchForceWithdraw(
        address to,
        uint256[] memory vestIds
    ) external override returns (uint256 withdrawAmount, uint256 penalty) {
        for (uint256 i = 0; i < vestIds.length; i++) {
            (uint256 withdrawAmount_, uint256 penalty_) = _forceWithdraw(to, vestIds[i]);
            withdrawAmount += withdrawAmount_;
            penalty += penalty_;
        }
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function getVestInfo(address user, uint256 vestId) external view override returns (VestInfo memory) {
        return userVestInfos[user][vestId];
    }

    function getVestInfosByPage(
        address user,
        uint256 offset,
        uint256 size
    ) external view override returns (VestInfo[] memory vestInfos) {
        uint256 len = userVestInfos[user].length;
        if (offset > len) {
            return vestInfos;
        }
        if (size >= len - offset) {
            size = len - offset;
        }
        vestInfos = new VestInfo[](size);
        for (uint256 i = 0; i < len; i++) {
            vestInfos[i] = userVestInfos[user][offset + i];
        }
    }

    function getVestInfosLength(address user) external view override returns (uint256 length) {
        return userVestInfos[user].length;
    }

    function getClaimable(address user, uint256 vestId) external view override returns (uint256 claimable) {
        return _getClaimable(user, vestId);
    }

    function getTotalClaimable(
        address user,
        uint256[] memory vestIds
    ) external view override returns (uint256 claimable) {
        for (uint256 i = 0; i < vestIds.length; i++) {
            claimable += _getClaimable(user, vestIds[i]);
        }
    }

    function getLocking(address user, uint256 vestId) external view override returns (uint256 locking) {
        return _getLocking(user, vestId);
    }

    function getTotalLocking(address user, uint256[] memory vestIds) external view override returns (uint256 locking) {
        for (uint256 i = 0; i < vestIds.length; i++) {
            locking += _getLocking(user, vestIds[i]);
        }
    }

    function getForceWithdrawable(
        address user,
        uint256 vestId
    ) external view override returns (uint256 withdrawable, uint256 penalty) {
        return _getForceWithdrawable(user, vestId);
    }

    function getTotalForceWithdrawable(
        address user,
        uint256[] memory vestIds
    ) external view override returns (uint256 withdrawable, uint256 penalty) {
        for (uint256 i = 0; i < vestIds.length; i++) {
            (uint256 withdrawable_, uint256 penalty_) = _getForceWithdrawable(user, vestIds[i]);
            withdrawable += withdrawable_;
            penalty += penalty_;
        }
    }

    function _getClaimable(address user, uint256 vestId) internal view returns (uint256 claimable) {
        VestInfo memory info = userVestInfos[user][vestId];
        if (!info.forceWithdrawn) {
            uint256 pastTime = block.timestamp - info.startTime;
            uint256 wholeTime = info.endTime - info.startTime;
            if (pastTime >= wholeTime) {
                claimable = info.vestAmount;
            } else {
                claimable = info.vestAmount.mulDiv(pastTime, wholeTime);
            }
            claimable = claimable - info.claimedAmount;
        }
    }

    function _getLocking(address user, uint256 vestId) internal view returns (uint256 locking) {
        VestInfo memory info = userVestInfos[user][vestId];
        if (!info.forceWithdrawn) {
            if (block.timestamp >= info.endTime) {
                locking = 0;
            } else {
                uint256 leftTime = info.endTime - block.timestamp;
                uint256 wholeTime = info.endTime - info.startTime;
                locking = info.vestAmount.mulDiv(leftTime, wholeTime);
            }
        }
    }

    function _getForceWithdrawable(
        address user,
        uint256 vestId
    ) internal view returns (uint256 withdrawable, uint256 penalty) {
        VestInfo memory info = userVestInfos[user][vestId];
        uint256 locking = _getLocking(user, vestId);
        uint256 left = (locking *
            (forceWithdrawMinRemainRatio +
                ((10000 - forceWithdrawMinRemainRatio) * (block.timestamp - info.startTime)) /
                vestTime)) / 10000;
        if (left > locking) left = locking;
        uint256 claimable = _getClaimable(user, vestId);
        withdrawable = claimable + left;
        penalty = locking - left;
    }

    function _withdraw(address to, uint256 vestId, uint256 amount) internal {
        require(to != address(0), "can not withdraw to zero address");
        require(amount > 0, "zero amount");
        VestInfo storage info = userVestInfos[msg.sender][vestId];
        require(!info.forceWithdrawn, "already force withdrawn");

        uint256 claimable = _getClaimable(msg.sender, vestId);
        require(amount <= claimable, "amount > claimable");

        info.claimedAmount += amount;
        TransferHelper.safeTransfer(apeXToken, to, amount);
        _burn(address(this), amount);
        emit Withdraw(msg.sender, to, amount, vestId);
    }

    function _forceWithdraw(address to, uint256 vestId) internal returns (uint256 withdrawAmount, uint256 penalty) {
        require(to != address(0), "can not withdraw to zero address");
        VestInfo storage info = userVestInfos[msg.sender][vestId];
        require(!info.forceWithdrawn, "already force withdrawn");

        (withdrawAmount, penalty) = _getForceWithdrawable(msg.sender, vestId);
        require(withdrawAmount > 0, "withdrawAmount is zero");
        TransferHelper.safeTransfer(apeXToken, to, withdrawAmount);
        if (penalty > 0) TransferHelper.safeTransfer(apeXToken, treasury, penalty);
        info.claimedAmount += withdrawAmount;
        info.forceWithdrawn = true;
        _burn(address(this), withdrawAmount + penalty);
        emit ForceWithdraw(msg.sender, to, withdrawAmount, penalty, vestId);
    }

    function _spendAllowance(address from, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance[from][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(balanceOf[from] >= value, "balance of from < value");
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address _owner, address spender, uint256 value) private {
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "can not tranfer to zero address");
        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= value, "transfer amount exceeds balance");
        balanceOf[from] = fromBalance - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}