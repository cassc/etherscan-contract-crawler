// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFuture } from "./interfaces/IFuture.sol";
import { Treasury } from "./Treasury.sol";
import { IDetailedERC20 } from "./interfaces/IDetailedERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract Core is Ownable{
    using SafeERC20 for IERC20;
    address public immutable treasuryAddress;

    // supported protocols
    struct LendingProtocol {
        bool isSupported;
        bool isLP;
    }

    // mapping for supported protocols
    mapping(bytes32 => LendingProtocol) public supportedProtocols;

    uint256 internal constant MAX_UINT = 2**256 - 1;

    /**
     * @dev stores a future stream, all users subscribed to stream will be rolled over
     * to the next one as more futures are created
     *
     * eg: we start with AAVE ADAI 30 day future with index 1
     * the map stores keccak(protocol, underlying, period) to array of all futures created sorted by creation.
     * the last element of the stream is the current active future for a specific platform, duration, underlying
     */
    mapping(bytes32 => address[]) public streams;

    /**
     * @dev checks if an epoch has expired
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future to be checked
     */
    modifier isEpochExpired(bytes32 _streamKey, uint256 _epoch) {
        revertNonExistentStream(_streamKey);
        address epochAddress = streams[_streamKey][_epoch];
        require(IFuture(epochAddress).expired(), "ERR_EPOCH_NOT_EXPIRED");
        _;
    }

    /**
     * @dev checks if a protocol is supported or not
     * @param _protocol: The identifier of the protocol
     */
    modifier supportedProtocol(string memory _protocol) {
        bytes32 protocolHash = keccak256(abi.encode(_protocol));
        require(supportedProtocols[protocolHash].isSupported, "ERR_UNSUPPORTED_PROTOCOL");
        _;
    }

    event NewStream(address underlying, string protocol, uint256 durationSeconds, bytes32 streamKey);
    event EpochStarted(bytes32 streamKey, uint256 futureIndex);
    event EpochExpired(bytes32 streamKey, uint256 futureIndex);
    event Deposited(bytes32 streamKey, address user, uint256 amount, uint256 EpochId);
    event PrincipleRedeemed(bytes32 streamKey, address user, uint256 epoch, uint256 amount);
    event YieldRedeemed(bytes32 streamKey, address user, uint256 epoch, uint256 amount);

    /**
     * @dev We set the immutables on contract creation such as owner.
     * @notice We also create the treasury and set its address to immutable
     */
    constructor() {
        treasuryAddress = address(new Treasury());
    }

    /**
     * @dev To check whether a protocol is an Lp protocol(underlying is an LP token).
     * @param _protocol keccak256 format of a protocl string like "AAVE"/"UNISWAP".
     */
    function isLpProtocol(bytes32 _protocol) public view virtual returns(bool) {
        return supportedProtocols[_protocol].isLP;
    }

    ///// PROTOCOL ADMINISTRATION

    /**
     * @dev add support for new protocols controlled by owner
     *
     * @param _protocol: name of the protocol to add. eg - AAVE/COMP
     * @param _isLP: True, if the protocol is an LP token
     */
    function addProtocol(string memory _protocol, bool _isLP) external onlyOwner {
        require(!supportedProtocols[keccak256(abi.encode(_protocol))].isSupported, "ERR_PROTOCOL_ALREADY_SUPPORTED");

        supportedProtocols[keccak256(abi.encode(_protocol))] = LendingProtocol(true, _isLP);
    }

    /**
     * @dev creates a new stream of future and creates the first epoch.
     *
     * each stream can contain multiple epochs of futures but the futures can only
     * be present serially. it means that a new epoch in a stream
     * can only be created after the ongoing epoch expires.
     *
     * ============ STREAM 1 (7 day)=================>
     *          |          |          |          |
     * epoch 0  | epoch 1  | epoch 2  | epoch 3  |
     *          |          |          |          |
     *===============================================>
     *
     *
     * ============ STREAM 2 (30 day)================>
     *          |          |          |          |
     * epoch 0  | epoch 1  | epoch 2  | epoch 3  |
     *          |          |          |          |
     *===============================================>
     *
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     */
    function registerNewStream(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds,
        bytes memory _bytecode,
        bytes memory _extraData
    ) external onlyOwner supportedProtocol(_protocol) {
        require(_underlying != address(0), "ERR_INVALID_ADDRESS_ZERO");
        require(_durationSeconds > 0, "ERR_INVALID_DURATION_ZERO");
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);
        // check if there is already an existing stream for the given meta
        // if it exists then cannot create a new stream with same params
        require(!isStreamInitialized(streamKey), "ERR_STREAM_ALREADY_EXISTS");
        // add the genesis future in treasury
        createNewEpoch(_protocol, _underlying, _durationSeconds, 0, _bytecode, _extraData);

        emit NewStream(_underlying, _protocol, _durationSeconds, streamKey);
    }

    /**
     * @dev initializes a future epoch and enables users to interact with it
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     */
    function startEpoch(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds,
        bytes memory _bytecode,
        bytes memory _extraData
    ) external supportedProtocol(_protocol) onlyOwner {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);

        // check if stream exists (ie: has a 0th epoch)
        revertNonExistentStream(streamKey);

        address currentEpochAddress = getEpochAddress(streamKey, getCurrentEpoch(streamKey));
        require(IFuture(currentEpochAddress).expiry() < block.timestamp, "ERR_STREAM_CONTAINS_ACTIVE_EPOCH");

        // create New Future Epoch
        createNewEpoch(_protocol, _underlying, _durationSeconds, 0, _bytecode, _extraData);
    }

    /**
     * @dev updates the treasury linked to the particular stream such that it marks
     * the previous epoch as expired and the balances becomes claimabale.
     *
     * @param _streamKey: name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: index of the expired instance of future in a stream
     * @param _epochAddress: address of the expired future instance
     */
    function expireEpoch(
        bytes32 _streamKey,
        uint256 _epoch,
        address _epochAddress
    ) external {
        require(!IFuture(_epochAddress).expired(), "ERR_EPOCH_EXPIRED");
        // check if the previous epoch has ended before adding a new one
        Treasury treasury = Treasury(treasuryAddress);
        // expiring previous Ifuture and renew treasury
        treasury.renew(_streamKey, _epoch, _epochAddress);
        emit EpochExpired(_streamKey, _epoch);
    }

    /**
     * @dev uses future factory to deploy a new future epoch based
     * on the the provided params. uses the treasury to transfer the leftover
     * amount from previous epoch to fund the new future
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _amountSubscribedInUnderlying: amount subscribed in underlying protocol.
     * @notice the amount subscribed in underlying is 0 for 0th epoch.
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     */
    function createNewEpoch(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds,
        uint256 _amountSubscribedInUnderlying,
        bytes memory _bytecode,
        bytes memory _extraData
    ) internal {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);

        uint256 nextEpoch = getNextEpoch(streamKey);
        address _treasuryAddress = treasuryAddress;

        // use contract factory to deploy a new future instance based on params
        address newEpochAddr =
            _getDeterministicEpoch(_protocol, _underlying, _treasuryAddress, _durationSeconds, _bytecode, _extraData);

        // check if the owner of the newly created future is our contract only
        require(IFuture(newEpochAddr).owner() == address(this), "ERR_INVALID_EPOCH");
        // if the newly created epoch is 0th, then get IBT symbol
        // for creating the new treasury stream
        if (nextEpoch == 0) {
            string memory interestBearingSymbol =
                IDetailedERC20(IFuture(newEpochAddr).getInterestBearingToken()).symbol();
            require(bytes(interestBearingSymbol).length > 0, "ERR_NO_SYMBOL");
            Treasury(_treasuryAddress).createNewTreasuryStream(
                _protocol,
                _underlying,
                _durationSeconds
            );
        }
        // while starting don't have to transfer funds
        // from previous epoch to new epoch
        // pull funds from treasury to this contract
        Treasury(_treasuryAddress).fundAndKickOffEpoch(
            _protocol,
            newEpochAddr,
            _durationSeconds,
            _amountSubscribedInUnderlying,
            getNextEpoch(streamKey)
        );

        // push the newly created epoch into stream's epoch array
        streams[streamKey].push(newEpochAddr);
        emit EpochStarted(streamKey, nextEpoch);
    }

    /**
     * @dev We need to create a new future with given params and
     * we need a determinsitic address for it.
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _treasuryAddress: the address of the treasury
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     * @return address of the newly created future
     */
    function _getDeterministicEpoch(
        string memory _protocol,
        address _underlying,
        address _treasuryAddress,
        uint256 _durationSeconds,
        bytes memory _bytecode,
        bytes memory _extraData
    ) internal returns (address) {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);
        uint256 epoch = getCurrentEpoch(streamKey);

        bytes32 salt =
            keccak256(
                abi.encodePacked(
                    address(this),
                    _protocol,
                    _underlying,
                    _durationSeconds,
                    _treasuryAddress,
                    epoch,
                    _extraData
                )
            );

        address addr;
        assembly {
            addr := create2(0, add(_bytecode, 0x20), mload(_bytecode), salt)
        }
        return addr;
    }

    ///// USER-PROTOCOL INTERACTION

    /**
     * @dev receives underlying token from user and puts inside the Epoch
     * the user recieves the appropriate amount of OT and YT in return
     *
     * @param _streamKey: name of the stream, created by hashing protocol, underlying, duration
     * @param _amountUnderlying: the quantity of underlying tokens user wishes to deposit
     * @return amount of OT minted
     * @return amount of underlying
    */

    function deposit(bytes32 _streamKey, uint256 _amountUnderlying) external returns (uint256, uint256) {
        // check if stream key exists
        revertNonExistentStream(_streamKey);
        address _treasuryAddress = treasuryAddress;

        // transfer underlying from the caller to treasury
        uint256 currentEpochId = getCurrentEpoch(_streamKey);
        IFuture currentEpoch = IFuture(getEpochAddress(_streamKey, currentEpochId));

        // get the yield
        uint256 yield = currentEpoch.yield();
        uint256 amountOT = 0;

        // calculate the amount of OT to be distributed using the yield
        if (yield > 0 && !isLpProtocol(currentEpoch.protocol())) {
            uint256 totalSupply = IERC20(currentEpoch.getYT()).totalSupply();
            amountOT = _amountUnderlying - ((yield * _amountUnderlying) / totalSupply);
        } else {
            amountOT = _amountUnderlying;
        }

        // transfer underlying to vault
        IERC20(currentEpoch.underlying()).safeTransferFrom(msg.sender, _treasuryAddress, _amountUnderlying);
        Treasury(_treasuryAddress).deposit(getEpochAddress(_streamKey, currentEpochId), _amountUnderlying);

        // normal deposit for adjusted amount
        currentEpoch.mintOT(msg.sender, amountOT);
        currentEpoch.mintYT(msg.sender, _amountUnderlying);

        emit Deposited(_streamKey, msg.sender, _amountUnderlying, currentEpochId);
        return (amountOT, _amountUnderlying);
    }

    ///// USER EXIT
    /**
     * @dev We need to allow the user to reedem their yield from an expired epoch
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future against which yield will be redeemed
     * @notice _epoch must be expired
     */
    function redeemYield(bytes32 _streamKey, uint256 _epoch) external isEpochExpired(_streamKey, _epoch) {
        IFuture epochInstance = IFuture(getEpochAddress(_streamKey, _epoch));

        uint256 totalSupply = epochInstance.totalSupplyYT();
        uint256 amountBurned = epochInstance.burnYT(msg.sender);

        uint256 amountRedeemed =
            Treasury(treasuryAddress).claimYield(
                _streamKey,
                _epoch,
                amountBurned,
                totalSupply,
                epochInstance.underlying(),
                msg.sender
            );

        emit YieldRedeemed(_streamKey, msg.sender, _epoch, amountRedeemed);
    }

    /**
     * @dev We need to allow the user to reedem their principle from an expired epoch
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future against which principle will be redeemed
     */
    function redeemPrinciple(bytes32 _streamKey, uint256 _epoch) external isEpochExpired(_streamKey, _epoch) {
        // check end epoch for user for the stream
        // bytes32 userKey = getUserEpochKey(msg.sender, _streamKey, _epoch);
        // require(userDetailsPerStream[userKey], "ERR_SUBSCRIPTION_NOT_FOUND");

        IFuture epochInstance = IFuture(getEpochAddress(_streamKey, _epoch));
        // check if user has OT to redeem
        require(IERC20(epochInstance.getOT()).balanceOf(msg.sender) > 0, "ERR_INSUFFICIENT_BALANCE");

        uint256 totalSupply = epochInstance.totalSupplyOT();
        uint256 amountBurned = epochInstance.burnOT(msg.sender);

        if (amountBurned > 0) {
            address underlying = epochInstance.underlying();
            uint amountRedeemed = Treasury(treasuryAddress).withdraw(
                _streamKey,
                underlying,
                msg.sender,
                _epoch,
                totalSupply,
                amountBurned
            );

            emit PrincipleRedeemed(_streamKey, msg.sender, _epoch, amountRedeemed);
        }
    }

    //
    // VIEWS
    //

    /**
     * @dev Get the current future index for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return current future index
     * @notice in case stream hasn't been initialised, it returns MAX_UINT
     */
    function getCurrentEpoch(bytes32 _streamKey) public view returns (uint256) {
        if (!isStreamInitialized(_streamKey)) {
            return MAX_UINT;
        }
        return streams[_streamKey].length - 1;
    }

    /**
     * @dev Get the upcoming future index for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return the upcoming future index
     */
    function getNextEpoch(bytes32 _streamKey) public view returns (uint256) {
        return streams[_streamKey].length;
    }

    /**
     * @dev Get the address of future for a given stream and index
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return address of the future
     */
    function getEpochAddress(bytes32 _streamKey, uint256 _epoch) public view returns (address) {
        return streams[_streamKey][_epoch];
    }

    /**
     * @dev Get the address of OT for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return address of the OT
     */
    function getOT(bytes32 _streamKey, uint256 _epoch) public view returns (address) {
        address epochAddress = getEpochAddress(_streamKey, _epoch);
        return address(IFuture(epochAddress).getOT());
    }

    /**
     * @dev Get the address of YT for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return address of the YT
     */
    function getYT(bytes32 _streamKey, uint256 _epoch) public view returns (address) {
        address epochAddress = getEpochAddress(_streamKey, _epoch);
        return address(IFuture(epochAddress).getYT());
    }

    function getOTYTCount(bytes32 _streamKey, uint256 _amountUnderlying) public view returns (uint256, uint256) {
        revertNonExistentStream(_streamKey);

        // transfer underlying from the caller to treasury
        uint256 currentEpochId = getCurrentEpoch(_streamKey);
        IFuture currentEpoch = IFuture(getEpochAddress(_streamKey, currentEpochId));

        // get the yield
        uint256 yield = currentEpoch.yield();
        uint256 amountOT = 0;

        // calculate OT
        if (yield > 0) {
            uint256 totalSupply = IERC20(currentEpoch.getYT()).totalSupply();
            amountOT = _amountUnderlying - ((yield * _amountUnderlying) / totalSupply);
        } else {
            amountOT = _amountUnderlying;
        }

        return (amountOT, _amountUnderlying);
    }

    /**
     * @dev Check if a given stream is initialized
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return boolean indicating if the stream is initialized or not
     */
    function isStreamInitialized(bytes32 _streamKey) public view returns (bool) {
        // the first future in the stream is always address(0)
        if (streams[_streamKey].length > 0) return true;
        return false;
    }

    /**
     * @dev Function that reverts if a given stream is invalid or uninitialized
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     */
    function revertNonExistentStream(bytes32 _streamKey) internal view {
        require(_streamKey != bytes32(0), "ERR_INVALID_STREAM_KEY_ZERO");
        require(isStreamInitialized(_streamKey), "ERR_STREAM_NOT_INITIALIZED");
    }

    /**
     * @dev Get the yield generated in a given epoch of a stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return the yield generated
     */
    function getYieldRemaining(bytes32 _streamKey, uint256 _epoch) public view returns (uint256) {
        return Treasury(treasuryAddress).yields(_streamKey, _epoch);
    }

    /**
     * @dev Get the principle remaining in a given epoch of a stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return total principle remaining
     */
    function getPrincipleRemaining(bytes32 _streamKey, uint256 _epoch) public view returns (uint256) {
        return Treasury(treasuryAddress).underlyingForOt(_streamKey, _epoch);
    }

    //
    // PURE FUNCTIONS
    //

    /**
     * @dev Get the unique name of the stream, created by hashing protocol, underlying, duration
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _duration: number of blocks the future will run before renewing
     * @return the hashed streamKey
     */
    function getStreamKey(
        string memory _protocol,
        address _underlying,
        uint256 _duration
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_protocol, _underlying, _duration));
    }
}