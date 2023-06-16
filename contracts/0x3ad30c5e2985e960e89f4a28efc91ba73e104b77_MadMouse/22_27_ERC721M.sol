// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './ERC721MLibrary.sol';

error IncorrectOwner();
error NonexistentToken();
error QueryForZeroAddress();

error TokenIdUnstaked();
error ExceedsStakingLimit();

error MintToZeroAddress();
error MintZeroQuantity();
error MintMaxSupplyReached();
error MintMaxWalletReached();

error CallerNotOwnerNorApproved();

error ApprovalToCaller();
error ApproveToCurrentOwner();

error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();

abstract contract ERC721M {
    using Address for address;
    using Strings for uint256;
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    uint256 public totalSupply;

    uint256 immutable startingIndex;
    uint256 immutable collectionSize;
    uint256 immutable maxPerWallet;

    // note: hard limit of 255, otherwise overflows can happen
    uint256 constant stakingLimit = 100;

    mapping(uint256 => uint256) internal _tokenData;
    mapping(address => uint256) internal _userData;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startingIndex_,
        uint256 collectionSize_,
        uint256 maxPerWallet_
    ) {
        name = name_;
        symbol = symbol_;
        collectionSize = collectionSize_;
        maxPerWallet = maxPerWallet_;
        startingIndex = startingIndex_;
    }

    /* ------------- External ------------- */

    function stake(uint256[] calldata tokenIds) external payable {
        uint256 userData = _claimReward();
        for (uint256 i; i < tokenIds.length; ++i) userData = _stake(msg.sender, tokenIds[i], userData);
        _userData[msg.sender] = userData;
    }

    function unstake(uint256[] calldata tokenIds) external payable {
        uint256 userData = _claimReward();
        for (uint256 i; i < tokenIds.length; ++i) userData = _unstake(msg.sender, tokenIds[i], userData);
        _userData[msg.sender] = userData;
    }

    function claimReward() external payable {
        _userData[msg.sender] = _claimReward();
    }

    /* ------------- Private ------------- */

    function _stake(
        address from,
        uint256 tokenId,
        uint256 userData
    ) private returns (uint256) {
        uint256 _numStaked = userData.numStaked();

        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.owner();

        if (_numStaked >= stakingLimit) revert ExceedsStakingLimit();
        if (owner != from) revert IncorrectOwner();

        delete getApproved[tokenId];

        // hook, used for reading DNA, updating role balances,
        (uint256 userDataX, uint256 tokenDataX) = _beforeStakeDataTransform(tokenId, userData, tokenData);
        (userData, tokenData) = applySafeDataTransform(userData, tokenData, userDataX, tokenDataX);

        tokenData = tokenData.setstaked();
        userData = userData.decreaseBalance(1).increaseNumStaked(1);

        if (_numStaked == 0) userData = userData.setStakeStart(block.timestamp);

        _tokenData[tokenId] = tokenData;

        emit Transfer(from, address(this), tokenId);

        return userData;
    }

    function _unstake(
        address to,
        uint256 tokenId,
        uint256 userData
    ) private returns (uint256) {
        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.trueOwner();
        bool isStaked = tokenData.staked();

        if (owner != to) revert IncorrectOwner();
        if (!isStaked) revert TokenIdUnstaked();

        (uint256 userDataX, uint256 tokenDataX) = _beforeUnstakeDataTransform(tokenId, userData, tokenData);
        (userData, tokenData) = applySafeDataTransform(userData, tokenData, userDataX, tokenDataX);

        // if mintAndStake flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.mintAndStake()) {
            unchecked {
                tokenData = _ensureTokenDataSet(tokenId + 1, tokenData).unsetMintAndStake();
            }
        }

        tokenData = tokenData.unsetstaked();
        userData = userData.increaseBalance(1).decreaseNumStaked(1).setStakeStart(block.timestamp);

        _tokenData[tokenId] = tokenData;

        emit Transfer(address(this), to, tokenId);

        return userData;
    }

    /* ------------- Internal ------------- */

    function _mintAndStake(
        address to,
        uint256 quantity,
        bool stake_
    ) internal {
        unchecked {
            uint256 totalSupply_ = totalSupply;
            uint256 startTokenId = startingIndex + totalSupply_;

            uint256 userData = _userData[to];
            uint256 numMinted_ = userData.numMinted();

            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();

            if (totalSupply_ + quantity > collectionSize) revert MintMaxSupplyReached();
            if (numMinted_ + quantity > maxPerWallet && address(this).code.length != 0) revert MintMaxWalletReached();

            userData = userData.increaseNumMinted(quantity);

            uint256 tokenData = TokenDataOps.newTokenData(to, block.timestamp, stake_);

            // don't have to care about next token data if only minting one
            // could optimize to implicitly flag last token id of batch
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();

            if (stake_) {
                uint256 _numStaked = userData.numStaked();

                userData = claimReward(userData);
                userData = userData.increaseNumStaked(quantity);

                if (_numStaked + quantity > stakingLimit) revert ExceedsStakingLimit();
                if (_numStaked == 0) userData = userData.setStakeStart(block.timestamp);

                uint256 tokenId;
                for (uint256 i; i < quantity; ++i) {
                    tokenId = startTokenId + i;

                    (userData, tokenData) = _beforeStakeDataTransform(tokenId, userData, tokenData);

                    emit Transfer(address(0), to, tokenId);
                    emit Transfer(to, address(this), tokenId);
                }
            } else {
                userData = userData.increaseBalance(quantity);
                for (uint256 i; i < quantity; ++i) emit Transfer(address(0), to, startTokenId + i);
            }

            _userData[to] = userData;
            _tokenData[startTokenId] = tokenData;

            totalSupply += quantity;
        }
    }

    function _claimReward() internal returns (uint256) {
        uint256 userData = _userData[msg.sender];
        return claimReward(userData);
    }

    function claimReward(uint256 userData) private returns (uint256) {
        uint256 reward = _pendingReward(msg.sender, userData);

        userData = userData.setLastClaimed(block.timestamp);

        _payoutReward(msg.sender, reward);

        return userData;
    }

    function _tokenDataOf(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NonexistentToken();

        for (uint256 curr = tokenId; ; curr--) {
            uint256 tokenData = _tokenData[curr];
            if (tokenData != 0) return (curr == tokenId) ? tokenData : tokenData.copy();
        }

        // unreachable
        return 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return startingIndex <= tokenId && tokenId < startingIndex + totalSupply;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        // make sure no one is misled by token transfer events
        if (to == address(this)) {
            uint256 userData = _claimReward();
            _userData[msg.sender] = _stake(msg.sender, tokenId, userData);
        } else {
            uint256 tokenData = _tokenDataOf(tokenId);
            address owner = tokenData.owner();

            bool isApprovedOrOwner = (msg.sender == owner ||
                isApprovedForAll[owner][msg.sender] ||
                getApproved[tokenId] == msg.sender);

            if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
            if (to == address(0)) revert TransferToZeroAddress();
            if (owner != from) revert TransferFromIncorrectOwner();

            delete getApproved[tokenId];

            unchecked {
                _tokenData[tokenId] = _ensureTokenDataSet(tokenId + 1, tokenData)
                    .setOwner(to)
                    .setLastTransfer(block.timestamp)
                    .incrementOwnerCount();
            }

            _userData[from] = _userData[from].decreaseBalance(1);
            _userData[to] = _userData[to].increaseBalance(1);

            emit Transfer(from, to, tokenId);
        }
    }

    function _ensureTokenDataSet(uint256 tokenId, uint256 tokenData) private returns (uint256) {
        if (!tokenData.nextTokenDataSet() && _tokenData[tokenId] == 0 && _exists(tokenId))
            _tokenData[tokenId] = tokenData.copy(); // make sure to not pass any token specific data in
        return tokenData.flagNextTokenDataSet();
    }

    /* ------------- Virtual (hooks) ------------- */

    function _beforeStakeDataTransform(
        uint256, // tokenId
        uint256 userData,
        uint256 tokenData
    ) internal view virtual returns (uint256, uint256) {
        return (userData, tokenData);
    }

    function _beforeUnstakeDataTransform(
        uint256, // tokenId
        uint256 userData,
        uint256 tokenData
    ) internal view virtual returns (uint256, uint256) {
        return (userData, tokenData);
    }

    function _pendingReward(address, uint256 userData) internal view virtual returns (uint256);

    function _payoutReward(address user, uint256 reward) internal virtual;

    /* ------------- View ------------- */

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _tokenDataOf(tokenId).owner();
    }

    function trueOwnerOf(uint256 tokenId) external view returns (address) {
        return _tokenDataOf(tokenId).trueOwner();
    }

    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert QueryForZeroAddress();
        return _userData[owner].balance();
    }

    function numStaked(address user) external view returns (uint256) {
        return _userData[user].numStaked();
    }

    function numOwned(address user) external view returns (uint256) {
        uint256 userData = _userData[user];
        return userData.balance() + userData.numStaked();
    }

    function numMinted(address user) external view returns (uint256) {
        return _userData[user].numMinted();
    }

    function pendingReward(address user) external view returns (uint256) {
        return _pendingReward(user, _userData[user]);
    }

    // O(N) read-only functions

    function tokenIdsOf(address user, uint256 type_) external view returns (uint256[] memory) {
        unchecked {
            uint256 numTotal = type_ == 0 ? this.balanceOf(user) : type_ == 1
                ? this.numStaked(user)
                : this.numOwned(user);

            uint256[] memory ids = new uint256[](numTotal);

            if (numTotal == 0) return ids;

            uint256 count;
            for (uint256 i = startingIndex; i < totalSupply + startingIndex; ++i) {
                uint256 tokenData = _tokenDataOf(i);
                if (user == tokenData.trueOwner()) {
                    bool staked = tokenData.staked();
                    if ((type_ == 0 && !staked) || (type_ == 1 && staked) || type_ == 2) {
                        ids[count++] = i;
                        if (numTotal == count) return ids;
                    }
                }
            }

            return ids;
        }
    }

    function totalNumStaked() external view returns (uint256) {
        unchecked {
            uint256 count;
            for (uint256 i = startingIndex; i < startingIndex + totalSupply; ++i) {
                if (_tokenDataOf(i).staked()) ++count;
            }
            return count;
        }
    }

    /* ------------- ERC721 ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function approve(address spender, uint256 tokenId) external {
        address owner = _tokenDataOf(tokenId).owner();

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721ReceiverImplementer();
    }
}