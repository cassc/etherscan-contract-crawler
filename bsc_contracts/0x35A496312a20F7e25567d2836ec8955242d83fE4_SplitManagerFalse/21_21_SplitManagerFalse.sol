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
contract SplitManagerFalse is BaseGovernanceWithUserUpgradable, ISplitManager {
    bytes32 public constant LOCK_CONTRACT_ROLE = keccak256("LOCK_CONTRACT_ROLE");
    ILock public lockContract;

    event SplitManagerFalseInitialized(address);
    
    modifier onlyLockContract() {
        require(hasRole(LOCK_CONTRACT_ROLE, _msgSender()), "ERROR: Only lock");
        _;
    }

    function initialize(ILock lock, bytes calldata data) public initializer {
        (address governanceAddress) = abi.decode(data, (address));
        __SplitManagerFalse_init(lock, governanceAddress);
    }

    function __SplitManagerFalse_init(ILock _lock, address governanceAddress) internal onlyInitializing {
        __BaseGovernanceWithUser_init(governanceAddress);
        __SplitManagerFalse_init_unchained(_lock);
    }

    function __SplitManagerFalse_init_unchained(ILock _lock) internal onlyInitializing {
        _setupRole(LOCK_CONTRACT_ROLE, address(_lock));
        lockContract = _lock;
        emit SplitManagerFalseInitialized(address(this));
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
     * @return If the split is allowed
     */
    function registerSplit(
        uint /*originId*/, 
        uint[] memory /*splitedIds*/, 
        uint[] memory /*splitParts*/
        ) 
        external
        view
        override
        onlyLockContract
        returns(bool)
    {
            return false;
    }

    /**
     * @notice Get the locked part of a NFT/Deposit
     * @return The locked part proportion normalized
     */
    function getLockedPart(uint /*ID*/) public pure override returns(uint) {
        return 1e18;
    }

    /**
     * @notice Get the locked part of a NFT/Deposit
     * @return unlockedPart unlocked part proportion normalized
     */
    function getUnlockedPart(uint256 /*id*/) public pure override returns(uint256 unlockedPart) {
        unlockedPart = 0;
    }
}