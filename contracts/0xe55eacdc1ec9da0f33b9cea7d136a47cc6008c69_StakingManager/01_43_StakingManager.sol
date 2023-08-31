// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/ITNFT.sol";
import "./interfaces/IBNFT.sol";
import "./interfaces/IAuctionManager.sol";
import "./interfaces/IStakingManager.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IEtherFiNode.sol";
import "./interfaces/IEtherFiNodesManager.sol";
import "./TNFT.sol";
import "./BNFT.sol";
import "./EtherFiNode.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin-upgradeable/contracts/proxy/beacon/IBeaconUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol";

contract StakingManager is
    Initializable,
    IStakingManager,
    IBeaconUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    
    uint128 public maxBatchDepositSize;
    uint128 public stakeAmount;

    address public implementationContract;
    address public liquidityPoolContract;

    bool public whitelistEnabled;
    bytes32 public merkleRoot;

    ITNFT public TNFTInterfaceInstance;
    IBNFT public BNFTInterfaceInstance;
    IAuctionManager public auctionManager;
    IDepositContract public depositContractEth2;
    IEtherFiNodesManager public nodesManager;
    UpgradeableBeacon private upgradableBeacon;

    mapping(uint256 => address) public bidIdToStaker;

    address public admin;

    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    event StakeDeposit(address indexed staker, uint256 bidId, address withdrawSafe);
    event DepositCancelled(uint256 id);
    event ValidatorRegistered(address indexed operator, address indexed bNftOwner, address indexed tNftOwner, 
                              uint256 validatorId, bytes validatorPubKey, string ipfsHashForEncryptedValidatorKey);
    event WhitelistDisabled();
    event WhitelistEnabled();
    event MerkleUpdated(bytes32 oldMerkle, bytes32 indexed newMerkle);

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize to set variables on deployment
    /// @dev Deploys NFT contracts internally to ensure ownership is set to this contract
    /// @dev AuctionManager Contract must be deployed first
    /// @param _auctionAddress The address of the auction contract for interaction
    function initialize(address _auctionAddress) external initializer {
        require(_auctionAddress != address(0), "No zero addresses");
         
        stakeAmount = 32 ether;
        maxBatchDepositSize = 25;

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        auctionManager = IAuctionManager(_auctionAddress);
        depositContractEth2 = IDepositContract(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b);
    }

    /// @notice Allows depositing multiple stakes at once
    /// @param _candidateBidIds IDs of the bids to be matched with each stake
    /// @return Array of the bid IDs that were processed and assigned
    function batchDepositWithBidIds(uint256[] calldata _candidateBidIds, bytes32[] calldata _merkleProof)
        external payable whenNotPaused correctStakeAmount nonReentrant returns (uint256[] memory)
    {
        verifyWhitelisted(msg.sender, _merkleProof);

        require(_candidateBidIds.length > 0, "No bid Ids provided");
        uint256 numberOfDeposits = msg.value / stakeAmount;
        require(numberOfDeposits <= maxBatchDepositSize, "Batch too large");
        require( auctionManager.numberOfActiveBids() >= numberOfDeposits, "No bids available at the moment");

        uint256[] memory processedBidIds = new uint256[](numberOfDeposits);
        uint256 processedBidIdsCount = 0;

        for (uint256 i = 0;
            i < _candidateBidIds.length && processedBidIdsCount < numberOfDeposits;
            ++i) {
            uint256 bidId = _candidateBidIds[i];
            address bidStaker = bidIdToStaker[bidId];
            bool isActive = auctionManager.isBidActive(bidId);
            if (bidStaker == address(0) && isActive) {
                auctionManager.updateSelectedBidInformation(bidId);
                processedBidIds[processedBidIdsCount] = bidId;
                processedBidIdsCount++;
                _processDeposit(bidId);
            }
        }

        // resize the processedBidIds array to the actual number of processed bid IDs
        assembly {
            mstore(processedBidIds, processedBidIdsCount)
        }

        uint256 unMatchedBidCount = numberOfDeposits - processedBidIdsCount;
        if (unMatchedBidCount > 0) {
            _refundDeposit(msg.sender, stakeAmount * unMatchedBidCount);
        }

        return processedBidIds;
    }

    /// @notice Batch creates validator object, mints NFTs, sets NB variables and deposits into beacon chain
    /// @param _depositRoot The fetched root of the Beacon Chain
    /// @param _validatorId Array of IDs of the validator to register
    /// @param _depositData Array of data structures to hold all data needed for depositing to the beacon chain
    function batchRegisterValidators(
        bytes32 _depositRoot,
        uint256[] calldata _validatorId,
        DepositData[] calldata _depositData
    ) public whenNotPaused nonReentrant verifyDepositState(_depositRoot) {
        require(_validatorId.length == _depositData.length, "Array lengths must match");
        require(_validatorId.length <= maxBatchDepositSize, "Too many validators");

        for (uint256 x; x < _validatorId.length; ++x) {
            _registerValidator(_validatorId[x], msg.sender, msg.sender, _depositData[x]);
        }
    }

    /// @notice Creates validator object, mints NFTs, sets NB variables and deposits into beacon chain
    /// @param _depositRoot The fetched root of the Beacon Chain
    /// @param _validatorId Array of IDs of the validator to register
    /// @param _bNftRecipient Array of BNFT recipients
    /// @param _tNftRecipient Array of TNFT recipients
    /// @param _depositData Array of data structures to hold all data needed for depositing to the beacon chain
    function batchRegisterValidators(
        bytes32 _depositRoot,
        uint256[] calldata _validatorId,
        address _bNftRecipient, 
        address _tNftRecipient,
        DepositData[] calldata _depositData
    ) public whenNotPaused nonReentrant verifyDepositState(_depositRoot) {
        require(_validatorId.length == _depositData.length, "Array lengths must match");
        require(_validatorId.length <= maxBatchDepositSize, "Too many validators");

        for (uint256 x; x < _validatorId.length; ++x) {
            _registerValidator(_validatorId[x],_bNftRecipient, _tNftRecipient, _depositData[x]);    
        }  
    }

    /// @notice Cancels a user's deposits
    /// @param _validatorIds the IDs of the validators deposits to cancel
    function batchCancelDeposit(uint256[] calldata _validatorIds) public whenNotPaused nonReentrant {
        for (uint256 x; x < _validatorIds.length; ++x) {
            _cancelDeposit(_validatorIds[x]);    
        }  
    }

    /// @notice Sets the EtherFi node manager contract
    /// @param _nodesManagerAddress address of the manager contract being set
    function setEtherFiNodesManagerAddress(address _nodesManagerAddress) public onlyOwner {
        require(address(nodesManager) == address(0), "Address already set");
        require(_nodesManagerAddress != address(0), "No zero addresses");

        nodesManager = IEtherFiNodesManager(_nodesManagerAddress);
    }

    /// @notice Sets the Liquidity pool contract address
    /// @param _liquidityPoolAddress address of the liquidity pool contract being set
    function setLiquidityPoolAddress(address _liquidityPoolAddress) public onlyOwner {
        require(liquidityPoolContract == address(0), "Address already set");
        require(_liquidityPoolAddress != address(0), "No zero addresses");

        liquidityPoolContract = _liquidityPoolAddress;
    }

    /// @notice Sets the max number of deposits allowed at a time
    /// @param _newMaxBatchDepositSize the max number of deposits allowed
    function setMaxBatchDepositSize(uint128 _newMaxBatchDepositSize) public onlyAdmin {
        maxBatchDepositSize = _newMaxBatchDepositSize;
    }

    function registerEtherFiNodeImplementationContract(address _etherFiNodeImplementationContract) public onlyOwner {
        require(implementationContract == address(0), "Address already set");
        require(_etherFiNodeImplementationContract != address(0), "No zero addresses");

        implementationContract = _etherFiNodeImplementationContract;
        upgradableBeacon = new UpgradeableBeacon(implementationContract);      
    }

    /// @notice Instantiates the TNFT interface
    /// @param _tnftAddress Address of the TNFT contract
    function registerTNFTContract(address _tnftAddress) public onlyOwner {
        require(address(TNFTInterfaceInstance) == address(0), "Address already set");
        require(_tnftAddress != address(0), "No zero addresses");

        TNFTInterfaceInstance = ITNFT(_tnftAddress);
    }

    /// @notice Instantiates the BNFT interface
    /// @param _bnftAddress Address of the BNFT contract
    function registerBNFTContract(address _bnftAddress) public onlyOwner {
        require(address(BNFTInterfaceInstance) == address(0), "Address already set");
        require(_bnftAddress != address(0), "No zero addresses");

        BNFTInterfaceInstance = IBNFT(_bnftAddress);
    }

    /// @notice Upgrades the etherfi node
    /// @param _newImplementation The new address of the etherfi node
    function upgradeEtherFiNode(address _newImplementation) public onlyOwner {
        require(_newImplementation != address(0), "No zero addresses");
        
        upgradableBeacon.upgradeTo(_newImplementation);
        implementationContract = _newImplementation;
    }

    /// @notice Disables the bid whitelist
    /// @dev Allows both regular users and whitelisted users to bid
    function disableWhitelist() public onlyAdmin {
        whitelistEnabled = false;
        emit WhitelistDisabled();
    }

    /// @notice Enables the bid whitelist
    /// @dev Only users who are on a whitelist can bid
    function enableWhitelist() public onlyAdmin {
        whitelistEnabled = true;
        emit WhitelistEnabled();
    }

    /// @notice Updates the merkle root whitelists have been updated
    /// @dev Merkleroot Fetches generated in JS offline and sent to the contract
    /// @dev Used in the staking manager and LP
    /// @param _newMerkle New merkle root to be used for staking
    function updateMerkleRoot(bytes32 _newMerkle) external onlyAdmin {
        bytes32 oldMerkle = merkleRoot;
        merkleRoot = _newMerkle;

        emit MerkleUpdated(oldMerkle, _newMerkle);
    }

    function verifyWhitelisted(address _address, bytes32[] calldata _merkleProof) public view {
        if (whitelistEnabled) {
            bool verified = MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_address)));
            require(verified, "User is not whitelisted");
        }
    }

    function pauseContract() external onlyAdmin { _pause(); }
    function unPauseContract() external onlyAdmin { _unpause(); }

    /// @notice Updates the address of the admin
    /// @param _newAdmin the new address to set as admin
    function updateAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Cannot be address zero");
        admin = _newAdmin;
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Creates validator object, mints NFTs, sets NB variables and deposits into beacon chain
    /// @param _validatorId ID of the validator to register
    /// @param _bNftRecipient The address to receive the minted B-NFT
    /// @param _tNftRecipient The address to receive the minted T-NFT
    /// @param _depositData Data structure to hold all data needed for depositing to the beacon chain
    /// however, instead of the validator key, it will include the IPFS hash
    /// containing the validator key encrypted by the corresponding node operator's public key
    function _registerValidator(
        uint256 _validatorId, address _bNftRecipient, address _tNftRecipient, DepositData calldata _depositData
    ) internal {
        require(bidIdToStaker[_validatorId] == msg.sender, "Not deposit owner");        
        nodesManager.setEtherFiNodePhase(_validatorId, IEtherFiNode.VALIDATOR_PHASE.LIVE);

        // Deposit to the Beacon Chain
        bytes memory withdrawalCredentials = nodesManager.getWithdrawalCredentials(_validatorId);
        depositContractEth2.deposit{value: stakeAmount}(_depositData.publicKey, withdrawalCredentials, _depositData.signature, _depositData.depositDataRoot);

        nodesManager.incrementNumberOfValidators(1);
        nodesManager.setEtherFiNodeIpfsHashForEncryptedValidatorKey(_validatorId, _depositData.ipfsHashForEncryptedValidatorKey);

        auctionManager.processAuctionFeeTransfer(_validatorId);

        // Let validatorId = nftTokenId
        uint256 nftTokenId = _validatorId;
        TNFTInterfaceInstance.mint(_tNftRecipient, nftTokenId);
        BNFTInterfaceInstance.mint(_bNftRecipient, nftTokenId);

        emit ValidatorRegistered(
            auctionManager.getBidOwner(_validatorId),
            _bNftRecipient,
            _tNftRecipient,
            _validatorId,
            _depositData.publicKey,
            _depositData.ipfsHashForEncryptedValidatorKey
        );
    }

    function registerEth2DepositContract(address _address) public onlyOwner {
        require(_address != address(0), "No zero addresses");
        depositContractEth2 = IDepositContract(_address);
    }

    /// @notice Update the state of the contract now that a deposit has been made
    /// @param _bidId The bid that won the right to the deposit
    function _processDeposit(uint256 _bidId) internal {
        bidIdToStaker[_bidId] = msg.sender;
        uint256 validatorId = _bidId;
        address etherfiNode = createEtherfiNode(validatorId);
        nodesManager.setEtherFiNodePhase(validatorId, IEtherFiNode.VALIDATOR_PHASE.STAKE_DEPOSITED);
        emit StakeDeposit(msg.sender, _bidId, etherfiNode);
    }

    /// @notice Cancels a users stake
    /// @param _validatorId the ID of the validator deposit to cancel
    function _cancelDeposit(uint256 _validatorId) internal {
        require(bidIdToStaker[_validatorId] == msg.sender, "Not deposit owner");

        bidIdToStaker[_validatorId] = address(0);
        nodesManager.setEtherFiNodePhase(_validatorId, IEtherFiNode.VALIDATOR_PHASE.CANCELLED);
        nodesManager.unregisterEtherFiNode(_validatorId);

        // Call function in auction contract to re-initiate the bid that won
        auctionManager.reEnterAuction(_validatorId);
        _refundDeposit(msg.sender, stakeAmount);

        emit DepositCancelled(_validatorId);

        require(bidIdToStaker[_validatorId] == address(0), "Bid already cancelled");
    }

    function createEtherfiNode(uint256 _validatorId) private returns (address) {
        BeaconProxy proxy = new BeaconProxy(address(upgradableBeacon), "");
        EtherFiNode node = EtherFiNode(payable(proxy));
        node.initialize(address(nodesManager));
        nodesManager.registerEtherFiNode(_validatorId, address(node));
        return address(node);
    }

    /// @notice Refunds the depositor their staked ether for a specific stake
    /// @dev called internally from cancelStakingManager or when the time runs out for calling registerValidator
    /// @param _depositOwner address of the user being refunded
    /// @param _amount the amount to refund the depositor
    function _refundDeposit(address _depositOwner, uint256 _amount) internal {
        (bool sent, ) = _depositOwner.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    //--------------------------------------------------------------------------------------
    //------------------------------------  GETTERS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Fetches the address of the implementation contract currently being used by the proxy
    /// @return the address of the currently used implementation contract
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /// @notice Fetches the address of the implementation contract currently being used by the beacon proxy
    /// @return the address of the currently used implementation contract
    function implementation() public view override returns (address) {
        return upgradableBeacon.implementation();
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier correctStakeAmount() {
        require(msg.value > 0 && msg.value % stakeAmount == 0, "Insufficient staking amount");
        _;
    }

    modifier verifyDepositState(bytes32 _depositRoot) {
        // disable deposit root check if none provided
        if (_depositRoot != 0x0000000000000000000000000000000000000000000000000000000000000000) {
            bytes32 onchainDepositRoot = depositContractEth2.get_deposit_root();
            require(_depositRoot == onchainDepositRoot, "deposit root changed");
        }
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }
}