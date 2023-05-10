// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/IOnRye.sol";
import "./ItterableMapping.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Ham is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    IOnRye public onRye;

    bytes32 public constant CIEL_ROLE = keccak256("CIEL_ROLE");

    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;

    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    bool public autoProcessAccount;
    uint256 public constant MIN_TOKEN_BALANCE_FOR_DIVIDENDS =
        10000 * (10 ** 18); // Must hold 10000+ tokens.

    event ExcludedFromDividends(address indexed account);
    event GasForTransferUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(
        address divivdendToken,
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _ciel,
        address payable _onRye
    ) external initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CIEL_ROLE, _ciel);
        claimWait = 3600; // 1 Hour
        onRye = IOnRye(_onRye);
        autoProcessAccount = true;
    }

    function setAutoProcessAccount(
        bool state
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(state != autoProcessAccount, "TRT: current state");
        autoProcessAccount = state;
    }

    function eFR(address account) external onlyRole(CIEL_ROLE) nonReentrant {
        require(!excludedFromDividends[account], "TRT: already excluded");
        excludedFromDividends[account] = true;
        onRye._setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludedFromDividends(account);
    }

    function uCW(uint256 newClaimWait) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "TRT: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "TRT: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getClaimWait() external view returns (uint256) {
        return claimWait;
    }

    function getMagnifiedDividendPerShare() external view returns (uint256) {
        return onRye.getMagnifiedDividend();
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(
        address _account
    )
        external
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length - lastProcessedIndex
                    : 0;
                iterationsUntilProcessed =
                    index +
                    int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = onRye.withdrawableDividendOf(account);
        totalDividends = onRye.accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime - block.timestamp
            : 0;
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }
        return block.timestamp - lastClaimTime >= claimWait;
    }

    function sb(
        address payable account,
        uint256 newBalance
    ) external onlyRole(CIEL_ROLE) {
        if (excludedFromDividends[account]) {
            return;
        }
        if (newBalance >= MIN_TOKEN_BALANCE_FOR_DIVIDENDS) {
            onRye._setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            onRye._setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
        if (autoProcessAccount) {
            _processAccount(account, true);
        }
    }

    function p(
        uint256 gas
    ) external onlyRole(CIEL_ROLE) returns (uint256, uint256, uint256) {
        //fix
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }
        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 claims = 0;
        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;
            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }
            address account = tokenHoldersMap.keys[_lastProcessedIndex];
            if (canAutoClaim(lastClaimTimes[account])) {
                if (_processAccount(payable(account), true)) {
                    claims++;
                }
            }
            iterations++;
            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed + gasLeft - newGasLeft;
            }
            gasLeft = newGasLeft;
        }
        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }

    function _processAccount(
        address payable account,
        bool automatic
    ) internal nonReentrant returns (bool) {
        uint256 amount = onRye._withdrawDividendOfUser(account);
        if (amount > 0) {
            address token = onRye._userCustomRewardToken(account);
            lastClaimTimes[account] = block.timestamp;
            emit Claim(token, account, amount, automatic);
            return true;
        }
        return false;
    }

    function pA(
        address payable account,
        bool automatic
    ) external onlyRole(CIEL_ROLE) returns (bool) {
        bool os = _processAccount(account, automatic);
        return os;
    }

    function getTotalPendingDividends() external view returns (uint256) {
        return onRye._getTotalPendingDividends();
    }

    function setTotalPendingDividends(
        uint256 newDividends
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        onRye.sTPD(newDividends);
    }
}