// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CommonStructs.sol";
import "../tokens/IWrapper.sol";
import "../checks/SignatureCheck.sol";


contract CommonBridge is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    // DEFAULT_ADMIN_ROLE can grants and revokes all roles below; Set to multisig (proxy contract address)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");  // can change tokens; unpause contract; change params like lockTime, minSafetyBlocks, ...
    bytes32 public constant RELAY_ROLE = keccak256("RELAY_ROLE");  // can submit transfers
    bytes32 public constant WATCHDOG_ROLE = keccak256("WATCHDOG_ROLE");  // can pause contract
    bytes32 public constant FEE_PROVIDER_ROLE = keccak256("FEE_PROVIDER_ROLE");  // fee signatures must be signed by this role

    // Signature contains timestamp divided by SIGNATURE_FEE_TIMESTAMP; SIGNATURE_FEE_TIMESTAMP should be the same on relay;
    uint private constant SIGNATURE_FEE_TIMESTAMP = 1800;  // 30 min
    // Signature will be valid for `SIGNATURE_FEE_TIMESTAMP` * `signatureFeeCheckNumber` seconds after creation
    uint internal signatureFeeCheckNumber;


    // queue of Transfers to be pushed in another network
    CommonStructs.Transfer[] queue;

    // locked transfers from another network
    mapping(uint => CommonStructs.LockedTransfers) public lockedTransfers;
    // head index of lockedTransfers 'queue' mapping
    uint public oldestLockedEventId;


    // this network to side network token addresses mapping
    mapping(address => address) public tokenAddresses;
    // token that implement `IWrapper` interface and used to wrap native coin
    address public wrapperAddress;

    // addresses that will receive fees
    address payable public transferFeeRecipient;
    address payable public bridgeFeeRecipient;

    address public sideBridgeAddress;  // transfer events from side networks must be created by this address
    uint public minSafetyBlocks;  // proof must contains at least `minSafetyBlocks` blocks after block with transfer
    uint public timeframeSeconds;  // `withdrawFinish` func will be produce Transfer event no more often than `timeframeSeconds`
    uint public lockTime;  // transfers received from side networks can be unlocked after `lockTime` seconds

    uint public inputEventId; // last processed event from side network
    uint public outputEventId;  // last created event in this network. start from 1 coz 0 consider already processed

    uint public lastTimeframe; // timestamp / `timeframeSeconds` of latest withdraw


    event Withdraw(address indexed from, uint eventId, address tokenFrom, address tokenTo, uint amount,
        uint transferFeeAmount, uint bridgeFeeAmount);
    event Transfer(uint indexed eventId, CommonStructs.Transfer[] queue);
    event TransferSubmit(uint indexed eventId);
    event TransferFinish(uint indexed eventId);

    function __CommonBridge_init(CommonStructs.ConstructorArgs calldata args) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(RELAY_ROLE, args.relayAddress);
        _setupRoles(WATCHDOG_ROLE, args.watchdogsAddresses);
        _setupRole(FEE_PROVIDER_ROLE, args.feeProviderAddress);

        // initialise tokenAddresses with start values
        _tokensAddBatch(args.tokenThisAddresses, args.tokenSideAddresses);
        wrapperAddress = args.wrappingTokenAddress;

        sideBridgeAddress = args.sideBridgeAddress;
        transferFeeRecipient = args.transferFeeRecipient;
        bridgeFeeRecipient = args.bridgeFeeRecipient;
        minSafetyBlocks = args.minSafetyBlocks;
        timeframeSeconds = args.timeframeSeconds;
        lockTime = args.lockTime;

        // 1, coz eventId 0 considered already processed
        oldestLockedEventId = 1;
        outputEventId = 1;

        signatureFeeCheckNumber = 3;

        lastTimeframe = block.timestamp / timeframeSeconds;
    }


    // `wrapWithdraw` function used for wrap some amount of native coins and send it to side network;
    /// @dev Amount to wrap is calculated by subtracting fees from msg.value; Use `wrapperAddress` token to wrap;

    /// @param toAddress Address in side network that will receive the tokens
    /// @param transferFee Amount (in native coins), payed to compensate gas fees in side network
    /// @param bridgeFee Amount (in native coins), payed as bridge earnings
    /// @param feeSignature Signature signed by relay that confirms that the fee values are valid
    function wrapWithdraw(address toAddress,
        bytes calldata feeSignature, uint transferFee, uint bridgeFee
    ) public payable {
        address tokenSideAddress = tokenAddresses[wrapperAddress];
        require(tokenSideAddress != address(0), "Unknown token address");

        require(msg.value > transferFee + bridgeFee, "Sent value <= fee");

        uint amount = msg.value - transferFee - bridgeFee;
        feeCheck(wrapperAddress, feeSignature, transferFee, bridgeFee, amount);
        transferFeeRecipient.transfer(transferFee);
        bridgeFeeRecipient.transfer(bridgeFee);

        IWrapper(wrapperAddress).deposit{value : amount}();

        //
        queue.push(CommonStructs.Transfer(tokenSideAddress, toAddress, amount));
        emit Withdraw(msg.sender, outputEventId, address(0), tokenSideAddress, amount, transferFee, bridgeFee);

        withdrawFinish();
    }

    // `withdraw` function used for sending tokens from this network to side network;
    /// @param tokenThisAddress Address of token [that will be transferred] in current network
    /// @param toAddress Address in side network that will receive the tokens
    /// @param amount Amount of tokens to be sent
    /** @param unwrapSide If true, user on side network will receive native network coin instead of ERC20 token.
     Transferred token MUST be wrapper of side network native coin (ex: WETH, if side net is Ethereum)
     `tokenAddresses[0x0] == tokenThisAddress` means that `tokenThisAddress` is thisNet analogue of wrapper token in sideNet
    */
    /// @param transferFee Amount (in native coins), payed to compensate gas fees in side network
    /// @param bridgeFee Amount (in native coins), payed as bridge earnings
    /// @param feeSignature Signature signed by relay that confirms that the fee values are valid
    function withdraw(
        address tokenThisAddress, address toAddress, uint amount, bool unwrapSide,
        bytes calldata feeSignature, uint transferFee, uint bridgeFee
    ) payable public {
        address tokenSideAddress;
        if (unwrapSide) {
            require(tokenAddresses[address(0)] == tokenThisAddress, "Token not point to native token");
            // tokenSideAddress will be 0x0000000000000000000000000000000000000000 - for native token
        } else {
            tokenSideAddress = tokenAddresses[tokenThisAddress];
            require(tokenSideAddress != address(0), "Unknown token address");
        }

        require(msg.value == transferFee + bridgeFee, "Sent value != fee");

        require(amount > 0, "Cannot withdraw 0");

        feeCheck(tokenThisAddress, feeSignature, transferFee, bridgeFee, amount);
        transferFeeRecipient.transfer(transferFee);
        bridgeFeeRecipient.transfer(bridgeFee);

        require(IERC20(tokenThisAddress).transferFrom(msg.sender, address(this), amount), "Fail transfer coins");

        queue.push(CommonStructs.Transfer(tokenSideAddress, toAddress, amount));
        emit Withdraw(msg.sender, outputEventId, tokenThisAddress, tokenSideAddress, amount, transferFee, bridgeFee);

        withdrawFinish();
    }

    // can be called to force emit `Transfer` event, without waiting for withdraw in next timeframe
    function triggerTransfers() public {
        require(queue.length != 0, "Queue is empty");

        emit Transfer(outputEventId++, queue);
        delete queue;
    }


    // after `lockTime` period, transfers can be unlocked
    function unlockTransfers(uint eventId) public whenNotPaused {
        require(eventId == oldestLockedEventId, "can unlock only oldest event");

        CommonStructs.LockedTransfers memory transfersLocked = lockedTransfers[eventId];
        require(transfersLocked.endTimestamp > 0, "no locked transfers with this id");
        require(transfersLocked.endTimestamp < block.timestamp, "lockTime has not yet passed");

        proceedTransfers(transfersLocked.transfers);

        delete lockedTransfers[eventId];
        emit TransferFinish(eventId);

        oldestLockedEventId = eventId + 1;
    }

    // optimized version of unlockTransfers that unlock all transfer that can be unlocked in one call
    function unlockTransfersBatch() public whenNotPaused {
        uint eventId = oldestLockedEventId;
        for (;; eventId++) {
            CommonStructs.LockedTransfers memory transfersLocked = lockedTransfers[eventId];
            if (transfersLocked.endTimestamp == 0 || transfersLocked.endTimestamp > block.timestamp) break;

            proceedTransfers(transfersLocked.transfers);

            delete lockedTransfers[eventId];
            emit TransferFinish(eventId);
        }
        oldestLockedEventId = eventId;
    }

    // delete transfers with passed eventId **and all after it**
    function removeLockedTransfers(uint eventId) public onlyRole(ADMIN_ROLE) whenPaused {
        require(eventId >= oldestLockedEventId, "eventId must be >= oldestLockedEventId");  // can't undo unlocked :(
        require(eventId <= inputEventId, "eventId must be <= inputEventId");

        // now waiting for submitting a new transfer with `eventId` id
        inputEventId = eventId - 1;

        for (; lockedTransfers[eventId].endTimestamp != 0; eventId++)
            delete lockedTransfers[eventId];

    }

    // pretend like bridge already receive and process all transfers up to `eventId` id
    // BIG WARNING: CAN'T BE UNDONE coz of security reasons
    function skipTransfers(uint eventId) public onlyRole(ADMIN_ROLE) whenPaused {
        require(eventId >= oldestLockedEventId, "eventId must be >= oldestLockedEventId"); // can't undo unlocked :(

        inputEventId = eventId - 1; // now waiting for submitting a new transfer with `eventId` id
        oldestLockedEventId = eventId;  // and no need to unlock previous transfers
    }


    // views

    // returns locked transfers from another network
    function getLockedTransfers(uint eventId) public view returns (CommonStructs.LockedTransfers memory) {
        return lockedTransfers[eventId];
    }


    function isQueueEmpty() public view returns (bool) {
        return queue.length == 0;
    }


    // admin setters
    function changeMinSafetyBlocks(uint minSafetyBlocks_) public onlyRole(ADMIN_ROLE) {
        minSafetyBlocks = minSafetyBlocks_;
    }

    function changeTransferFeeRecipient(address payable feeRecipient_) public onlyRole(ADMIN_ROLE) {
        transferFeeRecipient = feeRecipient_;
    }

    function changeBridgeFeeRecipient(address payable feeRecipient_) public onlyRole(ADMIN_ROLE) {
        bridgeFeeRecipient = feeRecipient_;
    }

    function changeTimeframeSeconds(uint timeframeSeconds_) public onlyRole(ADMIN_ROLE) {
        lastTimeframe = (lastTimeframe * timeframeSeconds) / timeframeSeconds_;
        timeframeSeconds = timeframeSeconds_;
    }

    function changeLockTime(uint lockTime_) public onlyRole(ADMIN_ROLE) {
        lockTime = lockTime_;
    }

    function changeSignatureFeeCheckNumber(uint signatureFeeCheckNumber_) public onlyRole(ADMIN_ROLE) {
        signatureFeeCheckNumber = signatureFeeCheckNumber_;
    }

    // token addressed mapping

    function tokensAdd(address tokenThisAddress, address tokenSideAddress) public onlyRole(ADMIN_ROLE) {
        tokenAddresses[tokenThisAddress] = tokenSideAddress;
    }

    function tokensRemove(address tokenThisAddress) public onlyRole(ADMIN_ROLE) {
        delete tokenAddresses[tokenThisAddress];
    }

    function tokensAddBatch(address[] calldata tokenThisAddresses, address[] calldata tokenSideAddresses) public onlyRole(ADMIN_ROLE) {
        _tokensAddBatch(tokenThisAddresses, tokenSideAddresses);
    }

    function _tokensAddBatch(address[] calldata tokenThisAddresses, address[] calldata tokenSideAddresses) private {
        require(tokenThisAddresses.length == tokenSideAddresses.length, "sizes of tokenThisAddresses and tokenSideAddresses must be same");
        uint arrayLength = tokenThisAddresses.length;
        for (uint i = 0; i < arrayLength; i++)
            tokenAddresses[tokenThisAddresses[i]] = tokenSideAddresses[i];
    }

    function tokensRemoveBatch(address[] calldata tokenThisAddresses) public onlyRole(ADMIN_ROLE) {
        uint arrayLength = tokenThisAddresses.length;
        for (uint i = 0; i < arrayLength; i++)
            delete tokenAddresses[tokenThisAddresses[i]];
    }

    // pause

    function pause() public onlyRole(WATCHDOG_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // roles

    function grantRoles(bytes32 role, address[] calldata accounts) public onlyRole(getRoleAdmin(role)) {
        // check permission to grant role via onlyRole(getRoleAdmin(role))
        _setupRoles(role, accounts);
    }
    function revokeRoles(bytes32 role, address[] calldata accounts) public {
        // revokeRole will check for permissions
        for (uint i = 0; i < accounts.length; i++)
            revokeRole(role, accounts[i]);
    }
    function _setupRoles(bytes32 role, address[] calldata accounts) internal {
        // no permissions check at all
        for (uint i = 0; i < accounts.length; i++)
            _setupRole(role, accounts[i]);
    }

    // internal

    // submitted transfers saves in `lockedTransfers` for `lockTime` period
    function lockTransfers(CommonStructs.Transfer[] calldata events, uint eventId) internal {
        lockedTransfers[eventId].endTimestamp = block.timestamp + lockTime;
        for (uint i = 0; i < events.length; i++)
            lockedTransfers[eventId].transfers.push(events[i]);
    }


    // sends money according to the information in the Transfer structure
    // if transfer.tokenAddress == 0x0, then it's transfer of `wrapperAddress` token with auto-unwrap to native coin
    function proceedTransfers(CommonStructs.Transfer[] memory transfers) internal {
        for (uint i = 0; i < transfers.length; i++) {

            if (transfers[i].tokenAddress == address(0)) {// native token
                IWrapper(wrapperAddress).withdraw(transfers[i].amount);
                payable(transfers[i].toAddress).transfer(transfers[i].amount);
            } else {// ERC20 token
                require(
                    IERC20(transfers[i].tokenAddress).transfer(transfers[i].toAddress, transfers[i].amount),
                    "Fail transfer coins");
            }

        }
    }

    // used by `withdraw` and `wrapWithdraw` functions;
    // emit `Transfer` event with current queue if timeframe was changed;
    function withdrawFinish() internal {
        uint nowTimeframe = block.timestamp / timeframeSeconds;
        if (nowTimeframe != lastTimeframe) {
            emit Transfer(outputEventId++, queue);
            delete queue;

            lastTimeframe = nowTimeframe;
        }
    }

    // encode message with received values and current timestamp;
    // check that signature is same message signed by address with RELAY_ROLE;
    // make `signatureFeeCheckNumber` attempts, each time decrementing timestampEpoch (workaround for old signature)
    function feeCheck(address token, bytes calldata signature, uint transferFee, uint bridgeFee, uint amount) internal view {
        bytes32 messageHash;
        address signer;
        uint timestampEpoch = block.timestamp / SIGNATURE_FEE_TIMESTAMP;

        for (uint i = 0; i < signatureFeeCheckNumber; i++) {
            messageHash = keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(token, timestampEpoch, transferFee, bridgeFee, amount))
                ));

            signer = ecdsaRecover(messageHash, signature);
            if (hasRole(FEE_PROVIDER_ROLE, signer))
                return;
            timestampEpoch--;
        }
        revert("Signature check failed");
    }

    function checkEventId(uint eventId) internal {
        require(eventId == ++inputEventId, "EventId out of order");
    }

    receive() external payable {}  // need to receive native token from wrapper contract

    uint256[15] private __gap;
}