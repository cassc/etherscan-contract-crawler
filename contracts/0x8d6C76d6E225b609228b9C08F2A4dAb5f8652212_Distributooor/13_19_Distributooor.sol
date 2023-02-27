// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IRaffleChef} from "../interfaces/IRaffleChef.sol";
import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {IRandomiser} from "../interfaces/IRandomiser.sol";
import {IRandomiserCallback} from "../interfaces/IRandomiserCallback.sol";
import {IDistributooor} from "../interfaces/IDistributooor.sol";
import {IDistributooorFactory} from "../interfaces/IDistributooorFactory.sol";

// solhint-disable not-rely-on-time
// solhint-disable no-inline-assembly

/// @title Distributooor
/// @notice Base contract that implements helpers to consume a raffle from a
///     {RaffleChef}. Keeps track of participants that have claimed a winning
///     (and prevents them from claiming twice).
contract Distributooor is
    IDistributooor,
    IERC721Receiver,
    IERC1155Receiver,
    IRandomiserCallback,
    TypeAndVersion,
    Initializable,
    OwnableUpgradeable
{
    using Strings for uint256;
    using Strings for address;

    /// @notice Type of prize
    enum PrizeType {
        ERC721,
        ERC1155
    }

    address public distributooorFactory;
    /// @notice {RaffleChef} instance to consume
    address public raffleChef;
    /// @notice Raffle ID corresponding to a raffle in {RaffleChef}
    uint256 public raffleId;
    /// @notice Randomiser
    address public randomiser;
    /// @notice Track whether a given leaf (representing a participant) has
    /// claimed or not
    mapping(bytes32 => bool) public hasClaimed;

    /// @notice Array of bytes representing prize data
    bytes[] private prizes;

    /// @notice Due date (block timestamp) after which the raffle is allowed
    ///     to be performed. CANNOT be changed after initialisation.
    uint256 public raffleActivationTimestamp;
    /// @notice The block timestamp after which the owner may reclaim the
    ///     prizes from this contract. CANNOT be changed after initialisation.
    uint256 public prizeExpiryTimestamp;

    /// @notice Committed merkle root from collector
    bytes32 public merkleRoot;
    /// @notice Commited number of entries from collector
    uint256 public nParticipants;
    /// @notice Committed provenance
    string public provenance;

    /// @notice VRF request ID
    uint256 public randRequestId;
    /// @notice Timestamp of last VRF requesst
    uint256 public lastRandRequest;

    uint256[37] private __Distributooor_gap;

    event Claimed(
        address claimooor,
        uint256 originalIndex,
        uint256 permutedIndex
    );

    error ERC721NotReceived(address nftContract, uint256 tokenId);
    error ERC1155NotReceived(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    );
    error InvalidPrizeType(uint8 prizeType);
    error InvalidTimestamp(uint256 timestamp);
    error RaffleActivationPending(uint256 secondsLeft);
    error PrizeExpiryTimestampPending(uint256 secondsLeft);
    error IncorrectSignatureLength(uint256 sigLength);
    error InvalidRandomWords(uint256[] randomWords);
    error RandomnessAlreadySet(
        uint256 existingRandomness,
        uint256 newRandomness
    );
    error UnknownRandomiser(address randomiser);
    error RandomRequestInFlight(uint256 requestId);

    constructor() {
        _disableInitializers();
    }

    function init(
        address raffleOwner,
        address raffleChef_,
        address randomiser_,
        uint256 raffleActivationTimestamp_,
        uint256 prizeExpiryTimestamp_
    ) public initializer {
        bool isActivationInThePast = raffleActivationTimestamp_ <=
            block.timestamp;
        bool isActivationOnOrAfterExpiry = raffleActivationTimestamp_ >=
            prizeExpiryTimestamp_;
        bool isClaimDurationTooShort = prizeExpiryTimestamp_ -
            raffleActivationTimestamp_ <
            1 hours;
        if (
            raffleActivationTimestamp_ == 0 ||
            isActivationInThePast ||
            isActivationOnOrAfterExpiry ||
            isClaimDurationTooShort
        ) {
            revert InvalidTimestamp(raffleActivationTimestamp_);
        }
        if (prizeExpiryTimestamp_ == 0) {
            revert InvalidTimestamp(prizeExpiryTimestamp_);
        }

        __Ownable_init();
        _transferOwnership(raffleOwner);

        // Assumes that the DistributooorFactory is the deployer
        distributooorFactory = _msgSender();
        raffleChef = raffleChef_;
        randomiser = randomiser_;
        raffleActivationTimestamp = raffleActivationTimestamp_;
        prizeExpiryTimestamp = prizeExpiryTimestamp_;
    }

    /// @notice See {TypeAndVersion-typeAndVersion}
    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "Distributooor 1.1.0";
    }

    /// @notice {IERC165-supportsInterface}
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(TypeAndVersion).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /// @notice Revert if raffle has not yet been finalised
    modifier onlyCommittedRaffle() {
        uint256 raffleId_ = raffleId;
        require(
            raffleId_ != 0 &&
                IRaffleChef(raffleChef).getRaffleState(raffleId_) ==
                IRaffleChef.RaffleState.Committed,
            "Raffle is not yet finalised"
        );
        _;
    }

    /// @notice Revert if raffle has not yet reached activation
    modifier onlyAfterActivation() {
        if (!isReadyForActivation()) {
            revert RaffleActivationPending(
                raffleActivationTimestamp - block.timestamp
            );
        }
        _;
    }

    /// @notice Revert if raffle has not passed its deadline
    modifier onlyAfterExpiry() {
        if (!isPrizeExpired()) {
            revert PrizeExpiryTimestampPending(
                prizeExpiryTimestamp - block.timestamp
            );
        }
        _;
    }

    modifier onlyFactory() {
        if (_msgSender() != distributooorFactory) {
            revert Unauthorised(_msgSender());
        }
        _;
    }

    function isReadyForActivation() public view returns (bool) {
        return block.timestamp >= raffleActivationTimestamp;
    }

    function isPrizeExpired() public view returns (bool) {
        return block.timestamp >= prizeExpiryTimestamp;
    }

    /// @notice Verify that a proof is valid, and that it is part of the set of
    ///     winners. Revert otherwise. A winner is defined as an account that
    ///     has a shuffled index x' s.t. x' < nWinners
    /// @param leaf The leaf value representing the participant
    /// @param index Index of account in original participants list
    /// @param proof Merkle proof of inclusion of account in original
    ///     participants list
    /// @return permuted index
    function _verifyAndRecordClaim(
        bytes32 leaf,
        uint256 index,
        bytes32[] memory proof
    ) internal virtual onlyCommittedRaffle returns (uint256) {
        (bool isWinner, uint256 permutedIndex) = IRaffleChef(raffleChef)
            .verifyRaffleWinner(raffleId, leaf, proof, index);
        // Nullifier identifies a unique entry in the merkle tree
        bytes32 nullifier = keccak256(abi.encode(leaf, index));
        require(isWinner, "Not a raffle winner");
        require(!hasClaimed[nullifier], "Already claimed");
        hasClaimed[nullifier] = true;
        return permutedIndex;
    }

    /// @notice Check if preimage of `leaf` is a winner
    /// @param leaf Hash of entry
    /// @param index Index of account in original participants list
    /// @param proof Merkle proof of inclusion of account in original
    ///     participants list
    function check(
        bytes32 leaf,
        uint256 index,
        bytes32[] calldata proof
    )
        external
        view
        onlyCommittedRaffle
        returns (bool isWinner, uint256 permutedIndex)
    {
        (isWinner, permutedIndex) = IRaffleChef(raffleChef).verifyRaffleWinner(
            raffleId,
            leaf,
            proof,
            index
        );
    }

    function checkSig(
        address expectedSigner,
        bytes32 messageHash,
        bytes calldata signature
    ) public pure returns (bool, address) {
        // signature should be in the format (r,s,v)
        address recoveredSigner = ECDSA.recover(messageHash, signature);
        bool isValid = expectedSigner == recoveredSigner;
        return (isValid, recoveredSigner);
    }

    /// @notice Claim a prize from the contract. The caller must be included in
    ///     the Merkle tree of participants.
    /// @param index IndpermutedIndexccount in original participants list
    /// @param proof Merkle proof of inclusion of account in original
    ///     participants list
    function claim(
        uint256 index,
        bytes32[] calldata proof
    ) external onlyCommittedRaffle {
        address claimooor = _msgSender();
        bytes32 hashedLeaf = keccak256(abi.encodePacked(claimooor));

        uint256 permutedIndex = _verifyAndRecordClaim(hashedLeaf, index, proof);

        // Decode the prize & transfer it to claimooor
        bytes memory rawPrize = prizes[permutedIndex];
        PrizeType prizeType = _getPrizeType(rawPrize);
        if (prizeType == PrizeType.ERC721) {
            (address nftContract, uint256 tokenId) = _getERC721Prize(rawPrize);
            IERC721(nftContract).safeTransferFrom(
                address(this),
                claimooor,
                tokenId
            );
        } else if (prizeType == PrizeType.ERC1155) {
            (
                address nftContract,
                uint256 tokenId,
                uint256 amount
            ) = _getERC1155Prize(rawPrize);
            IERC1155(nftContract).safeTransferFrom(
                address(this),
                claimooor,
                tokenId,
                amount,
                bytes("")
            );
        }

        emit Claimed(claimooor, index, permutedIndex);
    }

    function requestMerkleRoot(
        uint256 chainId,
        address collectooorFactory,
        address collectooor
    ) external onlyAfterActivation onlyOwner {
        IDistributooorFactory(distributooorFactory).requestMerkleRoot(
            chainId,
            collectooorFactory,
            collectooor
        );
    }

    /// @notice See {IDistributooor-receiveParticipantsMerkleRoot}
    function receiveParticipantsMerkleRoot(
        uint256 srcChainId,
        address srcCollector,
        uint256 blockNumber,
        bytes32 merkleRoot_,
        uint256 nParticipants_
    ) external onlyAfterActivation onlyFactory {
        if (raffleId != 0 || merkleRoot != 0 || nParticipants != 0) {
            // Only allow merkle root to be received once;
            // otherwise it's already finalised
            revert MerkleRootRejected(merkleRoot_, nParticipants_, blockNumber);
        }
        if (randRequestId != 0 && block.timestamp - lastRandRequest < 1 hours) {
            // Allow retrying a VRF call if 1 hour has passed
            revert RandomRequestInFlight(randRequestId);
        }
        lastRandRequest = block.timestamp;

        merkleRoot = merkleRoot_;
        nParticipants = nParticipants_;
        emit MerkleRootReceived(merkleRoot_, nParticipants_, blockNumber);

        provenance = string(
            abi.encodePacked(
                srcChainId.toString(),
                ":",
                srcCollector.toHexString()
            )
        );

        // Next step: call VRF
        randRequestId = IRandomiser(randomiser).getRandomNumber(address(this));
    }

    /// @notice See {IRandomiserCallback}
    function receiveRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external {
        if (_msgSender() != randomiser) {
            revert UnknownRandomiser(_msgSender());
        }
        if (randRequestId != requestId) {
            revert InvalidRequestId(requestId);
        }
        if (merkleRoot == 0 || nParticipants == 0) {
            revert MerkleRootNotReady(requestId);
        }
        if (raffleId != 0) {
            revert AlreadyFinalised(raffleId);
        }
        if (randomWords.length == 0) {
            revert InvalidRandomWords(randomWords);
        }

        // Finalise raffle
        bytes32 merkleRoot_ = merkleRoot;
        uint256 nParticipants_ = nParticipants;
        uint256 randomness = randomWords[0];
        string memory provenance_ = provenance;
        uint256 raffleId_ = IRaffleChef(raffleChef).commit(
            merkleRoot_,
            nParticipants_,
            prizes.length,
            provenance_,
            randomness
        );
        raffleId = raffleId_;

        emit Finalised(
            raffleId_,
            merkleRoot_,
            nParticipants_,
            randomness,
            provenance_
        );
    }

    /// @notice Load a prize into this contract as the nth prize where
    ///     n == |prizes|
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        _addERC721Prize(_msgSender(), tokenId);
        return this.onERC721Received.selector;
    }

    /// @notice Add prize as nth prize if ERC721 token is already loaded into
    ///     this contract.
    /// @param nftContract NFT contract address
    /// @param tokenId Token ID of the NFT to accept
    function _addERC721Prize(address nftContract, uint256 tokenId) internal {
        // Ensure that this contract actually has custody of the ERC721
        if (IERC721(nftContract).ownerOf(tokenId) != address(this)) {
            revert ERC721NotReceived(nftContract, tokenId);
        }

        // Record prize
        bytes memory prize = abi.encode(
            uint8(PrizeType.ERC721),
            nftContract,
            tokenId
        );
        prizes.push(prize);
        emit ERC721Received(nftContract, tokenId);
    }

    /// @notice Load prize(s) into this contract. If amount > 1, then
    ///     prizes are inserted sequentially as individual prizes.
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 amount,
        bytes calldata options
    ) external returns (bytes4) {
        bool isSinglePrize;
        if (options.length > 0) {
            isSinglePrize = abi.decode(options, (bool));
        }

        if (isSinglePrize) {
            _addERC1155Prize(_msgSender(), id, amount);
        } else {
            for (uint256 i; i < amount; ++i) {
                _addERC1155Prize(_msgSender(), id, 1);
            }
        }
        return this.onERC1155Received.selector;
    }

    /// @notice Load prize(s) into this contract. If amount > 1, then
    ///     prizes are inserted sequentially as individual prizes.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata options
    ) external returns (bytes4) {
        require(ids.length == amounts.length);

        bool isSinglePrize;
        if (options.length > 0) {
            isSinglePrize = abi.decode(options, (bool));
        }

        for (uint256 i; i < ids.length; ++i) {
            if (isSinglePrize) {
                _addERC1155Prize(_msgSender(), ids[i], amounts[i]);
            } else {
                for (uint256 j; j < amounts[i]; ++j) {
                    _addERC1155Prize(_msgSender(), ids[i], 1);
                }
            }
        }
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Add prize as nth prize if ERC1155 token is already loaded into
    ///     this contract.
    /// @notice NB: The contract does not check that there is enough ERC1155
    ///     tokens to distribute as prizes.
    /// @param nftContract NFT contract address
    /// @param tokenId Token ID of the NFT to accept
    /// @param amount Amount of ERC1155 tokens
    function _addERC1155Prize(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Ensure that this contract actually has custody of the ERC721
        if (IERC1155(nftContract).balanceOf(nftContract, tokenId) >= amount) {
            revert ERC1155NotReceived(nftContract, tokenId, amount);
        }

        // Record prize
        bytes memory prize = abi.encode(
            uint8(PrizeType.ERC1155),
            nftContract,
            tokenId,
            amount
        );
        prizes.push(prize);
        emit ERC1155Received(nftContract, tokenId, amount);
    }

    /// @notice Add k ERC1155 tokens as the [n+0..n+k)th prizes
    /// @notice NB: The contract does not check that there is enough ERC1155
    ///     tokens to distribute as prizes.
    /// @param nftContract NFT contract address
    /// @param tokenId Token ID of the NFT to accept
    /// @param amount Amount of ERC1155 tokens
    function _addERC1155SequentialPrizes(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Ensure that this contract actually has custody of the ERC721
        if (IERC1155(nftContract).balanceOf(nftContract, tokenId) >= amount) {
            revert ERC1155NotReceived(nftContract, tokenId, amount);
        }

        // Record prizes
        for (uint256 i; i < amount; ++i) {
            bytes memory prize = abi.encode(
                uint8(PrizeType.ERC1155),
                nftContract,
                tokenId,
                1
            );
            prizes.push(prize);
        }
    }

    function _getPrizeType(
        bytes memory prize
    ) internal pure returns (PrizeType) {
        uint8 rawType;
        assembly {
            rawType := and(mload(add(prize, 0x20)), 0xff)
        }
        if (rawType > 1) {
            revert InvalidPrizeType(rawType);
        }
        return PrizeType(rawType);
    }

    function _getERC721Prize(
        bytes memory prize
    ) internal pure returns (address nftContract, uint256 tokenId) {
        (, nftContract, tokenId) = abi.decode(prize, (uint8, address, uint256));
    }

    function _getERC1155Prize(
        bytes memory prize
    )
        internal
        pure
        returns (address nftContract, uint256 tokenId, uint256 amount)
    {
        (, nftContract, tokenId, amount) = abi.decode(
            prize,
            (uint8, address, uint256, uint256)
        );
    }

    /// @notice Self-explanatory
    function getPrizeCount() public view returns (uint256) {
        return prizes.length;
    }

    /// @notice Get a slice of the prize list at the desired offset. The prize
    ///     list is represented in raw bytes, with the 0th byte signifying
    ///     whether it's an ERC-721 or ERC-1155 prize. See {_getPrizeType},
    ///     {_getERC721Prize}, and {_getERC1155Prize} functions for how to
    ///     decode each prize.
    /// @param offset Prize index to start slice at (0-based)
    /// @param limit How many prizes to fetch at maximum (may return fewer)
    function getPrizes(
        uint256 offset,
        uint256 limit
    ) public view returns (bytes[] memory prizes_) {
        uint256 len = prizes.length;
        if (len == 0 || offset >= prizes.length) {
            return new bytes[](0);
        }
        limit = offset + limit >= prizes.length
            ? prizes.length - offset
            : limit;
        prizes_ = new bytes[](limit);
        for (uint256 i; i < limit; ++i) {
            prizes_[i] = prizes[offset + i];
        }
    }

    /// @notice Withdraw ERC721 after deadline has passed
    function withdrawERC721(
        address nftContract,
        uint256 tokenId
    ) external onlyOwner onlyAfterExpiry {
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );
        emit ERC721Reclaimed(nftContract, tokenId);
    }

    /// @notice Withdraw ERC1155 after deadline has passed
    function withdrawERC1155(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner onlyAfterExpiry {
        IERC1155(nftContract).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId,
            amount,
            bytes("")
        );
        emit ERC1155Reclaimed(nftContract, tokenId, amount);
    }
}