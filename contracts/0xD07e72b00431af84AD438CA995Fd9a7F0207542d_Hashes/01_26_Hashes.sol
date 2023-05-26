// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IHashes } from "./IHashes.sol";
import { LibDeactivateToken } from "./LibDeactivateToken.sol";
import { LibEIP712 } from "./LibEIP712.sol";
import { LibSignature } from "./LibSignature.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Hashes
 * @author DEX Labs
 * @notice This contract handles the Hashes ERC-721 token.
 */
contract Hashes is IHashes, ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /// @notice version for this Hashes contract
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

    /// @notice activationFee The fee to activate (and the payment to deactivate)
    ///         a governance class hash that wasn't reserved. This is the initial
    ///         minting fee.
    uint256 public immutable override activationFee;

    /// @notice locked The lock status of the contract. Once locked, the contract
    ///         will never be unlocked. Locking prevents the transfer of ownership.
    bool public locked;

    /// @notice mintFee Minting fee.
    uint256 public mintFee;

    /// @notice reservedAmount Number of Hashes reserved.
    uint256 public reservedAmount;

    /// @notice governanceCap Number of Hashes qualifying for governance.
    uint256 public governanceCap;

    /// @notice nonce Monotonically-increasing number (token ID).
    uint256 public nonce;

    /// @notice baseTokenURI The base of the token URI.
    string public baseTokenURI;

    bytes internal constant TABLE = "0123456789abcdef";

    /// @notice A checkpoint for marking vote count from given block.
    struct Checkpoint {
        uint32 id;
        uint256 votes;
    }

    /// @notice deactivated A record of tokens that have been deactivated by token ID.
    mapping(uint256 => bool) public deactivated;

    /// @notice lastProposalIds A record of the last recorded proposal IDs by an address.
    mapping(address => uint256) public lastProposalIds;

    /// @notice checkpoints A record of votes checkpoints for each account, by index.
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice numCheckpoints The number of checkpoints for each account.
    mapping(address => uint256) public numCheckpoints;

    mapping(uint256 => bytes32) nonceToHash;

    mapping(uint256 => bool) redeemed;

    /// @notice Emitted when governance class tokens are activated.
    event Activated(address indexed owner, uint256 indexed tokenId);

    /// @notice Emitted when governance class tokens are deactivated.
    event Deactivated(address indexed owner, uint256 indexed tokenId, uint256 proposalId);

    /// @notice Emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice Emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /// @notice Emitted when a Hash was generated/minted
    event Generated(address artist, uint256 tokenId, string phrase);

    /// @notice Emitted when a reserved Hash was redemed
    event Redeemed(address artist, uint256 tokenId, string phrase);

    // @notice Emitted when the base token URI is updated
    event BaseTokenURISet(string baseTokenURI);

    // @notice Emitted when the mint fee is updated
    event MintFeeSet(uint256 indexed fee);

    /**
     * @notice Constructor for the Hashes token. Initializes the state.
     * @param _mintFee Minting fee
     * @param _reservedAmount Reserved number of Hashes
     * @param _governanceCap Number of hashes qualifying for governance
     * @param _baseTokenURI The initial base token URI.
     */
    constructor(uint256 _mintFee, uint256 _reservedAmount, uint256 _governanceCap, string memory _baseTokenURI) ERC721("Hashes", "HASH") Ownable() {
        reservedAmount = _reservedAmount;
        activationFee = _mintFee;
        mintFee = _mintFee;
        governanceCap = _governanceCap;
        for (uint i = 0; i < reservedAmount; i++) {
            // Compute and save the hash (temporary till redemption)
            nonceToHash[nonce] = keccak256(abi.encodePacked(nonce, _msgSender()));
            // Mint the token
            _safeMint(_msgSender(), nonce++);
        }
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice Allows the owner to lock ownership. This prevents ownership from
     *         ever being transferred in the future.
     */
    function lock() external onlyOwner {
        require(!locked, "Hashes: can't lock twice.");
        locked = true;
    }

    /**
     * @dev An overridden version of `transferOwnership` that checks to see if
     *      ownership is locked.
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        require(!locked, "Hashes: can't transfer ownership when locked.");
        super.transferOwnership(_newOwner);
    }

    /**
     * @notice Allows governance to update the base token URI.
     * @param _baseTokenURI The new base token URI.
     */
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BaseTokenURISet(_baseTokenURI);
    }

    /**
     * @notice Allows governance to update the fee to mint a hash.
     * @param _mintFee The fee to mint a hash.
     */
    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
        emit MintFeeSet(_mintFee);
    }

    /**
     * @notice Allows a token ID owner to activate their governance class token.
     * @return activationCount The amount of tokens that were activated.
     */
    function activateTokens() external payable nonReentrant returns (uint256 activationCount) {
        // Activate as many tokens as possible.
        for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (tokenId >= reservedAmount && tokenId < governanceCap && deactivated[tokenId]) {
                deactivated[tokenId] = false;
                activationCount++;

                // Emit an activation event.
                emit Activated(msg.sender, tokenId);
            }
        }

        // Increase the sender's governance power.
        _moveDelegates(address(0), msg.sender, activationCount);

        // Ensure that sufficient ether was provided to pay the activation fee.
        // If a sufficient amount was provided, send it to the owner. Refund the
        // sender with the remaining amount of ether.
        bool sent;
        uint256 requiredFee = activationFee.mul(activationCount);
        require(msg.value >= requiredFee, "Hashes: must pay adequate fee to activate hash.");
        (sent,) = owner().call{value: requiredFee}("");
        require(sent, "Hashes: couldn't pay owner the activation fee.");
        if (msg.value > requiredFee) {
            (sent,) = msg.sender.call{value: msg.value - requiredFee}("");
            require(sent, "Hashes: couldn't refund sender with the remaining ether.");
        }

        return activationCount;
    }

    /**
     * @notice Allows the owner to process a series of deactivations from governance
     *         class tokens owned by a single holder. The owner is responsible for
     *         handling payment once deactivations have been finalized.
     * @param _tokenOwner The owner of the hashes to deactivate.
     * @param _proposalId The proposal ID that this deactivation is related to.
     * @param _signature The signature to prove the owner wants to deactivate
     *        their holdings.
     * @return deactivationCount The amount of tokens that were deactivated.
     */
    function deactivateTokens(address _tokenOwner, uint256 _proposalId, bytes memory _signature) external override nonReentrant onlyOwner returns (uint256 deactivationCount) {
        // Ensure that the token owner has approved the deactivation.
        require(lastProposalIds[_tokenOwner] < _proposalId, "Hashes: can't re-use an old proposal ID.");
        lastProposalIds[_tokenOwner] = _proposalId;
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name(), version, getChainId(), address(this));
        bytes32 deactivateHash =
            LibDeactivateToken.getDeactivateTokenHash(
                LibDeactivateToken.DeactivateToken({ proposalId: _proposalId }),
                eip712DomainHash
            );
        require(LibSignature.getSignerOfHash(deactivateHash, _signature) == _tokenOwner, "Hashes: The token owner must approve the deactivation.");

        // Deactivate as many tokens as possible.
        for (uint256 i = 0; i < balanceOf(_tokenOwner); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_tokenOwner, i);
            if (tokenId >= reservedAmount && tokenId < governanceCap && !deactivated[tokenId]) {
                deactivated[tokenId] = true;
                deactivationCount++;

                // Emit a deactivation event.
                emit Deactivated(_tokenOwner, tokenId, _proposalId);
            }
        }

        // Decrease the voter's governance power.
        _moveDelegates(_tokenOwner, address(0), deactivationCount);

        return deactivationCount;
    }

    /**
     * @notice Generate a new Hashes token provided a phrase. This
     *         function generates/saves a hash, mints the token, and
     *         transfers the minting fee to the HashesDAO when
     *         applicable.
     * @param _phrase Phrase used as part of hashing inputs.
     */
    function generate(string memory _phrase) external nonReentrant payable {
        // Ensure that the hash can be generated.
        require(bytes(_phrase).length > 0, "Hashes: Can't generate hash with the empty string.");

        // Ensure token minter is passing in a sufficient minting fee.
        require(msg.value >= mintFee, "Hashes: Must pass sufficient mint fee.");

        // Compute and save the hash
        nonceToHash[nonce] = keccak256(abi.encodePacked(nonce, _msgSender(), _phrase));

        // Mint the token
        _safeMint(_msgSender(), nonce++);

        uint256 mintFeePaid;
        if (mintFee > 0) {
            // If the minting fee is non-zero

            // Send the fee to HashesDAO.
            (bool sent,) = owner().call{value: mintFee}("");
            require(sent, "Hashes: failed to send ETH to HashesDAO");

            // Set the mintFeePaid to the current minting fee
            mintFeePaid = mintFee;
        }

        if (msg.value > mintFeePaid) {
            // If minter passed ETH value greater than the minting
            // fee paid/computed above

            // Refund the remaining ether balance to the sender. Since there are no
            // other payable functions, this remainder will always be the senders.
            (bool sent,) = _msgSender().call{value: msg.value - mintFeePaid}("");
            require(sent, "Hashes: failed to refund ETH.");
        }

        if (nonce == governanceCap) {
            // Set mint fee to 0 now that governance cap has been hit.
            // The minting fee can only be increased from here via
            // governance.
            mintFee = 0;
        }

        emit Generated(_msgSender(), nonce - 1, _phrase);
    }

    /**
     * @notice Redeem a reserved Hashes token. Any may redeem a
     *         reserved Hashes token so long as they hold the token
     *         and this particular token hasn't been redeemed yet.
     *         Redemption lets an owner of a reserved token to
     *         modify the phrase as they choose.
     * @param _tokenId Token ID.
     * @param _phrase Phrase used as part of hashing inputs.
     */
    function redeem(uint256 _tokenId, string memory _phrase) external nonReentrant {
        // Ensure redeemer is the token owner.
        require(_msgSender() == ownerOf(_tokenId), "Hashes: must be owner.");

        // Ensure that redeemed token is a reserved token.
        require(_tokenId < reservedAmount, "Hashes: must be a reserved token.");

        // Ensure the token hasn't been redeemed before.
        require(!redeemed[_tokenId], "Hashes: already redeemed.");

        // Mark the token as redeemed.
        redeemed[_tokenId] = true;

        // Update the hash.
        nonceToHash[_tokenId] = keccak256(abi.encodePacked(_tokenId, _msgSender(), _phrase));

        emit Redeemed(_msgSender(), _tokenId, _phrase);
    }

    /**
     * @notice Verify the validity of a Hash token given its inputs.
     * @param _tokenId Token ID for Hash token.
     * @param _minter Minter's (or redeemer's) Ethereum address.
     * @param _phrase Phrase used at time of generation/redemption.
     * @return Whether the Hash token's hash saved given this token ID
     *         matches the inputs provided.
     */
    function verify(uint256 _tokenId, address _minter, string memory _phrase) external override view returns (bool) {
        // Enforce the normal hashes regularity conditions before verifying.
        if (_tokenId >= nonce || _minter == address(0) || bytes(_phrase).length == 0) {
            return false;
        }

        // Verify the provided phrase.
        return nonceToHash[_tokenId] == keccak256(abi.encodePacked(_tokenId, _minter, _phrase));
    }

    /**
     * @notice Retrieve token URI given a token ID.
     * @param _tokenId Token ID.
     * @return Token URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Ensure that the token ID is valid and that the hash isn't empty.
        require(_tokenId < nonce, "Hashes: Can't provide a token URI for a non-existent hash.");

        // Return the base token URI concatenated with the token ID.
        return string(abi.encodePacked(baseTokenURI, _toDecimalString(_tokenId)));
    }

    /**
     * @notice Retrieve hash given a token ID.
     * @param _tokenId Token ID.
     * @return Hash associated with this token ID.
     */
    function getHash(uint256 _tokenId) external override view returns (bytes32) {
        return nonceToHash[_tokenId];
    }

    /**
     * @notice Gets the current votes balance.
     * @param _account The address to get votes balance.
     * @return The number of current votes.
     */
    function getCurrentVotes(address _account) external view returns (uint256) {
        uint256 numCheckpointsAccount = numCheckpoints[_account];
        return numCheckpointsAccount > 0 ? checkpoints[_account][numCheckpointsAccount - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber) external override view returns (uint256) {
        require(_blockNumber < block.number, "Hashes: block not yet determined.");

        uint256 numCheckpointsAccount = numCheckpoints[_account];
        if (numCheckpointsAccount == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][numCheckpointsAccount - 1].id <= _blockNumber) {
            return checkpoints[_account][numCheckpointsAccount - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].id > _blockNumber) {
            return 0;
        }

        // Perform binary search to find the most recent token holdings
        // leading to a measure of voting power
        uint256 lower = 0;
        uint256 upper = numCheckpointsAccount - 1;
        while (upper > lower) {
            // ceil, avoiding overflow
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.id == _blockNumber) {
                return cp.votes;
            } else if (cp.id < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (tokenId < governanceCap && !deactivated[tokenId]) {
            // If Hashes token is in the governance class, transfer voting rights
            // from `from` address to `to` address.
            _moveDelegates(from, to, 1);
        }
    }

    function _moveDelegates(
        address _initDel,
        address _finDel,
        uint256 _amount
    ) internal {
        if (_initDel != _finDel && _amount > 0) {
            // Initial delegated address is different than final
            // delegated address and nonzero number of votes moved
            if (_initDel != address(0)) {
                // If we are not minting a new token

                uint256 initDelNum = numCheckpoints[_initDel];

                // Retrieve and compute the old and new initial delegate
                // address' votes
                uint256 initDelOld = initDelNum > 0 ? checkpoints[_initDel][initDelNum - 1].votes : 0;
                uint256 initDelNew = initDelOld.sub(_amount);
                _writeCheckpoint(_initDel, initDelOld, initDelNew);
            }

            if (_finDel != address(0)) {
                // If we are not burning a token
                uint256 finDelNum = numCheckpoints[_finDel];

                // Retrieve and compute the old and new final delegate
                // address' votes
                uint256 finDelOld = finDelNum > 0 ? checkpoints[_finDel][finDelNum - 1].votes : 0;
                uint256 finDelNew = finDelOld.add(_amount);
                _writeCheckpoint(_finDel, finDelOld, finDelNew);
            }
        }
    }

    function _writeCheckpoint(
        address _delegatee,
        uint256 _oldVotes,
        uint256 _newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "Hashes: exceeds 32 bits.");
        uint256 delNum = numCheckpoints[_delegatee];
        if (delNum > 0 && checkpoints[_delegatee][delNum - 1].id == blockNumber) {
            // If latest checkpoint is current block, edit in place
            checkpoints[_delegatee][delNum - 1].votes = _newVotes;
        } else {
            // Create a new id, vote pair
            checkpoints[_delegatee][delNum] = Checkpoint({ id: blockNumber, votes: _newVotes });
            numCheckpoints[_delegatee] = delNum.add(1);
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _toDecimalString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function _toHexString(uint256 _value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(66);
        buffer[0] = bytes1("0");
        buffer[1] = bytes1("x");
        for (uint256 i = 0; i < 64; i++) {
            buffer[65 - i] = bytes1(TABLE[_value % 16]);
            _value /= 16;
        }
        return string(buffer);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}