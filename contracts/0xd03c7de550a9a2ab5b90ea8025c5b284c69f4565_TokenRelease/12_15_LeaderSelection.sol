// SPDX-License-Identifier: Apache-2.0
/// @dev Note, we want to use the 0.7.4 version to align with previous deployment.
pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/GetCode.sol";
import "../utils/BytesLib.sol";

/// @notice The interface for the ITokenRelease contract.
interface ITokenRelease {
    function owner() external returns (address);
    function cliff() external returns (uint256);
    function beneficiary() external returns (address);
}

/// @notice The Fuel v1 interface.
interface IFuel_v1 {
    function commitBlock(uint32,bytes32,uint32,bytes32[] memory) external payable;
    function bondWithdraw(bytes memory) external;
    function operator() external returns (address);
    function commitWitness(bytes32 transactionId) external;
}

/// @notice The control Multisig for the Fuel v1.0 system.
interface IMultisig {
    /// @dev https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol#L189
    function submitTransaction(address payable destination, uint value, bytes memory data)
        external
        returns (uint transactionId);
}

/// @notice The Fuel v1 Proxy contract bypass.
interface IProxy {
    /// @dev Transact bypass.
    function transact(address payable destination, uint256 value, bytes memory data) external payable;
}

/// @notice The Fuel v1 Optimistic Rollup leader selection.
/// @dev Each producer must create a Release schedule with a minimum amount of locked value.
/// @dev Leader selection is based on a list of releases and incrementation which resets.
contract LeaderSelection {
    // Constants.

    // Minimum required balance a TokenRelease must have to register as a producer.
    uint256 public constant minimumTokens = 32000 ether;

    // ITokenRelease code hash.
    bytes32 public constant releaseBytecodeHash = 0x2a7cfb605ecbaaebee7c515143b57775b198b4b26f09976132e4bed2fc6b1957;

    // ITokenRelease code size.
    uint256 public constant releaseBytecodeSize = 5794;

    // ITokenRelease code size.
    uint256 public constant releaseConstructorSize = 160;

    // The Fuel v1 bond value amount.
    uint256 public constant bondValue = .5 ether;

    // The reset window for leader id selection.
    // Note, each producer gets a 1/4 day to produce if they are the leader.
    uint256 public constant resetWindow = (1 days) / 4;

    // Immutable variables.

    // The Fuel v1 contract address.
    IFuel_v1 public immutable fuel;

    // The Fuel v1 contract address.
    IMultisig public immutable controlMultisig;

    // The Fuel v1 IProxy contract address.
    address public immutable proxy;

    // State variables.

    // The Fuel v2 multisignature wallet address.
    address public multisig;

    // The Fuel v2 DSToken contract address.
    IERC20 public token;

    // The block production leader index.
    uint32 public leaderId;

    // The next producer slot to be registered.
    uint32 public freeId;

    // The last time a new leader was selected.
    uint256 public lastSelected;

    // The total number of block releases registered.
    uint32 public numReleases;

    // The mapping from producer index to their address.
    mapping(uint32 => address) public releases;

    // The mapping from producer address to their index.
    mapping(address => uint32) public ids;

    // The mapping from the release address to block height to Ethereum block to is committed bool.
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public commitment;

    /// @notice Setup the multisig, fuel contract, initial producer and initial token.
    constructor(
        address initMultisig,
        IFuel_v1 initFuel,
        ITokenRelease initProducer,
        IERC20 initToken,
        IMultisig initControlMultisig
    ) {
        // Setup the constructor immutable variables.
        multisig = initMultisig;
        proxy = initFuel.operator();
        fuel = initFuel;
        token = initToken;
        controlMultisig = initControlMultisig;

        // Register the initial producer.
        register(initProducer);
    }

    /// @dev We want the commitBlock to do all the work for leaderId selection.
    /// @dev Below describes a model where leaderId management is done, checks and commitBlock.
    function commitBlock(
        uint32 minimum,
        bytes32 minimumHash,
        uint32 height,
        bytes32[] calldata roots
    ) payable external {
        // If a new leader needs to be selected.
        if ((block.timestamp - lastSelected) > resetWindow) {
            incrementLeaderId();
        }

        // Set the new leader.
        ITokenRelease release = ITokenRelease(releases[leaderId]);

        // If the leader is expired, skip ahead to the next leader and stop.
        if (block.timestamp >= release.cliff()) {
            // Set the free id to the leader id.
            freeId = leaderId;

            // Increment the leader id.
            incrementLeaderId();

            // Stop the commitment process here.
            return;
        }

        // Require the leader beneficiary is the message sender.
        require(msg.sender == release.beneficiary(), "beneficiary");

        // Require that the transaction has value.
        require(msg.value == bondValue, "bond-value");

        // Create the commit block data to send to the IProxy.
        // @dev https://github.com/FuelLabs/fuel/blob/master/src/Fuel.yulp#L113.
        bytes memory data = abi.encodeWithSelector(
            IFuel_v1.commitBlock.selector,
            minimum,
            minimumHash,
            height,
            roots
        );

        // Send commitBlock data to the IProxy, which will commit the block in Fuel.
        /// @dev no-rentrancy vector, as IProxy is pre-set.
        /// @dev https://github.com/FuelLabs/fuel/blob/master/src/OwnedProxy.yulp#L43
        IProxy(proxy).transact{ value: bondValue }(
            payable(address(fuel)),
            bondValue,
            data
        );

        // Notate commitment.
        commitment[msg.sender][height][block.number] = true;
    }

    /// @dev We want the current block leader to be able to use commitWitness to retrieve root fees.
    /// @dev If the leader doesn't retrieve their fees in their leader window, anyone else can.
    function commitWitness(
        bytes32 transactionId
    ) external {
        // Get the current release leader.
        ITokenRelease release = ITokenRelease(releases[leaderId]);

        // Require the leader beneficiary is the message sender.
        require(msg.sender == release.beneficiary(), "beneficiary");

        // Create the commitWitness data to send to the proxy.
        bytes memory data = abi.encodeWithSelector(
            IFuel_v1.commitWitness.selector,
            transactionId
        );

        // Send the commitWitness data to the proxy.
        IProxy(proxy).transact{ value: 0 }(
            payable(address(fuel)),
            0,
            data
        );
    }

    /// @dev Allow producers to retrieve their bonds.
    function bondWithdraw(
        bytes memory blockHeader
    ) external {
        // The parsed block height from the Block Header.
        address producer = BytesLib.toAddress(blockHeader, 0);

        // The block header producer is the proxy.
        require(producer == proxy, "producer-proxy");

        // The parsed block height from the Block Header.
        uint256 height = BytesLib.toUint256(blockHeader, 20 + 32);

        // The parsed block number from the Block Header.
        uint256 blockNumber = BytesLib.toUint256(blockHeader, 20 + 32 + 32);

        // Require that the commitment has been made.
        require(commitment[msg.sender][height][blockNumber], "block-commitment");

        // Nullify this commitment to ensure re-rentrancy prevention.
        commitment[msg.sender][height][blockNumber] = false;

        // Create the bondwithdraw data to send to the proxy.
        bytes memory data = abi.encodeWithSelector(
            IFuel_v1.bondWithdraw.selector,
            blockHeader
        );

        // Get the pre-proxy balance.
        uint256 preProxyBalance = proxy.balance;

        // Send the bond retrieval data to the proxy contract.
        // Re-entrancy note, if this is tried twice the Fuel v1.0 contract will throw.
        IProxy(proxy).transact{ value: 0 }(
            payable(address(fuel)),
            0,
            data
        );

        // Ensure the proxy balance is exactly bondValue higher after this withdrawal attempt.
        require(proxy.balance == preProxyBalance + bondValue, "bond-value");

        // Empty bytes.
        bytes memory emptyBytes;

        // Build the retrieval data for the proxy.
        bytes memory retrievalData = abi.encodeWithSelector(
            IProxy.transact.selector,
            payable(msg.sender),
            bondValue,
            emptyBytes
        );

        // Use the control multisig to withdraw the funds.
        controlMultisig.submitTransaction(
            payable(proxy),
            0,
            retrievalData
        );
    }

    /// @dev increment new leader id.
    function incrementLeaderId() internal {
        // Increment the leaderId.
        leaderId += 1;

        // Set the last selected timestamp.
        lastSelected = block.timestamp;

        // If leaderId is passed available releases, reset to start.
        if (leaderId >= numReleases) {
            leaderId = 0;
        }
    }

    /// @dev Register a token release contract.
    function register(ITokenRelease release) public {
        // Check the release contract to ensure it's valid.
        check(release);

        // Set producer and release.
        ids[address(release)] = freeId;

        // Set release.
        releases[freeId] = address(release);

        // Increase the number of releases.
        if (freeId == numReleases) {
            numReleases += 1;
        }

        // Reset the freeId to the numReleases.
        freeId = numReleases;
    }

    /// @dev Check that a release contract is the right code, setup and not registered.
    function check(ITokenRelease release) internal {
        // Ensure the release contract address is not empty.
        require(address(release) != address(0), "empty");

        // Get the bytecode of the token release contract in question.
        bytes memory bytecode = GetCode.at(address(release), releaseConstructorSize);

        // Ensure the bytecode for the release contract is the TokenRelease contract bytecode.
        require(keccak256(bytecode) == releaseBytecodeHash, "bytecode-hash");

        // Ensure the code size of the provided third-party contract is the correct TokenRelease contract size.
        require(
            GetCode.sizeAt(address(release)) == (releaseBytecodeSize + releaseConstructorSize),
            "code-length"
        );

        // Check that the owner is either null address (i.e. no owner) or the Fuel multisignature wallet.
        require(release.owner() == address(0)
            || release.owner() == multisig, "owner-check");

        // Ensure the balance of the release contract meets the minimum requirement.
        require(token.balanceOf(address(release)) >= minimumTokens, "minimum");

        // Ensure the release contract has not already been registered.
        require(ids[address(release)] == 0, "id-registered");

        // Ensure the release contract has not already been registered.
        // Need this check since EVM defaults mapping values to 0, so
        // ids[address(release)] == 0 alone doesn't guarantee no prior registration.
        require(releases[0] != address(release), "already-registered");
    }

    /// @notice This will nullify the multisig and give full ownership of Fuel v1 agg. prod. to this contract.
    /// @dev Token releases will no longer allow the Fuel multisig to be registered as the owner.
    function nullifyMultisig() external {
        // Require that the sender is the Fuel multisig.
        require(msg.sender == multisig, "multisig");

        // Nullify the multisig.
        multisig = address(0);
    }
}