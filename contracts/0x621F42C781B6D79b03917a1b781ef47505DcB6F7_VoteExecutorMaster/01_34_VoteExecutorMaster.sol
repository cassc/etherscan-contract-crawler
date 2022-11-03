// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/ILiquidityHandler.sol";
import "../interfaces/IAlluoToken.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGnosis.sol";
import "../interfaces/IAlluoStrategyV2.sol";
import "../interfaces/IExchange.sol";                                                                 
import "../interfaces/IWrappedEther.sol";                               
import "../interfaces/IIbAlluo.sol";
import "../Farming/priceFeedsV2/PriceFeedRouterV2.sol";
import "./strategies/StrategyHandler.sol";

contract VoteExecutorMaster is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using ECDSAUpgradeable for bytes32;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    address public constant ALLUO = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
    address public gnosis;
    address public locker;
    address public exchangeAddress;
    address public priceFeed;
    address public liquidityHandler;
    address public strategyHandler;
    IWrappedEther public constant wETH = IWrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint256 public timeLock;
    uint256 public minSigns;
    bool public upgradeStatus;

    mapping(string => address) public ibAlluoSymbolToAddress;

    SubmittedData[] public submittedData;
    mapping(bytes32 => uint256) public hashExecutionTime;

    CrossChainInfo public crossChainInfo;
    mapping(uint => AssetBridging) public assetIdToAssetBridging;

    mapping(uint256 => Deposit[]) public assetIdToDepositList;

    struct Deposit{
        uint256 directionId;
        uint256 amount;
    }
    
    struct CrossChainInfo{
        address anyCallAddress;
        address anyCallExecutor;
        address nextChainExecutor;
        address previousChainExecutor;
        uint256 currentChain;
        uint256 nextChain;
        uint256 previousChain;
    }

    struct AssetBridging{
        address token;
        address anyToken;
        bytes4 functionSignature;
        address multichainRouter;
        uint256 minimumAmount;
    }
    
    struct Message {
        uint256 commandIndex;
        bytes commandData;
    }

    struct SubmittedData {
        bytes data;
        uint256 time;
        bytes[] signs;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Executor: Not contract");
        gnosis = _multiSigWallet;
        minSigns = 1;
        exchangeAddress = 0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec;

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {
        if(msg.sender != address(wETH)){
            wETH.deposit{value : msg.value}();
        }
    }

    /// @notice Allows anyone to submit data for execution of votes
    /// @dev Attempts to parse at high level and then confirm hash before submitting to queue
    /// @param data Payload fully encoded as required (see formatting using encoding functions below)

    function submitData(bytes memory data) external {

        (bytes32 hashed, Message[] memory _messages, uint256 timestamp) = abi.decode(data, (bytes32, Message[], uint256));

        require(hashed == keccak256(abi.encode(_messages, timestamp)), "Hash doesn't match");

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
        (bytes32 dataHash,,) = abi.decode(submittedData[_dataId].data, (bytes32, Message[], uint256));

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
            SubmittedData memory exactData = submittedData[index];
            (bytes32 hashed, Message[] memory messages,) = abi.decode(exactData.data, (bytes32, Message[], uint256));
            require(exactData.time + timeLock < block.timestamp, "Under timelock");
            require(hashExecutionTime[hashed] == 0, "Duplicate Hash");

            if(exactData.signs.length >= minSigns){
                uint256 currentChain = crossChainInfo.currentChain;

                StrategyHandler(strategyHandler).calculateAll();

                bool needToWithdrawTreasury;
                uint amountToWithdrawTreasury;
                Message memory lastMessage = messages[messages.length-1];
                if(lastMessage.commandIndex == 3){
                    (int256 treasuryDelta) = abi.decode(lastMessage.commandData, (int256));
                    StrategyHandler(strategyHandler).adjustTreasury(treasuryDelta);
                    if(treasuryDelta < 0){
                        needToWithdrawTreasury = true;
                        amountToWithdrawTreasury = uint(-treasuryDelta);
                    }
                }
               
                uint[] memory amountsDeployed = StrategyHandler(strategyHandler).getLatestDeployed();
                
                for (uint256 j; j < messages.length; j++) {
                    uint256 commandIndex = messages[j].commandIndex;
                    if(messages[j].commandIndex == 0){
                        (string memory ibAlluoSymbol, uint256 newAnnualInterest, uint256 newInterestPerSecond) = abi.decode(messages[j].commandData, (string, uint256, uint256));
                        IIbAlluo ibAlluo = IIbAlluo(ibAlluoSymbolToAddress[ibAlluoSymbol]);
                        if(ibAlluo.annualInterest() != newAnnualInterest){
                           ibAlluo.setInterest(newAnnualInterest, newInterestPerSecond);
                        }
                    }
                    else if(commandIndex == 1){
                        (uint256 mintAmount, uint256 period) = abi.decode(messages[j].commandData, (uint256, uint256));
                        IAlluoToken(ALLUO).mint(locker, mintAmount);
                        ILocker(locker).setReward(mintAmount / (period));
                    }

                    else if(commandIndex == 2) {
                        // Handle all withdrawals first and then add all deposit actions to an array to be executed afterwards
                        (uint256 directionId, uint256 percent) = abi.decode(messages[j].commandData, (uint256, uint256));
                        (address strategyPrimaryToken, StrategyHandler.LiquidityDirection memory direction) = StrategyHandler(strategyHandler).getDirectionFullInfoById(directionId);
                        if (direction.chainId == currentChain) {

                            if(percent == 0){
                                IAlluoStrategyV2(direction.strategyAddress).exitAll(direction.exitData, 10000, strategyPrimaryToken, address(this), false, false);
                                StrategyHandler(strategyHandler).removeFromActiveDirections(directionId);
                            }
                            else{
                                uint newAmount = percent * amountsDeployed[direction.assetId] / 10000;
                                if(newAmount < direction.latestAmount){
                                    uint exitPercent = 10000 - newAmount * 10000 / direction.latestAmount;
                                    IAlluoStrategyV2(direction.strategyAddress).exitAll(direction.exitData, exitPercent, strategyPrimaryToken, address(this), false, false);
                                }
                                else{
                                    uint depositAmount = newAmount - direction.latestAmount;
                                    assetIdToDepositList[direction.assetId].push(Deposit(directionId, depositAmount));
                                }
                            }
                        }
                    }
                }
                if(needToWithdrawTreasury){
                    assetIdToDepositList[0].push(Deposit(type(uint).max, amountToWithdrawTreasury));
                }
                hashExecutionTime[hashed] = block.timestamp;
                bytes memory finalData = abi.encode(exactData.data, exactData.signs);
                IAnyCall(crossChainInfo.anyCallAddress).anyCall(crossChainInfo.nextChainExecutor, finalData, address(0), crossChainInfo.nextChain, 0);
            }     
    }

    // Execute deposits. Only executes if we have sufficient balances.
    function _executeDeposits() internal {
        uint8 numberOfAssets = StrategyHandler(strategyHandler).numberOfAssets();
        for (uint256 i; i < numberOfAssets; i++) {
            Deposit[] storage depositList = assetIdToDepositList[i];
            address strategyPrimaryToken = StrategyHandler(strategyHandler).getPrimaryTokenByAssetId(i,1);
            address exchange = exchangeAddress;
            while(depositList.length > 0){
                Deposit memory depositInfo = depositList[depositList.length - 1];
                if(depositInfo.directionId != type(uint).max){

                    StrategyHandler.LiquidityDirection memory direction = StrategyHandler(strategyHandler).getLiquidityDirectionById(depositInfo.directionId);
                    (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(strategyPrimaryToken, i);
                    uint exactAmount = (depositInfo.amount * 10**fiatDecimals) / fiatPrice;
                    uint256 tokenAmount = exactAmount / 10**(18 - IERC20MetadataUpgradeable(strategyPrimaryToken).decimals());
                    uint256 actualBalance = IERC20MetadataUpgradeable(strategyPrimaryToken).balanceOf(address(this));
                    if(depositList.length == 1 && actualBalance < tokenAmount){
                        uint assetAmount = StrategyHandler(strategyHandler).getAssetAmount(i);
                        uint assetMaxSlippageAmount = assetAmount - (assetAmount * 9800 / 10000);
                        uint minAmount = (exactAmount - assetMaxSlippageAmount) / 10**(18 - IERC20MetadataUpgradeable(strategyPrimaryToken).decimals());
                        if(minAmount < actualBalance){

                            tokenAmount = actualBalance;
                        }
                        else{
                            revert("VEMaster: Slippage screwed you");
                        }
                    }
                    if (direction.entryToken != strategyPrimaryToken) {
                        IERC20MetadataUpgradeable(strategyPrimaryToken).approve(exchange, tokenAmount);
                        tokenAmount = IExchange(exchange).exchange(strategyPrimaryToken, direction.entryToken, tokenAmount, 0);
                    }
                    IERC20MetadataUpgradeable(direction.entryToken).safeTransfer(direction.strategyAddress, tokenAmount);
                    IAlluoStrategyV2(direction.strategyAddress).invest(direction.entryData, tokenAmount);
                    StrategyHandler(strategyHandler).addToActiveDirections(depositInfo.directionId);
                }
                else{
                    (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(strategyPrimaryToken, i);
                    uint exactAmount = (depositInfo.amount * 10**fiatDecimals) / fiatPrice;
                    uint256 tokenAmount = exactAmount / 10**(18 - IERC20MetadataUpgradeable(strategyPrimaryToken).decimals());
                    
                    IERC20MetadataUpgradeable(strategyPrimaryToken).safeTransfer(gnosis, tokenAmount);
                }
                depositList.pop();
            }
        }
        StrategyHandler(strategyHandler).calculateOnlyLp();
    }
    
    function executeDeposits() public onlyRole(DEFAULT_ADMIN_ROLE){
        _executeDeposits();
    }

   function _bridgeFunds() internal {
        CrossChainInfo memory crossChainInfoMemory = crossChainInfo;
        uint8 numberOfAssets = StrategyHandler(strategyHandler).numberOfAssets();
        for (uint256 i; i < numberOfAssets; i++) {
            AssetBridging memory currentBridgingInfo = assetIdToAssetBridging[i];
            address primaryToken = currentBridgingInfo.token;
            uint256 tokenBalance = IERC20MetadataUpgradeable(primaryToken).balanceOf(address(this));
            if (assetIdToDepositList[i].length == 0 && currentBridgingInfo.minimumAmount <= tokenBalance) {

                if(primaryToken == address(wETH)){
                    wETH.withdraw(tokenBalance);
                    bytes memory data = abi.encodeWithSelector(
                        currentBridgingInfo.functionSignature, 
                        currentBridgingInfo.anyToken, // anyWETH
                        crossChainInfoMemory.previousChainExecutor, 
                        crossChainInfoMemory.previousChain
                    );
                    currentBridgingInfo.multichainRouter.functionCallWithValue(data, tokenBalance);
                }
                else{
                    IERC20MetadataUpgradeable(primaryToken).approve(currentBridgingInfo.multichainRouter, tokenBalance);
                    bytes memory data = abi.encodeWithSelector(
                        currentBridgingInfo.functionSignature, 
                        currentBridgingInfo.anyToken, 
                        crossChainInfoMemory.previousChainExecutor, 
                        tokenBalance, 
                        crossChainInfoMemory.previousChain
                    );
                    currentBridgingInfo.multichainRouter.functionCall(data);
                }
            }
        }
    }

    function bridgeFunds() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _bridgeFunds();
    }

    function getSubmittedData(uint256 _dataId) external view returns(bytes memory, uint256, bytes[] memory){
        SubmittedData memory submittedDataExact = submittedData[_dataId];
        return(submittedDataExact.data, submittedDataExact.time, submittedDataExact.signs);
    }

    function encodeApyCommand(
        string memory _ibAlluoName, 
        uint256 _newAnnualInterest, 
        uint256 _newInterestPerSecond
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_ibAlluoName, _newAnnualInterest, _newInterestPerSecond);
        return (0, encodedCommand);
    }

    function encodeMintCommand(
        uint256 _newMintAmount,
        uint256 _period
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_newMintAmount, _period);
        return (1, encodedCommand);
    }

   function encodeLiquidityCommand(
        string memory _codeName,
        uint256 _percent
    ) public view  returns (uint256, bytes memory) {
        uint256 directionId = StrategyHandler(strategyHandler).getDirectionIdByName(_codeName);
        return (2, abi.encode(directionId, _percent));
    }

    function encodeTreasuryAllocationChangeCommand(
        int256 _delta
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_delta);
        return (3, encodedCommand);
    }
    
    function encodeAllMessages(uint256[] memory _commandIndexes, bytes[] memory _messages) public view  returns (bytes32 messagesHash, Message[] memory messages, bytes memory inputData) {
        uint256 timestamp = block.timestamp;
        uint length = _commandIndexes.length;
        require(length == _messages.length, "Array length mismatch");

        for (uint256 i; i < length; i++) {
            if(_commandIndexes[i] == 3){
                uint temporaryIndex = _commandIndexes[length-1];
                bytes memory temporaryMessage = _messages[length-1];
                _commandIndexes[length-1] = _commandIndexes[i];
                _messages[length-1] = _messages[i];
                _commandIndexes[i] = temporaryIndex;
                _messages[i] = temporaryMessage;
            }
        }

        messages = new Message[](length);
        for (uint256 i; i < length; i++) {
            messages[i] = Message(_commandIndexes[i], _messages[i]);
        }
        messagesHash = keccak256(abi.encode(messages, timestamp));
        inputData = abi.encode(
                messagesHash,
                messages,
                timestamp
        );
    }

    /// @notice Updates all the ibAlluo addresses used when setting APY
    function updateAllIbAlluoAddresses() public {
        address[] memory ibAlluoAddressList = ILiquidityHandler(liquidityHandler).getListOfIbAlluos();
        for (uint256 i; i< ibAlluoAddressList.length; i++) {
            ibAlluoSymbolToAddress[IIbAlluo(ibAlluoAddressList[i]).symbol()] = ibAlluoAddressList[i];
        }
    }

    function removeTokenByAddress(address _address, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "Wrong address");
        IERC20MetadataUpgradeable(_address).safeTransfer(msg.sender, _amount);
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

    function setCrossChainInfo(
        address _anyCallAddress,
        address _anyCallExecutor,
        address _nextChainExecutor,
        address _previousChainExecutor,
        uint256 _currentChain,
        uint256 _nextChain,
        uint256 _previousChain
        ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        crossChainInfo = CrossChainInfo(_anyCallAddress, _anyCallExecutor, _nextChainExecutor, _previousChainExecutor, _currentChain, _nextChain, _previousChain);
    }

    /// @notice Sets the minimum required signatures before data is accepted on L2.
    /// @param _minSigns New value
    function setMinSigns(uint256 _minSigns) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minSigns = _minSigns;
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

    function setHandler(address _newHandler)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newHandler.isContract(), "Executor: Not contract");
        liquidityHandler = _newHandler;
    }

    function setExchangeAddress(address _newExchange) public onlyRole(DEFAULT_ADMIN_ROLE) {
        exchangeAddress = _newExchange;
    }

    function setStrategyHandler(address _newHandler) public onlyRole(DEFAULT_ADMIN_ROLE) {
        strategyHandler = _newHandler;
    }

    function setPriceFeed(address _newFeed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        priceFeed = _newFeed;
    }

    function grantRole(bytes32 role, address account)
    public
    override
    onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Handler: Not contract");
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

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }

    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = destinations.length;
        for (uint256 i = 0; i < length; i++) {
            destinations[i].functionCall(calldatas[i]);
        }
    }
}


interface IAnyCall {
    function anyCall(address _to, bytes calldata _data, address _fallback, uint256 _toChainID, uint256 _flags) external;
}