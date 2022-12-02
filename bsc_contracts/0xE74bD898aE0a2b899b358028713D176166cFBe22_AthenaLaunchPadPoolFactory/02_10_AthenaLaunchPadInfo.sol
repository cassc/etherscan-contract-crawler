// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";


/// @title AthenaLaunchPadInfo
contract AthenaLaunchPadInfo is Ownable {
    address[] private presaleAddresses;

    mapping(address => bool) public alreadyAdded;
    mapping(uint256 => address) public presaleAddressByProjectID;
    mapping(address => bool) public operator;

    modifier onlyOperator() {
        require(operator[msg.sender], "Invalid Operator!! Not authorised");
        _;
    }

    /**
     * @dev To add presale address
     *
     * Requirements:
     * - presale address cannot be address zero.
     * - presale should not be already added
     */
    function addPresaleAddress(address _presale, uint256 _presaleProjectID) external onlyOperator returns (uint256) {
        require(_presale != address(0), "Address cannot be a zero address");
        require(!alreadyAdded[_presale], "Address already added");

        presaleAddresses.push(_presale);
        alreadyAdded[_presale] = true;
        presaleAddressByProjectID[_presaleProjectID] = _presale;
        return presaleAddresses.length - 1;
    }

    /**
     * @dev To return presale counts
     */
    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    /**
     * @dev To get presale contract address by DB id
     */
    function getPresaleAddressByDbId(uint256 asvaDbId) external view returns (address) {
        return presaleAddressByProjectID[asvaDbId];
    }

    /**
     * @dev To get presale contract address by asvaId
     *
     * Requirements:
     * - asvaId must be a valid id
     */
    function getPresaleAddress(uint256 asvaId) external view returns (address) {
        require(validAsvaId(asvaId), "Not a valid Id");
        return presaleAddresses[asvaId];
    }

    /**
     * @dev To get valid asva Id's
     */
    function validAsvaId(uint256 asvaId) public view returns (bool) {
        if (asvaId >= 0 && asvaId <= presaleAddresses.length - 1)  {
            return true;
        }
        return false;
    }

    /**
     * @dev assign operator Role
     */
    function addOperator(address _addr) external onlyOwner {
        require(_addr != address(0x0), "_addr should be valid address");
        require(!operator[_addr], "_addr is already an operator");

        operator[_addr] = true;
    }

    /**
     * @dev revoke operator Role
     */
    function revokeOperator(address _addr) external onlyOwner {
        require(_addr != address(0x0), "_addr should be valid address");
        require(operator[_addr], "_addr is not an operator");

        operator[_addr] = false;
    }
}