// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC2981, IERC165} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {ITokenURIGenerator} from "./interfaces/ITokenURIGenerator.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";
import {INFTLocker} from "./interfaces/INFTLocker.sol";
import {INFTStaker} from "./interfaces/INFTStaker.sol";

/**
  @title Voting Escrow
  @author Curve Finance
  @notice Votes have a weight depending on time, so that users are
  committed to the future of (whatever they are voting for)
  @dev Vote weight decays linearly over time. Lock time cannot be
  more than `MAXTIME` (4 years).

  # Voting escrow to have time-weighted votes
  # Votes have a weight depending on time, so that users are committed
  # to the future of (whatever they are voting for).
  # The weight in this implementation is linear, and lock cannot be more than maxtime:
  # w ^
  # 1 +        /
  #   |      /
  #   |    /
  #   |  /
  #   |/
  # 0 +--------+------> time
  # maxtime (4 years?)
*/

contract MAHAX is ReentrancyGuard, INFTLocker, AccessControl, ERC2981 {
    IRegistry public override registry;

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant MAXTIME = 4 * 365 * 86400;
    int128 internal constant iMAXTIME = 4 * 365 * 86400;
    uint256 internal constant MULTIPLIER = 1 ether;

    ITokenURIGenerator public renderingContract;

    uint256 public supply;
    mapping(uint256 => LockedBalance) public locked;

    mapping(uint256 => uint256) public ownershipChange;

    uint256 public epoch;
    mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point
    mapping(uint256 => Point[1000000000]) public userPointHistory; // user -> Point[userEpoch]

    mapping(uint256 => uint256) public userPointEpoch;
    mapping(uint256 => int128) public slopeChanges; // time -> signed slope change

    mapping(uint256 => uint256) public attachments;
    mapping(uint256 => bool) public staked;

    string public constant name = "Locked MAHA NFT";
    string public constant symbol = "MAHAX";
    string public constant version = "1.0.0";
    uint8 public constant decimals = 18;
    uint256 public minLockAmount = 99 * 1e18;

    /// @dev Current count of token
    uint256 internal tokenId;

    /// @dev Mapping from NFT ID to the address that owns it.
    mapping(uint256 => address) internal idToOwner;

    /// @dev Mapping from NFT ID to approved address.
    mapping(uint256 => address) internal idToApprovals;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint256) internal ownerToNFTokenCount;

    /// @dev Mapping from owner address to mapping of index to tokenIds
    mapping(address => mapping(uint256 => uint256))
        internal ownerToNFTokenIdList;

    /// @dev Mapping from NFT ID to index of owner
    mapping(uint256 => uint256) internal tokenToOwnerIndex;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    bytes32 public constant MIGRATION_ROLE = keccak256("MIGRATION_ROLE");

    modifier onlyGovernance() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not governance");
        _;
    }

    modifier onlyMigrator() {
        require(hasRole(MIGRATION_ROLE, msg.sender), "not migrator");
        _;
    }

    constructor(
        address _registry,
        address _royaltyRcv,
        uint96 _royaltyFeeNumerator
    ) {
        registry = IRegistry(_registry);

        pointHistory[0].blk = block.number;
        pointHistory[0].ts = block.timestamp;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MIGRATION_ROLE, msg.sender);

        _setDefaultRoyalty(_royaltyRcv, _royaltyFeeNumerator);
    }

    /// @dev Interface identification is specified in ERC-165.
    /// @param _interfaceID Id of the interface
    function supportsInterface(bytes4 _interfaceID)
        public
        view
        override(ERC2981, IERC165, AccessControl)
        returns (bool)
    {
        return
            bytes4(0x01ffc9a7) == _interfaceID || // ERC165
            bytes4(0x80ac58cd) == _interfaceID || // ERC721
            bytes4(0x5b5e139f) == _interfaceID || // ERC721Metadata
            super.supportsInterface(_interfaceID);
    }

    function totalSupplyWithoutDecay()
        external
        view
        override
        returns (uint256)
    {
        return supply;
    }

    /// @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @return Value of the slope
    function getLastUserSlope(uint256 _tokenId) external view returns (int128) {
        uint256 uepoch = userPointEpoch[_tokenId];
        return userPointHistory[_tokenId][uepoch].slope;
    }

    /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @param _idx User epoch number
    /// @return Epoch time of the checkpoint
    function userPointHistoryTs(uint256 _tokenId, uint256 _idx)
        external
        view
        returns (uint256)
    {
        return userPointHistory[_tokenId][_idx].ts;
    }

    /// @notice Get timestamp when `_tokenId`'s lock finishes
    /// @param _tokenId User NFT
    /// @return Epoch time of the lock end
    function lockedEnd(uint256 _tokenId) external view returns (uint256) {
        return locked[_tokenId].end;
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function _balance(address _owner) internal view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return _balance(_owner);
    }

    /// @dev Returns the address of the owner of the NFT.
    /// @param _tokenId The identifier for an NFT.
    function _ownerOf(uint256 _tokenId) internal view returns (address) {
        return idToOwner[_tokenId];
    }

    /// @dev Returns the address of the owner of the NFT.
    /// @param _tokenId The identifier for an NFT.
    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        return _ownerOf(_tokenId);
    }

    /// @dev Returns the voting power of the `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the voting power of.
    function votingPowerOf(address _owner)
        external
        view
        returns (uint256 _power)
    {
        for (uint256 index = 0; index < ownerToNFTokenCount[_owner]; index++) {
            uint256 _tokenId = ownerToNFTokenIdList[_owner][index];
            _power += _balanceOfNFT(_tokenId, block.timestamp);
        }
    }

    /// @dev Get the approved address for a single NFT.
    /// @param _tokenId ID of the NFT to query the approval of.
    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        return idToApprovals[_tokenId];
    }

    /// @dev Checks if `_operator` is an approved operator for `_owner`.
    /// @param _owner The address that owns the NFTs.
    /// @param _operator The address that acts on behalf of the owner.
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        // return require(!staked[_tokenId], "staked");
        return (ownerToOperators[_owner])[_operator];
    }

    /// @dev  Get token by index
    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256)
    {
        return ownerToNFTokenIdList[_owner][_tokenIndex];
    }

    /// @dev Returns whether the given spender can transfer a given token ID
    /// @param _spender address of the spender to query
    /// @param _tokenId uint ID of the token to be transferred
    /// @return bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token
    function _isApprovedOrOwner(address _spender, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        address owner = idToOwner[_tokenId];
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// @dev Add a NFT to an index mapping to a given address
    /// @param _to address of the receiver
    /// @param _tokenId uint ID Of the token to be added
    function _addTokenToOwnerList(address _to, uint256 _tokenId) internal {
        uint256 currentCount = _balance(_to);
        ownerToNFTokenIdList[_to][currentCount] = _tokenId;
        tokenToOwnerIndex[_tokenId] = currentCount;
    }

    /// @dev Remove a NFT from an index mapping to a given address
    /// @param _from address of the sender
    /// @param _tokenId uint ID Of the token to be removed
    function _removeTokenFromOwnerList(address _from, uint256 _tokenId)
        internal
    {
        // Delete
        uint256 currentCount = _balance(_from) - 1;
        uint256 currentIndex = tokenToOwnerIndex[_tokenId];

        if (currentCount == currentIndex) {
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint256 lastTokenId = ownerToNFTokenIdList[_from][currentCount];

            // Add
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentIndex] = lastTokenId;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[lastTokenId] = currentIndex;

            // Delete
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        }
    }

    /// @dev Add a NFT to a given address
    ///      Throws if `_tokenId` is owned by someone.
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        // Throws if `_tokenId` is owned by someone
        assert(idToOwner[_tokenId] == address(0));
        // Change the owner
        idToOwner[_tokenId] = _to;
        // Update owner token index tracking
        _addTokenToOwnerList(_to, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_to] += 1;
    }

    /// @dev Remove a NFT from a given address
    ///      Throws if `_from` is not the current owner.
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
        // Throws if `_from` is not the current owner
        assert(idToOwner[_tokenId] == _from);
        // Change the owner
        idToOwner[_tokenId] = address(0);
        // Update owner token index tracking
        _removeTokenFromOwnerList(_from, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_from] -= 1;
    }

    /// @dev Clear an approval of a given address
    ///      Throws if `_owner` is not the current owner.
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        // Throws if `_owner` is not the current owner
        assert(idToOwner[_tokenId] == _owner);
        if (idToApprovals[_tokenId] != address(0)) {
            // Reset approvals
            idToApprovals[_tokenId] = address(0);
        }
    }

    /// @dev Exeute transfer of a NFT.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
    ///      address for this NFT. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_tokenId` is not a valid NFT.
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        address _sender
    ) internal {
        require(!staked[_tokenId], "staked");
        // Check requirements
        require(_isApprovedOrOwner(_sender, _tokenId), "not approved sender");
        // Clear approval. Throws if `_from` is not the current owner
        _clearApproval(_from, _tokenId);
        // Remove NFT. Throws if `_tokenId` is not a valid NFT
        _removeTokenFrom(_from, _tokenId);
        // Add NFT
        _addTokenTo(_to, _tokenId);
        // Set the block of ownership transfer (for Flash NFT protection)
        ownershipChange[_tokenId] = block.number;
        // Log the transfer
        emit Transfer(_from, _to, _tokenId);
    }

    /* TRANSFER FUNCTIONS */
    /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    /// @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
    ///        they maybe be permanently lost.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _transferFrom(_from, _to, _tokenId, msg.sender);
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @dev Transfers the ownership of an NFT from one address to another address.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    ///      approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    /// @param _data Additional data with no specified format, sent in call to `_to`.
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override {
        _transferFrom(_from, _to, _tokenId, msg.sender);

        if (_isContract(_to)) {
            // Throws if transfer destination is a contract which does not implement 'onERC721Received'
            try
                IERC721Receiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    _data
                )
            returns (bytes4) {} catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /// @dev Transfers the ownership of an NFT from one address to another address.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    ///      approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
    ///      Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
    ///      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    /// @param _approved Address to be approved for the given NFT ID.
    /// @param _tokenId ID of the token to be approved.
    function _approve(address _approved, uint256 _tokenId) internal {
        address owner = idToOwner[_tokenId];
        // Throws if `_tokenId` is not a valid NFT
        require(owner != address(0), "owner is 0x0");
        // Throws if `_approved` is the current owner
        require(_approved != owner, "not owner");
        // Check requirements
        bool senderIsOwner = (idToOwner[_tokenId] == msg.sender);
        bool senderIsApprovedForAll = (ownerToOperators[owner])[msg.sender];
        require(senderIsOwner || senderIsApprovedForAll, "invalid sender");
        // Set the approval
        idToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
    ///      Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
    ///      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    /// @param _approved Address to be approved for the given NFT ID.
    /// @param _tokenId ID of the token to be approved.
    function approve(address _approved, uint256 _tokenId) external override {
        _approve(_approved, _tokenId);
    }

    /// @dev Enables or disables approval for a third party ("operator") to manage all of
    ///      `msg.sender`'s assets. It also emits the ApprovalForAll event.
    ///      Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    /// @notice This works even if sender doesn't own any tokens at the time.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval.
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        // Throws if `_operator` is the `msg.sender`
        assert(_operator != msg.sender);
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @dev Function to mint tokens
    ///      Throws if `_to` is zero address.
    ///      Throws if `_tokenId` is owned by someone.
    /// @param _to The address that will receive the minted tokens.
    /// @param _tokenId The token id to mint.
    /// @return A boolean that indicates if the operation was successful.
    function _mint(address _to, uint256 _tokenId) internal returns (bool) {
        // Throws if `_to` is zero address
        assert(_to != address(0));
        // Add NFT. Throws if `_tokenId` is owned by someone
        _addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    /// @notice Record global and per-user data to checkpoint
    /// @param _tokenId NFT token ID. No user checkpoint if 0
    /// @param oldLocked Pevious locked amount / end lock time for the user
    /// @param newLocked New locked amount / end lock time for the user
    function _checkpoint(
        uint256 _tokenId,
        LockedBalance memory oldLocked,
        LockedBalance memory newLocked
    ) internal {
        Point memory uOld;
        Point memory uNew;
        int128 oldDslope = 0;
        int128 newDslope = 0;
        uint256 _epoch = epoch;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                uOld.slope = oldLocked.amount / iMAXTIME;
                uOld.bias =
                    uOld.slope *
                    int128(int256(oldLocked.end - block.timestamp));
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                uNew.slope = newLocked.amount / iMAXTIME;
                uNew.bias =
                    uNew.slope *
                    int128(int256(newLocked.end - block.timestamp));
            }

            // Read values of scheduled changes in the slope
            // oldLocked.end can be in the past and in the future
            // newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
            oldDslope = slopeChanges[oldLocked.end];
            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    newDslope = oldDslope;
                } else {
                    newDslope = slopeChanges[newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.ts;
        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            blockSlope =
                (MULTIPLIER * (block.number - lastPoint.blk)) /
                (block.timestamp - lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint256 tI = (lastCheckpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                tI += WEEK;
                int128 dSlope = 0;
                if (tI > block.timestamp) {
                    tI = block.timestamp;
                } else {
                    dSlope = slopeChanges[tI];
                }
                lastPoint.bias -=
                    lastPoint.slope *
                    int128(int256(tI - lastCheckpoint));
                lastPoint.slope += dSlope;
                if (lastPoint.bias < 0) {
                    // This can happen
                    lastPoint.bias = 0;
                }
                if (lastPoint.slope < 0) {
                    // This cannot happen - just in case
                    lastPoint.slope = 0;
                }
                lastCheckpoint = tI;
                lastPoint.ts = tI;
                lastPoint.blk =
                    initialLastPoint.blk +
                    (blockSlope * (tI - initialLastPoint.ts)) /
                    MULTIPLIER;
                _epoch += 1;
                if (tI == block.timestamp) {
                    lastPoint.blk = block.number;
                    break;
                } else {
                    pointHistory[_epoch] = lastPoint;
                }
            }
        }

        epoch = _epoch;
        // Now pointHistory is filled until t=now

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        // Record the changed point into history
        pointHistory[_epoch] = lastPoint;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [newLocked.end]
            // and add old_user_slope to [oldLocked.end]
            if (oldLocked.end > block.timestamp) {
                // oldDslope was <something> - uOld.slope, so we cancel that
                oldDslope += uOld.slope;
                if (newLocked.end == oldLocked.end) {
                    oldDslope -= uNew.slope; // It was a new deposit, not extension
                }
                slopeChanges[oldLocked.end] = oldDslope;
            }

            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    newDslope -= uNew.slope; // old slope disappeared at this point
                    slopeChanges[newLocked.end] = newDslope;
                }
                // else: we recorded it already in oldDslope
            }
            // Now handle user history
            uint256 userEpoch = userPointEpoch[_tokenId] + 1;

            userPointEpoch[_tokenId] = userEpoch;
            uNew.ts = block.timestamp;
            uNew.blk = block.number;
            userPointHistory[_tokenId][userEpoch] = uNew;
        }
    }

    /// @notice Deposit and lock tokens for a user
    /// @param _tokenId NFT that holds lock
    /// @param _value Amount to deposit
    /// @param unlockTime New time when to unlock the tokens, or 0 if unchanged
    /// @param lockedBalance Previous locked amount / timestamp
    /// @param depositType The type of deposit
    function _depositFor(
        uint256 _tokenId,
        uint256 _value,
        uint256 unlockTime,
        LockedBalance memory lockedBalance,
        DepositType depositType,
        bool _shouldPullUserMaha,
        bool _stakeNFT
    ) internal {
        registry.ensureNotPaused();

        LockedBalance memory _locked = lockedBalance;
        uint256 supplyBefore = supply;

        supply = supplyBefore + _value;
        LockedBalance memory oldLocked;
        (oldLocked.amount, oldLocked.end) = (_locked.amount, _locked.end);

        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int256(_value));
        if (unlockTime != 0) {
            _locked.end = unlockTime;
        }
        if (depositType == DepositType.CREATE_LOCK_TYPE) {
            _locked.start = block.timestamp;
        }

        locked[_tokenId] = _locked;

        // Possibilities:
        // Both oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, oldLocked, _locked);

        address from = msg.sender;
        if (
            _value != 0 &&
            depositType != DepositType.MERGE_TYPE &&
            _shouldPullUserMaha
        ) {
            assert(
                IERC20(registry.maha()).transferFrom(
                    from,
                    address(this),
                    _value
                )
            );
        }

        if (_stakeNFT) INFTStaker(registry.staker())._stakeFromLock(_tokenId);

        emit Deposit(
            from,
            _tokenId,
            _value,
            _locked.end,
            depositType,
            block.timestamp
        );
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    function _stake(uint256 _tokenId) external override {
        require(msg.sender == registry.staker(), "not staker");
        staked[_tokenId] = true;
    }

    function _unstake(uint256 _tokenId) external override {
        require(msg.sender == registry.staker(), "not staker");
        staked[_tokenId] = false;
    }

    function merge(uint256 _from, uint256 _to) external {
        require(!staked[_from], "staked");
        require(!staked[_to], "staked");

        require(_from != _to, "same nft");
        require(_isApprovedOrOwner(msg.sender, _from), "from not approved");
        require(_isApprovedOrOwner(msg.sender, _to), "to not approved");

        LockedBalance memory _locked0 = locked[_from];
        LockedBalance memory _locked1 = locked[_to];
        uint256 value0 = uint256(int256(_locked0.amount));
        uint256 end = _locked0.end >= _locked1.end
            ? _locked0.end
            : _locked1.end;

        locked[_from] = LockedBalance(0, 0, 0);
        _checkpoint(_from, _locked0, LockedBalance(0, 0, 0));
        _burn(_from);
        _depositFor(
            _to,
            value0,
            end,
            _locked1,
            DepositType.MERGE_TYPE,
            false,
            false
        );
    }

    function blockNumber() external view returns (uint256) {
        return block.number;
    }

    /// @notice Record global data to checkpoint
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0, 0), LockedBalance(0, 0, 0));
    }

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function depositFor(uint256 _tokenId, uint256 _value)
        external
        nonReentrant
    {
        LockedBalance memory _locked = locked[_tokenId];

        require(_value > 0, "value = 0"); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock.");
        _depositFor(
            _tokenId,
            _value,
            0,
            _locked,
            DepositType.DEPOSIT_FOR_TYPE,
            true,
            false
        );
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    /// @param _shouldPullUserMaha Should we pull maha with the lock
    /// @param _stakeNFT should we stake into the staking contract
    function _createLock(
        uint256 _value,
        uint256 _lockDuration,
        address _to,
        bool _shouldPullUserMaha,
        bool _stakeNFT
    ) internal returns (uint256) {
        registry.ensureNotPaused();

        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_value > 0, "value = 0"); // dev: need non-zero value
        require(_value >= 100e18, "value should be >= 100 MAHA");
        require(unlockTime > block.timestamp, "Can only lock in the future");
        require(
            unlockTime <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        ++tokenId;
        uint256 _tokenId = tokenId;
        _mint(_to, _tokenId);

        _depositFor(
            _tokenId,
            _value,
            unlockTime,
            locked[_tokenId],
            DepositType.CREATE_LOCK_TYPE,
            _shouldPullUserMaha,
            _stakeNFT
        );

        require(
            _balanceOfNFT(_tokenId, block.timestamp) >= minLockAmount,
            "min amount for nft not met"
        );

        return _tokenId;
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function createLockFor(
        uint256 _value,
        uint256 _lockDuration,
        address _to
    ) external nonReentrant returns (uint256) {
        return _createLock(_value, _lockDuration, _to, true, false);
    }

    function migrateTokenFor(
        uint256 _value,
        uint256 _lockDuration,
        address _to
    ) external onlyMigrator returns (uint256) {
        return _createLock(_value, _lockDuration, _to, false, false);
    }

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _stakeNFT Should we also stake the NFT as well?
    function createLock(
        uint256 _value,
        uint256 _lockDuration,
        bool _stakeNFT
    ) external nonReentrant returns (uint256) {
        return _createLock(_value, _lockDuration, msg.sender, true, _stakeNFT);
    }

    /// @notice Upload users.
    /// @param _users The users for whose lock is to be added.
    /// @param _value The values for users.
    /// @param _lockDuration The lock duration for users.
    function uploadUsers(
        address[] memory _users,
        uint256[] memory _value,
        uint256[] memory _lockDuration
    ) external onlyMigrator {
        require(_value.length == _lockDuration.length, "invalid data");
        require(_users.length == _value.length, "invalid data");

        for (uint256 i = 0; i < _users.length; i++) {
            _createLock(_value[i], _lockDuration[i], _users[i], false, false);
        }
    }

    /// @notice Sets the royalty info for all NFT marketplaces
    /// @param _royaltyRcv The address to recieve royalties
    /// @param _royaltyFeeNumerator The amount of royalty to recieve
    function setRoyaltyInfo(address _royaltyRcv, uint96 _royaltyFeeNumerator)
        external
        onlyGovernance
    {
        _setDefaultRoyalty(_royaltyRcv, _royaltyFeeNumerator);
    }

    /// @notice Sets the min amount to lock
    /// @param _minLockAmount The min amount to lock
    function setMinLockAmount(uint256 _minLockAmount) external onlyGovernance {
        minLockAmount = _minLockAmount;
    }

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increaseAmount(uint256 _tokenId, uint256 _value)
        external
        nonReentrant
    {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];

        assert(_value > 0); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock.");

        _depositFor(
            _tokenId,
            _value,
            0,
            _locked,
            DepositType.INCREASE_LOCK_AMOUNT,
            true,
            false
        );
    }

    /// @notice Extend the unlock time for `_tokenId`
    /// @param _lockDuration New number of seconds until tokens unlock
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration)
        external
        nonReentrant
    {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];
        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlockTime > _locked.end, "Can only increase lock duration");
        require(
            unlockTime <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );
        require(
            unlockTime <= _locked.start + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _depositFor(
            _tokenId,
            0,
            unlockTime,
            _locked,
            DepositType.INCREASE_UNLOCK_TIME,
            false,
            false
        );
    }

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock has expired
    function withdraw(uint256 _tokenId) external nonReentrant {
        registry.ensureNotPaused();

        assert(_isApprovedOrOwner(msg.sender, _tokenId));
        require(!staked[_tokenId], "staked");

        LockedBalance memory _locked = locked[_tokenId];
        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 value = uint256(int256(_locked.amount));

        locked[_tokenId] = LockedBalance(0, 0, 0);
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        // oldLocked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, _locked, LockedBalance(0, 0, 0));

        assert(IERC20(registry.maha()).transfer(msg.sender, value));

        // Burn the NFT
        _burn(_tokenId);

        emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    /// @notice Sets the optional tokenURI override contract.
    function setRenderingContract(ITokenURIGenerator _contract)
        external
        onlyGovernance
    {
        renderingContract = _contract;
    }

    /// @notice If renderingContract is set then returns its tokenURI(tokenId)
    /// return value, otherwise returns the standard baseTokenURI + tokenId.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return renderingContract.tokenURI(_tokenId);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /// @notice Binary search to estimate timestamp for block number
    /// @param _block Block to find
    /// @param maxEpoch Don't go beyond this epoch
    /// @return Approximate timestamp for block
    function _findBlockEpoch(uint256 _block, uint256 maxEpoch)
        internal
        view
        returns (uint256)
    {
        // Binary search
        uint256 _min = 0;
        uint256 _max = maxEpoch;
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /// @notice Get the current voting power for `_tokenId`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    /// @param _tokenId NFT for lock
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function _balanceOfNFT(uint256 _tokenId, uint256 _t)
        internal
        view
        returns (uint256)
    {
        uint256 _epoch = userPointEpoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[_tokenId][_epoch];
            lastPoint.bias -=
                lastPoint.slope *
                int128(int256(_t) - int256(lastPoint.ts));
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(int256(lastPoint.bias));
        }
    }

    function balanceOfNFT(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {
        if (ownershipChange[_tokenId] == block.number) return 0;
        return _balanceOfNFT(_tokenId, block.timestamp);
    }

    function balanceOfNFTAt(uint256 _tokenId, uint256 _t)
        external
        view
        returns (uint256)
    {
        return _balanceOfNFT(_tokenId, _t);
    }

    /// @notice Measure voting power of `_tokenId` at block height `_block`
    /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    /// @param _tokenId User's wallet NFT
    /// @param _block Block to calculate the voting power at
    /// @return Voting power
    function _balanceOfAtNFT(uint256 _tokenId, uint256 _block)
        internal
        view
        returns (uint256)
    {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        assert(_block <= block.number);

        // Binary search
        uint256 _min = 0;
        uint256 _max = userPointEpoch[_tokenId];
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[_tokenId][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = userPointHistory[_tokenId][_min];

        uint256 maxEpoch = epoch;
        uint256 _epoch = _findBlockEpoch(_block, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 dBlock = 0;
        uint256 dT = 0;
        if (_epoch < maxEpoch) {
            Point memory point1 = pointHistory[_epoch + 1];
            dBlock = point1.blk - point0.blk;
            dT = point1.ts - point0.ts;
        } else {
            dBlock = block.number - point0.blk;
            dT = block.timestamp - point0.ts;
        }
        uint256 blockTime = point0.ts;
        if (dBlock != 0) {
            blockTime += (dT * (_block - point0.blk)) / dBlock;
        }

        upoint.bias -= upoint.slope * int128(int256(blockTime - upoint.ts));
        if (upoint.bias >= 0) {
            return uint256(uint128(upoint.bias));
        } else {
            return 0;
        }
    }

    function balanceOfAtNFT(uint256 _tokenId, uint256 _block)
        external
        view
        returns (uint256)
    {
        return _balanceOfAtNFT(_tokenId, _block);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param point The point (bias/slope) to start search from
    /// @param t Time to calculate the total voting power at
    /// @return Total voting power at that time
    function _supplyAt(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        Point memory lastPoint = point;
        uint256 tI = (lastPoint.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; ++i) {
            tI += WEEK;
            int128 dSlope = 0;
            if (tI > t) {
                tI = t;
            } else {
                dSlope = slopeChanges[tI];
            }
            lastPoint.bias -=
                lastPoint.slope *
                int128(int256(tI - lastPoint.ts));
            if (tI == t) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = tI;
        }

        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        return uint256(uint128(lastPoint.bias));
    }

    /// @notice Calculate total voting power
    /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    /// @return Total voting power
    function totalSupplyAtT(uint256 t) public view returns (uint256) {
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];
        return _supplyAt(lastPoint, t);
    }

    function totalSupply() external view override returns (uint256) {
        return totalSupplyAtT(block.timestamp);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param _block Block to calculate the total voting power at
    /// @return Total voting power at `_block`
    function totalSupplyAt(uint256 _block)
        external
        view
        override
        returns (uint256)
    {
        assert(_block <= block.number);
        uint256 _epoch = epoch;
        uint256 targetEpoch = _findBlockEpoch(_block, _epoch);

        Point memory point = pointHistory[targetEpoch];
        uint256 dt = 0;
        if (targetEpoch < _epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt =
                    ((_block - point.blk) * (pointNext.ts - point.ts)) /
                    (pointNext.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return _supplyAt(point, point.ts + dt);
    }

    function _burn(uint256 _tokenId) internal {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "caller is not owner nor approved"
        );

        address owner = _ownerOf(_tokenId);

        // Clear approval
        _approve(address(0), _tokenId);
        // Remove token
        _removeTokenFrom(msg.sender, _tokenId);
        emit Transfer(owner, address(0), _tokenId);
    }
}