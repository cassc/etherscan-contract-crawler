// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./helpers.sol";

contract InstaAutomationHelper is Helpers {
    using SafeERC20 for IERC20;

    constructor(address aavePoolAddressesProvider_, address instaList_)
        Helpers(aavePoolAddressesProvider_, instaList_)
    {}

    modifier onlyOwner() {
        require(msg.sender == _owner, "not-an-owner");
        _;
    }

    modifier onlyExecutor() {
        require(_executors[msg.sender], "not-an-executor");
        _;
    }

    modifier onlyDSA(address user_) {
        require(instaList.accountID(user_) != 0, "not-a-dsa");
        _;
    }

    function changeOwner(address newOwner_) public onlyOwner {
        require(newOwner_ != address(0), "invalid-owner");
        require(newOwner_ != _owner, "same-owner");

        address[] memory owners_ = new address[](2);
        bool[] memory status_ = new bool[](2);

        (owners_[0], owners_[1]) = (_owner, newOwner_);
        (status_[0], status_[1]) = (false, true);
        _executors[_owner] = false;
        _executors[newOwner_] = true;

        _owner = newOwner_;
        emit LogChangedOwner(owners_[0], owners_[1]);
        emit LogFlippedExecutors(owners_, status_);
    }

    function flipExecutor(address[] memory executor_, bool[] memory status_)
        public
        onlyOwner
    {
        uint256 length_ = executor_.length;
        for (uint256 i; i < length_; i++) {
            require(
                executor_[i] != _owner,
                "owner-cant-be-removed-as-executor"
            );
            _executors[executor_[i]] = status_[i];
        }
        emit LogFlippedExecutors(executor_, status_);
    }

    function updateBufferHf(uint128 newBufferHf_) public onlyOwner {
        emit LogUpdatedBufferHf(_bufferHf, newBufferHf_);
        _bufferHf = newBufferHf_;
    }

    function updateMinimunHf(uint128 newMinimumThresholdHf_) public onlyOwner {
        emit LogUpdatedMinHf(_minimumThresholdHf, newMinimumThresholdHf_);
        _minimumThresholdHf = newMinimumThresholdHf_;
    }

    function updateAutomationFee(uint16 newAutomationFee_) public onlyOwner {
        emit LogUpdatedAutomationFee(_automationFee, newAutomationFee_);
        _automationFee = newAutomationFee_;
    }

    function transferFee(address[] memory tokens_, address recipient_)
        public
        onlyOwner
    {
        uint256 length_ = tokens_.length;
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        uint256[] memory amounts_ = new uint256[](length_);
        for (uint256 i; i < length_; i++) {
            bool isNative = tokens_[i] == native;
            uint256 amount_;
            if (isNative) {
                amount_ = address(this).balance;
                (bool sent, ) = recipient_.call{value: amount_}("");
                require(sent, "native-token-transfer-failed");
            } else {
                amount_ = IERC20(tokens_[i]).balanceOf(address(this));
                IERC20(tokens_[i]).safeTransfer(recipient_, amount_);
            }
            amounts_[i] = amount_;
        }

        emit LogFeeTransferred(recipient_, tokens_, amounts_);
    }

    function systemCall(string calldata actionId_, bytes memory metadata_)
        public
        onlyExecutor
    {
        emit LogSystemCall(msg.sender, actionId_, metadata_);
    }
}

contract InstaAaveV2AutomationImplementation is InstaAutomationHelper {
    constructor(address aavePoolAddressesProvider_, address instaList_)
        InstaAutomationHelper(aavePoolAddressesProvider_, instaList_)
    {}

    function initialize(
        address owner_,
        uint16 automationFee_,
        uint128 minimumThresholdHf_,
        uint128 bufferHf_
    ) public {
        require(_status == 0, "already-initialized");
        _status = 1;
        _owner = owner_;
        _minimumThresholdHf = minimumThresholdHf_;
        _bufferHf = bufferHf_;
        _automationFee = automationFee_;
        _id = 1;

        _executors[owner_] = true;
    }

    function submitAutomationRequest(
        uint256 safeHealthFactor_,
        uint256 thresholdHealthFactor_
    ) external onlyDSA(msg.sender) {
        require(
            safeHealthFactor_ < type(uint72).max,
            "safe-health-factor-too-large"
        );
        require(
            thresholdHealthFactor_ < safeHealthFactor_ &&
                thresholdHealthFactor_ >= _minimumThresholdHf,
            "thresholdHealthFactor-out-of-range"
        );

        uint32 userLatestId = _userLatestId[msg.sender];
        require(
            userLatestId == 0 ||
                _userAutomationConfigs[userLatestId].status != Status.AUTOMATED,
            "position-already-in-protection"
        );

        uint256 healthFactor_ = getHealthFactor(msg.sender);
        require(
            healthFactor_ < type(uint128).max,
            "current-health-factor-too-large-for-automation-request"
        );

        emit LogSubmittedAutomation(
            msg.sender,
            _id,
            uint128(safeHealthFactor_),
            uint128(thresholdHealthFactor_),
            uint128(healthFactor_)
        );

        _userAutomationConfigs[_id] = Automation({
            user: msg.sender,
            nonce: 0,
            status: Status.AUTOMATED,
            safeHF: uint128(safeHealthFactor_),
            thresholdHF: uint128(thresholdHealthFactor_)
        });

        _userLatestId[msg.sender] = _id;
        _id++;
    }

    function _cancelAutomation(
        address user_,
        uint8 errorCode_,
        uint32 id_,
        bool isSystem_
    ) internal onlyDSA(user_) {
        require(_userLatestId[user_] == id_, "not-valid-id");
        Automation storage _userAutomationConfig = _userAutomationConfigs[id_];

        require(
            user_ != address(0) && _userAutomationConfig.user == user_,
            "automation-user-not-valid"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        if (isSystem_) {
            emit LogSystemCancelledAutomation(
                user_,
                id_,
                _userAutomationConfig.nonce,
                errorCode_
            );
            _userAutomationConfig.status = Status.DROPPED;
        } else {
            emit LogCancelledAutomation(
                user_,
                id_,
                _userAutomationConfig.nonce
            );
            _userAutomationConfig.status = Status.CANCELLED;
        }
        _userLatestId[user_] = 0;
    }

    function cancelAutomationRequest() external {
        _cancelAutomation(msg.sender, 0, _userLatestId[msg.sender], false);
    }

    function systemCancel(
        address[] memory users_,
        uint32[] memory ids_,
        uint8[] memory errorCodes_
    ) external onlyExecutor {
        uint256 length_ = users_.length;
        require(length_ == ids_.length, "invalid-inputs");
        require(length_ == errorCodes_.length, "invalid-inputs");

        for (uint256 i; i < length_; i++)
            _cancelAutomation(users_[i], errorCodes_[i], ids_[i], true);
    }

    function executeAutomation(
        address user_,
        uint32 id_,
        uint32 nonce_,
        bool onCastRevert_,
        ExecutionParams memory params_,
        bytes calldata metadata_
    ) external onlyDSA(user_) onlyExecutor {
        require(_userLatestId[user_] == id_, "not-valid-id");
        Automation storage _userAutomationConfig = _userAutomationConfigs[id_];

        require(
            user_ != address(0) && _userAutomationConfig.user == user_,
            "automation-user-not-valid"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "canceled-or-dropped"
        );

        require(_userAutomationConfig.nonce == nonce_, "not-valid-nonce");

        Spell memory spells_ = _buildSpell(params_);

        uint128 initialHf_ = uint128(getHealthFactor(user_));

        require(
            ((_userAutomationConfig.thresholdHF + _bufferHf) >= initialHf_) ||
                (
                    (_userAutomationConfig.safeHF >= (initialHf_ + _bufferHf) &&
                        _userAutomationConfig.nonce > 0)
                ),
            "position-not-ready-for-automation"
        );

        bool success_ = cast(AccountInterface(user_), spells_);

        if (!success_) {
            if (!onCastRevert_)
                emit LogExecutionFailedAutomation(
                    user_,
                    id_,
                    nonce_,
                    params_,
                    metadata_,
                    initialHf_
                );
            else revert("automation-cast-failed");
        } else {
            uint128 finalHf_ = uint128(getHealthFactor(user_));

            require(
                finalHf_ > initialHf_,
                "automation-failed: Final-Health-Factor <= Initial-Health-factor"
            );

            bool isSafe_ = finalHf_ >=
                (_userAutomationConfig.safeHF - _bufferHf);

            params_.swap.callData = "0x"; // Making it 0x, so it will reduce gas cost for event emission

            emit LogExecutedAutomation(
                user_,
                id_,
                nonce_,
                params_,
                isSafe_,
                _automationFee,
                metadata_,
                finalHf_,
                initialHf_
            );
        }
        _userAutomationConfig.nonce++;
    }
}