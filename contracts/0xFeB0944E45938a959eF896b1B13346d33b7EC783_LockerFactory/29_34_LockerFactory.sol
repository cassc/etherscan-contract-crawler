// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//         .-""-.
//        / .--. \
//       / /    \ \
//       | |    | |
//       | |.-""-.|
//      ///`.::::.`\
//     ||| ::/  \:: ;
//     ||; ::\__/:: ;
//      \\\ '::::' /
//       `=':-..-'`
//    https://duo.cash

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./NFT.sol";
import "./Locker.sol";
import "./LockerProxy.sol";


contract LockerFactory is NFT{

    struct LockInfo {
        // The latest NFT id to represents the ownership
        uint256 latestId;
        // The timestamp of when this locker was created (or relocked)
        uint256 createdAt;
        // The address of the user/contract that owned it upon unlock
        // (is 0 address if currently locked)
        address unlockedBy;
        // The timestamp at which the proxy can be unlocked
        uint256 unlockAt;
    }

    // Tracks the last used ID
    uint256 public lastId;
    // Maps the lockers proxy address to the LockInfo
    mapping(address => LockInfo) public lockers;
    // Maps the ownership ids to the proxy address
    mapping(uint256 => address) public ids;

    // The singleton instance of the proxy contract
    // This proxy is cloned for every locker
    address public immutable proxySingleton;
    // The singleton instance of the Locker contract
    // This contract becomes the implementation of the cloned proxy
    address public immutable lockerSingleton;
    // The admin contract managing all the TransparentUpgradeableProxy clones (not the original)
    ProxyAdmin public immutable proxyAdmin;

    // Events
    event LockerCreated(uint256 indexed id, address indexed locker, address indexed owner, uint256 lockedUntil);
    event LockerExtended(uint256 indexed prevId, uint256 indexed newId, address indexed locker, uint256 lockedUntil);
    event LockerUnlocked(uint256 indexed id, address indexed locker, address indexed owner);

    // Errors
    error IsLocked();
    error NoPermission();
    error InvalidTimestamp();

    constructor(address _royaltyImplementation, address _metadataImplementation, address _manager) 
        NFT(
            "DuoCash Locker",
            "LOCKER",
            _royaltyImplementation,
            _metadataImplementation,
            _manager
        ) {
        // We purposfully create the critical contracts here so its easy to verify how they were all setup
        lockerSingleton = address(
            new Locker()
        );

        // This proxy will get cloned for every new locker, ownership is burned to prevent anything happening to the singleton.
        proxySingleton = address(
            new LockerProxy(
                address(lockerSingleton),
                address(0x000000000000000000000000000000000000dEaD),
                new bytes(0)
            )
        );

        // We have to use a ProxyAdmin to allow for using safeTransfer to lock a locker inside of another locker (lockerception).
        // This is because otherwise the 'safeTransfer' tries to check the 'onERC721Received' of the locker,
        // But because the NFT contract would also be the admin of the locker it isn't allowed to interact with the implementation.
        // See https://docs.openzeppelin.com/contracts/4.x/api/proxy#TransparentUpgradeableProxy for more information
        proxyAdmin = new ProxyAdmin();
    }

    /// @notice Create a new locker
    /// @dev If the _owner is a smart contract it must implement {IERC721Receiver-onERC721Received}
    /// @param _owner gets the ownership of the new locker and its NFT (if 0 assumes msg.sender)
    /// @param _unlocksAt timestamp past which the locker can be unlocked (can be 0, to create unlocked)
    function setup(
        address _owner,
        uint256 _unlocksAt
    ) external returns (uint256 lockerId, address lockerAddress) {
        // The timestamp has to be 0 (meaning it isn't timelocked) or a timestamp in the future
        if (_unlocksAt <= block.timestamp &&
            _unlocksAt != 0){
            revert InvalidTimestamp();
        } 
        // If owner is set to 0 address we use the sender
        if(_owner == address(0)) _owner = msg.sender;
        
        // Increase the ID 
        // note: the amount of calls needed makes this impossible to overflow
        uint256 newLockerId;
        unchecked {
            newLockerId = ++lastId;
        }
        // Get the chainId
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        // Clone the proxy implementation, we clone a proxy to save on gas, we do this using Create2.
        // The Create2 salt is made up of the lockerId(/tokenId) and the chainId, this is done to prevent duplicate 
        // addresses across chains which may cause confusion to users.
        // This can never deploy to the same address twice as the 'newLockerId' is unique every time
        // (and even if we somehow got a duplicate salt, attempting to clone to the same address reverts the call)
        LockerProxy locker = LockerProxy(payable(
            Clones.cloneDeterministic(
                proxySingleton,
                keccak256(
                    abi.encodePacked(
                        newLockerId,
                        chainId
                    )
                )
            )
        ));

        // Initialize the cloned proxy
        locker.proxyInitialize(
            lockerSingleton,
            address(proxyAdmin),
            new bytes(0)
        );

        // Register the locker
        lockers[address(locker)] = LockInfo(
            newLockerId,
            block.timestamp,
            address(0),
            _unlocksAt
        );
        // Map the ownership token its id to this locker
        ids[newLockerId] = address(locker);
        // Mint the ownership NFT with the corresponding id
        _safeMint(_owner, newLockerId);

        emit LockerCreated(newLockerId, address(locker), _owner, _unlocksAt);
        return (newLockerId, address(locker));
    }

    /// @notice Extend the time until the locker can be unlocked
    /// @dev This burns the ownership NFT and mints a new one, make sure your contract has 'ApprovalForAll' if you want have access to the new NFT
    /// @param _lockerId the locker that should be extended
    /// @param _extendUntil timestamp past which the locker can be unlocked
    function extend(uint256 _lockerId, uint256 _extendUntil) external returns (uint256){
        // On unlock the ownership NFT gets burned, this method reverts if the NFT no longer exists
        if (!_isApprovedOrOwner(msg.sender, _lockerId)){
            revert NoPermission();
        }

        // Get the locker info
        address lockerAddress = ids[_lockerId];
        LockInfo storage locker = lockers[lockerAddress];

        // Make sure the new unlock time is both after this block and
        // its later than the current 'unlockAt'
        if (block.timestamp >= _extendUntil||
            locker.unlockAt >= _extendUntil){
            revert InvalidTimestamp();
        }

        // Burn the old ownership ID
        address lockerOwner = ownerOf(_lockerId);
        _burn(_lockerId);

        // To prevent a user from extending the lock before selling the NFT
        // a new ownership NFT gets minted to represent the locker.
        uint256 newLockerId;
        unchecked {
            newLockerId = ++lastId;
        }

        // if the locker has been locked before we use the old createdAt (since the user is extending the lock)
        // if not we use the current time
        if(locker.unlockAt == 0){
            locker.createdAt = block.timestamp;
        }

        // Update the LockInfo
        locker.latestId = newLockerId;
        locker.unlockAt = _extendUntil;

        // Add the mapping for the new ID
        // we also keep the old one(s) intact so its easier for UIs to find the new ID
        // the old NFT has been burned so it can't be used to unlock
        ids[newLockerId] = lockerAddress;
        
        // Mint the new ownership NFT
        _safeMint(lockerOwner, newLockerId);
        
        emit LockerExtended(_lockerId, newLockerId, lockerAddress, _extendUntil);
        return newLockerId;
    }

    /// @notice Unlock the locker if the required time has passed
    /// @param _lockerId the locker that should be unlocked
    /// @param _implementation the new implementation of the locker proxy
    /// @param _data will perform a call to the proxy with this calldata after the implementation has been set (optional)
    function unlock(
        uint256 _lockerId,
        address _implementation,
        bytes memory _data
    ) external {
         // On unlock the ownership NFT gets burned, this method reverts if the NFT no longer exists
        if (!_isApprovedOrOwner(msg.sender, _lockerId)){
            revert NoPermission();
        }

        // Get the locker info
        address lockerAddress = ids[_lockerId];
        LockInfo storage locker = lockers[lockerAddress];

        // Check if the locker is unlocked
        if(locker.unlockAt > block.timestamp){ 
            revert IsLocked();
        }

        // Update the state to reflect the unlock
        address lockerOwner = ownerOf(_lockerId);
        locker.unlockedBy = lockerOwner;
        
        // Burn the ownership NFT
        _burn(_lockerId);

        // Upgrade the proxy to the new (user chosen) implementation
        // if _data is set we also perform that call (ex. to initialize the new implementation)
        proxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(payable(lockerAddress)),
            _implementation,
            _data
        );

        emit LockerUnlocked(_lockerId, lockerAddress, lockerOwner);
    }

    /// @notice Once unlocked this can be used to get full control over the locker
    /// @dev Changes the admin of the proxy to the specified address
    /// @param _lockerId The locker identifier
    /// @param _to The new Admin of the locker
    function claimOwnership(
        uint256 _lockerId,
        address _to
    ) external {
        // Get the locker info
        address lockerAddress = ids[_lockerId];
        if(msg.sender != lockers[lockerAddress].unlockedBy) revert NoPermission();

        // Transfer ownership of the Locker Proxy to the user chosen address
        proxyAdmin.changeProxyAdmin(
            TransparentUpgradeableProxy(payable(lockerAddress)),
            _to
        );
    }

    /// @notice Get a locker address and info by its current or previous ID(s)
    /// @param _lockerId The locker identifier
    function getLockerById(uint256 _lockerId) external view returns (address, LockInfo memory){
        address lockerAddress = ids[_lockerId];
        LockInfo memory info = lockers[lockerAddress];

        return (lockerAddress, info);
    }
}