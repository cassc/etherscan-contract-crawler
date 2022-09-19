//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IMedals.sol";
import "./interface/IGasStake.sol";

contract Loan is ERC721Holder, AccessControlEnumerable, ReentrancyGuard {
    
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.UintSet private medalIds;
    EnumerableSet.AddressSet private teamCreators;

    address public lp = 0x1F41eDef9C52e00Cfc4c55953455c3C5152782e8;
    address public token = 0x55476A6381aEB31F3ce34F363f7d2bbBECE2B311;
    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public medals = 0x829AA1551fa2B2ed46555E6a55c6f78E28737086;
    address public gasStake = 0x84594b7c24a39DbF9c81AF723e54dC4586972ecb;

    uint256 public maxLevel;
    uint256 public creatorRatio = 2e17;
    uint256 public gasStakeRatio = 8e17;
    uint256 public repayTimes = 6;
    uint256 public INTERVAL = 7 * 24 * 60 * 60;

    struct Member {
        address account;
        uint256 loanStatus;
        uint256 repayCount;
    }

    struct Group {
        uint256 level;
        uint256 tokenId;
        uint256 activate;
        uint256 createTime;
        address creator;
        uint256 index;
    }

    struct LoanLevel {
        uint256 loanAmount;
        uint256 period;
        uint256 repayRatio;
        uint256 interestRatio;
        uint256 overduePeriod;
        uint256 overdueRatio;
    }

    struct LoanInfo {
        uint256 loanAmount;
        uint256 level;
        uint256 period;
        uint256 repayRatio;
        uint256 repayPeriod;
        uint256 interestRatio;
        uint256 overduePeriod;
        uint256 overdueRatio;
        uint256 borrowTime;
        uint256 alreadyRepayPeriod;
        uint256 index;
    }

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
    }

    mapping(uint256 => LoanLevel) public loanLevel;
    mapping(address => uint256[]) private indexes;
    mapping(uint256 => Group) private loanTeam;
    mapping(uint256 => Member[]) private teamMember;
    mapping(address => LoanInfo[]) private loanInfos;

    function init(address _lp, address _token, address _usdt, address _medals, address _gasStake) external onlyRole(OPERATOR_ROLE) {
        lp = _lp;
        token = _token;
        usdt = _usdt;
        medals = _medals;
        gasStake = _gasStake;
    }

    function setRepayConfig(uint256 _creatorRatio, uint256 _gasStakeRatio) external onlyRole(OPERATOR_ROLE) {
        creatorRatio = _creatorRatio;
        gasStakeRatio = _gasStakeRatio;
    }

    function setMedalId(uint256 _medalId) external onlyRole(OPERATOR_ROLE) {
        medalIds.add(_medalId);
    }

    function setMedals(address _medals) external onlyRole(OPERATOR_ROLE) {
        medals = _medals;
    }

    function rescue(IERC20 _token, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        _token.safeTransfer(msg.sender, amount);
    }

    function setLoanLevel(
        uint256 _level,
        uint256 _amount,
        uint256 _period,
        uint256 _repayRatio,
        uint256 _interestRatio,
        uint256 _overduePeriod,
        uint256 _overdueRatio
    ) external onlyRole(OPERATOR_ROLE) {
        LoanLevel storage level = loanLevel[_level];
        level.loanAmount = _amount;
        level.period = _period;
        level.repayRatio = _repayRatio;
        level.interestRatio = _interestRatio;
        level.overduePeriod = _overduePeriod;
        level.overdueRatio = _overdueRatio;
        maxLevel = _level > maxLevel ? _level : maxLevel;
    }

    function createLoanTeam(address[] memory addrs, uint256 _tokenId) external nonReentrant {
        require(IERC721(medals).ownerOf(_tokenId) == msg.sender, "Loan: not medal owner!");
        require(addrs.length == 5, "Loan: addrs length error!");
        require(!_checkActivated(msg.sender), "Loan: exist activated!");
        require(!_checkDuplicate(addrs), "Loan: duplicate address!");
        require(_checkCreateable(addrs, msg.sender), "Loan: not createable!");
        require(_checkMedalIdExist(_tokenId), "Loan: medalId invalid!");
        _counter.increment();
        uint256 _index = _counter.current();
        _addGroupMember(addrs, _index, _tokenId);
        indexes[msg.sender].push(_index);
        teamCreators.add(msg.sender);
        IERC721(medals).safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function staking(uint256 _groupIndex, uint256 _tokenId) external nonReentrant {
        uint index = _getIndex(msg.sender, _groupIndex);
        require(index > 0, "Loan: invalid groupIndex!");
        require(IERC721(medals).ownerOf(_tokenId) == msg.sender, "Loan: not owner!");
        require(!_checkActivated(msg.sender), "Loan: exist activated!");
        Group storage group = loanTeam[index];
        require(group.creator == msg.sender, "Loan: no permission!");
        require(group.activate == 0, "Loan: activate already!");
        group.tokenId = _tokenId;
        group.activate = 1;
        IERC721(medals).safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function redeem(uint256 _groupIndex) external nonReentrant {
        uint index = _getIndex(msg.sender, _groupIndex);
        require(index > 0, "Loan: invalid groupIndex!");
        require(_countLoanRecord(index) == 0, "Loan: loan records exist!");
        Group storage group = loanTeam[index];
        require(group.activate == 1, "Loan: active status error!");
        require(group.creator == msg.sender, "Loan: no permission!");
        group.activate = 0;
        IERC721(medals).safeTransferFrom(address(this), msg.sender, group.tokenId);
    }

    function levelUp(uint256 _groupIndex) external nonReentrant {
        uint index = _getIndex(msg.sender, _groupIndex);
        require(index > 0, "Loan: invalid groupIndex!");
        require(_checkStatus(index), "Loan: status error!");
        Group storage group = loanTeam[index];
        require(group.activate == 1, "Loan: not activate!");
        require(group.creator == msg.sender, "Loan: no permission!");
        require(group.level < maxLevel, "Loan: already maxLevel!");
        group.level += 1;
        _reset(index);
    }

    function reset(uint256 _groupIndex) external nonReentrant {
        uint index = _getIndex(msg.sender, _groupIndex);
        require(index > 0, "Loan: invalid groupIndex!");
        require(_checkStatus(index), "Loan: status error!");
        Group storage group = loanTeam[index];
        require(group.activate == 1, "Loan: not activate!");
        require(group.creator == msg.sender, "Loan: no permission!");
        require(group.level == maxLevel, "Loan: not maxLevel!");
        _reset(index);
    }

    function borrow(uint256 _groupIndex, address _addr) external nonReentrant {
        require(checkLoanable(_addr, _groupIndex), "Loan: loan unable!");
        uint index = _getIndex(msg.sender, _groupIndex);
        require(index > 0, "Loan: invalid groupIndex!");
        Group storage group = loanTeam[index];
        LoanInfo storage loanInfo = loanInfos[_addr].push();
        require(loanInfo.loanAmount == 0, "Loan: repeated loan!");
        require(group.creator == msg.sender, "Loan: address error!");
        require(group.activate == 1, "Loan: not activate!");
        require(group.creator == msg.sender, "Loan: no permission!");
        LoanLevel memory config = loanLevel[group.level];
        loanInfo.level = group.level;
        loanInfo.loanAmount = config.loanAmount;
        loanInfo.period = config.period;
        loanInfo.repayRatio = config.repayRatio;
        loanInfo.interestRatio = config.interestRatio;
        loanInfo.overduePeriod = config.overduePeriod;
        loanInfo.overdueRatio = config.overdueRatio;
        loanInfo.borrowTime = block.timestamp;
        loanInfo.alreadyRepayPeriod = 0;
        loanInfo.index = _groupIndex;
        _borrowUpdateMember(_addr, index);
        uint256 price = getTokenPrice();
        uint256 amount = config.loanAmount * 1e18 / price;
        IERC20(token).safeTransfer(_addr, amount);
    }

    function repay() external nonReentrant {
        uint256 length = loanInfos[msg.sender].length;
        require(length > 0, "Loan: repay error!");
        LoanInfo storage loanInfo = loanInfos[msg.sender][length - 1];
        require(loanInfo.loanAmount > 0, "Loan: no Record!");
        uint256 current = loanInfo.alreadyRepayPeriod + 1;
        require(current <= loanInfo.period, "Loan: already repay!");
        uint256 repayTime = loanInfo.borrowTime + (INTERVAL * current);
        require(block.timestamp > repayTime, "Loan: not required!");
        loanInfo.alreadyRepayPeriod = current;
        uint index = _getIndex(msg.sender, loanInfo.index);
        _repayUpdateMember(loanInfo.period, index, current);
        (uint256 principal, uint256 interest) = _calculateInterest(loanInfo, repayTime);
        uint256 total = principal + interest;
        IERC20(usdt).safeTransferFrom(msg.sender, address(this), total);
        IERC20(usdt).approve(gasStake, total);
        IGasStake(gasStake).recharge(principal);
        IGasStake(gasStake).recharge(interest * gasStakeRatio / 1e18);
        IERC20(usdt).safeTransfer(loanTeam[index].creator, interest * creatorRatio / 1e18);
    }

    function _checkActivated(address _addr) private view returns (bool) {
        Group[] memory groups = _getGroups(_addr);
        for (uint256 i = 0; i < groups.length; i++) {
            if (groups[i].activate == 1) {
                return true;
            }
        }
        return false;
    }

    function _checkCreateable(address[] memory addrs, address _msgSender) private view returns (bool) {
        if (!teamCreators.contains(_msgSender) && indexes[_msgSender].length > 0) {
            return false;
        }
        for (uint256 i = 0; i < addrs.length; i++) {
            address _addr = addrs[i];
            if (indexes[_addr].length > 0 || _msgSender == _addr) {
                return false;
            }
        }
        return true;
    }

    function _checkDuplicate(address[] memory addrs) private pure returns (bool) {
        uint160[] memory arr = new uint160[](5);
        for (uint256 i = 0; i < addrs.length; i++) {
            arr[i] = uint160(addrs[i]);
        }
        arr = _insertionSort(arr);
        for (uint160 i = 1; i < arr.length; i++) {
            if (arr[i - 1] >= arr[i]) {
                return true;
            }
        }
        return false;
    }

    function _insertionSort(uint160[] memory a) private pure returns (uint160[] memory) {
        for (uint160 i = 1; i < a.length; i++) {
            uint160 temp = a[i];
            uint160 j = i;
            while ((j >= 1) && (temp < a[j - 1])) {
                a[j] = a[j - 1];
                j--;
            }
            a[j] = temp;
        }
        return (a);
    }

    function _checkMedalIdExist(uint256 _tokenId) private returns (bool) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        (uint256[] memory ids, ) = IMedals(medals).getMedalInfos(tokenIds);
        return medalIds.contains(ids[0]);
    }

    function checkLoanable(address _addr, uint256 _groupIndex) public view returns (bool) {
        uint256 index = _getIndex(_addr, _groupIndex);
        if (index == 0) {
            return false;
        }
        Group memory group = loanTeam[index];    
        if (group.level == 0 || _addr == group.creator || group.activate != 1) {
            return false;
        }
        return _checkLoanable(index, _addr);
    }

    function _checkLoanable(uint256 index, address _addr) private view returns (bool) {
        Member[] memory members = teamMember[index];
        uint256 _loanCount = _getLoanCount(members);
        uint256 count = 0;
        for (uint256 i = 0; i < members.length; i++) {
            Member memory _member = members[i];
            if (_member.account == _addr && members[i].loanStatus != 1) {
                return false;
            }
            if (members[i].repayCount >= repayTimes) {
                count += 1;
            }
        }
        if (_loanCount < 2) {
            return true;
        } else if (_loanCount < 4) {
            return count >= 2;
        } else {
            return count >= 4;
        }
    }

    function _getLoanCount(Member[] memory members) private pure returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i].loanStatus != 1) {
                count += 1;
            }
        }
        return count;
    }

    function _checkStatus(uint256 _index) private view returns (bool) {
        Member[] memory members = teamMember[_index];
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i].loanStatus != 3) {
                return false;
            }
        }
        return true;
    }

    function _countLoanRecord(uint256 _index) private view returns (uint256) {
        uint256 count = 0;
        Member[] memory members = teamMember[_index];
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i].loanStatus == 2) {
                count += 1;
            }
        }
        return count;
    }

    function _reset(uint256 _index) private {
        Member[] storage members = teamMember[_index];
        for (uint256 i = 0; i < members.length; i++) {
            Member storage member = members[i];
            member.loanStatus = 1;
            member.repayCount = 0;
        }
    }

    function _addGroupMember(address[] memory addrs, uint256 _index, uint256 _tokenId) private {
        Group storage group = loanTeam[_index];
        group.level = 1;
        group.tokenId = _tokenId;
        group.activate = 1;
        group.index = _index;
        group.creator = msg.sender;
        group.createTime = block.timestamp;
        for (uint256 i = 0; i < 5; i++) {
            address addr = addrs[i];
            Member storage member = teamMember[_index].push();
            member.account = addr;
            member.loanStatus = 1;
            indexes[addr].push(_index);
        }
    }

    function _getIndex(address _addr, uint256 _groupIndex) private view returns (uint256){
        Group[] memory groups = _getGroups(_addr);
        if (groups.length == 0 || _groupIndex >= groups.length) {
            return 0;
        }
        return groups[_groupIndex].index;
    }

    function _getGroups(address _addr) private view returns(Group[] memory groups) {
        uint len = indexes[_addr].length;
        if (len > 0) {
            groups = new Group[](indexes[_addr].length); 
            uint256[] memory indexs = indexes[_addr];
            for (uint256 i = 0; i < indexs.length; i++) {
                groups[i] = loanTeam[indexs[i]];
            }
        }
    }

    function _borrowUpdateMember(address _addr, uint256 _index) private {
        Member[] storage members = teamMember[_index];
        for (uint256 i = 0; i < members.length; i++) {
            Member storage member = members[i];
            if (member.account == _addr) {
                if (member.loanStatus != 1) {
                    revert("Loan: status error!");
                }
                member.loanStatus = 2;
            }
        }
    } 

    function _repayUpdateMember(uint256 _period, uint256 _index, uint256 _repayCount) private {
        Member[] storage members = teamMember[_index];
        for (uint256 i = 0; i < members.length; i++) {
            Member storage member = members[i];
            if (member.account == msg.sender) {
                member.repayCount = _repayCount;
                if (_repayCount == _period) {
                    member.loanStatus = 3;
                } 
            }
        }
    }

    function _calculateInterest(LoanInfo memory loanInfo, uint256 repayTime) private view returns (uint256, uint256) {
        LoanLevel memory config = loanLevel[loanInfo.level];
        uint256 principal = (config.loanAmount * loanInfo.repayRatio) / 1e18;
        uint256 overdue = 0;
        if (block.timestamp > repayTime + INTERVAL * loanInfo.overduePeriod) {
            overdue = (principal * config.overdueRatio) / 1e18;
        }
        uint256 interest = (principal * config.interestRatio) / 1e18 + overdue;
        return (principal, interest);
    }

    function getTokenPrice() public view returns (uint256) {
        uint256 usdtBalance = IERC20(usdt).balanceOf(lp);
        uint256 tokenBalance = IERC20(token).balanceOf(lp);
        return (1e18 * usdtBalance) / tokenBalance;
    }

    function getGroupIndexs(address _addr) external view returns (uint256[] memory) {
        return indexes[_addr];
    }

    function getGroupMembers(uint256 _index) external view returns (Member[] memory) {
        return teamMember[_index];
    }

    function getGroupByIndex(uint256 _index) external view returns (Group memory) {
        return loanTeam[_index];
    }

    function getBrorrowInfo(address _addr) external view returns (LoanInfo[] memory) {
        return loanInfos[_addr];
    }

    function getMedalsInfo(address _addr, uint256 _medalsId) external view returns (uint256[] memory) {
        return IMedals(medals).accountMedalTokenIds(_addr, _medalsId);
    }
}