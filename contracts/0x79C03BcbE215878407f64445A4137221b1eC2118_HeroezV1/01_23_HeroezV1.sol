// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Heroez - Heroez is the first professional esport team 100% governed by its own community
 * @notice This contract will be ultimately governed by the Heroez DAO who will have all the rights to make the contract evolve
 * @author Nicolas SENECAL - @senecolas
 * @custom:project-website  https://heroez.gg
 * @custom:security-contact [email protected]
 */
contract HeroezV1 is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using Strings for uint256;
    using ECDSA for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * ========================
     *          Events
     * ========================
     */

    /**
     * @notice Event emitted when the tokens are revealed
     */
    event Revealed();

    /**
     * @notice Event emitted when the actual wave is set or edited
     */
    event WaveSetup(uint256 indexed waveId, uint256 supply);

    /**
     * @notice Event emitted when a round is created or edited
     */
    event RoundSetup(
        uint256 indexed waveId,
        uint256 indexed roundId,
        uint32 supply,
        uint64 startTime,
        uint64 duration,
        uint256 price,
        address validator
    );

    /**
     * @notice Event emitted when `maxMintsPerWallet` has been modified
     */
    event MaxMintsPerWalletChanged(uint256 newMaxMintsPerWallet);

    /**
     * @notice Event emitted when `baseURI` has been modified
     */
    event BaseURIChanged(string newBaseURI);

    /**
     * @notice Event emitted when URI can definitely not be modified
     */
    event BaseURILocked();

    /**
     * @notice Event emitted when `baseExtension` has been modified
     */
    event BaseExtensionChanged(string newBaseExtension);

    /**
     * @notice Event emitted when `unrevealedURI` has been modified
     */
    event UnrevealedURIChanged(string newUnrevealedURI);

    /**
     * @notice Event emitted when native coin were removed from the contract
     */
    event Withdrawn(address indexed to, uint256 amount);

    /**
     * @notice Event emitted when some ERC20 were removed from the contract
     */
    event TokenWithdrawn(
        address indexed to,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Event emitted when `burnable` option has been modified
     */
    event BurnableChanged(bool newBurnable);

    /**
     * ========================
     *          Struct
     * ========================
     */

    /**
     * @notice Structure for packing the information of a mint round
     * @member supply Number of tokens that can be minted in this round. Can be 0 for use the wave supply
     * @member totalMinted Number of token minted in this round
     * @member startTime The start date of the round in seconds
     * @member duration The duration of the round in seconds. Can be 0 for no time limitation
     * @member price The price of the round in ETH (can be 0)
     * @member validator The address of the whitelist validator. Can be 'address(0)' for no whitelist
     */
    struct Round {
        uint32 supply;
        uint64 startTime;
        uint64 duration;
        uint256 price;
        uint256 totalMinted;
        address validator;
    }

    /**
     * ========================
     *         Storage
     * ========================
     */

    /// Maximum supply of all contract
    uint256 public constant MAX_SUPPLY = 11_111;

    /// If tokens are revealed
    bool public revealed;

    /// If tokens are burnable
    bool public burnable;

    /// If the URI can definitely not be modified anymore
    bool public baseURILocked;

    /// Id of the actual wave, or 0 if none
    uint256 public waveId;

    /// The supply of the actual wave, or 0 if we use the total supply
    uint256 public waveSupply;

    /// Number of token minted in the actual wave
    uint256 public waveTotalMinted;

    /// Number of tokens that a wallet can mint in a public round
    uint256 public maxMintsPerWallet;

    /// Burned token counter
    uint256 public totalBurned;

    /// Total of minted token
    uint256 internal _totalMinted;

    /// Total of tokens reserved and distributed to founders at initialization
    uint256 internal _totalReservedTokens;

    /// Base extension for the end of token id in `tokenURI`
    string public baseExtension;

    /// The not reveal token URI
    string public unrevealedURI;

    /// The base token URI to add before the token id
    string public baseURI;

    /// The current contract version
    string public version;

    /// Number of existing rounds by wave
    mapping(uint256 => uint256) public waveToRoundsLength;

    /// Identifier that can still be minted
    mapping(uint256 => uint256) internal _availableIds;

    /// All rounds by wave (starts at index 1)
    mapping(uint256 => mapping(uint256 => Round)) internal _waveToRounds;

    /// Total of minted token by address for a roundId in a waveId
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        internal _waveToRoundsToOwnerTotalMinted;

    /**
     * ========================
     *          Public
     * ========================
     */

    /**
     * CONSTRUCTOR
     *
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Tnitialize the contract version
     *
     * @param founders Array of founders for airdrops the first tokens
     */
    function initialize(address[] calldata founders) public initializer {
        __ERC721_init("Heroez", "HRZ");
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // Storage initialisation
        version = "1.1.0";
        baseExtension = ".json";
        maxMintsPerWallet = 3;

        // Airdrops the first tokens for founders
        for (uint256 i; i < founders.length; i++) {
            _mint(founders[i], i + 1);
        }
        _totalMinted += founders.length;
        _totalReservedTokens = founders.length;
    }

    /**
     * @notice Mint the `amount` of tokens in a round in the current wave without validator
     *
     * @dev Call {Heroez-_roundMint}.
     * @dev Requirements:
     * - Current wave must exist
     * - Round must not have a validator
     * - Total minted for the user during this round must be less than `maxMintsPerWallet`.

     * - View {Heroez-_roundMint} requirements
     *
     * @param roundId The mint round index in the current wave
     * @param amount The number of tokens to mint
     */
    function mint(uint256 roundId, uint256 amount) external payable virtual {
        require(waveId > 0, "No wave");
        require(
            _waveToRounds[waveId][roundId].validator == address(0),
            "Need a sig"
        );
        require(
            _waveToRoundsToOwnerTotalMinted[waveId][roundId][msg.sender] +
                amount <=
                maxMintsPerWallet,
            "Max allowed"
        );
        _roundMint(roundId, amount);
    }

    /**
     * @notice Mint the `amount` of tokens with the signature of the round validator in the current wave .
     *
     * @dev Requirements:
     * - Current wave must exist
     * - Round must have a validator
     * - Total minted for the user during this round must be less than `maxMint`.
     * - `sig` must be signed by the validator of the wave and contains all information to check.
     * - `payloadExpiration` must be less than the block timestamp.
     * - View {Heroez-_roundMint} requirements.
     *
     * @param roundId The mint round index in the current wave
     * @param amount The number of tokens to mint
     * @param maxMint The maximum token that the user is allowed to mint in the wave (verified in `sig`)
     * @param payloadExpiration The maximum timestamp before the signature is considered invalid (verified in `sig`)
     * @param sig The EC signature generated by the wave validator
     */
    function mintWithValidation(
        uint256 roundId,
        uint256 amount,
        uint256 maxMint,
        uint256 payloadExpiration,
        bytes memory sig
    ) external payable virtual {
        require(waveId > 0, "No wave");
        address validator = _waveToRounds[waveId][roundId].validator;
        require(validator != address(0), "No wave validator");
        require(
            _waveToRoundsToOwnerTotalMinted[waveId][roundId][msg.sender] +
                amount <=
                maxMint,
            "Max allowed"
        );

        _checkSignature(
            payloadExpiration,
            abi.encodePacked(
                msg.sender,
                payloadExpiration,
                waveId,
                roundId,
                maxMint,
                address(this),
                block.chainid
            ),
            sig,
            validator
        );

        _roundMint(roundId, amount);
    }

    /**
     * @notice Mint `amount` of tokens and transfers it to `wallet`
     *
     * @dev Requirements:
     * - View {Heroez-_safeMint} Requirements
     *
     * @param wallet The address to send new tokens
     * @param amount The amount of tokens to send
     * @param useCurrentWave If we have to count these aidrops like a mint in the current wave (increase the current totalMinted)
     */
    function airdrop(
        address wallet,
        uint256 amount,
        bool useCurrentWave
    ) external virtual onlyOwner {
        _safeMint(wallet, amount);
        if (useCurrentWave) {
            waveTotalMinted += amount;
        }
    }

    /**
     * @notice Process multiple airdrop by matching the input arrays one-on-one

     * @dev Requirements:
     * - View {Heroez-_safeMint} Requirements
     *
     * @param wallets Array of address to send new tokens
     * @param amounts Array of amount of tokens to send to the corresponding wallet
     * @param useCurrentWave If we have to count these aidrops like a mint in the current wave (increase the current totalMinted)
     */
    function airdrops(
        address[] calldata wallets,
        uint256[] calldata amounts,
        bool useCurrentWave
    ) external onlyOwner {
        require(wallets.length == amounts.length, "arrays length mismatch");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            _safeMint(wallets[i], amounts[i]);
            totalAmount += amounts[i];
        }
        if (useCurrentWave) {
            waveTotalMinted += totalAmount;
        }
    }

    /**
     * @notice Create or edit the actual wave. Reset `waveTotalMinted` if the wave is different than the current one.
     *
     * @dev The choice of the waveId is free. If it existed in the past, we keep the same data (rounds and totalMinted).
     *
     * @param newWaveId The new actual wave number. Can be set to 0 to disable actual wave.
     * @param supply Number of tokens that can be minted in this wave. Can be 0 for use the total supply
     */
    function setupWave(uint256 newWaveId, uint256 supply)
        external
        virtual
        onlyOwner
    {
        if (waveTotalMinted != 0 && waveId != newWaveId) {
            waveTotalMinted = 0;
        }
        waveId = newWaveId;
        waveSupply = supply;

        emit WaveSetup(newWaveId, supply);
    }

    /**
     * @notice Create or edit a wave's round
     *
     * @dev Requirements:
     * - `roundId` must exist or increment `waveToRoundsLength` for create one.
     * - `roundId` can't be 0.
     *
     * @param roundWaveId The wave identifier of the round
     * @param roundId The round identifier in relation to `roundWaveId`
     * @param supply Number of tokens that can be minted in this wave. Can be 0 for use the total supply
     * @param startTime The start date of the wave in seconds
     * @param duration The duration of the wave in seconds. Can be 0 for no time limitation
     * @param validator The address of the whitelist validator. Can be 'address(0)' for no whitelist
     * @param price The price of the wave in ETH (can be 0)
     */
    function setupRound(
        uint256 roundWaveId,
        uint256 roundId,
        uint32 supply,
        uint64 startTime,
        uint64 duration,
        address validator,
        uint256 price
    ) external virtual onlyOwner {
        require(roundWaveId > 0 && roundId > 0, "Id can't be 0");
        require(
            roundId <= waveToRoundsLength[roundWaveId] + 1,
            "Invalid roundId"
        );

        // Create a new round
        if (roundId == waveToRoundsLength[roundWaveId] + 1) {
            waveToRoundsLength[roundWaveId] += 1;
        }

        Round storage round = _waveToRounds[roundWaveId][roundId];
        round.supply = supply;
        round.startTime = startTime;
        round.duration = duration;
        round.price = price;
        round.validator = validator;

        emit RoundSetup(
            roundWaveId,
            roundId,
            supply,
            startTime,
            duration,
            price,
            validator
        );
    }

    /**
     * @notice Change number of tokens that a wallet can mint in a public wave
     */
    function setMaxMintsPerWallet(uint256 newMaxMints)
        external
        virtual
        onlyOwner
    {
        maxMintsPerWallet = newMaxMints;
        emit MaxMintsPerWalletChanged(newMaxMints);
    }

    /**
     * @notice Change the baseURI
     */
    function setBaseURI(string memory newBaseURI) external virtual onlyOwner {
        require(
            !baseURILocked || bytes(baseURI).length == 0,
            "baseURI permanently locked"
        );
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    /**
     * @notice Change the URI base extension
     */
    function setBaseExtension(string memory newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = newBaseExtension;
        emit BaseExtensionChanged(newBaseExtension);
    }

    /**
     * @notice Change the UnrevealedURI
     */
    function setUnrevealedURI(string memory newUnrevealedURI)
        external
        onlyOwner
    {
        unrevealedURI = newUnrevealedURI;
        emit UnrevealedURIChanged(newUnrevealedURI);
    }

    /**
     * @notice Activate token revelation (irreversible)
     */
    function reveal() external virtual onlyOwner {
        revealed = true;
        emit Revealed();
    }

    /**
     * @notice Prevents tokens from changing their URI  (irreversible)
     */
    function lockBaseURI() external virtual onlyOwner {
        baseURILocked = true;
        emit BaseURILocked();
    }

    /**
     * @notice Activate burnable option
     * @param newBurnable If users are authorized to burn their tokens or not
     */
    function setBurnable(bool newBurnable) public virtual onlyOwner {
        burnable = newBurnable;
        emit BurnableChanged(newBurnable);
    }

    /**
     * @notice Withdraw network native coins
     *
     * @param to The address of the tokens/coins receiver.
     * @param amount Amount to claim.
     */
    function withdraw(address payable to, uint256 amount)
        public
        virtual
        onlyOwner
    {
        (bool succeed, ) = to.call{value: amount}("");
        require(succeed, "Failed to withdraw");
        emit Withdrawn(to, amount);
    }

    /**
     * @notice Withdraw ERC20 if stuck in the contract
     *
     * @param to The address of the tokens/coins receiver.
     * @param token The address of the token contract.
     * @param amount Amount to claim.
     */
    function withdrawTokens(
        address to,
        address token,
        uint256 amount
    ) public virtual onlyOwner {
        IERC20Upgradeable customToken = IERC20Upgradeable(token);
        customToken.safeTransfer(to, amount);
        emit TokenWithdrawn(to, token, amount);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     * - `burnable`has to be true.
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        require(burnable, "Not burnable");
        totalBurned++;
        super.burn(tokenId);
    }

    /*
     * ========================
     *          Views
     * ========================
     */

    /**
     * @notice Returns the number of tokens that can still be mined by the public
     */
    function getRemainingTokens() public view virtual returns (uint256) {
        return MAX_SUPPLY - _totalMinted;
    }

    /**
     * @notice Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalMinted - totalBurned;
    }

    /**
     * @notice Returns the total amount of tokens minted by `wallet` for `roundId` in `roundWaveId`.
     */
    function rounds(uint256 roundWaveId, uint256 roundId)
        public
        view
        returns (Round memory)
    {
        return _waveToRounds[roundWaveId][roundId];
    }

    /**
     * @notice Returns the total amount of tokens minted by `wallet` for `roundId` in `roundWaveId`.
     */
    function totalMintedBy(
        address wallet,
        uint256 roundWaveId,
        uint256 roundId
    ) public view returns (uint256) {
        return _waveToRoundsToOwnerTotalMinted[roundWaveId][roundId][wallet];
    }

    /**
     * @notice Returns the URI of `tokenId` or the `unrevealedURI` if the tokens have not been revealed yet
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        if (!revealed) {
            return unrevealedURI;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * ========================
     *          Internal
     * ========================
     */

    /**
     * @notice Safely mint the `amount` of tokens for `msg.sender` in accordance with wave and round configuration
     *
     * @dev Requirements:
     * - View {Heroez-_safeMint} Requirements
     * - `roundId` must exist in the current wave and be in progress
     * - The current wave must have enough supply
     * - The round must have enough supply
     * - msg.value must contain the price
     * - msg.sender must not be a smart contract
     *
     * @param roundId The round index in the current wave
     * @param amount The number of tokens to mint
     */
    function _roundMint(uint256 roundId, uint256 amount) internal virtual {
        Round storage round = _waveToRounds[waveId][roundId];

        // No smart contract
        require(
            msg.sender == tx.origin,
            "Minting from smart contracts is disallowed"
        );

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

        // Wave supply requirements
        require(
            (waveSupply == 0 || waveTotalMinted + amount <= waveSupply),
            "Wave supply exceeded"
        );

        // Safe mint
        _safeMint(msg.sender, amount);

        // Increase user total minted
        waveTotalMinted += amount;
        _waveToRoundsToOwnerTotalMinted[waveId][roundId][msg.sender] += amount;
        round.totalMinted += amount;
    }

    /**
     * @notice Safely mint the `amount` of tokens for `wallet`
     *
     * @dev Requirements:
     * - `amount` must be above 0
     * - The supply must not be exceeded with amount
     *
     * @dev Increase `_totalMinted`
     *
     * @param wallet The wallet to transfer new tokens
     * @param amount The number of tokens to mint
     */
    function _safeMint(address wallet, uint256 amount)
        internal
        virtual
        override
    {
        require(amount > 0, "Zero amount");
        require(_totalMinted + amount <= MAX_SUPPLY, "Supply exceeded");

        // Mint
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _getRandomToken(wallet, _totalMinted + i);
            _mint(wallet, tokenId);
        }
        _totalMinted += amount;
    }

    /**
     * @notice Gives a identifier from a pseudo random function (inspired by Cyberkongs VX)
     *
     * @dev Pass identifiers that are already airdrops for founders with  `_totalReservedTokens`
     *
     * @param wallet The wallet to complexify the random
     * @param totalMinted Updated total minted
     */
    function _getRandomToken(address wallet, uint256 totalMinted)
        internal
        returns (uint256)
    {
        uint256 remaining = MAX_SUPPLY - totalMinted;
        uint256 rand = (uint256(
            keccak256(
                abi.encodePacked(
                    wallet,
                    block.difficulty,
                    block.timestamp,
                    remaining
                )
            )
        ) % remaining);
        uint256 value = rand;

        if (_availableIds[rand] != 0) {
            value = _availableIds[rand];
        }

        if (_availableIds[remaining - 1] == 0) {
            _availableIds[rand] = remaining - 1;
        } else {
            _availableIds[rand] = _availableIds[remaining - 1];
            delete _availableIds[remaining - 1];
        }

        return value + _totalReservedTokens + 1;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    receive() external payable virtual {}
}