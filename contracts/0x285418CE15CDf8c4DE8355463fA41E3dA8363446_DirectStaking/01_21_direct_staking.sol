// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "iface.sol";
import "BytesLib.sol";
import "ECDSA.sol";
import "Strings.sol";
import "SafeERC20.sol";
import "Initializable.sol";
import "AccessControlUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";


/**
 * @title RockX Ethereum Direct Staking Contract
 */
contract DirectStaking is Initializable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;

    // structure to record taking info.
    struct ValidatorInfo {
        bytes pubkey;
        address claimAddr;
        uint256 extraData; // a 256bit extra data, could be used in DID to ref a user

        // mark exiting
        bool exiting;
    }
    // Variables in implementation v0 
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant DEPOSIT_SIZE = 32 ether;

    uint256 private constant MULTIPLIER = 1e18; 
    uint256 private constant DEPOSIT_AMOUNT_UNIT = 1000000000 wei;
    uint256 private constant SIGNATURE_LENGTH = 96;
    uint256 private constant PUBKEY_LENGTH = 48;

    /**
        Incorrect storage preservation:

        |Implementation_v0   |Implementation_v1        |
        |--------------------|-------------------------|
        |address _owner      |address _lastContributor | <=== Storage collision!
        |mapping _balances   |address _owner           |
        |uint256 _supply     |mapping _balances        |
        |...                 |uint256 _supply          |
        |                    |...                      |
        Correct storage preservation:

        |Implementation_v0   |Implementation_v1        |
        |--------------------|-------------------------|
        |address _owner      |address _owner           |
        |mapping _balances   |mapping _balances        |
        |uint256 _supply     |uint256 _supply          |
        |...                 |address _lastContributor | <=== Storage extension.
        |                    |...                      |
    */

    // Always extend storage instead of modifying it
    bytes private DEPOSIT_AMOUNT_LITTLE_ENDIAN;

    address public ethDepositContract;  // ETH 2.0 Deposit contract
    address public rewardPool; // reward pool address
    address public sysSigner; // the signer for parameters in stake()

    // validator registry
    ValidatorInfo [] private validatorRegistry;

    // users's signed params to avert doubled staking
    mapping(bytes32=>bool) private signedParams;    

    // user apply for validator exit
    uint256 [] private exitQueue;

    // shanghai merge
    bool private shanghai;
   
    /**
     * @dev empty reserved space for future adding of variables
     */
    uint256[32] private __gap;

    /** 
     * ======================================================================================
     * 
     * SYSTEM SETTINGS, OPERATED VIA OWNER(DAO/TIMELOCK)
     * 
     * ======================================================================================
     */
    
    /**
     * @dev This contract will not accept direct ETH transactions.
     */
    receive() external payable {
        revert("Do not send ETH here");
    }

    /**
     * @dev pause the contract
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev unpause the contract
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev enable exit after shanghai merge.
     */
    modifier onlyShanghai() {
        require(shanghai, "AVAILABLE_AFTER_SHANGHAI_MERGE");
        _;
    }

    /**
     * @dev disable implementation init
     */
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @dev initialization
     */
    function initialize() initializer public {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRY_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        // little endian deposit amount
        uint256 depositAmount = DEPOSIT_SIZE / DEPOSIT_AMOUNT_UNIT;
        DEPOSIT_AMOUNT_LITTLE_ENDIAN = to_little_endian_64(uint64(depositAmount));
    }

    /**
     * @dev set signer adress
     */
    function setSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sysSigner = _signer;

        emit SignerSet(_signer);
    }

    /**
     * @dev set reward pool contract address
     */
    function setRewardPool(address _rewardPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardPool = _rewardPool;

        emit RewardPoolContractSet(_rewardPool);
    }

    /**
     * @dev set eth deposit contract address
     */
    function setETHDepositContract(address _ethDepositContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ethDepositContract = _ethDepositContract;

        emit DepositContractSet(_ethDepositContract);
    }

    /**
     * @dev toggle shanghai merge
     */
    function toggleShangHai() external onlyRole(DEFAULT_ADMIN_ROLE) {
        shanghai = !shanghai;

        emit ShangHaiStatus(shanghai);
    }

    /**
     * @dev verify signer of the paramseters
     */
    function verifySigner(
        uint256 extraData,
        address claimaddr,
        address withdrawaddr,
        bytes[] calldata pubkeys,
        bytes[] calldata signatures,
        bytes calldata paramsSig) public view returns(bool) {

        // params signature verification
        bytes32 digest = ECDSA.toEthSignedMessageHash(_digest(extraData, claimaddr, withdrawaddr, pubkeys, signatures));
        address signer = ECDSA.recover(digest, paramsSig);

        return (signer == sysSigner);
    }

    /**
     * ======================================================================================
     * 
     * VIEW FUNCTIONS
     * 
     * ======================================================================================
     */

    /**
     * @dev return registered validator by index
     */
    function getValidatorInfo(uint256 idx) external view returns (
        bytes memory pubkey,
        address claimAddress,
        uint256 extraData
     ){
        ValidatorInfo storage info = validatorRegistry[idx];  
        return (info.pubkey, info.claimAddr, info.extraData);
    }

    /**
     * @dev return registered validator by range
     */
    function getValidatorInfos(uint256 from, uint256 to) external view returns (
        bytes [] memory pubkeys,
        address [] memory claimAddresses,
        uint256 [] memory extraDatas
     ){
        pubkeys = new bytes[](to - from);
        claimAddresses =  new address[](to - from);
        extraDatas = new uint256[](to - from);

        uint256 counter = 0;
        for (uint i = from; i < to;i++) {
            ValidatorInfo storage info = validatorRegistry[i];
            pubkeys[counter] = info.pubkey;
            claimAddresses[counter] = info.claimAddr;
            extraDatas[counter] = info.extraData;

            counter++;
        }
    }

    /**
     * @dev return validators count
     */
    function getNextValidators() external view returns (uint256) { return validatorRegistry.length; }

    /**
     * @dev return exit queue
     */
    function getExitQueue(uint256 from, uint256 to) external view returns (uint256[] memory) { 
        uint256[] memory ids = new uint256[](to - from);
        uint256 counter = 0;
        for (uint i = from; i < to;i++) {
            ids[counter] = exitQueue[i];
            counter++;
        }
        return ids;
    }

    /**
     * @dev return exit queue length
     */
    function getExitQueueLength() external view returns (uint256) { return exitQueue.length; }

    /**
     * ======================================================================================
     * 
     * USER EXTERNAL FUNCTIONS
     * 
     * ======================================================================================
     */
     
    /**
     * @dev user stakes
     */
    function stake(
        address claimaddr,
        address withdrawaddr,
        bytes[] calldata pubkeys,
        bytes[] calldata signatures,
        bytes calldata paramsSig, uint256 extradata, uint256 tips) external payable nonReentrant whenNotPaused {

        // global check
        _require(!signedParams[keccak256(paramsSig)], "REPLAYED_PARAMS");
        _require(signatures.length <= 10, "RISKY_DEPOSITS");
        _require(signatures.length == pubkeys.length, "INCORRECT_SUBMITS");
        _require(sysSigner != address(0x0) &&
                ethDepositContract != address(0x0) &&
                rewardPool != address(0x0), 
                "NOT_INITIATED");


        // params signature verification
        _require(verifySigner(extradata, claimaddr, withdrawaddr, pubkeys, signatures, paramsSig), "SIGNER_MISMATCH");

        // validity check
        _require(withdrawaddr != address(0x0) &&
                    claimaddr != address(0x0),
                    "ZERO_ADDRESS");

        // may add a minimum tips for each stake 
        uint256 ethersToStake = msg.value - tips;
        _require(ethersToStake % DEPOSIT_SIZE == 0, "ETHERS_NOT_ALIGNED");
        uint256 nodesAmount = ethersToStake / DEPOSIT_SIZE;
        _require(signatures.length == nodesAmount, "MISMATCHED_ETHERS");

        // build withdrawal credential from withdraw address
        // uint8('0x1') + 11 bytes(0) + withdraw address
        bytes memory cred = abi.encodePacked(bytes1(0x01), new bytes(11), withdrawaddr);
        bytes32 withdrawal_credential = BytesLib.toBytes32(cred, 0);

        // deposit
        for (uint256 i = 0;i < nodesAmount;i++) {
            ValidatorInfo memory info;
            info.pubkey = pubkeys[i];
            info.claimAddr = claimaddr;
            info.extraData = extradata;
            validatorRegistry.push(info);

            // deposit to offical contract.
            _deposit(pubkeys[i], signatures[i], withdrawal_credential);

            // join the reward pool once it's deposited to official one.
            IRewardPool(rewardPool).joinpool(info.claimAddr, DEPOSIT_SIZE);
        }

        // update signedParams to avert repeated use of signature
        signedParams[keccak256(paramsSig)] = true;
    
        // log
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @dev user exits his validator
     */
    function exit(uint256 validatorId) external onlyShanghai {
        ValidatorInfo storage info = validatorRegistry[validatorId];
        require(!info.exiting, "EXITING");
        require(msg.sender == info.claimAddr, "CLAIM_ADDR_MISMATCH");

        info.exiting = true;
        exitQueue.push(validatorId);

        // to leave the reward pool
        IRewardPool(rewardPool).leavepool(info.claimAddr, DEPOSIT_SIZE);
    }

    /** 

     * ======================================================================================
     * 
     * INTERNAL FUNCTIONS
     * 
     * ======================================================================================
     */

    /**
     * @dev Invokes a deposit call to the official Deposit contract
     */
    function _deposit(bytes calldata pubkey, bytes calldata signature, bytes32 withdrawal_credential) internal {
        // Compute deposit data root (`DepositData` hash tree root)
        // https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 signature_root = sha256(abi.encodePacked(
            sha256(BytesLib.slice(signature, 0, 64)),
            sha256(abi.encodePacked(BytesLib.slice(signature, 64, SIGNATURE_LENGTH - 64), bytes32(0)))
        ));
        
        bytes32 depositDataRoot = sha256(abi.encodePacked(
            sha256(abi.encodePacked(pubkey_root, withdrawal_credential)),
            sha256(abi.encodePacked(DEPOSIT_AMOUNT_LITTLE_ENDIAN, bytes24(0), signature_root))
        ));

        IDepositContract(ethDepositContract).deposit{value:DEPOSIT_SIZE} (
            pubkey, abi.encodePacked(withdrawal_credential), signature, depositDataRoot);
    }

    /**
     * @dev to little endian
     * https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code
     */
    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }

    /**
     * @dev code size will be smaller
     */
    function _require(bool condition, string memory text) private pure {
        require (condition, text);
    }

    /**
     * @dev digest params
     */
    function _digest(
        uint256 extraData,
        address claimaddr,
        address withdrawaddr,
        bytes[] calldata pubkeys,
        bytes[] calldata signatures) private view returns (bytes32) {

        bytes32 digest = sha256(abi.encode(extraData, address(this), claimaddr, withdrawaddr));

        for (uint i=0;i<pubkeys.length;i++) {
            digest = sha256(abi.encode(digest, pubkeys[i], signatures[i]));
        }

        return digest;
    }
    
    /**
     * ======================================================================================
     * 
     * SYSTEM EVENTS
     *
     * ======================================================================================
     */
    event RewardPoolContractSet(address addr);
    event DepositContractSet(address addr);
    event SignerSet(address addr);
    event Staked(address addr, uint256 amount);
    event ShangHaiStatus(bool status);
}