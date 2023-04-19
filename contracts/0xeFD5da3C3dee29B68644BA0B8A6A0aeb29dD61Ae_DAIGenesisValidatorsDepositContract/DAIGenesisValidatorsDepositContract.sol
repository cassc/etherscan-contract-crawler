/**
 *Submitted for verification at Etherscan.io on 2023-04-18
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File contracts/interfaces/IERC165.sol

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.15;

// Based on official specification in https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}


// File contracts/interfaces/IERC1820Registry.sol

interface IERC1820Registry {
    function setInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash,
        address _implementer
    ) external;
}


// File contracts/LUKSOGenesisValidatorsDepositContract.sol


/**
 * @title DAI Genesis Validators Deposit Contract
 * @author DAI
 *
 * @notice This contract allows anyone to register as Genesis Validators for the DAI Blockchain.
 * To become a Genesis Validator, a participant must send 32 DAIe to this contract alongside its validator data
 * (public key, withdrawal credentials, signature, deposit data root and initial supply vote).
 *
 * This smart contract allows deposits from 2023-04-19 06:00am UTC on. They will revert before that time.
 *
 * Once enough Genesis Validator keys are present, the `FREEZER` can initiate the freeze of this contract,
 * which will happen exactly 146 blocks after the initiation (~30 minutes).
 * After this contract is frozen, it only functions as a historical reference and all DAIe in it will be forever locked.
 *
 * The `genesis.szz` for the DAI Blockchain, will be generated out of this smart contract using the `getDepositData()` function and
 * Genesis Validators will have their DAI balance on the DAI Blockchain after the network start.
 *
 * @dev The DAI Genesis Validators Deposit Contract will be deployed on the Ethereum network.
 * The contract automatically registers deposits and their related deposit validator data when receiving
 * the callback from the DAIe token contract via the `tokensReceived` function.
 *
 * Once the contract is frozen, no more deposits can be made.
 *
 */
contract DAIGenesisValidatorsDepositContract is IERC165 {

    /**
     * @dev The `FREEZER` of the contract can freeze the contract via the `freezeContract()` function
     */
    address public constant FREEZER = 0x5ADEe9Ac1aDbf15B972166D6D6E540eA89A5063d;

    // The address of the DAIe token contract.
    address public constant DAI_TOKEN_CONTRACT_ADDRESS = 0xA8b919680258d369114910511cc87595aec0be6D;

    // The address of the registry contract (ERC1820 Registry)
    address public constant ERC1820_REGISTRY_ADDRESS = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;

    // The hash of the interface of the contract that receives tokens
    bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    // _to_little_endian_64(uint64(32 ether / 1 gwei))
    bytes constant AMOUNT_TO_LITTLE_ENDIAN_64 = hex"0040597307000000";

    // Timestamp from which the deposits are accepted (2023-04-19 06:00am UTC)
    uint256 public constant DEPOSIT_START_TIMESTAMP = 1681884000;

    // The current number of deposits in the contract
    uint256 internal deposit_count;

    // The delay in blocks for the contract to be frozen (46,523 blocks ~ 1 week)
    uint256 public constant FREEZE_DELAY = 146;

    // The block number when the contract will be frozen
    uint256 public freezeBlockNumber;

    /**
     * @notice New DAIe deposit made
     * @dev Emitted when an address made a deposit of 32 DAIe to become a genesis validator on DAI
     * @param pubkey the public key of the genesis validator
     * @param withdrawal_credentials the withdrawal credentials of the genesis validator
     * @param amount the amount of DAIe deposited (32 DAIe)
     * @param signature the BLS signature of the genesis validator
     * @param index the deposit number for this deposit
     */
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        uint256 amount,
        bytes signature,
        uint256 index
    );

    /**
     * @dev Emitted when the `FREEZER` of the contract freezes the contract
     * @param initiatedAt the block number when freezing the contract was initiated
     * @param freezeAt the block number when the contract will be frozen
     */
    event FreezeInitiated(uint256 initiatedAt, uint256 freezeAt);

    /**
     * @dev Storing all the deposit data which should be sliced
     * in order to get the following parameters:
     * - pubkey - the first 48 bytes
     * - withdrawal_credentials - the following 32 bytes
     * - signature - the following 96 bytes
     * - deposit_data_root - the following 32 bytes
     * - initial_supply_vote - the last byte is the initial supply of DAI (in millions)
     *   the genesis validator voted for (0 means non-vote)
     */
    mapping(uint256 => bytes) internal deposit_data;

    /**
     * @dev Storing the amount of votes for each supply where the index is the initial supply of DAI in million
     */
    mapping(uint256 => uint256) public supplyVoteCounter;

    /**
     * @dev Storing the hash of the public key in order to check if it is already registered
     */
    mapping(bytes32 => bool) private _registeredPubKeyHash;

    /**
     * @dev Set the `TOKENS_RECIPIENT_INTERFACE_HASH` for the deposit contract
     */
    constructor() {
        // Set this contract as the implementer of the tokens recipient interface in the registry contract
        IERC1820Registry(ERC1820_REGISTRY_ADDRESS).setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }

    /**
     * @dev Whenever this contract receives DAIe tokens, it must be for the reason of becoming a Genesis Validator.
     *
     * Requirements:
     * - `amount` MUST be exactly 32 DAIe
     * - `depositData` MUST be encoded properly
     * - `depositData` MUST contain:
     *   • pubkey - the first 48 bytes
     *   • withdrawal_credentials - the following 32 bytes
     *   • signature - the following 96 bytes
     *   • deposit_data_root - the following 32 bytes
     *   • supply - that last byte is the initial supply of DAI in million where 0 means non-vote
     */
    function tokensReceived(
        address /* operator */,
        address /* from */,
        address /* to */,
        uint256 amount,
        bytes calldata depositData,
        bytes calldata /* operatorData */
    ) external {

        // Check that the current timestamp is after the deposit start timestamp (2023-04-19 06:00am UTC)
        require(block.timestamp >= DEPOSIT_START_TIMESTAMP, "DAIGenesisValidatorsDepositContract: Deposits not yet allowed");

        uint256 freezeBlockNumberValue = freezeBlockNumber;

        // Check the contract is not frozen
        require(
            freezeBlockNumberValue == 0 || block.number < freezeBlockNumberValue,
            "DAIGenesisValidatorsDepositContract: Contract is frozen"
        );

        // Check the calls can only come from the DAIe token contract
        require(
            msg.sender == DAI_TOKEN_CONTRACT_ADDRESS,
            "DAIGenesisValidatorsDepositContract: Not called on DAIe transfer"
        );

        // Check the amount received is exactly 32 DAIe
        require(
            amount == 32 ether,
            "DAIGenesisValidatorsDepositContract: Cannot send an amount different from 32 DAIe"
        );

        /**
         * Check the deposit data has the correct length (209 bytes)
         *  - 48 bytes for the pubkey
         *  - 32 bytes for the withdrawal_credentials
         *  - 96 bytes for the BLS signature
         *  - 32 bytes for the deposit_data_root
         *  - 1 byte for the initialSupplyVote
         */
        require(
            depositData.length == 209,
            "DAIGenesisValidatorsDepositContract: depositData not encoded properly"
        );

        uint256 initialSupplyVote = uint256(uint8(depositData[208]));

        // Check the `initialSupplyVote` is a value between 0 and 100 (inclusive), where 0 is a non-vote
        require(
            initialSupplyVote <= 100,
            "DAIGenesisValidatorsDepositContract: Invalid initialSupplyVote vote"
        );

        // increment the counter for the given initial supply vote
        supplyVoteCounter[initialSupplyVote]++;

        // Store the deposit data in the contract state
        deposit_data[deposit_count] = depositData;

        // Extract the validator deposit data from the `depositData`
        bytes calldata pubkey = depositData[:48];
        bytes calldata withdrawal_credentials = depositData[48:80];
        bytes calldata signature = depositData[80:176];
        bytes32 deposit_data_root = bytes32(depositData[176:208]);

        // Compute the SHA256 hash of the pubkey
        bytes32 pubKeyHash = sha256(pubkey);

        // Prevent depositing twice for the same pubkey
        require(
            !_registeredPubKeyHash[pubKeyHash],
            "DAIGenesisValidatorsDepositContract: Deposit already processed"
        );

        // Mark the pubkey as registered
        _registeredPubKeyHash[pubKeyHash] = true;

        // Compute deposit data root (`DepositData` hash tree root)
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));

        // Compute the root of the BLS signature data
        bytes32 signature_root = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(signature[:64])),
                sha256(abi.encodePacked(signature[64:], bytes32(0)))
            )
        );

        // Compute the root of the deposit data
        bytes32 computedDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
                sha256(abi.encodePacked(AMOUNT_TO_LITTLE_ENDIAN_64, bytes24(0), signature_root))
            )
        );

        // Verify computed and expected deposit data roots match
        require(
            computedDataRoot == deposit_data_root,
            "DAIGenesisValidatorsDepositContract: reconstructed DepositData does not match supplied deposit_data_root"
        );

        // Emit `DepositEvent` log
        emit DepositEvent(
            pubkey,
            withdrawal_credentials,
            32 ether,
            signature,
            deposit_count
        );

        deposit_count++;
    }

    /**
     * @dev This function will freeze the DAI Genesis Deposit Contract after 46,523 blocks (~ 1 week).
     * This function can only be called by the `FREEZER` once!
     */
    function freezeContract() external {
        // Check the contract is not already frozen
        require(
            freezeBlockNumber == 0,
            "DAIGenesisValidatorsDepositContract: Contract is already frozen"
        );

        // Check this function can only be called by the `FREEZER`
        require(msg.sender == FREEZER, "DAIGenesisValidatorsDepositContract: Caller is not the freezer");

        // Set the freeze block number to the current block number + FREEZE_DELAY
        uint256 freezeAt = block.number + FREEZE_DELAY;
        freezeBlockNumber = freezeAt;
        emit FreezeInitiated(block.number, freezeAt);
    }

    /**
     * @dev Returns whether the public key is registered or not
     *
     * @param pubkey The public key of the genesis validator
     * @return bool `true` if the public key is registered, `false` otherwise
     */
    function isPubkeyRegistered(bytes calldata pubkey) external view returns (bool) {
        return _registeredPubKeyHash[sha256(pubkey)];
    }

    /**
     * @dev Returns the current number of deposits
     *
     * @return The number of deposits at the time the function was called
     */
    function depositCount() external view returns (uint256) {
        return deposit_count;
    }

    /**
     * @dev Retrieves an array of votes per supply and the total number of votes
     */
    function getsVotesPerSupply()
        external
        view
        returns (uint256[101] memory votesPerSupply, uint256 totalVotes)
    {
        for (uint256 i = 0; i <= 100; i++) {
            votesPerSupply[i] = supplyVoteCounter[i];
        }
        return (votesPerSupply, deposit_count);
    }

    /**
     * @dev Get an array of all encoded deposit data
     */
    function getDepositData() external view returns (bytes[] memory returnedArray) {
        returnedArray = new bytes[](deposit_count);
        for (uint256 i = 0; i < deposit_count; i++) returnedArray[i] = deposit_data[i];
    }

    /**
     * @dev Get the encoded deposit data at a given `index`
     */
    function getDepositDataByIndex(uint256 index) external view returns (bytes memory) {
        return deposit_data[index];
    }

    /**
     * @dev Determines whether the contract supports a given interface
     *
     * @param interfaceId The interface ID to check
     * @return `true` if the contract supports the interface, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}