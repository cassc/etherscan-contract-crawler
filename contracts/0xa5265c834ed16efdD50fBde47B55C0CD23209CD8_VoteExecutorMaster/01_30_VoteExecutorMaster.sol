// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IAlluoToken.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGnosis.sol";
import "../interfaces/IAlluoStrategyNew.sol";
import "../interfaces/IMultichain.sol";
import "../interfaces/IIbAlluo.sol";
import "../interfaces/ILiquidityHandler.sol";

contract VoteExecutorMaster is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using ECDSAUpgradeable for bytes32;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    address public constant ALLUO = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;

    struct Message {
        uint256 commandIndex;
        bytes commandData;
    }

    struct SubmittedData {
        bytes data;
        uint256 time;
        bytes[] signs;
    }

    struct DepositQueue {
        bytes[] depositData;
        uint256 depositNumber;
    }

    SubmittedData[] public submittedData;

    uint256 public minSigns;
    uint256 public timeLock;

    mapping(bytes32 => uint256) public hashExecutionTime;
    
    address public gnosis;
    address public locker;

    struct Bridging{
        address anyCallAddress;
        address multichainRouter;
        address nextChainExecutor;
        uint256 currentChain;
        uint256 nextChain;
    }

    Bridging public bridgingInfo;

    bool public upgradeStatus;

    address public handler;
    mapping(string => address) public ibAlluoSymbolToAddress;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet, 
        address _locker, 
        address _anyCall,
        uint256 _timeLock
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Executor: Not contract");
        gnosis = _multiSigWallet;
        minSigns = 2;
        timeLock = _timeLock;
        locker = _locker;
        bridgingInfo.anyCallAddress = _anyCall;
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);
    }


    /// @notice Allows anyone to submit data for execution of votes
    /// @dev Attempts to parse at high level and then confirm hash before submitting to queue
    /// @param data Payload fully encoded as required (see formatting using encoding functions below)

    function submitData(bytes memory data) external {

        (bytes32 hashed, Message[] memory _messages) = abi.decode(data, (bytes32, Message[]));

        require(hashed == keccak256(abi.encode(_messages)), "Hash doesn't match");

        SubmittedData memory newSubmittedData;
        newSubmittedData.data = data;
        newSubmittedData.time = block.timestamp;
        submittedData.push(newSubmittedData);
    }


    /// @notice Allow anyone to approve data for execution given off-chain signatures
    /// @dev Checks against existing sigs submitted and only allow non-duplicate multisig owner signatures to approve the payload
    /// @param _dataId Id of data payload to be approved
    /// @param _signs Array of off-chain EOA signatures to approve the payload.

    function approveSubmittedData(uint256 _dataId, bytes[] memory _signs) external {
        (bytes32 dataHash,) = abi.decode(submittedData[_dataId].data, (bytes32, Message[]));

        address[] memory owners = IGnosis(gnosis).getOwners();

        bytes[] memory submittedSigns = submittedData[_dataId].signs;
        address[] memory uniqueSigners = new address[](owners.length);
        uint256 numberOfSigns;

        for (uint256 i; i< submittedSigns.length; i++) {
            numberOfSigns++;
            uniqueSigners[i]= _getSignerAddress(dataHash, submittedSigns[i]);
        }

        for (uint256 i; i < _signs.length; i++) {
            for (uint256 j; j < owners.length; j++) {
                if(_verify(dataHash, _signs[i], owners[j]) && _checkUniqueSignature(uniqueSigners, owners[j])){
                    submittedData[_dataId].signs.push(_signs[i]);
                    uniqueSigners[numberOfSigns] = owners[j];
                    numberOfSigns++;
                    break;
                }
            }
        }
    }

    function executeSpecificData(uint256 index) external {
            (bytes32 hashed, Message[] memory messages) = abi.decode(submittedData[index].data, (bytes32, Message[]));
            require(submittedData[index].time + timeLock < block.timestamp, "Under timelock");
            require(hashExecutionTime[hashed] == 0 || block.timestamp >= hashExecutionTime[hashed] + 1 days, "Duplicate Hash");

            if(submittedData[index].signs.length >= minSigns){
                for (uint256 j; j < messages.length; j++) {
                    if(messages[j].commandIndex == 0){
                        (string memory ibAlluoSymbol, uint256 newAnnualInterest, uint256 newInterestPerSecond) = abi.decode(messages[j].commandData, (string, uint256, uint256));
                        IIbAlluo ibAlluo = IIbAlluo(ibAlluoSymbolToAddress[ibAlluoSymbol]);
                        if(ibAlluo.annualInterest() != newAnnualInterest){
                           ibAlluo.setInterest(newAnnualInterest, newInterestPerSecond);
                        }
                    }
                    else if(messages[j].commandIndex == 1){
                        (uint256 mintAmount, uint256 period) = abi.decode(messages[j].commandData, (uint256, uint256));
                        IAlluoToken(ALLUO).mint(locker, mintAmount);
                        ILocker(locker).setReward(mintAmount / period);
                    }
                }
                hashExecutionTime[hashed] = block.timestamp;
                bytes memory finalData = abi.encode(submittedData[index].data, submittedData[index].signs);
                IAnyCall(bridgingInfo.anyCallAddress).anyCall(bridgingInfo.nextChainExecutor, finalData, address(0), bridgingInfo.nextChain, 0);
            }     
    }


    /// @notice Updates all the ibAlluo addresses used when setting APY
    function updateAllIbAlluoAddresses() public {
        address[] memory ibAlluoAddressList = ILiquidityHandler(handler).getListOfIbAlluos();
        for (uint256 i; i< ibAlluoAddressList.length; i++) {
            ibAlluoSymbolToAddress[IIbAlluo(ibAlluoAddressList[i]).symbol()] = ibAlluoAddressList[i];
        }
    }

    function encodeAllMessages(uint256[] memory _commandIndexes, bytes[] memory _commands) public pure  
    returns (
        bytes32 messagesHash, 
        Message[] memory messages,
        bytes memory inputData
    ) {
        require(_commandIndexes.length == _commands.length, "Array length mismatch");
        messages = new Message[](_commandIndexes.length);
        for (uint256 i; i < _commandIndexes.length; i++) {
            messages[i] = Message(_commandIndexes[i], _commands[i]);
        }
        messagesHash = keccak256(abi.encode(messages));

        inputData = abi.encode(
                messagesHash,
                messages
            );
    }

    function getSubmittedData(uint256 _dataId) external view returns(bytes memory, uint256, bytes[] memory){
        SubmittedData memory submittedDataExact = submittedData[_dataId];
        return(submittedDataExact.data, submittedDataExact.time, submittedDataExact.signs);
    }

    function decodeData(bytes memory _data) public pure returns(bytes32, Message[] memory){
        (bytes32 dataHash, Message[] memory messages) = abi.decode(_data, (bytes32, Message[]));
        return (dataHash, messages);
    } 

    function encodeApyCommand(
        string memory _ibAlluoName, 
        uint256 _newAnnualInterest, 
        uint256 _newInterestPerSecond
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_ibAlluoName, _newAnnualInterest, _newInterestPerSecond);
        return (0, encodedCommand);
    }

    function decodeApyCommand(
        bytes memory _data
    ) public pure returns (string memory, uint256, uint256) {
        return abi.decode(_data, (string, uint256, uint256));
    }

    function encodeMintCommand(
        uint256 _newMintAmount,
        uint256 _period
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_newMintAmount, _period);
        return (1, encodedCommand);
    }

    function decodeMintCommand(
        bytes memory _data
    ) public pure returns (uint256, uint256) {
        return abi.decode(_data, (uint256, uint256));
    }


    function grantRole(bytes32 role, address account)
    public
    override
    onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Executor: Not contract");
        }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(bool _status)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }

    function changeTimeLock(uint256 _newTimeLock)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        timeLock = _newTimeLock;
    }

    function _verify(bytes32 data, bytes memory signature, address account) internal pure returns (bool) {
        return data
            .toEthSignedMessageHash()
            .recover(signature) == account;
    }
    function _getSignerAddress(bytes32 data, bytes memory signature) internal pure returns (address) {
        return data
            .toEthSignedMessageHash()
            .recover(signature);
    }
    
    function _checkUniqueSignature(address[] memory _uniqueSigners, address _signer) internal pure returns (bool) {
        for (uint256 k; k< _uniqueSigners.length; k++) {
            if (_uniqueSigners[k] ==_signer) {
                return false;
            }
        }
        return true;
    }

    /// Admin functions 
    function setHandler(address newHandler)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newHandler.isContract(), "Executor: Not contract");
        handler = newHandler;
    }

    /**
    * @notice Set the address of the multisig.
    * @param _gnosisAddress  
    **/
    function setGnosis(address _gnosisAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        gnosis = _gnosisAddress;
    }

    function setLocker(address _lockerAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        locker = _lockerAddress;
    }

    /// @notice Sets the minimum required signatures before data is accepted on L2.
    /// @param _minSigns New value
    function setMinSigns(uint256 _minSigns) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minSigns = _minSigns;
    }
    
    function setAnyCallAddresses(address _newAnyCallAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgingInfo.anyCallAddress = _newAnyCallAddress;
    }

    function setNextChainExecutor(address _newAddress, uint256 chainNumber) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgingInfo.nextChainExecutor = _newAddress;
        bridgingInfo.nextChain = chainNumber;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }
}


interface IAnyCall {
    function anyCall(address _to, bytes calldata _data, address _fallback, uint256 _toChainID, uint256 _flags) external;

}