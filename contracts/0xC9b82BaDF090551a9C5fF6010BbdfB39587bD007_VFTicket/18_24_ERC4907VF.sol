// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC721VF.sol";
import "./IERC4907VF.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ERC4907VF is ERC721VF, IERC4907VF {
    using ECDSA for bytes32;

    struct UserInfo {
        address user;
        uint64 expires;
    }

    mapping(uint256 => UserInfo) internal _users;
    mapping(bytes32 => bool) internal _executed;

    //Address of set user signer
    address private _signer;

    constructor(
        string memory name_,
        string memory symbol_,
        address signer
    ) ERC721VF(name_, symbol_) {
        _signer = signer;
    }

    /**
     * @dev Update the set user signer address with `signer`
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setSigner(address signer) public virtual {
        _signer = signer;
    }

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires,
        string calldata orderId,
        uint256 timestamp,
        bytes calldata signature
    ) public virtual {
        bytes32 txHash = _getTxHash(
            _msgSender(),
            tokenId,
            user,
            expires,
            orderId,
            timestamp
        );

        if (!_isValidSignature(txHash, signature)) {
            revert ERC4907VFInvalidSignature();
        }

        if ((timestamp + 15 minutes) <= block.timestamp) {
            revert ERC4907VFTransactionExpired();
        }

        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert ERC4907VFTransferCallerIsNotOwnerNorApproved();
        }

        _setUser(tokenId, user, expires);
    }

    function userOf(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);
        return _userOf(tokenId);
    }

    function tokensOfUserIn(
        address user,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (uint256[] memory userTokens) {
        address currentUserAddress;
        uint256 tokenCount = endIndex - startIndex + 1;

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            uint256 index = startIndex;
            for (index; index <= endIndex; index++) {
                currentUserAddress = _userOf(index);
                if (currentUserAddress == user) {
                    result[resultIndex++] = index;
                }
            }

            // Downsize the array to fit.
            assembly {
                mstore(result, resultIndex)
            }

            return result;
        }
    }

    function userExpires(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _users[tokenId].expires;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC4907VF).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _userOf(uint256 tokenId) internal view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return _ownerOf(tokenId);
        }
    }

    function _setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) internal virtual {
        _requireMinted(tokenId);

        UserInfo storage info = _users[tokenId];

        info.user = user;
        info.expires = 0;

        if (info.user != address(0)) {
            info.expires = expires;
        }

        emit UpdateUser(tokenId, user, expires);
    }

    /**
     * @dev Get the hash of a transaction
     */
    function _getTxHash(
        address sender,
        uint256 tokenId,
        address user,
        uint64 expires,
        string calldata orderId,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sender,
                    tokenId,
                    user,
                    expires,
                    orderId,
                    timestamp
                )
            );
    }

    /**
     * @dev Validate a tx is signed by the signer address
     */
    function _isValidSignature(bytes32 txHash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        address signer = txHash.toEthSignedMessageHash().recover(signature);
        return signer == _signer;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batch
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batch);

        if (from == to) {
            return;
        }

        address user = _users[tokenId].user;
        if (user == address(0)) {
            return;
        }

        delete _users[tokenId];
        emit UpdateUser(tokenId, address(0), 0);
    }
}