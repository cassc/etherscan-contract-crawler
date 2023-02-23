// contracts/Lock.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../common/BaseGovernanceWithUserUpgradable.sol";
import "../interfaces/IDepositManager.sol";
import "../interfaces/IUnlockSchedule.sol";
import "../interfaces/ISplitManager.sol";

// TODO Add events

contract FixedValueLock is BaseGovernanceWithUserUpgradable, ERC721EnumerableUpgradeable {
    string constant NAME = "Polkalokr Lock";
    string constant SYMBOL = "LKR-LOCK";
    uint256 private totalIDs;
    uint256 public totalLockedAmount;
    uint256 public assignedAmount;

    bool public canAddBeneficiaries;
    bool public canRemoveBeneficiaries;
    bool public canTransfer;
    bool public firstReleaseReached;

    bytes32 public constant BENEFICIARY_MANAGER_ROLE = keccak256("BENEFICIARY_MANAGER_ROLE");
    bytes32 public constant DEPOSIT_MANAGER_ROLE = keccak256("DEPOSIT_MANAGER_ROLE");

    IUnlockSchedule public schedule;
    IDepositManager public depositManager;
    ISplitManager public splitManager;

    IERC20Upgradeable public tokenERC20;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Claimed(uint256 indexed nftId, address indexed beneficiary, uint256 amount);
    event Added(address[] indexed beneficiaries, uint256[] beneficiariesAmounts);
    event Removed(uint256 indexed nftId, address indexed beneficiary, uint256 amount);
    event NFTClaimed(uint256 indexed nftId, address indexed beneficiary);
    event Minted(address[] addresses, uint256[] IDs);
    event FixedValueLockInitialized(address);

    modifier onlyBeneficiaryManager() {
        require(hasRole(BENEFICIARY_MANAGER_ROLE, _msgSender()), "ERROR: You are not the Beneficiary Manager");
        _;
    }

    modifier onlyDepositManager() {
        require(hasRole(DEPOSIT_MANAGER_ROLE, _msgSender()), "ERROR: Only the DepositManager");
        _;
    }

    modifier checkFirstRelease() {
        block.timestamp < schedule.lockStart() ? firstReleaseReached = false : firstReleaseReached = true ;
        require(!firstReleaseReached, "First release reached, cant add/remove new beneficiaries");
        _;
    }

    function initialize(
        bytes memory lockData,
        bytes memory beneficiariesData
    ) 
        public 
        initializer 
    {
        (
            ,
            , 
            ,
            ,
            address governanceAddress,
            ,
            ,
            ,
            
        ) = abi.decode(
            lockData, 
            (
                IUnlockSchedule,
                IDepositManager,
                ISplitManager,
                IERC20Upgradeable /*token*/,
                address /*governanceAddress*/,
                bool /*canAddBeneficiaries*/,
                bool /*canRemoveBeneficiaries*/,
                bool /*canTransfer*/,
                uint256 /*lockedAmount*/
            )
        );

        __BaseGovernanceWithUser_init(governanceAddress);
        __ERC721_init_unchained(NAME, SYMBOL);
        __ERC721Enumerable_init_unchained();
        __Lock_init(lockData, beneficiariesData);
    }

    function __Lock_init(
            bytes memory lockData,
            bytes memory beneficiariesData
    ) internal onlyInitializing {

        (
            IUnlockSchedule _schedule,
            IDepositManager _depositManager, 
            ISplitManager _splitManager,
            IERC20Upgradeable _tokenERC20,
            ,
            bool _canAddBeneficiaries,
            bool _canRemoveBeneficiaries,
            bool _canTransfer,
            uint256 _lockedAmount
        ) = abi.decode(
            lockData, 
            (
                IUnlockSchedule,
                IDepositManager,
                ISplitManager,
                IERC20Upgradeable,
                address,
                bool,
                bool,
                bool,
                uint256
            )
        );

        schedule = _schedule;
        depositManager = _depositManager;
        splitManager = _splitManager;
        tokenERC20 = _tokenERC20;
        canAddBeneficiaries = _canAddBeneficiaries;
        canRemoveBeneficiaries = _canRemoveBeneficiaries;
        canTransfer = _canTransfer;
        totalLockedAmount = _lockedAmount;

        _setupRole(BENEFICIARY_MANAGER_ROLE, _msgSender());
        _setupRole(DEPOSIT_MANAGER_ROLE, address(_depositManager));
        _initializeBeneficiaries(beneficiariesData, _lockedAmount);
        emit FixedValueLockInitialized(address(this));
    }

    function _initializeBeneficiaries(bytes memory _data,  uint256 _lockedAmount) internal onlyInitializing {
        tokenERC20.safeTransferFrom(_msgSender(), address(this), _lockedAmount);
        require(tokenERC20.balanceOf(address(this)) == _lockedAmount, "ERROR: Can't Lock Tokens With TX Fee");
        if(_data.length == 0 && _lockedAmount == 0 && canAddBeneficiaries == true) {
            // Expect beneficiaries to be added later
            return;
        }
        assignedAmount += depositManager.addDeposits(_data, _lockedAmount);

    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function lockStartTime() public view returns (uint256 lockStart, bool isReached) {
        lockStart = schedule.lockStart();
        isReached = (block.timestamp > lockStart);
        return (lockStart, isReached);
    }

    /**
     * @notice Get all the information from a specific ID
     * @param id NFT ID of the NFT for which the information is required
     * @return owner Owner or beneficiary of the NFT
     * @return lockedAmount The actual balance of amount locked
     * @return claimable The actual amount that the owner can claim
     * @return startLock The time when the lock start
     * @return endLock The time when the lock will end
     */
    function getInfoBySingleID(uint256 id) view external returns (address owner, uint256 lockedAmount, uint256 claimable, uint256 startLock, uint256 endLock){
        owner = ownerOf(id);
        (,, uint256 initAmount, uint256 claimed) = depositManager.getProperties(id);
        startLock = schedule.lockStart();
        endLock = schedule.lockEnd();
        lockedAmount = initAmount - claimed;
        claimable = schedule.unlockedAmount(initAmount) - claimed;
        if (claimable > lockedAmount) {
            claimable = lockedAmount;
        }
    }

    /**
     * @notice Get all the information from a set of IDs
     * @param ids List of NFT IDs which the information is required
     * @return owners List of owners or beneficiaries
     * @return lockedAmount List of actual balance of amount locked
     * @return claimable List of actual amount that is claimable
     */
    function getInfoByManyIDs(uint256[] memory ids) view external returns(address[] memory owners, uint256[] memory lockedAmount, uint256[] memory claimable) {
        uint256 length = ids.length;
        owners = new address[](length);
        lockedAmount = new uint256[](length);
        claimable = new uint256[](length);
        for(uint256 i; i < length; ) {
            (, , uint256 initAmount, uint256 claimed) = depositManager.getProperties(ids[i]);
            owners[i] = ownerOf(ids[i]);
            lockedAmount[i] = initAmount - claimed;
            claimable[i] = schedule.unlockedAmount(initAmount) - claimed;
            if (claimable[i] > lockedAmount[i]) {
                claimable[i] =lockedAmount[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function getNextReleaseTimestamp() view external returns(uint256) {
        return schedule.nextRelease();
    }

    function getUnsplittablePart(uint256 id) view external returns(uint256) {
        return splitManager.getLockedPart(id);
    }

    function getSplittablePart(uint256 id) view external returns(uint256) {
        return splitManager.getUnlockedPart(id);
    }

    /**
     * @notice Add new beneficiaries to the Lock
     * @dev Contracts should have enought allowance to transfer the totalAmount
     * @param data ABI-encoded data of beneficiaries (arrays of addresses and amounts - specific to DepositManager)
     * @param totalAmount Total amount of tokens to be locked for additional beneficiaries
     */
    function addBeneficiaries(bytes calldata data, uint256 totalAmount) external checkFirstRelease onlyBeneficiaryManager {
        require(canAddBeneficiaries, "ERROR: Cant add new beneficiaries");
        require(totalAmount + assignedAmount <= totalLockedAmount, "ERROR: Beneficiaries amounts exceeds the locked amount");
        assignedAmount += depositManager.addDeposits(data, totalAmount);
        (address[] memory addresses, uint256[] memory amounts) = 
            abi.decode(data, (address[], uint[]));
        emit Added(addresses, amounts);
    }

    /**
     * @notice Remove existing beneficiaries from the Lock
     * @dev All the IDs inside of the array should exists
     * @param data ABI-encoded data of beneficiaries IDs (arrays of IDs - specific to DepositManager)
     */
    function removeBeneficiaries(bytes calldata data) external checkFirstRelease onlyBeneficiaryManager {
        require(canRemoveBeneficiaries, "ERROR: Cannot remove beneficiaries");
        uint256[] memory IDs = abi.decode(data, (uint[]));
        for (uint256 i; i < IDs.length; ) {
            (address beneficiary, , uint256 initialAmount, uint256 claimed) =  depositManager.getProperties(IDs[i]);
            uint256 unlockedAmount = schedule.unlockedAmount(initialAmount);
            uint256 claimable = unlockedAmount - claimed;
            uint256 removable = initialAmount - unlockedAmount;
            depositManager.removeDeposits(IDs[i]);
            if(claimable != 0){
                tokenERC20.safeTransfer(beneficiary, claimable);
                emit Claimed(IDs[i], beneficiary, claimable);
            }
            if(removable != 0){
                assignedAmount -= removable;
            }
            emit Removed(IDs[i], beneficiary, removable);
            unchecked {
                ++i;
            }
        }
    }
    /**
     * @notice Claim and mint a NFT from the MerkleTree
     * @param ownershipProof ABI-encoded data to verify in MerkleTree (specific to DepositManager with Merkle Tree)
     * @return The Minted NFT Id
     */
    function claimNFT(bytes calldata ownershipProof) external returns(uint) {
        (bool _success, uint256 _ID) = depositManager.verifyOwnership(_msgSender(), ownershipProof);
        require(_success, "ERROR: You are not the owner or are approved for this NFT");
        emit NFTClaimed(_ID, ownerOf(_ID));
        return _ID;
    }
    
    /**
    * @notice Claim unlocked/free tokens from a specified NFT ID
    * @param nftId NFT ID to be claimed
    * @dev The data to proof the ownership is only require if the NFT is not minted yet
    */
    function claimUnlocked(uint256 nftId) external {
        bool _success = _isApprovedOrOwner(_msgSender(), nftId);
        require(_success, "ERROR: You are not the owner or are approved for this NFT");
        (, , uint256 initialAmount, uint256 claimed) =  depositManager.getProperties(nftId);
        uint256 unlockedAmount = schedule.unlockedAmount(initialAmount) - claimed;
        depositManager.updateClaimedAmount(nftId, unlockedAmount);
        tokenERC20.safeTransfer(_msgSender(), unlockedAmount);
        emit Claimed(nftId, _msgSender(), unlockedAmount);
    }

    /**
     * @notice Split a NFT
     * @param originId NFT ID to be split
     * @param splitParts List of proportions normalized to be used in the split
     * @param addresses List of addresses of beneficiaries
     * @dev The data to proof the ownership is only require if the NFT is not minted yet
     */
    function split(uint256 originId, uint256[] memory splitParts, address[] memory addresses) external returns(uint256[] memory) {
        bool _success = _isApprovedOrOwner(_msgSender(), originId);
        require(_success, "ERROR: You are not the owner or are approved for this NFT");
        uint256 lockedPart = splitManager.getLockedPart(originId);
        require(lockedPart < 1e18, "ERROR: All the NFT is locked");
        uint256[] memory newIDs = depositManager.split(originId, lockedPart, splitParts, addresses);
        bool success = splitManager.registerSplit(originId, newIDs, splitParts);
        require(success, "ERROR: You can not Split this NFT");
        return newIDs;
    }

    /**
     * @notice Deposit Manager call and mint an amount (count) of NFTs with addresses owners
     * @dev This function can be called only for DepositManager address
     * @param count Amount of NFTs to be minted
     * @param addresses Array of addresses to be Owners of the new NFTs
     * @return Array list with the IDs of the new NFTs
     */
    function mintNFTs(uint256 count, address[] memory addresses) external onlyDepositManager returns(uint256[] memory) {
        uint256[] memory IDs = new uint256[](count);
        for(uint256 i; i < count; ) {
            _safeMint(addresses[i], totalIDs + i);
            IDs[i] = totalIDs + i;
            unchecked {
                ++i;
            }
        }
        totalIDs += count;
        emit Minted(addresses,IDs);
        return IDs;
    }

    function _withdrawUnassigned(uint256 unassignedAmount) internal {
        //require(totalLockedAmount - assignedAmount > 0, "ERROR: Unassigned amount should be greater than 0");
        require(unassignedAmount > 0, "ERROR: Unassigned amount should be greater than 0");
        assignedAmount += unassignedAmount;
        tokenERC20.safeTransfer(_msgSender(), unassignedAmount);
    }

    function _withdrawRemainingLocked() internal returns(uint256) {
        uint256 stillLockedAmount = totalLockedAmount - schedule.unlockedAmount(totalLockedAmount);
        require(stillLockedAmount > 0, "ERROR: Remaining locked amount should be greater than 0");
        require(stillLockedAmount <= totalLockedAmount, "ERROR: Remaining locked amount can not be greater than total locked amount");
        assignedAmount = totalLockedAmount;
        tokenERC20.safeTransfer(_msgSender(), stillLockedAmount);
        return stillLockedAmount;
    }

    /**
     * @notice If lock owner have the capability, can withdraw all remaining funds after the lock ends
     * @dev This function can be called only after the lock ends
     */
    function withdrawAll() external onlyBeneficiaryManager {
        uint256 lockEnd = schedule.lockEnd();
        require(block.timestamp > lockEnd, "ERROR: Lock is not ended");

        uint256 unassignedAmount = totalLockedAmount - assignedAmount;

        (bool ownerCanWithdraw, bool isEventSchedule) = schedule.withdrawCapability();
        if(ownerCanWithdraw && isEventSchedule){//For EventUnlockSchedule
            _withdrawRemainingLocked();
        }else{//For all timebased UnlockSchedules
            _withdrawUnassigned(unassignedAmount);
        }
    }

    /**
     * @notice Deposit Manager call and burn a single NFT IDs
     * @dev This function can be called only for DepositManager address
     * @param id NFT ID to be burned
     */
    function burnNFT(uint256 id) external onlyDepositManager {
        _burn(id);
    }
    
    function  _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (!( (from == address(0)) || (to == address(0)) )) {  // not a mint or burn
            require(canTransfer, "ERROR: The lock policy do not allow transfers.");
            require(splitManager.getLockedPart(tokenId) == 0, "ERROR: There is locked part.");
            depositManager.transfer(to,tokenId);  
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}