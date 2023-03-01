// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {
    SafeERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {
    EnumerableSetUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {_getTknMaxWithdraw} from "./functions/VestingFormulaFunctions.sol";
import {Vesting} from "./structs/SVesting.sol";

// BE CAREFUL: DOT NOT CHANGE THE ORDER OF INHERITED CONTRACT
contract LinearVestingHub is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // solhint-disable-next-line max-line-length
    ////////////////////////////////////////// CONSTANTS AND IMMUTABLES ///////////////////////////////////

    // GEL Token
    // solhint-disable var-name-mixedcase
    IERC20Upgradeable public immutable TOKEN;
    // VESTING_TRE
    address public immutable VESTING_TREASURY;
    // solhint-enable var-name-mixedcase

    // !!!!!!!!!!!!!!!!!!!!!!!! DO NOT CHANGE ORDER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    mapping(address => uint256) public nextVestingIdByReceiver;
    mapping(address => Vesting[]) public vestingsByReceiver;
    uint256 public totalWithdrawn;

    EnumerableSetUpgradeable.AddressSet private _receivers;

    event LogAddVestings(uint256 sumTokenBalances);
    event LogAddVesting(
        uint256 indexed id,
        address indexed receiver,
        uint256 allocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 duration
    );
    event LogRemoveVesting(
        uint256 indexed id,
        address indexed receiver,
        uint256 unvestedToken
    );
    event LogIncreaseVestingBalance(
        uint256 indexed id,
        address indexed receiver,
        uint256 oldTokenBalance,
        uint256 newTokenBalance
    );
    event LogDecreaseVestingBalance(
        uint256 indexed id,
        address indexed receiver,
        uint256 oldTokenBalance,
        uint256 newTokenBalance
    );
    event LogChangeVestingStartTime(
        uint256 indexed id,
        address indexed receiver,
        uint256 oldStartTime,
        uint256 newStartTime
    );
    event LogChangeVestingCliffDuration(
        uint256 indexed id,
        address indexed receiver,
        uint256 oldCliffDuration,
        uint256 newCliffDuration
    );
    event LogChangeVestingDuration(
        uint256 indexed id,
        address indexed receiver,
        uint256 oldDuration,
        uint256 newDuration
    );
    event LogReplaceVestingWithNewReceiver(
        uint256 oldId,
        address indexed oldReceiver,
        uint256 newId,
        address indexed newReceiver
    );
    event LogWithdraw(uint256 id, address receiver, uint256 amountOfTokens);

    // !!!!!!!!!!!!!!!!!!!!!!!! MODIFIER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    modifier onlyProxyAdminOrReceiver(address _receiver) {
        require(
            msg.sender == _proxyAdmin() || msg.sender == _receiver,
            "LinearVestingHub:: only owner or receiver."
        );
        _;
    }

    constructor(IERC20Upgradeable token_, address vestingTreasury_) {
        TOKEN = token_;
        VESTING_TREASURY = vestingTreasury_;
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! ADMIN FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    function pause() external onlyProxyAdmin {
        _pause();
    }

    function unpause() external onlyProxyAdmin {
        _unpause();
    }

    function withdrawAllTokens() external onlyProxyAdmin whenPaused {
        uint256 balance = TOKEN.balanceOf(address(this));
        require(balance > 0, "LinearVestingHub::withdrawAllTokens: 0 balance");
        TOKEN.safeTransfer(VESTING_TREASURY, balance);
    }

    function addVestings(Vesting[] calldata vestings_) external onlyProxyAdmin {
        uint256 totalBalance;
        for (uint256 i = 0; i < vestings_.length; i++) {
            _addVesting(vestings_[i]);

            emit LogAddVesting(
                vestings_[i].id,
                vestings_[i].receiver,
                vestings_[i].tokenBalance,
                vestings_[i].startTime,
                vestings_[i].cliffDuration,
                vestings_[i].duration
            );
            totalBalance = totalBalance + vestings_[i].tokenBalance;
        }

        TOKEN.safeTransferFrom(VESTING_TREASURY, address(this), totalBalance);

        emit LogAddVestings(totalBalance);
    }

    function addVesting(Vesting calldata vesting_) external onlyProxyAdmin {
        _addVesting(vesting_);
        TOKEN.safeTransferFrom(
            VESTING_TREASURY,
            address(this),
            vesting_.tokenBalance
        );

        emit LogAddVesting(
            vesting_.id,
            vesting_.receiver,
            vesting_.tokenBalance,
            vesting_.startTime,
            vesting_.cliffDuration,
            vesting_.duration
        );
    }

    function removeVesting(
        address receiver_,
        uint8 vestingId_
    ) external onlyProxyAdminOrReceiver(receiver_) {
        Vesting memory vesting = vestingsByReceiver[receiver_][vestingId_];

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::removeVesting: vesting non existing."
        );

        delete vestingsByReceiver[receiver_][vestingId_];
        _tryRemoveReceiver(receiver_);

        TOKEN.safeTransfer(VESTING_TREASURY, vesting.tokenBalance);

        emit LogRemoveVesting(
            vesting.id,
            vesting.receiver,
            vesting.tokenBalance
        );
    }

    function increaseVestingBalance(
        address receiver_,
        uint256 vestingId_,
        uint256 addend_
    ) external onlyProxyAdmin {
        Vesting storage vesting = vestingsByReceiver[receiver_][vestingId_];

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::increaseVestingBalance: vesting non existing."
        );
        require(
            addend_ > 0,
            "LinearVestingHub::increaseVestingBalance: addend_ 0"
        );
        require(
            //solhint-disable-next-line not-rely-on-time
            block.timestamp < vesting.startTime + vesting.duration,
            "LinearVestingHub::increaseVestingBalance: cannot increase a completed vesting"
        );

        uint256 initTokenBalance = vesting.tokenBalance;
        vesting.tokenBalance = initTokenBalance + addend_;

        TOKEN.safeTransferFrom(VESTING_TREASURY, address(this), addend_);

        emit LogIncreaseVestingBalance(
            vestingId_,
            receiver_,
            initTokenBalance,
            vesting.tokenBalance
        );
    }

    // solhint-disable-next-line function-max-lines
    function decreaseVestingBalance(
        address receiver_,
        uint256 vestingId_,
        uint256 subtrahend_
    ) external onlyProxyAdmin {
        Vesting storage vesting = vestingsByReceiver[receiver_][vestingId_];

        uint256 startTime = vesting.startTime;
        uint256 duration = vesting.duration;
        uint256 initTokenBalance = vesting.tokenBalance;

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::decreaseVestingBalance: vesting non existing."
        );
        require(
            subtrahend_ > 0,
            "LinearVestingHub::decreaseVestingBalance: subtrahend_ 0"
        );
        require(
            subtrahend_ <= initTokenBalance,
            "LinearVestingHub::decreaseVestingBalance: subtrahend_ gt remaining token balance"
        );
        require(
            //solhint-disable-next-line not-rely-on-time
            block.timestamp < startTime + duration,
            "LinearVestingHub::decreaseVestingBalance: cannot decrease a completed vesting"
        );

        require(
            _getTknMaxWithdraw(
                initTokenBalance,
                vesting.withdrawnTokens,
                startTime,
                vesting.cliffDuration,
                duration
            ) <= initTokenBalance - subtrahend_,
            "LinearVestingHub::decreaseVestingBalance: cannot decrease vested tokens"
        );

        uint256 newTokenBalance = initTokenBalance - subtrahend_;
        vesting.tokenBalance = newTokenBalance;

        if (newTokenBalance == 0) {
            delete vestingsByReceiver[receiver_][vestingId_];
            _tryRemoveReceiver(receiver_);
        }

        TOKEN.safeTransfer(VESTING_TREASURY, subtrahend_);

        emit LogDecreaseVestingBalance(
            vestingId_,
            receiver_,
            initTokenBalance,
            newTokenBalance
        );
    }

    function changeVestingStartTime(
        uint256 _vestingId,
        address _receiver,
        uint256 _newStartTime
    ) external onlyProxyAdmin {
        Vesting storage vesting = vestingsByReceiver[_receiver][_vestingId];

        uint256 oldStartTime = vesting.startTime;

        vesting.startTime = _newStartTime;

        emit LogChangeVestingStartTime(
            _vestingId,
            _receiver,
            oldStartTime,
            _newStartTime
        );
    }

    function changeVestingCliffDuration(
        uint256 _vestingId,
        address _receiver,
        uint256 _newCliffDuration
    ) external onlyProxyAdmin {
        Vesting storage vesting = vestingsByReceiver[_receiver][_vestingId];

        uint256 oldCliffDuration = vesting.cliffDuration;

        vesting.cliffDuration = _newCliffDuration;

        emit LogChangeVestingCliffDuration(
            _vestingId,
            _receiver,
            oldCliffDuration,
            _newCliffDuration
        );
    }

    function changeVestingDuration(
        uint256 _vestingId,
        address _receiver,
        uint256 _newDuration
    ) external onlyProxyAdmin {
        Vesting storage vesting = vestingsByReceiver[_receiver][_vestingId];

        uint256 oldDuration = vesting.duration;

        vesting.duration = _newDuration;

        emit LogChangeVestingDuration(
            _vestingId,
            _receiver,
            oldDuration,
            _newDuration
        );
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! USER FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function replaceVestingWithNewReceiver(
        uint8[] calldata _oldVestingIds,
        address _oldReceiver,
        uint8[] calldata _newVestingIds,
        address _newReceiver
    ) external onlyProxyAdminOrReceiver(_oldReceiver) {
        for (uint256 i; i < _oldVestingIds.length; i++) {
            Vesting memory vesting = vestingsByReceiver[_oldReceiver][
                _oldVestingIds[i]
            ];

            delete vestingsByReceiver[_oldReceiver][_oldVestingIds[i]];

            vesting.receiver = _newReceiver;
            vesting.id = _newVestingIds[i];

            _addVestingFromMemory(vesting);

            emit LogReplaceVestingWithNewReceiver(
                _oldVestingIds[i],
                _oldReceiver,
                _newVestingIds[i],
                _newReceiver
            );
        }

        _tryRemoveReceiver(_oldReceiver);
    }

    // solhint-disable-next-line function-max-lines
    function withdraw(
        address receiver_,
        uint256 vestingId_,
        address to_,
        uint256 value_
    ) external whenNotPaused nonReentrant onlyProxyAdminOrReceiver(receiver_) {
        Vesting storage vesting = vestingsByReceiver[receiver_][vestingId_];

        uint256 startTime = vesting.startTime;
        uint256 cliffDuration = vesting.cliffDuration;
        uint256 initTokenBalance = vesting.tokenBalance;

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::withdraw: vesting non existing."
        );
        require(value_ > 0, "LinearVestingHub::withdraw: value_ 0");
        require(
            //solhint-disable-next-line not-rely-on-time
            block.timestamp > startTime + cliffDuration,
            "LinearVestingHub::withdraw: cliffDuration period."
        );
        require(
            value_ <=
                _getTknMaxWithdraw(
                    initTokenBalance,
                    vesting.withdrawnTokens,
                    startTime,
                    cliffDuration,
                    vesting.duration
                ),
            "LinearVestingHub::withdraw: receiver try to withdraw more than max withdraw"
        );

        vesting.tokenBalance = initTokenBalance - value_;
        vesting.withdrawnTokens = vesting.withdrawnTokens + value_;
        totalWithdrawn = totalWithdrawn + value_;

        if (vesting.tokenBalance == 0) {
            delete vestingsByReceiver[receiver_][vestingId_];
            _tryRemoveReceiver(receiver_);
        }

        TOKEN.safeTransfer(to_, value_);

        emit LogWithdraw(vestingId_, receiver_, value_);
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function withdrawAllAvailable(
        address receiver_,
        address to_
    ) external whenNotPaused nonReentrant onlyProxyAdminOrReceiver(receiver_) {
        Vesting[] memory receiverVestings = vestingsByReceiver[receiver_];

        require(
            receiverVestings.length > 0,
            "LinearVestingHub::withdrawAllAvailable: invalid receiver"
        );

        bool hasVestingLeft;
        uint256 total;

        for (uint256 i; i < receiverVestings.length; i++) {
            Vesting memory vestingMem = receiverVestings[i];

            if (vestingMem.receiver == address(0)) continue;

            uint256 amount = _getTknMaxWithdraw(
                vestingMem.tokenBalance,
                vestingMem.withdrawnTokens,
                vestingMem.startTime,
                vestingMem.cliffDuration,
                vestingMem.duration
            );

            if (amount == 0) {
                // Vestings are only considered stale if receiver is AddressZero
                hasVestingLeft = true;
                continue;
            }

            uint256 newTokenBalance = vestingMem.tokenBalance - amount;

            // Stored Effects
            if (newTokenBalance == 0) {
                delete vestingsByReceiver[receiver_][i];
                // hasVestingLeft=false
            } else {
                Vesting storage vesting = vestingsByReceiver[receiver_][i];
                vesting.tokenBalance = newTokenBalance;
                vesting.withdrawnTokens = vestingMem.withdrawnTokens + amount;
                hasVestingLeft = true;
            }

            total += amount;

            emit LogWithdraw(i, receiver_, amount);
        }

        require(
            total > 0,
            "LinearVestingHub::withdrawAllAvailable: zero available"
        );

        if (!hasVestingLeft) _receivers.remove(receiver_);

        totalWithdrawn += total;

        TOKEN.safeTransfer(to_, total);
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! HELPERS FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function getAllAvailable(
        address receiver_
    ) external view returns (uint256 total) {
        Vesting[] memory receiverVestings = vestingsByReceiver[receiver_];

        if (receiverVestings.length == 0) return 0;

        for (uint256 i; i < receiverVestings.length; i++) {
            Vesting memory vestingMem = receiverVestings[i];

            if (vestingMem.receiver == address(0)) continue;

            uint256 amount = _getTknMaxWithdraw(
                vestingMem.tokenBalance,
                vestingMem.withdrawnTokens,
                vestingMem.startTime,
                vestingMem.cliffDuration,
                vestingMem.duration
            );

            total += amount;
        }
    }

    function isReceiver(address receiver_) external view returns (bool) {
        return _receivers.contains(receiver_);
    }

    function receiverAt(uint256 index_) external view returns (address) {
        return _receivers.at(index_);
    }

    function receivers() external view returns (address[] memory r) {
        r = new address[](_receivers.length());
        for (uint256 i = 0; i < _receivers.length(); i++)
            r[i] = _receivers.at(i);
    }

    function numberOfReceivers() external view returns (uint256) {
        return _receivers.length();
    }

    /// @dev for off-chain reading only as very gas-intensive
    /// if eventually too gas intensive even for off-chain reading
    //  we'll need a paginated version
    function getAllActiveVestings()
        external
        view
        returns (Vesting[] memory activeVestings)
    {
        address[] memory __receivers = _receivers.values();

        // unfortunately we have to run this twice as solidity first
        // requires the length for array instantiation
        uint256 numberOfActiveVestings = _getTotalNumberOfActiveVestings(
            __receivers
        );

        activeVestings = new Vesting[](numberOfActiveVestings);

        uint256 counter;

        for (uint256 i; i < __receivers.length; i++) {
            Vesting[] memory receiverVestings = vestingsByReceiver[
                __receivers[i]
            ];

            for (uint256 j; j < receiverVestings.length; j++) {
                if (receiverVestings[j].receiver == address(0)) continue;
                activeVestings[counter] = receiverVestings[j];
                counter++;
            }
        }
    }

    /// @dev for off-chain use only, might require pagination
    function getTotalNumberOfVestings() external view returns (uint256) {
        return _getTotalNumberOfVestings(_receivers.values());
    }

    /// @dev for off-chain use only, might require pagination
    function getTotalNumberOfActiveVestings() public view returns (uint256) {
        return _getTotalNumberOfActiveVestings(_receivers.values());
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! INTERNAL FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    function _addVesting(Vesting calldata vesting_) internal {
        uint256 nextVestingId = nextVestingIdByReceiver[vesting_.receiver];
        require(
            vesting_.receiver != address(0),
            "LinearVestingHub::_addVesting: invalid receiver"
        );
        require(
            nextVestingId == vesting_.id,
            "LinearVestingHub::_addVesting: wrong vesting id"
        );
        require(
            vesting_.tokenBalance > 0,
            "LinearVestingHub::_addVesting: 0 vesting_tokenBalance"
        );

        _receivers.add(vesting_.receiver);

        vestingsByReceiver[vesting_.receiver].push(vesting_);

        nextVestingIdByReceiver[vesting_.receiver] = nextVestingId + 1;
    }

    function _addVestingFromMemory(Vesting memory vesting_) internal {
        uint256 nextVestingId = nextVestingIdByReceiver[vesting_.receiver];
        require(
            vesting_.receiver != address(0),
            "LinearVestingHub::_addVestingFromMemory: invalid receiver"
        );
        require(
            nextVestingId == vesting_.id,
            "LinearVestingHub::_addVestingFromMemory: wrong vesting id"
        );
        require(
            vesting_.tokenBalance > 0,
            "LinearVestingHub::_addVestingFromMemory: 0 vesting_tokenBalance"
        );

        _receivers.add(vesting_.receiver);

        vestingsByReceiver[vesting_.receiver].push(vesting_);

        nextVestingIdByReceiver[vesting_.receiver] = nextVestingId + 1;
    }

    function _tryRemoveReceiver(address receiver_) internal {
        for (uint256 i = 0; i < nextVestingIdByReceiver[receiver_]; i++)
            if (vestingsByReceiver[receiver_][i].receiver != address(0)) return;

        _receivers.remove(receiver_);
    }

    function _getTotalNumberOfVestings(
        address[] memory __receivers
    ) internal view returns (uint256 totalNumberOfVestings) {
        for (uint256 i; i < __receivers.length; i++)
            totalNumberOfVestings += vestingsByReceiver[__receivers[i]].length;
    }

    function _getTotalNumberOfActiveVestings(
        address[] memory __receivers
    ) internal view returns (uint256 totalNumberOfActiveVestings) {
        for (uint256 i; i < __receivers.length; i++) {
            Vesting[] memory receiverVestings = vestingsByReceiver[
                __receivers[i]
            ];

            for (uint256 j; j < receiverVestings.length; j++) {
                if (receiverVestings[j].receiver == address(0)) continue;
                totalNumberOfActiveVestings++;
            }
        }
    }
}