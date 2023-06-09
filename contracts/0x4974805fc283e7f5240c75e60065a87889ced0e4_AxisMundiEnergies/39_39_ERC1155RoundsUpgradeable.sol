// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev Contract allowing the management of mint rounds for {ERC1155Upgradeable}
 * @author Interplanetary Lab <[email protected]>
 */
contract ERC1155RoundsUpgradeable is ERC1155Upgradeable {
    using Strings for uint256;
    using ECDSA for bytes32;

    /**
     * ========================
     *          Struct
     * ========================
     */

    /**
     * @notice Structure for packing the information of a mint round
     * @member id The round id for reverse mapping
     * @member tokenId The token id minted in this round
     * @member supply Number of tokens that can be minted in this round. Can be 0 for no supply control.
     * @member totalMinted Number of token minted in this round
     * @member startTime The start date of the round in seconds
     * @member duration The duration of the round in seconds. Can be 0 for no time limitation
     * @member price The price of the round in ETH (can be 0)
     * @member validator The address of the whitelist validator. Can be 'address(0)' for no whitelist
     */
    struct Round {
        uint256 id;
        uint256 tokenId;
        uint32 supply;
        uint64 startTime;
        uint64 duration;
        uint256 price;
        uint256 totalMinted;
        address validator;
    }

    /**
     * ========================
     *          Events
     * ========================
     */

    /**
     * @notice Event emitted when a round is created or edited
     */
    event RoundSetup(
        uint256 indexed roundId,
        uint256 indexed tokenId,
        uint32 supply,
        uint64 startTime,
        uint64 duration,
        uint256 price,
        address validator
    );

    /**
     * ========================
     *         Storage
     * ========================
     */

    /// Total of minted token by tokenId
    mapping(uint256 => uint256) internal _totalMinted;

    /// Total of rounds setup
    uint256 public roundsLength;

    /// All rounds (starts at index 1)
    mapping(uint256 => Round) public rounds;

    /// Total of minted token by address and by tokenId for a roundId
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _roundsToOwnerTotalMinted;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155Rounds_init() internal onlyInitializing {
        __ERC1155Rounds_init_unchained();
    }

    function __ERC1155Rounds_init_unchained() internal onlyInitializing {}

    /*
     * ========================
     *          Views
     * ========================
     */

    /**
     * @notice Returns the total amount of tokens stored by the contract, by tokenId.
     * @param tokenId The token identifier
     */
    function totalSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _totalMinted[tokenId];
    }

    /**
     * @notice Returns the total amount of tokens minted by `wallet` for `roundId`.
     */
    function totalMintedBy(address wallet, uint256 roundId)
        public
        view
        returns (uint256)
    {
        return
            _roundsToOwnerTotalMinted[roundId][wallet][rounds[roundId].tokenId];
    }

    /**
     * @notice Returns the array of all rounds stored in the contract.
     *
     * @dev Starts with the index of roundId 1
     * @dev Function for web3 first, this one is not recommended for a call
     *      from another smart contract (can be expensive in gas).
     */
    function allRounds() public view returns (Round[] memory) {
        Round[] memory all = new Round[](roundsLength);
        for (uint256 id = 0; id < roundsLength; ++id) {
            all[id] = rounds[id + 1];
        }
        return all;
    }

    /**
     * ========================
     *        Functions
     * ========================
     */

    /**
     * @dev Mint the `amount` of tokens in a round without validator.
     * @dev Call {ERC721RoundsUpgradeable-_roundMint}.
     * @dev Requirements:
     * - Round must not have a validator
     * - View {ERC721RoundsUpgradeable-_roundMint} requirements
     *
     * @param to The address who want to mint
     * @param amount The number of tokens to mint
     */
    function _publicRoundMint(
        address to,
        uint256 roundId,
        uint256 amount
    ) internal virtual {
        require(rounds[roundId].validator == address(0), "Need a sig");
        _roundMint(to, roundId, amount);
    }

    /**
     * @dev Mint the `amount` of tokens with the signature of the round validator.
     *
     * @dev Requirements:
     * - Round must have a validator
     * - Total minted for the user during this round must be less than `maxMint`.
     * - `sig` must be signed by the validator of the wave and contains all information to check.
     * - `payloadExpiration` must be less than the block timestamp.
     * - View {ERC721RoundsUpgradeable-_roundMint} requirements.
     *
     * @param to The address who want to mint
     * @param roundId The mint round index
     * @param amount The number of tokens to mint
     * @param maxMint The maximum token that the user is allowed to mint in the round (verified in `sig`)
     * @param payloadExpiration The maximum timestamp before the signature is considered invalid (verified in `sig`)
     * @param sig The EC signature generated by the wave validator
     */
    function _privateRoundMint(
        address to,
        uint256 roundId,
        uint256 amount,
        uint256 maxMint,
        uint256 payloadExpiration,
        bytes memory sig
    ) internal virtual {
        uint256 tokenId = rounds[roundId].tokenId;
        address validator = rounds[roundId].validator;
        require(validator != address(0), "No round validator");
        require(
            _roundsToOwnerTotalMinted[roundId][to][tokenId] + amount <= maxMint,
            "Max allowed"
        );

        _checkSignature(
            payloadExpiration,
            abi.encodePacked(
                to,
                payloadExpiration,
                roundId,
                tokenId,
                maxMint,
                address(this),
                block.chainid
            ),
            sig,
            validator
        );

        _roundMint(to, roundId, amount);
    }

    /**
     * @dev Create or edit a round
     *
     * @dev Requirements:
     * - `roundId` must exist or increment `roundsLength` for create one.
     * - `roundId` can't be 0.
     *
     * @param roundId The round identifier
     * @param tokenId The token identifier
     * @param supply Number of tokens that can be minted in this round. Can be 0 for no supply control.
     * @param startTime The start date of the round in seconds
     * @param duration The duration of the round in seconds. Can be 0 for no time limitation
     * @param validator The address of the whitelist validator. Can be 'address(0)' for no whitelist
     * @param price The price of the round in ETH (can be 0)
     */
    function _setupRound(
        uint256 roundId,
        uint256 tokenId,
        uint32 supply,
        uint64 startTime,
        uint64 duration,
        address validator,
        uint256 price
    ) internal virtual {
        require(roundId > 0 && roundId <= roundsLength + 1, "Invalid roundId");
        require(tokenId >= 0, "Invalid tokenId");

        // Create a new round
        if (roundId == roundsLength + 1) {
            roundsLength += 1;
        }

        Round storage round = rounds[roundId];
        round.id = roundId;
        round.tokenId = tokenId;
        round.supply = supply;
        round.startTime = startTime;
        round.duration = duration;
        round.price = price;
        round.validator = validator;

        emit RoundSetup(
            roundId,
            tokenId,
            supply,
            startTime,
            duration,
            price,
            validator
        );
    }

    /**
     * @dev Safely mint the `amount` of tokens for `to` address in accordance with round configuration
     *
     * @dev Requirements:
     * - View {ERC721RoundsUpgradeable-_mintWithAmount} Requirements
     * - `roundId` must exist and be in progress
     * - The round must have enough supply
     * - msg.value must contain the price
     *
     * @param to The address who want to mint
     * @param roundId The round index in the current wave
     * @param amount The number of tokens to mint
     */
    function _roundMint(
        address to,
        uint256 roundId,
        uint256 amount
    ) internal virtual {
        Round storage round = rounds[roundId];

        // Round active
        require(
            block.timestamp >= round.startTime &&
                round.startTime > 0 &&
                (round.duration == 0 ||
                    block.timestamp < round.startTime + round.duration),
            "Round not in progress"
        );

        // Correct price
        require(round.price * amount <= msg.value, "Wrong price");

        // Round supply requirements
        require(
            (round.supply == 0 || round.totalMinted + amount <= round.supply),
            "Round supply exceeded"
        );

        uint256 tokenId = round.tokenId;

        // For custom conditions or process
        _beforeRoundMint(to, tokenId, amount);

        // Safe mint
        _mintWithAmount(to, tokenId, amount);

        // Increase user total minted
        round.totalMinted += amount;
        _roundsToOwnerTotalMinted[roundId][to][tokenId] += amount;

        // For custom process
        _afterRoundMint(to, tokenId, amount);
    }

    /**
     * @dev Mint the `amount` of tokens for `to`
     *
     * @dev Requirements:
     * - `amount` must be above 0
     * - The supply must not be exceeded with amount
     *
     * @dev Increase `_totalMinted`
     *
     * @param to The wallet to transfer new tokens
     * @param tokenId The token identifier
     * @param amount The number of tokens to mint
     */
    function _mintWithAmount(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "Zero amount");

        // For custom conditions or process
        _beforeMint(to, tokenId, amount);

        // Mint
        _mint(to, tokenId, amount, "");

        _totalMinted[tokenId] += amount;

        // For custom process
        _afterMint(to, tokenId, amount);
    }

    /**
     * @notice Reverts if the data does not correspond to the signature, to the correct signer or if it has expired
     *
     * @dev Requirements:
     * - `payloadExpiration` must be less than the block timestamp
     * - `sig` must be a hash of `data`
     * - `sig` must be signed by `signer`
     *
     * @param payloadExpiration The maximum timestamp before the signature is considered invalid
     * @param data All encoded pack data in order
     * @param sig The EC signature generated by the signatory
     * @param signer The address that is supposed to be the signatory
     */
    function _checkSignature(
        uint256 payloadExpiration,
        bytes memory data,
        bytes memory sig,
        address signer
    ) internal view {
        require(payloadExpiration >= block.timestamp, "Signature expired");
        require(
            keccak256(data).toEthSignedMessageHash().recover(sig) == signer,
            "Invalid signature"
        );
    }

    /**
     * @dev Hook that is called before any mint in a round
     *
     * Calling conditions:
     * - when the correct price was send.
     * - when round is in progress.
     * - when round supply not exceeded.
     *
     * @param to The wallet to transfer new tokens
     * @param roundId The mint round index
     * @param amount The number of tokens to mint
     */
    function _beforeRoundMint(
        address to,
        uint256 roundId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called before any mint
     *
     * Calling conditions:
     * - amount is not 0.
     *
     * @param to The wallet to transfer new tokens
     * @param tokenId The token identifier
     * @param amount The number of tokens to mint
     */
    function _beforeMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any mint in a round
     * @param to The wallet to transfer new tokens
     * @param tokenId The token identifier
     * @param amount The number of tokens to mint
     */
    function _afterRoundMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any mint
     * @param to The wallet to transfer new tokens
     * @param tokenId The token identifier
     * @param amount The number of tokens to mint
     */
    function _afterMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}