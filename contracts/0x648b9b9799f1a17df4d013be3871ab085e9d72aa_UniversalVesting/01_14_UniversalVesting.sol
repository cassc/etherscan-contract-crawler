// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract UniversalVesting is ReentrancyGuard, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public debtByToken;
    mapping(uint256 => Recipient) public recipients;
    mapping(address => EnumerableSet.UintSet) private recipientsSet;
    mapping(address => bool) public isApprovedToken;

    uint256 public nextId = 0;
    bool public isPublic = false;

    // think about packing it?? using smaller numbers
    struct Recipient {
        uint256 cliffPeriod;
        uint256 vestingWeeks;
        uint256 totalAllocation;
        uint256 paidOut;
        uint224 startTimestamp;
        address admin;
        address token;
        address recipient;
    }

    modifier requirePublic() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            require(isPublic, "UniversalVesting: not public yet");
        }
        _;
    }

    constructor(address gnosis) {
        _grantRole(DEFAULT_ADMIN_ROLE, gnosis);
    }

    function addRecipient(
        uint256 cliffPeriod,
        uint256 vestingWeeks,
        address recipient,
        uint256 totalAllocation,
        address token,
        bool transferFrom
    ) external nonReentrant requirePublic {
        require(isApprovedToken[token], "UniversalVesting: tkn !approved");

        if (transferFrom) {
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                totalAllocation
            );
        }

        uint256 _debtByToken = debtByToken[token] + totalAllocation;
        require(
            _debtByToken <= IERC20(token).balanceOf(address(this)),
            "UniversalVesting: low balance"
        );
        debtByToken[token] = _debtByToken;

        recipients[nextId] = Recipient(
            cliffPeriod,
            vestingWeeks,
            totalAllocation,
            0,
            uint224(block.timestamp),
            msg.sender,
            token,
            recipient
        );
        recipientsSet[recipient].add(nextId);

        nextId++;
    }

    function editRecipient(
        uint256 id,
        uint256 cliffPeriod,
        uint256 vestingWeeks,
        address recipient,
        uint256 totalAllocation,
        bool transferFrom
    ) external nonReentrant requirePublic {
        Recipient memory _recipient = recipients[id];
        require(msg.sender == _recipient.admin, "UniversalVesting: not admin");
        require(
            isApprovedToken[_recipient.token],
            "UniversalVesting: tkn !approved"
        );
        require(
            totalAllocation >= _recipient.paidOut,
            "UniversalVesting: low allocation"
        );

        if (totalAllocation < _recipient.totalAllocation) {
            IERC20(_recipient.token).safeTransfer(
                _recipient.admin,
                _recipient.totalAllocation - totalAllocation
            );
        } else if (
            totalAllocation > _recipient.totalAllocation && transferFrom
        ) {
            IERC20(_recipient.token).safeTransferFrom(
                msg.sender,
                address(this),
                totalAllocation - _recipient.totalAllocation
            );
        }

        uint256 newDebt = debtByToken[_recipient.token] +
            totalAllocation -
            _recipient.totalAllocation;
        require(
            newDebt <= IERC20(_recipient.token).balanceOf(address(this)),
            "UniversalVesting: low balance"
        );
        debtByToken[_recipient.token] = newDebt;

        if (recipient != _recipient.recipient) {
            recipientsSet[_recipient.recipient].remove(id);
            recipientsSet[recipient].add(id);
        }

        recipients[id].cliffPeriod = cliffPeriod;
        recipients[id].vestingWeeks = vestingWeeks;
        recipients[id].recipient = recipient;
        recipients[id].totalAllocation = totalAllocation;
    }

    function changeAdmin(uint256 id, address newAdmin) external requirePublic {
        require(
            msg.sender == recipients[id].admin,
            "UniversalVesting: not admin"
        );

        recipients[id].admin = newAdmin;
    }

    function claimFromAll() external nonReentrant {
        uint256[] memory ids = _getIdsForUser(msg.sender);
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            if (_claim(ids[i])) {
                recipientsSet[msg.sender].remove(ids[i]);
                i = i == 0 ? 0 : i - 1;
            }
        }
    }

    function claimById(uint256 id) external nonReentrant {
        if (_claim(id)) {
            recipientsSet[msg.sender].remove(id);
        }
    }

    function setPublicStatus(bool _isPublic)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isPublic = _isPublic;
    }

    function setTokenApproveStatus(address token, bool status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isApprovedToken[token] = status;
    }

    function getIdsForUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        return _getIdsForUser(user);
    }

    function getAvailableTokensById(uint256 id)
        external
        view
        returns (uint256)
    {
        Recipient memory _recipient = recipients[id];

        return _calculatePayout(_recipient);
    }

    function _getIdsForUser(address user)
        private
        view
        returns (uint256[] memory)
    {
        return recipientsSet[user].values();
    }

    function _claim(uint256 id) private returns (bool toDeleteFromList) {
        Recipient memory _recipient = recipients[id];

        require(
            isApprovedToken[_recipient.token],
            "UniversalVesting: tkn !approved"
        );
        require(
            msg.sender == _recipient.recipient,
            "UniversalVesting: not yours"
        );

        uint256 timeDiff = block.timestamp - _recipient.startTimestamp;
        require(timeDiff > _recipient.cliffPeriod, "UniversalVesting: cliff");

        uint256 payout = _calculatePayout(_recipient);

        debtByToken[_recipient.token] -= payout;
        recipients[id].paidOut = _recipient.paidOut + payout;

        if (_recipient.paidOut + payout == _recipient.totalAllocation) {
            toDeleteFromList = true;
        }

        IERC20(_recipient.token).safeTransfer(_recipient.recipient, payout);
    }

    function _calculatePayout(Recipient memory _recipient)
        private
        view
        returns (uint256 payout)
    {
        uint256 vestingEnd = _recipient.startTimestamp +
            (_recipient.vestingWeeks * 1 weeks);

        if (block.timestamp > vestingEnd) {
            payout = _recipient.totalAllocation;
        } else {
            payout =
                (_recipient.totalAllocation *
                    (block.timestamp - _recipient.startTimestamp)) /
                (_recipient.vestingWeeks * 1 weeks);
        }

        payout -= _recipient.paidOut;
    }
}