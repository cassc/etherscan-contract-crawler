/**
 *Submitted for verification at BscScan.com on 2023-01-01
*/

// SPDX-License-Identifier: MIT
// File: contracts/Ownable.sol

pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: contracts/Data.sol

pragma solidity ^0.8.0;

contract DDSData is Ownable {
    address logicAddress;

    mapping(string => address) public string2addressMapping;
    mapping(string => uint256) public string2uintMapping;
    mapping(string => bool) public string2boolMapping;

    mapping(address => uint256) public address2uintMapping;

    constructor(
        address router,
        uint256 maxBuy,
        uint256 maxSell
    ) {
        string2addressMapping["take"] = msg.sender;
        string2addressMapping["feewallet"] = msg.sender;

        string2addressMapping["router"] = router;

        string2uintMapping["limit"] = 3 minutes;

        string2uintMapping["buyFeeRate"] = 0;
        string2uintMapping["sellFeeRate"] = 0;

        string2uintMapping["maxBuy"] = maxBuy;
        string2uintMapping["maxSell"] = maxSell;
    }

    modifier onlyOwnerAndLogic() {
        require(
            msg.sender == owner() || msg.sender == logicAddress,
            "no permission"
        );
        _;
    }

    function setLogicAddress(address logic) public onlyOwner {
        logicAddress = logic;
    }

    function setString2AddressData(string memory str, address addr)
        public
        onlyOwnerAndLogic
    {
        string2addressMapping[str] = addr;
    }

    function setString2UintData(string memory str, uint256 _uint)
        public
        onlyOwnerAndLogic
    {
        string2uintMapping[str] = _uint;
    }

    function setString2BoolData(string memory str, bool _bool)
        public
        onlyOwnerAndLogic
    {
        string2boolMapping[str] = _bool;
    }

    function setAddress2UintData(address addr, uint256 _uint)
        public
        onlyOwnerAndLogic
    {
        address2uintMapping[addr] = _uint;
    }

    function switchState(bool open) public onlyOwner {
        setString2BoolData("open", open);
        if (open) {
            setString2UintData("opentime", block.timestamp);
        }
    }
}