// SPDX-License-Identifier: No License
/**
 * @title Vendor position tracker contract.
 * @dev   This contract helps prevent long waits before the pool shows up for the user after lending or borrowing.
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPositionTracker.sol";

contract PositionTracker is 
    IPositionTracker,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable 
{

    IPoolFactory public factory;

    mapping(bytes32 => Entry) public borrowPositions;        // All borrow positions of all users.
    mapping(address => bytes32) private borrowTail;          // Last borrow position of the user.
    mapping(address => uint256) public borrowPositionCount;  // Convenience to ensure FE pulls all the position

    mapping(bytes32 => Entry) public lendPositions;          // All lend positions of all users.
    mapping(address => bytes32) private lendTail;            // Last lend positions of the user.
    mapping(address => uint256) public lendPositionCount;

    uint256 public constant version = 1;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice                 Sets the address of the factory
    /// @param _factory         Address of the Vendor Pool Factory
    function initialize(IPoolFactory _factory) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        if (address(_factory) == address(0)) revert ZeroAddress();
        factory = _factory;
    }

    /// @notice                 Records a position of the users in the pool(msg.sender)
    /// @dev                    Pool for which the position is open is the msg.sender.
    /// @param                  _user The borrower's address.
    /// @param                  _pool The borrowing pool's address.
    function openBorrowPosition(address _user, address _pool) external {
        Entry memory newEntry = getEntry(_user, _pool);
        
        if (msg.sender != address(factory) && !factory.pools(msg.sender)) revert NotFactoryOrPool();
        if (borrowPositions[newEntry.id].id != bytes32(0)) revert PositionIsAlreadyOpen();
        
        Entry memory currentTail = borrowPositions[borrowTail[_user]];
        borrowPositions[newEntry.id] = newEntry;
        borrowTail[_user] = newEntry.id;
        borrowPositionCount[_user]++;

        if (currentTail.prev == bytes32(0) && currentTail.id == 0) return; // Very first position
        
        bytes32 newPrevId = currentTail.id;
        borrowPositions[newEntry.id].prev = newPrevId;
        borrowPositions[currentTail.id].next = newEntry.id;
    }

    /// @notice                 Records a position of the users in the pool(msg.sender)
    /// @dev                    Pool for which the position is open is the msg.sender.
    /// @param                  _user The lender's address.
    /// @param                  _pool The lending pool's address.
    function openLendPosition(address _user, address _pool) external {
        Entry memory newEntry = getEntry(_user, _pool);
        
        if (lendPositions[newEntry.id].id != bytes32(0)) revert PositionIsAlreadyOpen();
        if (msg.sender != address(factory) && !factory.pools(msg.sender)) revert NotFactoryOrPool();
        
        Entry memory currentTail = lendPositions[lendTail[_user]];
        lendPositions[newEntry.id] = newEntry;
        lendTail[_user] = newEntry.id;
        lendPositionCount[_user]++;

        if (currentTail.prev == bytes32(0) && currentTail.id == 0) return;
        
        bytes32 newPrevId = currentTail.id;
        lendPositions[newEntry.id].prev = newPrevId;
        lendPositions[currentTail.id].next = newEntry.id;
    }

    /// @notice                 Deletes a position of the users in the pool(msg.sender)
    /// @dev                    Pool for which the position is closed is the msg.sender.
    /// @param                  _user The borrower's address.
    function closeBorrowPosition(address _user) external {
        Entry memory entry = borrowPositions[keccak256(abi.encodePacked(_user, msg.sender))];
        
        if (entry.id == bytes32(0)) revert PositionNotFound();
        
        bytes32 prevEntryId = entry.prev;
        bytes32 nextEntryId = entry.next;

        if (prevEntryId != bytes32(0)) borrowPositions[prevEntryId].next = nextEntryId;
        if (nextEntryId != bytes32(0)) borrowPositions[nextEntryId].prev = prevEntryId;

        if (entry.id == borrowTail[_user]) borrowTail[_user] = entry.prev;
        delete borrowPositions[entry.id];
        borrowPositionCount[_user]--;
    }

    /// @notice                 Deletes a position of the users in the pool(msg.sender)
    /// @dev                    Pool for which the position is closed is the msg.sender.
    /// @param                  _user The lender's address.
    function closeLendPosition(address _user) external {
        Entry memory entry = lendPositions[keccak256(abi.encodePacked(_user, msg.sender))];
        
        if (entry.id == bytes32(0)) revert PositionNotFound();
        
        bytes32 prevEntryId = entry.prev;
        bytes32 nextEntryId = entry.next;

        if (prevEntryId != bytes32(0)) lendPositions[prevEntryId].next = nextEntryId;
        if (nextEntryId != bytes32(0)) lendPositions[nextEntryId].prev = prevEntryId;

        if (entry.id == lendTail[_user]) lendTail[_user] = entry.prev;
        delete lendPositions[entry.id];
        lendPositionCount[_user]--;
    }

    /// @notice                 Returns all of the borrower positions in reverse order.
    /// @dev                    Since the function will always return _count positions, some of the last once can be zeroed out.
    /// @param                  _borrower user who's positions we need to return.
    /// @param                 _start id of the position from which the array should start. Again from right to left.
    /// @param                  _count amount of positions to return. If returning more than present will pad with zero positions.
    function getBorrowPositions(address _borrower, bytes32 _start, uint256 _count) external view returns (Entry[] memory){
        if (_start != bytes32(0) && borrowPositions[_start].id == bytes32(0)) revert PositionNotFound();

        bytes32 pointerId = _start;
        if(_start == bytes32(0)){ // If the initial pointer is bytes(0) start from the very last position.
            pointerId = borrowTail[_borrower];
        }
        
        Entry[] memory result = new Entry[](_count);
        for (uint256 i = _count; i > 0; i-- ){
            Entry memory temp = borrowPositions[pointerId];
            result[_count - i] = temp;
            if (temp.prev == bytes32(0)) return result;
            pointerId = temp.prev;
        }
        return result;
    }

    /// @notice                  Returns all of the lender positions in reverse order.
    /// @dev                     Since the function will always return _count positions, some of the last once can be zeroed out.
    /// @param                   _lender user who's positions we need to return.
    /// @param                   _start id of the position from which the array should start. Again from right to left.
    /// @param                   _count amount of positions to return. If returning more than present will pad with zero positions.
    function getLendPositions(address _lender, bytes32 _start, uint256 _count) external view returns (Entry[] memory){
        if (_start != bytes32(0) && lendPositions[_start].id == bytes32(0)) revert PositionNotFound();

        bytes32 pointerId = _start;
        if(_start == bytes32(0)){
            pointerId = lendTail[_lender];
        }
        
        Entry[] memory result = new Entry[](_count);
        for (uint256 i = _count; i > 0; i-- ){
            Entry memory temp = lendPositions[pointerId];
            result[_count - i] = temp;
            if (temp.prev == bytes32(0)) return result;
            pointerId = temp.prev;
        }
        return result;
    }

    /// @notice                 Helper functions to create boiler plate Entry objects with no links.
    /// @param                  _user address of the lender or borrower.
    /// @param                  _pool address of the pool for which the position is being opened.
    function getEntry(address _user, address _pool) private pure returns (Entry memory) {
        return Entry({
            id: keccak256(abi.encodePacked(_user, _pool)),
            prev: bytes32(0),
            next: bytes32(0),
            user: _user,
            pool: _pool
        });
    }

    function setFactory(address _factory) external onlyOwner {
        factory = IPoolFactory(_factory);
    }

    /// @notice                 Pre-upgrade checks
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}