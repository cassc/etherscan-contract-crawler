// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ToDaMars is ERC20Burnable, Ownable, ReentrancyGuard {
    event Burn(address indexed user, uint256 amount);
    event Support(address indexed supporter, address indexed inviter, uint256 supportTimestamp, uint256 ethAmount, uint256 tokenAmount);
    event Refund(address indexed supporter, address indexed inviter, uint256 supportTimestamp, uint256 ethAmount, uint256 tokenAmount, uint256 refundTimestamp);

    struct SupportLog {
        address inviter;
        uint256 supportTimestamp;
        uint256 ethAmount;
        uint256 tokenAmount;
        uint256 refundTimestamp;
        uint256 getBonusTimestamp;
    }

    struct InviteLog {
        address supporter;
        uint256 supportTimestamp;
        uint256 tokenAmount;
    }

    address public elonMuskAddress;
    address public vitalikButerinAddress;

    uint256 public elonMuskReceiveTimestamp;
    uint256 public vitalikButerinReceiveTimestamp;

    uint256 public userExchangedTokenAmount;

    uint256 private immutable _initTotalSupply;
    uint256 private immutable _elonMuskTotalAmount;
    uint256 private immutable _vitalikButerinTotalAmount;
    uint256 private immutable _devTotalAmount;
    uint256 private immutable _otherTotalAmount;

    bool public airdropEnd;
    uint256 public airdropTokenAmount;
    mapping(address => bool) public airdropUsers;

    uint256 private _redundantEthAmount;
    uint256 private _devWithdrawTimestamp;
    uint256 private _contractDeployTimestamp;

    uint256[35] public ethExchangeRate = [uint256(10000000000000), 9000000000000, 8000000000000, 7000000000000, 6000000000000, 5000000000000, 4000000000000, 3000000000000, 2000000000000, 1000000000000, 900000000000, 800000000000, 700000000000, 600000000000, 500000000000, 400000000000, 300000000000, 200000000000, 100000000000, 90000000000, 80000000000, 70000000000, 60000000000, 50000000000, 40000000000, 30000000000, 20000000000, 10000000000, 9000000000, 8000000000, 7000000000, 6000000000, 5000000000, 4000000000, 3000000000];

    mapping(address => SupportLog[]) private _userSupportLogs;
    mapping(address => InviteLog[]) private _userInviteLogs;

    constructor() ERC20("ToDaMars", "TDM") {
        _initTotalSupply = 10000000000000000 * 10 ** decimals();
        _mint(msg.sender, _initTotalSupply);

        _elonMuskTotalAmount = _initTotalSupply * 50 / 100;
        _vitalikButerinTotalAmount = _initTotalSupply * 10 / 100;
        _devTotalAmount = _initTotalSupply * 5 / 100;
        _otherTotalAmount = _initTotalSupply * 35 / 100;

        _contractDeployTimestamp = block.timestamp;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        (uint256 actualAmount, uint256 burnAmount) = _splitTransferAmount(amount);
        super.transfer(to, actualAmount);
        if (burnAmount > 0) {
            super.burn(burnAmount);
            emit Burn(msg.sender, burnAmount);
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        (uint256 actualAmount, uint256 burnAmount) = _splitTransferAmount(amount);
        super.transferFrom(from, to, actualAmount);
        if (burnAmount > 0) {
            super.burnFrom(from, burnAmount);
            emit Burn(from, burnAmount);
        }
        return true;
    }

    function _inner_transferFrom(address from, address to, uint256 amount) internal {
        (uint256 actualAmount, uint256 burnAmount) = _splitTransferAmount(amount);
        super._transfer(from, to, actualAmount);
        if (burnAmount > 0) {
            super._burn(from, burnAmount);
            emit Burn(from, burnAmount);
        }
    }

    receive() external payable {
        support(address(0));
    }

    function support(address inviter) public payable nonReentrant {
        require(msg.value > 0, "ToDaMars: send eth");

        if (inviter == msg.sender) {
            inviter = address(0);
        }

        uint256 leftAmount = getLeftSupportTokenAmount();
        require(leftAmount > 0, "ToDaMars: no token left");

        uint256 exchangeTokenAmount = getExchangTokenAmount(msg.value);
        require(exchangeTokenAmount > 0, "ToDaMars: token amount is 0");

        if (exchangeTokenAmount > leftAmount) {
            exchangeTokenAmount = leftAmount;
        }

        _redundantEthAmount += msg.value / 10;
        userExchangedTokenAmount += exchangeTokenAmount;

        _inner_transferFrom(owner(), msg.sender, exchangeTokenAmount);

        SupportLog memory supportLog = SupportLog(inviter, block.timestamp, msg.value, exchangeTokenAmount, 0, 0);
        _userSupportLogs[msg.sender].push(supportLog);

        if (inviter != address(0)) {
            uint256 inviterTokenAmount = exchangeTokenAmount * 2 / 100;
            if (inviterTokenAmount > leftAmount - exchangeTokenAmount) {
                inviterTokenAmount = leftAmount - exchangeTokenAmount;
            }
            if (inviterTokenAmount > 0) {
                _inner_transferFrom(owner(), inviter, inviterTokenAmount);

                InviteLog memory inviteLog = InviteLog(msg.sender, block.timestamp, inviterTokenAmount);
                _userInviteLogs[inviter].push(inviteLog);
            }
        }

        emit Support(msg.sender, supportLog.inviter, supportLog.supportTimestamp, supportLog.ethAmount, supportLog.tokenAmount);
    }

    function refund(uint256 index) public nonReentrant {
        require(index >=0 && index < _userSupportLogs[msg.sender].length, "ToDaMars: index out of range");

        SupportLog storage supportLog = _userSupportLogs[msg.sender][index];
        require(supportLog.refundTimestamp == 0, "ToDaMars: already refund");

        uint256 refundAmount = supportLog.tokenAmount * 9 / 10;
        require(balanceOf(msg.sender) >= refundAmount, "ToDaMars: refund amount exceeds balance");

        supportLog.refundTimestamp = block.timestamp;

        burn(refundAmount);

        uint256 refundEthAmount = getRefundEthAmount(supportLog.ethAmount, supportLog.supportTimestamp, supportLog.refundTimestamp);
        payable(msg.sender).transfer(refundEthAmount);
        _redundantEthAmount = _redundantEthAmount - supportLog.ethAmount / 10 + supportLog.ethAmount - refundEthAmount;

        emit Refund(msg.sender, supportLog.inviter, supportLog.supportTimestamp, supportLog.ethAmount, supportLog.tokenAmount, supportLog.refundTimestamp);
    }

    function getBonus() public nonReentrant {
        require(elonMuskReceiveTimestamp > 0, "ToDaMars: wait for Elon Musk receiving token");

        SupportLog[] storage supportLogs = _userSupportLogs[msg.sender];
        for (uint256 i = 0; i < supportLogs.length; i++) {
            SupportLog storage log = supportLogs[i];
            if (log.refundTimestamp > 0 || log.getBonusTimestamp > 0 || log.supportTimestamp > elonMuskReceiveTimestamp) {
                continue;
            }

            uint256 getBonusTokenAmount = log.tokenAmount / 10;
            uint256 leftAmount = getLeftSupportTokenAmount();
            if (leftAmount <= 0) {
                break;
            }
            if (getBonusTokenAmount > leftAmount) {
                // getBonusTokenAmount = leftAmount;
                continue;
            }
            log.getBonusTimestamp = block.timestamp;
            _inner_transferFrom(owner(), msg.sender, getBonusTokenAmount);
        }
    }

    function airdrop() public nonReentrant {
        require(!airdropEnd, "ToDaMars: airdrop end");
        require(!airdropUsers[msg.sender], "ToDaMars: airdrop once");
        require(airdropTokenAmount < _initTotalSupply / 100, "ToDaMars: airdrop end");

        airdropUsers[msg.sender] = true;

        uint256 amount = _initTotalSupply / 100 / 10000;
        uint256 leftAmount = getLeftSupportTokenAmount();
        require(leftAmount > 0, "ToDaMars: no token left");
        if (amount > leftAmount) {
            amount = leftAmount;
        }
        airdropTokenAmount += amount;
        _inner_transferFrom(owner(), msg.sender, amount);
    }

    function airdropToggle() public onlyOwner {
        airdropEnd = !airdropEnd;
    }

    function getSupportLogs(address addr) public view returns (SupportLog[] memory) {
        return _userSupportLogs[addr];
    }

    function getInviteLogs(address addr) public view returns (InviteLog[] memory) {
        return _userInviteLogs[addr];
    }

    function getExchangTokenAmount(uint256 ethValue) public view returns (uint256) {
        uint256 exchangedTokenAmount = 0;
        uint256 exchangedEth = 0;
        uint256 tokenAmountOneLevel = _initTotalSupply / 100;
        uint256 startLevel = userExchangedTokenAmount / tokenAmountOneLevel;
        for (uint256 i = startLevel; i < ethExchangeRate.length; i++) {
            uint256 exchangeRate = ethExchangeRate[i];

            uint256 curLevelTokenAmount = tokenAmountOneLevel;
            if (i == startLevel) {
                curLevelTokenAmount = tokenAmountOneLevel - (userExchangedTokenAmount % tokenAmountOneLevel);
            }

            uint256 curLevelExchangeAmount = (ethValue - exchangedEth) * exchangeRate;
            if (curLevelExchangeAmount <= curLevelTokenAmount) {
                exchangedTokenAmount += curLevelExchangeAmount;
                break;
            }

            exchangedTokenAmount += curLevelTokenAmount;
            exchangedEth += curLevelTokenAmount / exchangeRate;
        }

        return exchangedTokenAmount;
    }

    function setElonMuskAddress(address addr) public onlyOwner {
        require(elonMuskReceiveTimestamp == 0, "ToDaMars: already set");
        elonMuskAddress = addr;
    }

    function withdrawElonMuskToken() public nonReentrant {
        require(elonMuskAddress != address(0), "ToDaMars: set address first");
        require(msg.sender == elonMuskAddress, "ToDaMars: you're not Elon Mask :(");
        require(elonMuskReceiveTimestamp == 0, "ToDaMars: already withdraw");

        elonMuskReceiveTimestamp = block.timestamp;
        _inner_transferFrom(owner(), elonMuskAddress, _elonMuskTotalAmount);
    }

    function sendTokenToElonMusk() public onlyOwner nonReentrant {
        require(elonMuskAddress != address(0), "ToDaMars: set address first");
        require(elonMuskReceiveTimestamp == 0, "ToDaMars: already sent");

        elonMuskReceiveTimestamp = block.timestamp;
        _inner_transferFrom(owner(), elonMuskAddress, _elonMuskTotalAmount);
    }

    function setVitalikButerinAddress(address addr) public onlyOwner {
        require(vitalikButerinReceiveTimestamp == 0, "ToDaMars: already set");
        vitalikButerinAddress = addr;
    }

    function withdrawVitalikButerinToken() public nonReentrant {
        require(vitalikButerinAddress != address(0), "ToDaMars: set address first");
        require(msg.sender == vitalikButerinAddress, "ToDaMars: you're not Vitalik Buterin :(");
        require(vitalikButerinReceiveTimestamp == 0, "ToDaMars: already withdraw");

        vitalikButerinReceiveTimestamp = block.timestamp;
        _inner_transferFrom(owner(), vitalikButerinAddress, _vitalikButerinTotalAmount);
    }

    function sendTokenToVitalikButerin() public onlyOwner nonReentrant {
        require(vitalikButerinAddress != address(0), "ToDaMars: set address first");
        require(vitalikButerinReceiveTimestamp == 0, "ToDaMars: already sent");

        vitalikButerinReceiveTimestamp = block.timestamp;
        _inner_transferFrom(owner(), vitalikButerinAddress, _vitalikButerinTotalAmount);
    }

    function withdrawDevToken(address addr) public nonReentrant onlyOwner {
        require(_devWithdrawTimestamp == 0, "ToDaMars: already withdraw");

        uint256 devTokenLockDays = 365;
        uint256 day = (block.timestamp - _contractDeployTimestamp) / 60 / 60 / 24;
        require(day > devTokenLockDays, "ToDaMars: dev token locked");

        _devWithdrawTimestamp = block.timestamp;
        _inner_transferFrom(owner(), addr, _devTotalAmount);
    }

    function withdrawRedundantEth(address addr) public nonReentrant onlyOwner {
        require(_redundantEthAmount > 0, "ToDaMars: no redundant eth");
        uint256 amount = _redundantEthAmount;
        _redundantEthAmount = 0;
        payable(addr).transfer(amount);
    }

    function getLeftSupportTokenAmount() public view returns (uint256) {
        uint balance = balanceOf(owner());
        if (elonMuskReceiveTimestamp == 0) {
            balance -= _elonMuskTotalAmount;
        }
        if (vitalikButerinReceiveTimestamp == 0) {
            balance -= _vitalikButerinTotalAmount;
        }
        if (_devWithdrawTimestamp == 0) {
            balance -= _devTotalAmount;
        }
        if (balance < 0) {
            balance = 0;
        }
        return balance;
    }

    function getRefundEthAmount(uint256 ethAmount, uint256 startTimestamp, uint256 endTimestamp) public pure returns (uint256) {
        uint256 day = (endTimestamp - startTimestamp) / 60 / 60 / 24;
        uint256 refundEthAmount = ethAmount * (50 + day) / 100;
        uint256 maxRefund = ethAmount * 9 / 10;
        if (refundEthAmount > maxRefund) {
            refundEthAmount = maxRefund;
        }
        return refundEthAmount;
    }

    function _splitTransferAmount(uint256 amount) internal pure returns (uint256, uint256) {
        uint256 burnAmount = amount / 10;
        return (amount - burnAmount, burnAmount);
    }
}