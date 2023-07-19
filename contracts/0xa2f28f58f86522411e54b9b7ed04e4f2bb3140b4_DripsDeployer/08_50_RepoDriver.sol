// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {
    AccountMetadata, Drips, StreamReceiver, IERC20, SafeERC20, SplitsReceiver
} from "./Drips.sol";
import {DriverTransferUtils} from "./DriverTransferUtils.sol";
import {Managed} from "./Managed.sol";
import {ERC677ReceiverInterface} from "chainlink/interfaces/ERC677ReceiverInterface.sol";
import {LinkTokenInterface} from "chainlink/interfaces/LinkTokenInterface.sol";
import {OperatorInterface} from "chainlink/interfaces/OperatorInterface.sol";
import {BufferChainlink, CBORChainlink} from "chainlink/Chainlink.sol";
import {ShortString, ShortStrings} from "openzeppelin-contracts/utils/ShortStrings.sol";

/// @notice The supported forges where repositories are stored.
enum Forge {
    GitHub,
    GitLab
}

/// @notice A Drips driver implementing repository-based account identification.
/// Each repository stored in one of the supported forges has a deterministic account ID assigned.
/// By default the repositories have no owner and their accounts can't be controlled by anybody,
/// use `requestUpdateOwner` to update the owner.
contract RepoDriver is ERC677ReceiverInterface, DriverTransferUtils, Managed {
    using SafeERC20 for IERC20;
    using CBORChainlink for BufferChainlink.buffer;

    /// @notice The Drips address used by this driver.
    Drips public immutable drips;
    /// @notice The driver ID which this driver uses when calling Drips.
    uint32 public immutable driverId;
    /// @notice The Link token used for paying the operators.
    LinkTokenInterface public immutable linkToken;
    /// @notice The JSON path inside `FUNDING.json` where the account ID owner is stored.
    ShortString internal immutable jsonPath;

    /// @notice The ERC-1967 storage slot holding a single `RepoDriverStorage` structure.
    bytes32 private immutable _repoDriverStorageSlot = _erc1967Slot("eip1967.repoDriver.storage");
    /// @notice The ERC-1967 storage slot holding a single `RepoDriverAnyApiStorage` structure.
    bytes32 private immutable _repoDriverAnyApiStorageSlot =
        _erc1967Slot("eip1967.repoDriver.anyApi.storage");

    /// @notice Emitted when the AnyApi operator configuration is updated.
    /// @param operator The new address of the AnyApi operator.
    /// @param jobId The new AnyApi job ID used for requesting account owner updates.
    /// @param defaultFee The new fee in Link for each account owner.
    /// update request when the driver is covering the cost.
    event AnyApiOperatorUpdated(
        OperatorInterface indexed operator, bytes32 indexed jobId, uint96 defaultFee
    );

    /// @notice Emitted when the account ownership update is requested.
    /// @param accountId The ID of the account.
    /// @param forge The forge where the repository is stored.
    /// @param name The name of the repository.
    event OwnerUpdateRequested(uint256 indexed accountId, Forge forge, bytes name);

    /// @notice Emitted when the account ownership is updated.
    /// @param accountId The ID of the account.
    /// @param owner The new owner of the repository.
    event OwnerUpdated(uint256 indexed accountId, address owner);

    struct RepoDriverStorage {
        /// @notice The owners of the accounts.
        mapping(uint256 accountId => address) accountOwners;
    }

    struct RepoDriverAnyApiStorage {
        /// @notice The requested account owner updates.
        mapping(bytes32 requestId => uint256 accountId) requestedUpdates;
        /// @notice The new address of the AnyApi operator.
        OperatorInterface operator;
        /// @notice The fee in Link for each account owner.
        /// update request when the driver is covering the cost.
        uint96 defaultFee;
        /// @notice The AnyApi job ID used for requesting account owner updates.
        bytes32 jobId;
        /// @notice If false, the initial operator configuration is possible.
        bool isInitialized;
        /// @notice The AnyApi requests counter used as a nonce when calculating the request ID.
        uint248 nonce;
    }

    /// @param drips_ The Drips contract to use.
    /// @param forwarder The ERC-2771 forwarder to trust. May be the zero address.
    /// @param driverId_ The driver ID to use when calling Drips.
    constructor(Drips drips_, address forwarder, uint32 driverId_) DriverTransferUtils(forwarder) {
        drips = drips_;
        driverId = driverId_;
        string memory chainName;
        address _linkToken;
        if (block.chainid == 1) {
            chainName = "ethereum";
            _linkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        } else if (block.chainid == 5) {
            chainName = "goerli";
            _linkToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        } else if (block.chainid == 11155111) {
            chainName = "sepolia";
            _linkToken = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        } else {
            chainName = "other";
            _linkToken = address(bytes20("dummy link token"));
        }
        jsonPath = ShortStrings.toShortString(string.concat("drips,", chainName, ",ownedBy"));
        linkToken = LinkTokenInterface(_linkToken);
    }

    modifier onlyOwner(uint256 accountId) {
        require(_msgSender() == ownerOf(accountId), "Caller is not the account owner");
        _;
    }

    /// @notice Returns the address of the Drips contract to use for ERC-20 transfers.
    function _drips() internal view override returns (Drips) {
        return drips;
    }

    /// @notice Calculates the account ID.
    /// Every account ID is a 256-bit integer constructed by concatenating:
    /// `driverId (32 bits) | forgeId (8 bits) | nameEncoded (216 bits)`.
    /// When `forge` is GitHub and `name` is at most 27 bytes long,
    /// `forgeId` is 0 and `nameEncoded` is `name` right-padded with zeros
    /// When `forge` is GitHub and `name` is longer than 27 bytes,
    /// `forgeId` is 1 and `nameEncoded` is the lower 27 bytes of the hash of `name`.
    /// When `forge` is GitLab and `name` is at most 27 bytes long,
    /// `forgeId` is 2 and `nameEncoded` is `name` right-padded with zeros
    /// When `forge` is GitLab and `name` is longer than 27 bytes,
    /// `forgeId` is 3 and `nameEncoded` is the lower 27 bytes of the hash of `name`.
    /// @param forge The forge where the repository is stored.
    /// @param name The name of the repository.
    /// For GitHub and GitLab it must follow the `user_name/repository_name` structure
    /// and it must be formatted identically as in the repository's URL,
    /// including the case of each letter and special characters being removed.
    /// @return accountId The account ID.
    function calcAccountId(Forge forge, bytes memory name)
        public
        view
        returns (uint256 accountId)
    {
        uint8 forgeId;
        uint216 nameEncoded;
        if (forge == Forge.GitHub) {
            if (name.length <= 27) {
                forgeId = 0;
                nameEncoded = uint216(bytes27(name));
            } else {
                forgeId = 1;
                // `nameEncoded` is the lower 27 bytes of the hash
                nameEncoded = uint216(uint256(keccak256(name)));
            }
        } else {
            if (name.length <= 27) {
                forgeId = 2;
                nameEncoded = uint216(bytes27(name));
            } else {
                forgeId = 3;
                // `nameEncoded` is the lower 27 bytes of the hash
                nameEncoded = uint216(uint256(keccak256(name)));
            }
        }
        // By assignment we get `accountId` value:
        // `zeros (224 bits) | driverId (32 bits)`
        accountId = driverId;
        // By bit shifting we get `accountId` value:
        // `zeros (216 bits) | driverId (32 bits) | zeros (8 bits)`
        // By bit masking we get `accountId` value:
        // `zeros (216 bits) | driverId (32 bits) | forgeId (8 bits)`
        accountId = (accountId << 8) | forgeId;
        // By bit shifting we get `accountId` value:
        // `driverId (32 bits) | forgeId (8 bits) | zeros (216 bits)`
        // By bit masking we get `accountId` value:
        // `driverId (32 bits) | forgeId (8 bits) | nameEncoded (216 bits)`
        accountId = (accountId << 216) | nameEncoded;
    }

    /// @notice Initializes the AnyApi operator configuration.
    /// Callable only once, and only before any calls to `updateAnyApiOperator`.
    /// @param operator The initial address of the AnyApi operator.
    /// @param jobId The initial AnyApi job ID used for requesting account owner updates.
    /// @param defaultFee The initial fee in Link for each account owner.
    /// update request when the driver is covering the cost.
    function initializeAnyApiOperator(OperatorInterface operator, bytes32 jobId, uint96 defaultFee)
        public
        whenNotPaused
    {
        require(!_repoDriverAnyApiStorage().isInitialized, "Already initialized");
        _updateAnyApiOperator(operator, jobId, defaultFee);
    }

    /// @notice Updates the AnyApi operator configuration. Callable only by the admin.
    /// @param operator The new address of the AnyApi operator.
    /// @param jobId The new AnyApi job ID used for requesting account owner updates.
    /// @param defaultFee The new fee in Link for each account owner.
    /// update request when the driver is covering the cost.
    function updateAnyApiOperator(OperatorInterface operator, bytes32 jobId, uint96 defaultFee)
        public
        whenNotPaused
        onlyAdmin
    {
        _updateAnyApiOperator(operator, jobId, defaultFee);
    }

    /// @notice Updates the AnyApi operator configuration. Callable only by the admin.
    /// @param operator The new address of the AnyApi operator.
    /// @param jobId The new AnyApi job ID used for requesting account owner updates.
    /// @param defaultFee The new fee in Link for each account owner.
    /// update request when the driver is covering the cost.
    function _updateAnyApiOperator(OperatorInterface operator, bytes32 jobId, uint96 defaultFee)
        internal
    {
        RepoDriverAnyApiStorage storage storageRef = _repoDriverAnyApiStorage();
        storageRef.isInitialized = true;
        storageRef.operator = operator;
        storageRef.jobId = jobId;
        storageRef.defaultFee = defaultFee;
        emit AnyApiOperatorUpdated(operator, jobId, defaultFee);
    }

    /// @notice Gets the current AnyApi operator configuration.
    /// @return operator The address of the AnyApi operator.
    /// @return jobId The AnyApi job ID used for requesting account owner updates.
    /// @return defaultFee The fee in Link for each account owner.
    /// update request when the driver is covering the cost.
    function anyApiOperator()
        public
        view
        returns (OperatorInterface operator, bytes32 jobId, uint96 defaultFee)
    {
        RepoDriverAnyApiStorage storage storageRef = _repoDriverAnyApiStorage();
        operator = storageRef.operator;
        jobId = storageRef.jobId;
        defaultFee = storageRef.defaultFee;
    }

    /// @notice Gets the account owner.
    /// @param accountId The ID of the account.
    /// @return owner The owner of the account.
    function ownerOf(uint256 accountId) public view returns (address owner) {
        return _repoDriverStorage().accountOwners[accountId];
    }

    /// @notice Requests an update of the ownership of the account representing the repository.
    /// The actual update of the owner will be made in a future transaction.
    /// The driver will cover the fee in Link that must be paid to the operator.
    /// If you want to cover the fee yourself, use `onTokenTransfer`.
    ///
    /// The repository must contain a `FUNDING.json` file in the project root in the default branch.
    /// The file must be a valid JSON with arbitrary data, but it must contain the owner address
    /// as a hexadecimal string under `drips` -> `<CHAIN NAME>` -> `ownedBy`, a minimal example:
    /// `{ "drips": { "ethereum": { "ownedBy": "0x0123456789abcDEF0123456789abCDef01234567" } } }`.
    /// If the operator can't read the owner when processing the update request,
    /// it ignores the request and no change to the account ownership is made.
    /// @param forge The forge where the repository is stored.
    /// @param name The name of the repository.
    /// For GitHub and GitLab it must follow the `user_name/repository_name` structure
    /// and it must be formatted identically as in the repository's URL,
    /// including the case of each letter and special characters being removed.
    /// @return accountId The ID of the account.
    function requestUpdateOwner(Forge forge, bytes memory name)
        public
        whenNotPaused
        returns (uint256 accountId)
    {
        uint256 fee = _repoDriverAnyApiStorage().defaultFee;
        require(linkToken.balanceOf(address(this)) >= fee, "Link balance too low");
        return _requestUpdateOwner(forge, name, fee);
    }

    /// @notice The function called when receiving funds from ERC-677 `transferAndCall`.
    /// Only supports receiving Link tokens, callable only by the Link token smart contract.
    /// The only supported usage is requesting account ownership updates,
    /// the transferred tokens are then used for paying the AnyApi operator fee,
    /// see `requestUpdateOwner` for more details.
    /// The received tokens are never refunded, so make sure that
    /// the amount isn't too low to cover the fee, isn't too high and wasteful,
    /// and the repository's content is valid so its ownership can be verified.
    /// @param amount The transferred amount, it will be used as the AnyApi operator fee.
    /// @param data The `transferAndCall` payload.
    /// It must be a valid ABI-encoded calldata for `requestUpdateOwner`.
    /// The call parameters will be used the same way as when calling `requestUpdateOwner`,
    /// to determine which account's ownership update is requested.
    function onTokenTransfer(address, /* sender */ uint256 amount, bytes calldata data)
        public
        whenNotPaused
    {
        require(msg.sender == address(linkToken), "Callable only by the Link token");
        require(data.length >= 4, "Data not a valid calldata");
        require(bytes4(data[:4]) == this.requestUpdateOwner.selector, "Data not requestUpdateOwner");
        (Forge forge, bytes memory name) = abi.decode(data[4:], (Forge, bytes));
        _requestUpdateOwner(forge, name, amount);
    }

    /// @notice Requests an update of the ownership of the account representing the repository.
    /// See `requestUpdateOwner` for more details.
    /// @param forge The forge where the repository is stored.
    /// @param name The name of the repository.
    /// @param fee The fee in Link to pay for the request.
    /// @return accountId The ID of the account.
    function _requestUpdateOwner(Forge forge, bytes memory name, uint256 fee)
        internal
        returns (uint256 accountId)
    {
        RepoDriverAnyApiStorage storage storageRef = _repoDriverAnyApiStorage();
        address operator = address(storageRef.operator);
        require(operator != address(0), "Operator address not set");
        uint256 nonce = storageRef.nonce++;
        bytes32 requestId = keccak256(abi.encodePacked(this, nonce));
        accountId = calcAccountId(forge, name);
        storageRef.requestedUpdates[requestId] = accountId;
        bytes memory payload = _requestPayload(forge, name);
        bytes memory callData = abi.encodeCall(
            OperatorInterface.operatorRequest,
            (
                address(0), // ignored, will be replaced in the operator with this contract address
                0, // ignored, will be replaced in the operator with the fee
                storageRef.jobId,
                this.updateOwnerByAnyApi.selector,
                nonce,
                2, // data version
                payload
            )
        );
        require(linkToken.transferAndCall(operator, fee, callData), "Transfer and call failed");
        // slither-disable-next-line reentrancy-events
        emit OwnerUpdateRequested(accountId, forge, name);
    }

    /// @notice Builds the AnyApi generic `bytes` fetching request payload.
    /// It instructs the operator to fetch the current owner of the account.
    /// @param forge The forge where the repository is stored.
    /// @param name The name of the repository.
    /// @return payload The AnyApi request payload.
    function _requestPayload(Forge forge, bytes memory name)
        internal
        view
        returns (bytes memory payload)
    {
        // slither-disable-next-line uninitialized-local
        BufferChainlink.buffer memory buffer;
        buffer = BufferChainlink.init(buffer, 256);
        buffer.encodeString("get");
        buffer.encodeString(_requestUrl(forge, name));
        buffer.encodeString("path");
        buffer.encodeString(ShortStrings.toString(jsonPath));
        return buffer.buf;
    }

    /// @notice Builds the URL for fetch the `FUNDING.json` file for the given repository.
    /// @param forge The forge where the repository is stored.
    /// @param name The name of the repository.
    /// @return url The built URL.
    function _requestUrl(Forge forge, bytes memory name)
        internal
        pure
        returns (string memory url)
    {
        if (forge == Forge.GitHub) {
            return string.concat(
                "https://raw.githubusercontent.com/", string(name), "/HEAD/FUNDING.json"
            );
        } else if (forge == Forge.GitLab) {
            return string.concat("https://gitlab.com/", string(name), "/-/raw/HEAD/FUNDING.json");
        } else {
            revert("Unsupported forge");
        }
    }

    /// @notice Updates the account owner. Callable only by the AnyApi operator.
    /// @param requestId The ID of the AnyApi request.
    /// Must be the same as the request ID generated when requesting an owner update,
    /// this function will update the account ownership that was requested back then.
    /// @param ownerRaw The new owner of the account. Must be a 20 bytes long address.
    function updateOwnerByAnyApi(bytes32 requestId, bytes calldata ownerRaw) public whenNotPaused {
        RepoDriverAnyApiStorage storage storageRef = _repoDriverAnyApiStorage();
        require(msg.sender == address(storageRef.operator), "Callable only by the operator");
        uint256 accountId = storageRef.requestedUpdates[requestId];
        require(accountId != 0, "Unknown request ID");
        delete storageRef.requestedUpdates[requestId];
        require(ownerRaw.length == 20, "Invalid owner length");
        address owner = address(bytes20(ownerRaw));
        _repoDriverStorage().accountOwners[accountId] = owner;
        emit OwnerUpdated(accountId, owner);
    }

    /// @notice Collects the account's received already split funds
    /// and transfers them out of the Drips contract.
    /// @param accountId The ID of the collecting account.
    /// The caller must be the owner of the account.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param transferTo The address to send collected funds to
    /// @return amt The collected amount
    function collect(uint256 accountId, IERC20 erc20, address transferTo)
        public
        whenNotPaused
        onlyOwner(accountId)
        returns (uint128 amt)
    {
        amt = drips.collect(accountId, erc20);
        if (amt > 0) drips.withdraw(erc20, transferTo, amt);
    }

    /// @notice Gives funds from the account to the receiver.
    /// The receiver can split and collect them immediately.
    /// Transfers the funds to be given from the message sender's wallet to the Drips contract.
    /// @param accountId The ID of the giving account. The caller must be the owner of the account.
    /// @param receiver The receiver account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param amt The given amount
    function give(uint256 accountId, uint256 receiver, IERC20 erc20, uint128 amt)
        public
        whenNotPaused
        onlyOwner(accountId)
    {
        _giveAndTransfer(accountId, receiver, erc20, amt);
    }

    /// @notice Sets the account's streams configuration.
    /// Transfers funds between the message sender's wallet and the Drips contract
    /// to fulfil the change of the streams balance.
    /// @param accountId The ID of the configured account.
    /// The caller must be the owner of the account.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The current streams receivers list.
    /// It must be exactly the same as the last list set for the account with `setStreams`.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The streams balance change to be applied.
    /// Positive to add funds to the streams balance, negative to remove them.
    /// @param newReceivers The list of the streams receivers of the sender to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @param maxEndHint1 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The first hint for finding the maximum end time when all streams stop due to funds
    /// running out after the balance is updated and the new receivers list is applied.
    /// Hints have no effect on the results of calling this function, except potentially saving gas.
    /// Hints are Unix timestamps used as the starting points for binary search for the time
    /// when funds run out in the range of timestamps from the current block's to `2^32`.
    /// Hints lower than the current timestamp are ignored.
    /// You can provide zero, one or two hints. The order of hints doesn't matter.
    /// Hints are the most effective when one of them is lower than or equal to
    /// the last timestamp when funds are still streamed, and the other one is strictly larger
    /// than that timestamp,the smaller the difference between such hints, the higher gas savings.
    /// The savings are the highest possible when one of the hints is equal to
    /// the last timestamp when funds are still streamed, and the other one is larger by 1.
    /// It's worth noting that the exact timestamp of the block in which this function is executed
    /// may affect correctness of the hints, especially if they're precise.
    /// Hints don't provide any benefits when balance is not enough to cover
    /// a single second of streaming or is enough to cover all streams until timestamp `2^32`.
    /// Even inaccurate hints can be useful, and providing a single hint
    /// or two hints that don't enclose the time when funds run out can still save some gas.
    /// Providing poor hints that don't reduce the number of binary search steps
    /// may cause slightly higher gas usage than not providing any hints.
    /// @param maxEndHint2 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The second hint for finding the maximum end time, see `maxEndHint1` docs for more details.
    /// @param transferTo The address to send funds to in case of decreasing balance
    /// @return realBalanceDelta The actually applied streams balance change.
    function setStreams(
        uint256 accountId,
        IERC20 erc20,
        StreamReceiver[] calldata currReceivers,
        int128 balanceDelta,
        StreamReceiver[] calldata newReceivers,
        // slither-disable-next-line similar-names
        uint32 maxEndHint1,
        uint32 maxEndHint2,
        address transferTo
    ) public whenNotPaused onlyOwner(accountId) returns (int128 realBalanceDelta) {
        return _setStreamsAndTransfer(
            accountId,
            erc20,
            currReceivers,
            balanceDelta,
            newReceivers,
            maxEndHint1,
            maxEndHint2,
            transferTo
        );
    }

    /// @notice Sets the account splits configuration.
    /// The configuration is common for all ERC-20 tokens.
    /// Nothing happens to the currently splittable funds, but when they are split
    /// after this function finishes, the new splits configuration will be used.
    /// Because anybody can call `split` on `Drips`, calling this function may be frontrun
    /// and all the currently splittable funds will be split using the old splits configuration.
    /// @param accountId The ID of the configured account.
    /// The caller must be the owner of the account.
    /// @param receivers The list of the account's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the account.
    /// If the sum of weights of all receivers is less than `_TOTAL_SPLITS_WEIGHT`,
    /// some funds won't be split, but they will be left for the account to collect.
    /// It's valid to include the account's own `accountId` in the list of receivers,
    /// but funds split to themselves return to their splittable balance and are not collectable.
    /// This is usually unwanted, because if splitting is repeated,
    /// funds split to themselves will be again split using the current configuration.
    /// Splitting 100% to self effectively blocks splitting unless the configuration is updated.
    function setSplits(uint256 accountId, SplitsReceiver[] calldata receivers)
        public
        whenNotPaused
        onlyOwner(accountId)
    {
        drips.setSplits(accountId, receivers);
    }

    /// @notice Emits the account's metadata.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @param accountId The ID of the emitting account.
    /// The caller must be the owner of the account.
    /// @param accountMetadata The list of account metadata.
    function emitAccountMetadata(uint256 accountId, AccountMetadata[] calldata accountMetadata)
        public
        whenNotPaused
        onlyOwner(accountId)
    {
        if (accountMetadata.length == 0) return;
        drips.emitAccountMetadata(accountId, accountMetadata);
    }

    /// @notice Returns the RepoDriver storage.
    /// @return storageRef The storage.
    function _repoDriverStorage() internal view returns (RepoDriverStorage storage storageRef) {
        bytes32 slot = _repoDriverStorageSlot;
        // slither-disable-next-line assembly
        assembly {
            storageRef.slot := slot
        }
    }

    /// @notice Returns the RepoDriver storage specific to AnyApi.
    /// @return storageRef The storage.
    function _repoDriverAnyApiStorage()
        internal
        view
        returns (RepoDriverAnyApiStorage storage storageRef)
    {
        bytes32 slot = _repoDriverAnyApiStorageSlot;
        // slither-disable-next-line assembly
        assembly {
            storageRef.slot := slot
        }
    }
}