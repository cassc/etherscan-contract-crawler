// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Interfaces
import "./interfaces/IReputationManager.sol";
import "./interfaces/ITellerV2.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// Libraries
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ReputationManager is IReputationManager, Initializable {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant CONTROLLER = keccak256("CONTROLLER");

    ITellerV2 public tellerV2;
    mapping(address => EnumerableSet.UintSet) private _delinquencies;
    mapping(address => EnumerableSet.UintSet) private _defaults;
    mapping(address => EnumerableSet.UintSet) private _currentDelinquencies;
    mapping(address => EnumerableSet.UintSet) private _currentDefaults;

    event MarkAdded(
        address indexed account,
        RepMark indexed repMark,
        uint256 bidId
    );
    event MarkRemoved(
        address indexed account,
        RepMark indexed repMark,
        uint256 bidId
    );

    /**
     * @notice Initializes the proxy.
     */
    function initialize(address _tellerV2) external initializer {
        tellerV2 = ITellerV2(_tellerV2);
    }

    function getDelinquentLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _delinquencies[_account].values();
    }

    function getDefaultedLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _defaults[_account].values();
    }

    function getCurrentDelinquentLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _currentDelinquencies[_account].values();
    }

    function getCurrentDefaultLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _currentDefaults[_account].values();
    }

    function updateAccountReputation(address _account) public override {
        uint256[] memory activeBidIds = tellerV2.getBorrowerActiveLoanIds(
            _account
        );
        for (uint256 i; i < activeBidIds.length; i++) {
            _applyReputation(_account, activeBidIds[i]);
        }
    }

    function updateAccountReputation(address _account, uint256 _bidId)
        public
        override
        returns (RepMark)
    {
        return _applyReputation(_account, _bidId);
    }

    function _applyReputation(address _account, uint256 _bidId)
        internal
        returns (RepMark mark_)
    {
        mark_ = RepMark.Good;

        if (tellerV2.isLoanDefaulted(_bidId)) {
            mark_ = RepMark.Default;

            // Remove delinquent status
            _removeMark(_account, _bidId, RepMark.Delinquent);
        } else if (tellerV2.isPaymentLate(_bidId)) {
            mark_ = RepMark.Delinquent;
        }

        // Mark status if not "Good"
        if (mark_ != RepMark.Good) {
            _addMark(_account, _bidId, mark_);
        }
    }

    function _addMark(
        address _account,
        uint256 _bidId,
        RepMark _mark
    ) internal {
        if (_mark == RepMark.Delinquent) {
            _delinquencies[_account].add(_bidId);
            _currentDelinquencies[_account].add(_bidId);
        } else if (_mark == RepMark.Default) {
            _defaults[_account].add(_bidId);
            _currentDefaults[_account].add(_bidId);
        }

        emit MarkAdded(_account, _mark, _bidId);
    }

    function _removeMark(
        address _account,
        uint256 _bidId,
        RepMark _mark
    ) internal {
        if (_mark == RepMark.Delinquent) {
            _currentDelinquencies[_account].remove(_bidId);
        } else if (_mark == RepMark.Default) {
            _currentDefaults[_account].remove(_bidId);
        }

        emit MarkRemoved(_account, _mark, _bidId);
    }
}