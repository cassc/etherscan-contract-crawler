// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

/// @title MultisigManager - Manages a set of owners and a threshold to perform actions
/// @notice Owners and threshold is managed by the administrator
contract MultisigManager {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    address administrator;
    mapping(address => address) internal owners;
    uint256 ownerCount;
    uint256 internal threshold;

    modifier authorized() {
        require(
            msg.sender == administrator,
            "WRAP: METHOD_CAN_ONLY_BE_CALLED_BY_ADMINISTRATOR"
        );
        _;
    }

    /// @dev Setup function sets initial storage of contract
    /// @param _owners List of owners
    /// @param _threshold Number of required confirmations for a Wrap transaction
    function _setup(address[] memory _owners, uint256 _threshold) internal {
        require(threshold == 0, "WRAP: CONTRACT_ALREADY_SETUP");
        require(
            _threshold <= _owners.length,
            "WRAP: THRESHOLD_CANNOT_EXCEED_OWNER_COUNT"
        );
        require(_threshold >= 1, "WRAP: THRESHOLD_NEEED_TO_BE_GREETER_THAN_0");
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(
                owner != address(0) && owner != SENTINEL_OWNERS,
                "WRAP: INVALID_OWNER_PROVIDED"
            );
            require(
                owners[owner] == address(0),
                "WRAP: DUPLICATE_OWNER_ADDRESS_PROVIDED"
            );
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner and update the threshold at the same time
    /// @notice Adds the owner `owner` and updates the threshold to `_threshold`
    /// @param owner New owner address
    /// @param _threshold New threshold
    function addOwnerWithThreshold(address owner, uint256 _threshold)
        public
        authorized
    {
        require(
            owner != address(0) && owner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[owner] == address(0),
            "WRAP: ADDRESS_IS_ALREADY_AN_OWNER"
        );
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner and update the threshold at the same time
    /// @notice Removes the owner `owner` and updates the threshold to `_threshold`
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed
    /// @param _threshold New threshold
    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public authorized {
        require(
            ownerCount - 1 >= _threshold,
            "WRAP: NEW_OWNER_COUNT_NEEDS_TO_BE_LONGER_THAN_THRESHOLD"
        );
        require(
            owner != address(0) && owner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[prevOwner] == owner,
            "WRAP: INVALID_PREV_OWNER_OWNER_PAIR_PROVIDED"
        );
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner with another address
    /// @notice Replaces the owner `oldOwner` with `newOwner`
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced
    /// @param newOwner New owner address
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public authorized {
        require(
            newOwner != address(0) && newOwner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[newOwner] == address(0),
            "WRAP: ADDRESS_IS_ALREADY_AN_OWNER"
        );
        require(
            oldOwner != address(0) && oldOwner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[prevOwner] == oldOwner,
            "WRAP: INVALID_PREV_OWNER_OWNER_PAIR_PROVIDED"
        );
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations
    /// @notice Changes the threshold to `_threshold`
    /// @param _threshold New threshold
    function changeThreshold(uint256 _threshold) public authorized {
        require(
            _threshold <= ownerCount,
            "WRAP: THRESHOLD_CANNOT_EXCEED_OWNER_COUNT"
        );
        require(_threshold >= 1, "WRAP: THRESHOLD_NEEED_TO_BE_GREETER_THAN_0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    /// @notice Get multisig threshold
    /// @return Threshold
    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    /// @notice Allow to check if an address is owner of the multisig
    /// @return True if owner, false otherwise
    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @notice Get multisig members
    /// @return Owners list
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }

    /// @notice Get current multisig administrator
    /// @return Administrator address
    function getAdministrator() public view returns (address) {
        return administrator;
    }
}