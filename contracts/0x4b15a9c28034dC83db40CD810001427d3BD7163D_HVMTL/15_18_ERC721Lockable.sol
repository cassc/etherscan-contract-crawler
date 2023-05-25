// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721Lockable.sol";

error TokenIsLocked();
error NotAllowedToLockToken();
error ExceedsMaxableLockTime();

/**
 * @title ERC721Lockable enables the temporary transfer lock on a token.
 */
abstract contract ERC721Lockable is ERC721, IERC721Lockable {
    uint256 public constant MAX_LOCK_EPOCH = 31536000; // 1 year in seconds
    mapping(uint256 => uint256) private lockedTokens;

    // add a list of contracts that can lock
    mapping(address => bool) public contractsAllowedToLock;

    modifier onlyTokenLocker() {
        if (contractsAllowedToLock[msg.sender] == false) {
            revert NotAllowedToLockToken();
        }
        _;
    }

    /**
     * @notice temporary lock the transferring of a token by a smart contract
     * @param tokenId id of the locked token
     * @param unlockTimestamp timestamp when token unlocks
     */
    function lockTokenByContract(
        uint256 tokenId,
        uint256 unlockTimestamp
    ) external onlyTokenLocker {
        if (lockedTokens[tokenId] > block.timestamp) {
            revert TokenIsLocked();
        }
        if (
            unlockTimestamp > block.timestamp &&
            (unlockTimestamp - block.timestamp) > MAX_LOCK_EPOCH
        ) revert ExceedsMaxableLockTime();

        lockedTokens[tokenId] = unlockTimestamp;
        emit TokenLocked(tokenId, unlockTimestamp);
    }

    /**
     * @notice unlocks token by authorized smart contract
     * @param tokenId id of the locked token
     */
    function unlockTokenByContract(uint256 tokenId) external onlyTokenLocker {
        delete lockedTokens[tokenId];
    }

    /**
     * @notice check if a token is currently locked
     * @param tokenId id of the locked token
     * @return boolean if token is locked
     */
    function isLocked(uint256 tokenId) external view returns (bool) {
        return (lockedTokens[tokenId] > block.timestamp);
    }

    /**
     * @notice check when token lock expires
     * @param tokenId id of the locked token
     * @return uint256 timestamp when token unlocks
     */
    function lockExpiration(uint256 tokenId) external view returns (uint256) {
        return lockedTokens[tokenId];
    }

    /**
     * @notice set the token lock contract
     * @param _tokenLockContract address of contract
     */
    function _addContractAllowedToLock(
        address _tokenLockContract,
        bool isEnabled
    ) internal {
        contractsAllowedToLock[_tokenLockContract] = isEnabled;
    }

    /**
     * @notice override of _beforeTokenTransfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        if (lockedTokens[tokenId] > block.timestamp) {
            revert TokenIsLocked();
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return
            interfaceId == type(IERC721Lockable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}