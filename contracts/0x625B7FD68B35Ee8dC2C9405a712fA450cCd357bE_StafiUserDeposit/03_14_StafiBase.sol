pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/storage/IStafiStorage.sol";

abstract contract StafiBase {

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    IStafiStorage stafiStorage = IStafiStorage(0);


    /**
    * @dev Throws if called by any sender that doesn't match a network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }


    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }


    /**
    * @dev Throws if called by any sender that isn't a trusted node
    */
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.trusted", _nodeAddress))), "Invalid trusted node");
        _;
    }
    
    /**
    * @dev Throws if called by any sender that isn't a super node
    */
    modifier onlySuperNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.super", _nodeAddress))), "Invalid super node");
        _;
    }


    /**
    * @dev Throws if called by any sender that isn't a registered staking pool
    */
    modifier onlyRegisteredStakingPool(address _stakingPoolAddress) {
        require(getBool(keccak256(abi.encodePacked("stakingpool.exists", _stakingPoolAddress))), "Invalid staking pool");
        _;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(roleHas("owner", msg.sender), "Account is not the owner");
        _;
    }


    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlyAdmin() {
        require(roleHas("admin", msg.sender), "Account is not an admin");
        _;
    }


    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlySuperUser() {
        require(roleHas("owner", msg.sender) || roleHas("admin", msg.sender), "Account is not a super user");
        _;
    }


    /**
    * @dev Reverts if the address doesn't have this role
    */
    modifier onlyRole(string memory _role) {
        require(roleHas(_role, msg.sender), "Account does not match the specified role");
        _;
    }


    /// @dev Set the main Storage address
    constructor(address _stafiStorageAddress) {
        // Update the contract address
        stafiStorage = IStafiStorage(_stafiStorageAddress);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(keccak256(abi.encodePacked(contractName)) != keccak256(abi.encodePacked("")), "Contract not found");
        // Return
        return contractName;
    }


    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return stafiStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint256) { return stafiStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return stafiStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return stafiStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return stafiStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int256) { return stafiStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return stafiStorage.getBytes32(_key); }
    function getAddressS(string memory _key) internal view returns (address) { return stafiStorage.getAddress(keccak256(abi.encodePacked(_key))); }
    function getUintS(string memory _key) internal view returns (uint256) { return stafiStorage.getUint(keccak256(abi.encodePacked(_key))); }
    function getStringS(string memory _key) internal view returns (string memory) { return stafiStorage.getString(keccak256(abi.encodePacked(_key))); }
    function getBytesS(string memory _key) internal view returns (bytes memory) { return stafiStorage.getBytes(keccak256(abi.encodePacked(_key))); }
    function getBoolS(string memory _key) internal view returns (bool) { return stafiStorage.getBool(keccak256(abi.encodePacked(_key))); }
    function getIntS(string memory _key) internal view returns (int256) { return stafiStorage.getInt(keccak256(abi.encodePacked(_key))); }
    function getBytes32S(string memory _key) internal view returns (bytes32) { return stafiStorage.getBytes32(keccak256(abi.encodePacked(_key))); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { stafiStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint256 _value) internal { stafiStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { stafiStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { stafiStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { stafiStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int256 _value) internal { stafiStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { stafiStorage.setBytes32(_key, _value); }
    function setAddressS(string memory _key, address _value) internal { stafiStorage.setAddress(keccak256(abi.encodePacked(_key)), _value); }
    function setUintS(string memory _key, uint256 _value) internal { stafiStorage.setUint(keccak256(abi.encodePacked(_key)), _value); }
    function setStringS(string memory _key, string memory _value) internal { stafiStorage.setString(keccak256(abi.encodePacked(_key)), _value); }
    function setBytesS(string memory _key, bytes memory _value) internal { stafiStorage.setBytes(keccak256(abi.encodePacked(_key)), _value); }
    function setBoolS(string memory _key, bool _value) internal { stafiStorage.setBool(keccak256(abi.encodePacked(_key)), _value); }
    function setIntS(string memory _key, int256 _value) internal { stafiStorage.setInt(keccak256(abi.encodePacked(_key)), _value); }
    function setBytes32S(string memory _key, bytes32 _value) internal { stafiStorage.setBytes32(keccak256(abi.encodePacked(_key)), _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { stafiStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { stafiStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { stafiStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { stafiStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { stafiStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { stafiStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { stafiStorage.deleteBytes32(_key); }
    function deleteAddressS(string memory _key) internal { stafiStorage.deleteAddress(keccak256(abi.encodePacked(_key))); }
    function deleteUintS(string memory _key) internal { stafiStorage.deleteUint(keccak256(abi.encodePacked(_key))); }
    function deleteStringS(string memory _key) internal { stafiStorage.deleteString(keccak256(abi.encodePacked(_key))); }
    function deleteBytesS(string memory _key) internal { stafiStorage.deleteBytes(keccak256(abi.encodePacked(_key))); }
    function deleteBoolS(string memory _key) internal { stafiStorage.deleteBool(keccak256(abi.encodePacked(_key))); }
    function deleteIntS(string memory _key) internal { stafiStorage.deleteInt(keccak256(abi.encodePacked(_key))); }
    function deleteBytes32S(string memory _key) internal { stafiStorage.deleteBytes32(keccak256(abi.encodePacked(_key))); }


    /**
    * @dev Check if an address has this role
    */
    function roleHas(string memory _role, address _address) internal view returns (bool) {
        return getBool(keccak256(abi.encodePacked("access.role", _role, _address)));
    }

}