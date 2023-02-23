// contracts/SplitManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../common/BaseGovernanceWithUserUpgradable.sol";
import "../interfaces/ILock.sol";

 /**
  * @title Split manager
  * @author Polkalokr
  * @notice This contract is used by the Lock to manage the split locks.
  * @dev 
  */
contract SplitManager is BaseGovernanceWithUserUpgradable, ISplitManager {
    bytes32 public constant LOCK_CONTRACT_ROLE = keccak256("LOCK_CONTRACT_ROLE");

    uint256 public initialLockedPart; //The initial locked part proportion normalized (100% = 1e18)
    ILock public lockContract;
    
    mapping(uint256 => bool) internal _isStoraged;
    mapping(uint256 => uint256) internal _lockedPart;

    uint256 private constant TOTAL = 1e18;

    event SplitManagerInitialized(address);

    modifier onlyLockContract() {
        require(hasRole(LOCK_CONTRACT_ROLE, _msgSender()), "ERROR: Only lock");
        _;
    }

    function initialize(ILock lock, bytes calldata data) public initializer {
        (uint256 _initialLockedPart, address governanceAddress) = abi.decode(data, (uint256, address));
        __SplitManager_init(lock, _initialLockedPart, governanceAddress);
    }

    function __SplitManager_init(ILock _lock, uint256 _initialLockedPart, address governanceAddress) internal onlyInitializing {
        __BaseGovernanceWithUser_init(governanceAddress);
        __SplitManager_init_unchained(_lock, _initialLockedPart);
    }

    function __SplitManager_init_unchained(ILock _lock, uint256 _initialLockedPart) internal onlyInitializing {
        require(_initialLockedPart > 0 && _initialLockedPart < TOTAL, "ERROR: The initial lockedpart must be >0 and <1e18");

        _setupRole(LOCK_CONTRACT_ROLE, address(_lock));
        lockContract = _lock;
        initialLockedPart = _initialLockedPart;
        emit SplitManagerInitialized(address(this));
    }

    function supportsInterface(
        bytes4 interfaceId
        ) 
        public 
        view 
        override(AccessControlUpgradeable) 
        returns(bool) 
    {
            return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Register a split
     * @dev The first ID and first splitPart must contain the locked part
     * @param originId NFT ID to be split
     * @param splitedIds List of NFTs IDs
     * @param splitParts List of proportions normalized to be used in the split
     * @return If the split is allowed
     */
    function registerSplit(
        uint256 originId, 
        uint256[] memory splitedIds, 
        uint256[] memory splitParts
        ) 
        external
        override
        onlyLockContract
        returns(bool)
    {
            require(_checkSplitPart(splitParts), "ERROR: Split must be exactly 100%.");
            uint256 locked = getLockedPart(originId);
            require(
                splitParts[0] >= locked, 
                "ERROR: There are not enough free tokens."
            );

            _lockedPart[splitedIds[0]] = TOTAL * locked / splitParts[0];
            _isStoraged[splitedIds[0]] = true;  
            for(uint256 i; i < splitParts.length;){
                _isStoraged[splitedIds[i]] = true;
                unchecked {
                    ++i;
                }
            }
            return true;
    }

    /**
     * @notice Get the locked part of a NFT/Deposit
     * @param id NFT ID to check the locked part
     * @return lockedPart locked part proportion normalized
     */
    function getLockedPart(uint256 id) public view override returns(uint256 lockedPart) {
        if(_isStoraged[id]){
            return _lockedPart[id];
        } else {
            return initialLockedPart;
        }
    }

    /**
     * @notice Get the locked part of a NFT/Deposit
     * @param id NFT ID to check the locked part
     * @return unlockedPart unlocked part proportion normalized
     */
    function getUnlockedPart(uint256 id) public view override returns(uint256 unlockedPart) {
        unlockedPart = TOTAL - getLockedPart(id);
    }

    function _checkSplitPart(uint256[] memory _splitParts) internal pure returns(bool) {
        uint256 splitPartsSum;
        for(uint256 i; i < _splitParts.length;) {
            splitPartsSum += _splitParts[i];
            unchecked {
                ++i;
            }
        }
        return splitPartsSum == TOTAL;
    }
}