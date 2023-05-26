// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract DesynOwnable {
    // State variables
    mapping(address => bool) public adminList;
    uint public allOwnerPercentage = 10000;

    address _owner;
    address[] owners;
    uint[] ownerPercentage;
    bool initialized;
    // Event declarations

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed newAdmin, uint indexed amount);
    event RemoveAdmin(address indexed oldAdmin, uint indexed amount);

    // Modifiers

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    modifier onlyAdmin() {
        require(adminList[msg.sender] || msg.sender == _owner, "onlyAdmin");
        _;
    }

    // Function declarations

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
    }

    function initHandle(address[] memory _owners, uint[] memory _ownerPercentage) external {
        require(_owners.length == _ownerPercentage.length, "ownerP");
        require(!initialized, "initialized!");
        
        _addAdmin(_owners);

        owners = _owners;
        ownerPercentage = _ownerPercentage;

        initialized = true;
        _ownerPercentageChecker();
    }

    function setManagersInfo(address[] memory _owners, uint[] memory _ownerPercentage) external onlyOwner {
        _clearAdmin();
        _addAdmin(_owners);
        owners = _owners;
        ownerPercentage = _ownerPercentage;
        _ownerPercentageChecker();
    }

    function _ownerPercentageChecker() internal view {
        uint totalPercentage;
        for (uint i; i < ownerPercentage.length; i++) {
            totalPercentage+=ownerPercentage[i];
        } 
        require(totalPercentage == 10000, "ERR_ILLEGAL_PERCENTAGE"); 
    }

    function _addAdmin(address[] memory admins) internal {
        bool hasOwner;
        for (uint i; i < admins.length; i++) {
            adminList[admins[i]] = true;
            if(admins[i] == _owner) hasOwner = true;
        } 

        require(hasOwner, "ERR_NEW_ADMINS_HAS_NO_OWNER");    
    }

    function _clearAdmin() internal {
        for(uint i; i < owners.length; i++) {
            delete adminList[owners[i]];
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     * @dev external for gas optimization
     * @param newOwner - address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        for (uint i;i < owners.length; i++) {
            if (owners[i] == _owner) {
                owners[i] = newOwner;
            }
        }

        adminList[_owner] = false;
        adminList[newOwner] = true;
        _owner = newOwner;
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwnerPercentage() external view returns (uint[] memory) {
        return ownerPercentage;
    }

    /**
     * @notice Returns the address of the current owner
     * @dev external for gas optimization
     * @return address - of the owner (AKA controller)
     */
    function getController() external view returns (address) {
        return _owner;
    }
}