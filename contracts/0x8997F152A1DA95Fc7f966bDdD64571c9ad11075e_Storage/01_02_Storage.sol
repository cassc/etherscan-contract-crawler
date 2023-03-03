// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract Storage {

    using EnumerableSet for EnumerableSet.AddressSet;

    // Shifter -> Depositor -> PasswordHash -> EncryptedNote
    mapping(address => mapping(address => mapping(bytes32 => bytes[]))) public notes;
    EnumerableSet.AddressSet internal shifterContracts;
    // Owner cannot be changed
    address public immutable owner;

    event ShifterContract(address shifterContract);
    event Store(address depositor, bytes encryptedNote, bytes32 passwordHash);

    constructor(address _shifterContract) {
        shifterContracts.add(_shifterContract);
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Message sender is not the owner");
        _;
    }

    function addShifter(address _shifterContract) external onlyOwner {
        shifterContracts.add(_shifterContract);
        emit ShifterContract(_shifterContract);
    }

    function store(address _depositor, bytes calldata _encryptedNote, bytes32 _passwordHash) external {
        require(shifterContracts.contains(msg.sender), "Only verified shifters can store notes.");
        require(_encryptedNote.length == 62, "Note size is incorrect.");
        notes[msg.sender][_depositor][_passwordHash].push(_encryptedNote);
        emit Store(_depositor, _encryptedNote, _passwordHash);
    }

    function getLatestDeposit(address _shifter, address _depositor, bytes32 _passwordHash) public view returns (bytes memory result) {
        require(notes[_shifter][_depositor][_passwordHash].length > 0, "Address has no deposits");
        return notes[_shifter][_depositor][_passwordHash][notes[_shifter][_depositor][_passwordHash].length - 1];
    }

    function getDeposits(address _shifter, address _depositor, bytes32 _passwordHash) external view returns (bytes[] memory result) {
        return notes[_shifter][_depositor][_passwordHash];
    }

    function getDepositsLength(address _shifter, address _depositor, bytes32 _passwordHash) external view returns (uint256 length) {
        return notes[_shifter][_depositor][_passwordHash].length;
    }

    function getDepositByIndex(address _shifter, address _depositor, bytes32 _passwordHash, uint256 _index) external view returns (bytes memory result) {
        return notes[_shifter][_depositor][_passwordHash][_index];
    }

    function getShifterCount() public view returns (uint256 count) {
        return shifterContracts.length();
    }

    function getShifterAtIndex(uint256 index) public view returns (address shifter) {
        return shifterContracts.at(index);
    }

    function isShifter(address _shifterContract) public view returns (bool isShifter) {
        return shifterContracts.contains(_shifterContract);
    }

    function getAllShifters() public view returns (address[] memory shifters) {
        shifters = new address[](getShifterCount());
        for (uint256 i = 0; i < getShifterCount(); i++) {
            shifters[i] = getShifterAtIndex(i);
        }
    }
}