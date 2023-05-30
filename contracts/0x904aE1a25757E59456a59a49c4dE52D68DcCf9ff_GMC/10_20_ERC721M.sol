// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712PermitUDS} from "UDS/auth/EIP712PermitUDS.sol";
import {UserDataOps, TokenDataOps} from "./ERC721MLibrary.sol";

// ------------- storage

struct ERC721MStorage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) userData;
    mapping(uint256 => uint256) tokenData;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

bytes32 constant DIAMOND_STORAGE_ERC721M_LOCKABLE = keccak256("diamond.storage.erc721m.lockable");

function s() pure returns (ERC721MStorage storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC721M_LOCKABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

// ------------- errors

error IncorrectOwner();
error TokenIdUnlocked();
error NonexistentToken();
error MintZeroQuantity();
error MintToZeroAddress();
error TransferFromInvalidTo();
error TransferToZeroAddress();
error CallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();

/// @title ERC721M (Integrated Token Locking)
/// @author phaze (https://github.com/0xPhaze/ERC721M)
/// @author modified from ERC721A (https://github.com/chiru-labs/ERC721A)
/// @author modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @notice Integrates EIP712Permit
abstract contract ERC721M is EIP712PermitUDS {
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    uint256 constant startingIndex = 1;

    constructor(string memory name_, string memory symbol_) {
        __ERC721_init(name_, symbol_);
    }

    /* ------------- init ------------- */

    function __ERC721_init(string memory name_, string memory symbol_) internal {
        s().name = name_;
        s().symbol = symbol_;
    }

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function balanceOf(address user) public view virtual returns (uint256) {
        return s().userData[user].balance();
    }

    function getApproved(uint256 id) external view virtual returns (address) {
        return s().getApproved[id];
    }

    function isApprovedForAll(address owner, address spender) external view virtual returns (bool) {
        return s().isApprovedForAll[owner][spender];
    }

    function ownerOf(uint256 id) public view virtual returns (address) {
        return _tokenDataOf(id).owner();
    }

    function totalSupply() public view virtual returns (uint256) {
        return s().totalSupply;
    }

    function getAux(uint256 id) public view returns (uint256) {
        return _tokenDataOf(id).aux();
    }

    function getLockStart(uint256 id) public view returns (uint256) {
        return _tokenDataOf(id).tokenLockStart();
    }

    function numMinted(address user) public view virtual returns (uint256) {
        return s().userData[user].numMinted();
    }

    function numLocked(address user) public view virtual returns (uint256) {
        return s().userData[user].numLocked();
    }

    function getLockStart(address user) public view virtual returns (uint256) {
        return s().userData[user].userLockStart();
    }

    function trueOwnerOf(uint256 id) public view virtual returns (address) {
        return _tokenDataOf(id).trueOwner();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- public ------------- */

    function approve(address spender, uint256 id) public virtual {
        address owner = _tokenDataOf(id).owner();

        if (msg.sender != owner && !s().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        s().getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isApprovedOrOwner(address from, uint256 id) private view returns (bool) {
        return (msg.sender == from || s().isApprovedForAll[from][msg.sender] || s().getApproved[id] == msg.sender);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(this)) revert TransferFromInvalidTo();
        if (to == address(0)) revert TransferToZeroAddress();

        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (tokenData.owner() != from) revert TransferFromIncorrectOwner();

        delete s().getApproved[id];

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.setOwner(to).flagNextTokenDataSet();

        s().userData[to] = s().userData[to].increaseBalance(1);
        s().userData[from] = s().userData[from].decreaseBalance(1);

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721Receiver();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _exists(uint256 id) internal view virtual returns (bool) {
        return startingIndex <= id && id < _nextTokenId();
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        return startingIndex + totalSupply();
    }

    function _increaseTotalSupply(uint256 amount) internal virtual {
        if (amount != 0) s().totalSupply = _nextTokenId() + amount - 1;
    }

    function _tokenDataOf(uint256 id) internal view virtual returns (uint256 out) {
        if (!_exists(id)) revert NonexistentToken();

        unchecked {
            uint256 tokenData;

            for (uint256 curr = id; ; curr--) {
                tokenData = s().tokenData[curr];

                if (tokenData != 0) return tokenData;
            }
        }
    }

    function _ensureTokenDataSet(uint256 id, uint256 tokenData) internal virtual {
        if (!tokenData.nextTokenDataSet() && s().tokenData[id] == 0 && _exists(id)) s().tokenData[id] = tokenData;
    }

    function _mint(address to, uint256 quantity) internal virtual {
        _mintAndLock(to, quantity, false, 0);
    }

    function _mint(
        address to,
        uint256 quantity,
        uint48 auxData
    ) internal virtual {
        _mintAndLock(to, quantity, false, auxData);
    }

    function _mintAndLock(
        address to,
        uint256 quantity,
        bool lock
    ) internal virtual {
        _mintAndLock(to, quantity, lock, 0);
    }

    function _mintAndLock(
        address to,
        uint256 quantity,
        bool lock,
        uint48 auxData
    ) internal virtual {
        unchecked {
            if (quantity == 0) revert MintZeroQuantity();
            if (to == address(0)) revert MintToZeroAddress();

            uint256 startTokenId = _nextTokenId();
            uint256 tokenData = uint256(uint160(to)).setAux(auxData);
            uint256 userData = s().userData[to];

            // don't have to care about next token data if only minting one
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();
            if (lock) {
                tokenData = tokenData.setConsecutiveLocked().lock();

                userData = userData.increaseNumLocked(quantity).setUserLockStart(block.timestamp);

                for (uint256 i; i < quantity; ++i) {
                    emit Transfer(address(0), to, startTokenId + i);
                    emit Transfer(to, address(this), startTokenId + i);
                }
            } else {
                for (uint256 i; i < quantity; ++i) {
                    emit Transfer(address(0), to, startTokenId + i);
                }
            }

            s().userData[to] = userData.increaseNumMinted(quantity).increaseBalance(quantity);
            s().tokenData[startTokenId] = tokenData;

            _increaseTotalSupply(quantity);
        }
    }

    function _setAux(uint256 id, uint48 aux) internal virtual {
        uint256 tokenData = _tokenDataOf(id);

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.setAux(aux);
    }

    function _lock(address from, uint256 id) internal virtual {
        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (tokenData.owner() != from) revert IncorrectOwner();

        delete s().getApproved[id];

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.lock().unsetConsecutiveLocked().flagNextTokenDataSet();
        s().userData[from] = s().userData[from].increaseNumLocked(1).setUserLockStart(block.timestamp);

        emit Transfer(from, address(this), id);
    }

    function _unlock(address from, uint256 id) internal virtual {
        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (!tokenData.locked()) revert TokenIdUnlocked();
        if (tokenData.trueOwner() != from) revert IncorrectOwner();

        // if isConsecutiveLocked flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.isConsecutiveLocked()) {
            unchecked {
                _ensureTokenDataSet(id + 1, tokenData);

                tokenData = tokenData.unsetConsecutiveLocked().flagNextTokenDataSet();
            }
        }

        s().tokenData[id] = tokenData.unlock();
        s().userData[from] = s().userData[from].decreaseNumLocked(1).setUserLockStart(block.timestamp);

        emit Transfer(address(this), from, id);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}