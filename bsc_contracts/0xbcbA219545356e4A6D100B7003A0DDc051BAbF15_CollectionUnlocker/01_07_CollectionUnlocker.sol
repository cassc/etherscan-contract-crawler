// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface UnlockContract {
    function unlockAI(uint256[] calldata _tokenIds) external;

    function getUnlockedStatus(uint256[] calldata _tokenIds) external view returns (bool[] memory);
}

contract CollectionUnlocker is Ownable {
    using SafeMath for uint256;

    bool public unlockActive = false;

    // Address of NFT collections that will be staked
    address[] public collections = [0x26eFFc1aDE68e0aFaf9be7b234544aa442b345b1];
    uint256[] public collectionConsumptionRate = [5];
    mapping(address => mapping(uint256 => bool)) ticketUsed; // collection => token ID => consumed

    address public unlockAddr;

    // Activate/deactivate unlocking
    function setUnlockActive(bool _val) external onlyOwner {
        unlockActive = _val;
    }

    function consumeTicketsToUnlock(
        address _collection,
        uint256[] calldata _ticketTokenIds, // Token IDs that will be used as a ticket
        uint256[] calldata _unlockTokenIds // Token IDs that will be unlocked
    ) external {
        require(unlockActive, "Unlocking not active!");
        uint256 _collectionIndex = getCollectionIndex(_collection); // Also requires that collection is valid
        require(
            _ticketTokenIds.length == _unlockTokenIds.length.mul(collectionConsumptionRate[_collectionIndex]),
            "Incorrect number of NFTs used for unlock!"
        );

        // Consume all tickets
        for (uint256 i = 0; i < _ticketTokenIds.length; i++) {
            require(
                IERC721Enumerable(collections[_collectionIndex]).ownerOf(_ticketTokenIds[i]) == address(msg.sender),
                "Sender not the owner of ticket token ID!"
            );
            require(!ticketUsed[collections[_collectionIndex]][_ticketTokenIds[i]], "Ticket of a token ID already consumed!");

            // Consume ticket
            ticketUsed[collections[_collectionIndex]][_ticketTokenIds[i]] = true;
        }

        // Unlock AI
        UnlockContract(unlockAddr).unlockAI(_unlockTokenIds);
    }

    function setUnlockAddr(address _addr) external onlyOwner {
        unlockAddr = _addr;
    }

    // Adds a new collection to collections array
    function addNewCollection(address _addr, uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate cannot be 0!");
        require(!isValidCollection(_addr), "Collection already exists!");

        collections.push(_addr);
        collectionConsumptionRate.push(_rate);
    }

    // Change collection address of _index in collections array.
    function setCollectionAddr(address _addr, uint256 _collectionIndex) external onlyOwner {
        require(!isValidCollection(_addr), "Collection already exists!");
        collections[_collectionIndex] = _addr;
    }

    // Change collection rate
    function setCollectionRate(uint256 _collectionIndex, uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate cannot be 0!");
        collectionConsumptionRate[_collectionIndex] = _rate;
    }

    // Remove collection located at _index in collections array
    function removeCollection(address _address) external onlyOwner {
        uint256 _collectionIndex = getCollectionIndex(_address);

        collections[_collectionIndex] = collections[collections.length - 1];
        collections.pop();

        collectionConsumptionRate[_collectionIndex] = collectionConsumptionRate[collectionConsumptionRate.length - 1];
        collectionConsumptionRate.pop();
    }

    // returns an array with the addresses of all collections that can be used as unlock tickets
    function getCollections() public view returns (address[] memory) {
        return collections;
    }

    // Returns an array with how many NFTs each collection needs per unlock
    function getCollectionRates() public view returns (uint256[] memory) {
        return collectionConsumptionRate;
    }

    // Returns true if _addr is found in collections array and false if it is not found.
    function isValidCollection(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < collections.length; i++) if (_addr == collections[i]) return true;
        return false;
    }

    // Returns index of collection if _addr is found in collections array.
    // Also acts as an "isValidCollection" requirement
    function getCollectionIndex(address _addr) public view returns (uint256) {
        // Requiring the collection to be valid ensures that an index for collection _addr exists.
        require(isValidCollection(_addr), "Invalid collection.");
        for (uint256 i = 0; i < collections.length; i++) if (_addr == collections[i]) return i;
    }

    function getTicketStatus(address _addr, uint256[] calldata _tokenIds) external view returns (bool[] memory) {
        bool[] memory _queriedIDs = new bool[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) _queriedIDs[i] = ticketUsed[_addr][_tokenIds[i]];
        return _queriedIDs;
    }
}