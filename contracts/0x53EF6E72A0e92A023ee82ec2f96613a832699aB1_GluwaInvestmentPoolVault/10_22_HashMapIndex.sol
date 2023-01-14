// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/** @title Library functions used by contracts within this ecosystem.*/
library HashMapIndex {
    /**
     * @dev Enum to store the states of HashMapping entries
     */
    enum HashState {
        /*0*/
        Invalid,
        /*1*/
        Active,
        /*2*/
        Archived
    }

    /**
     * @dev Efficient storage container for active and archived hashes enabling iteration
     */
    struct HashMapping {
        mapping(bytes32 => HashState) hashState;
        mapping(uint64 => bytes32) itHashMap;
        uint64 firstIdx;
        uint64 nextIdx;
        uint64 count;
    }

    /**
     * @dev Add a new hash to the storage container if it is not yet part of it
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to add to the struct
     */
    function add(HashMapping storage self, bytes32 _hash) internal {
        // Ensure that the hash has not been previously already been added (is still in an invalid state)
        assert(self.hashState[_hash] == HashState.Invalid);
        // Set the state of hash to Active
        self.hashState[_hash] = HashState.Active;
        // Index the hash with the next idx
        self.itHashMap[self.nextIdx] = _hash;
        self.nextIdx++;
        self.count++;
    }

    /**
     * @dev Archives an existing hash if it is an active hash part of the struct
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to archive in the struct
     */
    function archive(HashMapping storage self, bytes32 _hash) internal {
        // Ensure that the state of the hash is active
        assert(self.hashState[_hash] == HashState.Active);
        // Set the State of hash to Archived
        self.hashState[_hash] = HashState.Archived;
        // Reduce the size of the number of active hashes
        self.count--;

        // Check if the first hash in the active list is in an archived state
        if (
            self.hashState[self.itHashMap[self.firstIdx]] == HashState.Archived
        ) {
            self.firstIdx++;
        }

        // Repeat one more time to allowing for 'catch up' of firstIdx;
        // Check if the first hash in the active list is still active or has it already been archived
        if (
            self.hashState[self.itHashMap[self.firstIdx]] == HashState.Archived
        ) {
            self.firstIdx++;
        }
    }

    /**
     * @dev Verifies if the hash provided is a currently active hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is active (and part of the mapping)
     */
    function isActive(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] == HashState.Active;
    }

    /**
     * @dev Verifies if the hash provided is an archived hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is archived (and part of the mapping)
     */
    function isArchived(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] == HashState.Archived;
    }

    /**
     * @dev Verifies if the hash provided is either an active or archived hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is either active or archived (part of the mapping)
     */
    function isValid(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] != HashState.Invalid;
    }

    /**
     * @dev Retrieve the specified (_idx) hash from the struct
     * @param self Struct storage container pointing to itself
     * @param _idx Index of the hash to retrieve
     * @return Hash specified by the _idx value (returns 0x0 if _idx is an invalid index)
     */
    function get(HashMapping storage self, uint64 _idx)
        internal
        view
        returns (bytes32)
    {
        return self.itHashMap[_idx];
    }
}