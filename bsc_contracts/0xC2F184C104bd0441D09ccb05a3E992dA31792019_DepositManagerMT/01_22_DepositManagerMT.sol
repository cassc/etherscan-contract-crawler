// contracts/DepositManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./common/BaseGovernanceWithUserUpgradable.sol";
import "./interfaces/ILock.sol";
import "./interfaces/IUnlockSchedule.sol";

 /**
  * @title Deposit manager
  * @author Polkalokr
  * @notice This contract is used by the Lock to manage beneficiaries and their amounts, working with merkle trees
  * @dev 
  */
contract DepositManagerMT is BaseGovernanceWithUserUpgradable, IDepositManager {

    struct Property {
        address beneficiary;
        uint256 additionTime;
        uint256 initialAmount;
        uint256 claimedAmount;
    }
    mapping(uint256 => Property) private _properties;

    ILock public lockContract;
    bytes32 public constant LOCK_CONTRACT_ROLE = keccak256("LOCK_CONTRACT_ROLE");
    IUnlockSchedule internal schedule;

    uint256 internal constant EXP = 1e18;
    uint256 internal constant MAXIMUM_LOCK_AMOUNT = 1e41;
    uint256 internal constant SQREXP = 1e36;

    using MerkleProof for bytes32[];
    bytes32 public root;

    mapping (bytes32 => bool) private _isMinted;

    modifier onlyLockContract() {
        require(hasRole(LOCK_CONTRACT_ROLE, _msgSender()), "ERROR: Only lock");
        _;
    }

    function initialize(ILock _lock, bytes calldata data) public initializer {
        (address governanceAddress) = abi.decode(data, (address));
        __DepositManager_init(_lock, governanceAddress);
    }

    function __DepositManager_init(ILock _lock, address governanceAddress) internal onlyInitializing {
        __BaseGovernanceWithUser_init(governanceAddress);
        __DepositManager_init_unchained(_lock);
    }

    function __DepositManager_init_unchained(ILock _lock) internal onlyInitializing {
        lockContract = _lock;
        // schedule = IUnlockSchedule(_lock.schedule()); // THis will fail because we initialize DM before the Lock
        _setupRole(LOCK_CONTRACT_ROLE, address(_lock));
    }

    /**
     * @notice Get all the properties from an ID-NFT that the DM manage.
     * @dev Only will get the data that the Deposit Manager have stored
     * @param id NFT ID to get the properties
     * @return beneficiary or owner of the ID-NFT 
     * @return additionTime the Timestamp of when the beneficiary was added
     * @return initialAmount that was locked on this ID-NFT
     * @return claimedAmount so far 
     */
    function getProperties(uint256 id) public view override returns(address beneficiary, uint256 additionTime, uint256 initialAmount, uint256 claimedAmount) {
        Property memory property = _properties[id];
        beneficiary  = property.beneficiary;
        additionTime = property.additionTime;
        initialAmount = property.initialAmount; 
        claimedAmount = property.claimedAmount;
    }

    /**
     * @notice Add a new deposits and save the data
     * @dev If is the first call, the contract asume that Manager want to create the merkle tree. The contract will hash with keccak256 the data
     * @param data ABI-encoded data of beneficiaries (arrays of addresses and amounts)
     * @param totalAmount Total amount of tokens to be locked for additional beneficiaries
     */
    function addDeposits(bytes calldata data, uint256 totalAmount) external onlyLockContract override returns(uint256 deposited){
        (address[] memory addresses, uint256[] memory amounts) = _decodeDataBeneficiearies(data);
        require(_checkAmounts(amounts, totalAmount), "ERROR: Bad distribution amounts");
        if(address(schedule) == address(0)) {
            schedule = IUnlockSchedule(lockContract.schedule());
        }
        deposited = totalAmount;
        if(root != 0) {
            uint256 time = block.timestamp;
            uint256[] memory IDs = lockContract.mintNFTs(addresses.length, addresses);
            if(time > lockContract.lockStartTime()){
                uint256 claimablePart = schedule.unlockedAmount(SQREXP);
                for (uint256 i; i < addresses.length;) {
                    require(amounts[i] < MAXIMUM_LOCK_AMOUNT, "ERROR: Maximun Locked Amount Exceeded");
                    uint256 fullAmount = amounts[i] * SQREXP / (SQREXP - claimablePart);
                    uint256 claimed = fullAmount - amounts[i];
                    _setBeneficiary(IDs[i], addresses[i], time, fullAmount, claimed);
                    unchecked {
                        ++i;
                    }
                }
            }
            else{
                for (uint256 i; i < addresses.length;) {
                    _setBeneficiary(IDs[i], addresses[i], time, amounts[i], 0);
                    unchecked {
                        ++i;
                    }
                }
            }
        } else {
            _makeRoot(addresses, amounts);
        }
    }

    /**
     * @notice Remove an existing deposit and delete the data
     * @dev Manager benefiary onyl can remove Beneficiaries/ID that are already minted
     * @param id beneficiaries ID
     */
    function removeDeposits(uint256 id) external onlyLockContract override {
        lockContract.burnNFT(id);
        _removeID(id);
    }

    /**
     * @notice Split a deposit
     * @dev Split a deposit with IDs provided by the Lock Contract
     * @param originId NFT ID to be split
     * @param splitParts List of proportions normalized to be used in the split
     * @param addresses List of addresses of beneficiaries
     */
    function split(uint256 originId, uint256 lockedPart, uint256[] memory splitParts, address[] memory addresses) external onlyLockContract override returns(uint256[] memory){
        (address beneficiary, uint256 additionTime, uint256 initialAmount, uint256 amountClaimed) = getProperties(originId);
        uint256 amountBeneficiaries = addresses.length;
        if(lockedPart > 0){
            require(addresses[0] == beneficiary, "ERROR: You can't transfer the locked part");
        }
        uint256[] memory newIDs = lockContract.mintNFTs(amountBeneficiaries, addresses);
        require(_checkSplit(newIDs, splitParts, addresses), "ERROR: Check Split failed");

        lockContract.burnNFT(originId);
        _removeID(originId);
        for (uint256 i; i < amountBeneficiaries;) {
            uint256 _initialAmount = splitParts[i] * initialAmount / EXP;
            uint256 _amountClaimed = splitParts[i] * amountClaimed / EXP;
            _setBeneficiary(newIDs[i], addresses[i], additionTime, _initialAmount, _amountClaimed);
            unchecked {
                ++i;
            }
        }
        return newIDs;
    }

    /**
     * @notice Update the claimed amount of an NFT ID
     * @param id NFT ID to be update
     * @param amountToClaim The amount to claim and update
     */
    function updateClaimedAmount(uint256 id, uint256 amountToClaim) external onlyLockContract override {
        require(
            _properties[id].initialAmount > _properties[id].claimedAmount + amountToClaim,
            "ERROR: Not enought balance -  Deposit"
        );
        _properties[id].claimedAmount += amountToClaim;
    }
    
    /**
     * @notice Transfer an ID to a new beneficiary
     * @param to New beneficiary address that receives the NFT
     * @param id NFT ID to be transfer
     */
    function transfer(address to, uint256 id) external onlyLockContract override {
        _properties[id].beneficiary = to;
    }

    /**
     * @notice Verifying the onwership of a beneficiary for an ID
     * @dev data param will be empty. If this function is called, the ID just doesn't exist
     * @param beneficiary The beneficiary/caller
     * @param data initial amount and array of hashes of merkle tree leafs
     * @dev The data to proof the ownership is only require if the NFT is not minted yet
     */
    function verifyOwnership(address beneficiary, bytes calldata data) external override returns(bool, uint) {
        (uint256 initAmount, bytes32[] memory proof) = abi.decode(data, (uint, bytes32[]));
        bytes32 leaf = keccak256(abi.encodePacked(beneficiary, initAmount));
        if(proof.verify(root, leaf)) {
            require(!_isMinted[leaf], "ERROR: The NFT is already asigned and minted. Should be reference with their ID.");
            address[] memory addr = new address[](1);
            addr[0] = beneficiary;
            uint256[] memory ID = lockContract.mintNFTs(1, addr);
            _isMinted[leaf] = true;
            uint256 time = lockContract.lockStartTime();
            _setBeneficiary(ID[0], beneficiary, time, initAmount, 0);
            return (true, ID[0]);
        } else {
            return (false, 0);
        }
    }

    function _setBeneficiary(
        uint256 _id, 
        address _beneficiary, 
        uint256 _additionTime,
        uint256 _amount, 
        uint256 _claimed
        ) 
        internal 
        {
            _properties[_id] = Property(_beneficiary, _additionTime, _amount, _claimed);
    }

    function _removeID(uint256 _id) internal {
        delete _properties[_id]; 
    }

    function _checkAmounts(uint256[] memory amounts, uint256 totalAmount) internal pure returns(bool) {
        uint256 aux;
        for(uint256 i; i < amounts.length;) {
            aux += amounts[i];
            unchecked {
                ++i;
            }
        }
        return aux == totalAmount;
    }

    function _calculateByDivisible(uint256 a, uint256 divisible) internal pure returns(uint, uint) {
        uint256 amount1;
        uint256 amount2;
        if (a % divisible == 0) {
            amount1 = a / divisible;
            amount2 = a / divisible;
        } else {
            amount1 = (a-1) / divisible + 1;
            amount2 =   (a-1) / divisible;
        }
        return(amount1, amount2);
    }

    function _existIds(uint256[] memory IDs) internal view returns(bool) {
        for (uint256 i; i < IDs.length;) {
            if (_properties[IDs[i]].additionTime != 0) {
                return true;
            }  
            unchecked {
                ++i;
            }
        }
        return false;
    }
    
    function _checkSplit(
        uint256[] memory IDs, 
        uint256[] memory splitParts, 
        address[] memory addresses
        ) 
        internal 
        view 
        returns(bool) 
        {
        require(!_existIds(IDs), "ERROR: Existing ID");
        require(
            IDs.length == splitParts.length && IDs.length == addresses.length, 
            "ERROR: Addresses and amounts does not have same length"
        );
        uint256 total;
        for(uint256 i; i < splitParts.length;) {
            total += splitParts[i];
            unchecked {
                ++i;
            }
        }
        if(total == EXP){
            return true;
        } else {
            return false;
        }
    }

    function _decodeDataBeneficiearies(
        bytes calldata _data
        ) 
        internal 
        pure 
        returns(address[] memory, uint256[] memory) 
        {
        (address[] memory addresses, uint256[] memory amounts) = 
            abi.decode(_data, (address[], uint[]));
        require(
            addresses.length == amounts.length , 
            "ERROR: Addresses and amounts  does not have same length"
        );
        return(addresses, amounts);
    }

    function _makeRoot(address[] memory _addresses, uint256[] memory _amounts) internal {
            uint256 length = _addresses.length;
            bytes32[] memory hashes = new bytes32[](length);
            for(uint256 i; i < length;) {
                hashes[i] = keccak256(abi.encodePacked(_addresses[i], _amounts[i]));
                unchecked {
                    ++i;
                }
            }
            hashes = _sortHashes(hashes);
            while(length > 1) {
                uint256 _length = length % 2 == 0 ? length/2 : length/2 + 1;
                bytes32[] memory _hashes = new bytes32[](_length);
                for (uint256 i; i < _length;) {
                    if (2*i + 1 == length) {
                        _hashes[i] = hashes[2*i];
                    } else {
                        if (hashes[2*i] > hashes[2*i + 1]) {
                            _hashes[i] = keccak256(abi.encodePacked(hashes[2*i +1], hashes[2*i]));
                        } else {
                            _hashes[i] = keccak256(abi.encodePacked(hashes[2*i], hashes[2*i + 1]));
                        }
                    }
                    unchecked {
                       ++i;
                    }
                }
                length = _length;
                hashes = _hashes;
            }
            root = hashes[0];
    }

    function _sortHashes(bytes32[] memory _hashes) internal pure returns (bytes32[] memory) {
        uint256 _length = _hashes.length;
        for(uint256 i; i < _length;) {
            for(uint256 j = i+1; j < _length;) {
                if(_hashes[i] > _hashes[j]) {
                    (_hashes[i], _hashes[j]) = (_hashes[j], _hashes[i]);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return _hashes;
    }
}