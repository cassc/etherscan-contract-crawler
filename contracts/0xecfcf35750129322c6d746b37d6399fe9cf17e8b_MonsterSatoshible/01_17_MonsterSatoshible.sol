// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 *      __  __                 _
 *     |  \/  | ___  _ __  ___| |_ ___ _ __
 *     | |\/| |/ _ \| '_ \/ __| __/ _ \ '__|
 *     | |  | | (_) | | | \__ \ ||  __/ |
 *     |_|__|_|\___/|_| |_|___/\__\___|_|_     _
 *     / ___|  __ _| |_ ___  ___| |__ (_) |__ | | ___  ___
 *     \___ \ / _` | __/ _ \/ __| '_ \| | '_ \| |/ _ \/ __|
 *      ___) | (_| | || (_) \__ \ | | | | |_) | |  __/\__ \
 *     |____/ \__,_|\__\___/|___/_| |_|_|_.__/|_|\___||___/
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ERC2981ContractWideRoyalties.sol";
import "./MerkleProof.sol";

/**
 * @notice Original Satoshibles contract interface
 */
interface ISatoshible {
    function ownerOf(
        uint256 _tokenId
    )
        external
        view
        returns (address owner);
}

/**
 * @title Monster Satoshibles
 * @notice NFT of monsters that can be burned and combined into prime monsters!
 * @author Aaron Hanson
 */
contract MonsterSatoshible is ERC721, ERC2981ContractWideRoyalties, Ownable {

    /// The max token supply
    uint256 public constant MAX_SUPPLY = 6666;

    /// The presale portion of the max supply
    uint256 public constant MAX_PRESALE_SUPPLY = 3333;

    /// Mysterious constants 💀
    uint256 constant DEATH = 0xDEAD;
    uint256 constant LIFE = 0x024350AC;
    uint256 constant ALPHA = LIFE % DEATH * 1000;
    uint256 constant OMEGA = LIFE % DEATH + ALPHA;

    /// Prime types
    uint256 constant FRANKENSTEIN = 0;
    uint256 constant WEREWOLF = 1;
    uint256 constant VAMPIRE = 2;
    uint256 constant ZOMBIE = 3;
    uint256 constant INVALID = 4;

    /// Number of prime parts
    uint256 constant NUM_PARTS = 4;

    /// Bitfield mask for prime part detection during prime minting
    uint256 constant HAS_ALL_PARTS = 2 ** NUM_PARTS - 1;

    /// Merkle root summarizing the presale whitelist
    bytes32 public constant WHITELIST_MERKLE_ROOT =
        0xdb6eea27a6a35a02d1928e9582f75c1e0a518ad5992b5cfee9cc0d86fb387b8d;

    /// Additional team wallets (can withdraw)
    address public constant TEAM_WALLET_A =
        0xF746362D8162Eeb3624c17654FFAa6EB8bD71820;
    address public constant TEAM_WALLET_B =
        0x16659F9D2ab9565B0c07199687DE3634c0965391;
    address public constant TEAM_WALLET_C =
        0x7a73f770873761054ab7757E909ae48f771379D4;
    address public constant TEAM_WALLET_D =
        0xB7c7e3809591F720f3a75Fb3efa05E76E6B7B92A;

    /// The maximum ERC-2981 royalties percentage
    uint256 public constant MAX_ROYALTIES_PCT = 600;

    /// Original Satoshibles contract instance
    ISatoshible public immutable SATOSHIBLE_CONTRACT;

    /// The max presale token ID
    uint256 public immutable MAX_PRESALE_TOKEN_ID;

    /// The current token supply
    uint256 public totalSupply;

    /// The current state of the sale
    bool public saleIsActive;

    /// Indicates if the public sale was opened manually
    bool public publicSaleOpenedEarly;

    /// The default and discount token prices in wei
    uint256 public tokenPrice    = 99900000000000000; // 0.0999 ether
    uint256 public discountPrice = 66600000000000000; // 0.0666 ether

    /// Tracks number of presale mints already used per address
    mapping(address => uint256) public whitelistMintsUsed;

    /// The current state of the laboratory
    bool public laboratoryHasElectricity;

    /// Merkle root summarizing all monster IDs and their prime parts
    bytes32 public primePartsMerkleRoot;

    /// The provenance URI
    string public provenanceURI = "Not Yet Set";

    /// When true, the provenanceURI can no longer be changed
    bool public provenanceUriLocked;

    /// The base URI
    string public baseURI = "https://api.satoshibles.com/monsters/token/";

    /// When true, the baseURI can no longer be changed
    bool public baseUriLocked;

    /// Use Counters for token IDs
    using Counters for Counters.Counter;

    /// Monster token ID counter
    Counters.Counter monsterIds;

    /// Prime token ID counter for each prime type
    mapping(uint256 => Counters.Counter) primeIds;

    /// Prime ID offsets for each prime type
    mapping(uint256 => uint256) primeIdOffset;

    /// Bitfields that track original Satoshibles already used for discounts
    mapping(uint256 => uint256) satDiscountBitfields;

    /// Bitfields that track original Satoshibles already used in lab
    mapping(uint256 => uint256) satLabBitfields;

    /**
     * @notice Emitted when the saleIsActive flag changes
     * @param isActive Indicates whether or not the sale is now active
     */
    event SaleStateChanged(
        bool indexed isActive
    );

    /**
     * @notice Emitted when the public sale is opened early
     */
    event PublicSaleOpenedEarly();

    /**
     * @notice Emitted when the laboratoryHasElectricity flag changes
     * @param hasElectricity Indicates whether or not the laboratory is open
     */
    event LaboratoryStateChanged(
        bool indexed hasElectricity
    );

    /**
     * @notice Emitted when a prime is created in the lab
     * @param creator The account that created the prime
     * @param primeId The ID of the prime created
     * @param satId The Satoshible used as the 'key' to the lab
     * @param monsterIdsBurned The IDs of the monsters burned
     */
    event PrimeCreated(
        address indexed creator,
        uint256 indexed primeId,
        uint256 indexed satId,
        uint256[4] monsterIdsBurned
    );

    /**
     * @notice Requires the specified Satoshible to be owned by msg.sender
     * @param _satId Original Satoshible token ID
     */
    modifier onlySatHolder(
        uint256 _satId
    ) {
        require(
            SATOSHIBLE_CONTRACT.ownerOf(_satId) == _msgSender(),
            "Sat not owned"
        );
        _;
    }

    /**
     * @notice Requires msg.sender to be the owner or a team wallet
     */
    modifier onlyTeam() {
        require(
            _msgSender() == TEAM_WALLET_A
                || _msgSender() == TEAM_WALLET_B
                || _msgSender() == TEAM_WALLET_C
                || _msgSender() == TEAM_WALLET_D
                || _msgSender() == owner(),
            "Not owner or team address"
        );
        _;
    }

    /**
     * @notice Boom... Let's go!
     * @param _initialBatchCount Number of tokens to mint to msg.sender
     * @param _immutableSatoshible Original Satoshible contract address
     * @param _royaltiesPercentage Initial royalties percentage for ERC-2981
     */
    constructor(
        uint256 _initialBatchCount,
        address _immutableSatoshible,
        uint256 _royaltiesPercentage
    )
        ERC721("Monster Satoshibles", "MSBLS")
    {
        SATOSHIBLE_CONTRACT = ISatoshible(
            _immutableSatoshible
        );

        require(
            _royaltiesPercentage <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _msgSender(),
            _royaltiesPercentage
        );

        _initializePrimeIdOffsets();
        _initializeSatDiscountAvailability();
        _initializeSatLabAvailability();
        _mintTokens(_initialBatchCount);

        require(
            belowMaximum(_initialBatchCount, MAX_PRESALE_SUPPLY,
                MAX_SUPPLY
            ) == true,
            "Would exceed max supply"
        );

        unchecked {
            MAX_PRESALE_TOKEN_ID = _initialBatchCount + MAX_PRESALE_SUPPLY;
        }
    }

    /**
     * @notice Mints monster tokens during presale, optionally with discounts
     * @param _numberOfTokens Number of tokens to mint
     * @param _satsForDiscount Array of Satoshible IDs for discounted mints
     * @param _whitelistedTokens Account's total number of whitelisted tokens
     * @param _proof Merkle proof to be verified
     */
    function mintTokensPresale(
        uint256 _numberOfTokens,
        uint256[] calldata _satsForDiscount,
        uint256 _whitelistedTokens,
        bytes32[] calldata _proof
    )
        external
        payable
    {
        require(
            publicSaleOpenedEarly == false,
            "Presale has ended"
        );

        require(
            belowMaximum(monsterIds.current(), _numberOfTokens,
                MAX_PRESALE_TOKEN_ID
            ) == true,
            "Would exceed presale size"
        );

        require(
            belowMaximum(whitelistMintsUsed[_msgSender()], _numberOfTokens,
                _whitelistedTokens
            ) == true,
            "Would exceed whitelisted count"
        );

        require(
            verifyWhitelisted(_msgSender(), _whitelistedTokens,
                _proof
            ) == true,
            "Invalid whitelist proof"
        );

        whitelistMintsUsed[_msgSender()] += _numberOfTokens;

        _doMintTokens(
            _numberOfTokens,
            _satsForDiscount
        );
    }

    /**
     * @notice Mints monsters during public sale, optionally with discounts
     * @param _numberOfTokens Number of monster tokens to mint
     * @param _satsForDiscount Array of Satoshible IDs for discounted mints
     */
    function mintTokensPublicSale(
        uint256 _numberOfTokens,
        uint256[] calldata _satsForDiscount
    )
        external
        payable
    {
        require(
            publicSaleOpened() == true,
            "Public sale has not started"
        );

        require(
            belowMaximum(monsterIds.current(), _numberOfTokens,
                MAX_SUPPLY
            ) == true,
            "Not enough tokens left"
        );

        _doMintTokens(
            _numberOfTokens,
            _satsForDiscount
        );
    }

    /**
     * @notice Mints a prime token by burning two or more monster tokens
     * @param _primeType Prime type to mint
     * @param _satId Original Satoshible token ID to use as 'key' to the lab
     * @param _monsterIds Array of monster token IDs to potentially be burned
     * @param _monsterPrimeParts Array of bitfields of monsters' prime parts
     * @param _proofs Array of merkle proofs to be verified
     */
    function mintPrimeToken(
        uint256 _primeType,
        uint256 _satId,
        uint256[] calldata _monsterIds,
        uint256[] calldata _monsterPrimeParts,
        bytes32[][] calldata _proofs
    )
        external
        onlySatHolder(_satId)
    {
        require(
            laboratoryHasElectricity == true,
            "Prime laboratory not yet open"
        );

        require(
            _primeType < INVALID,
            "Invalid prime type"
        );

        require(
            belowMaximum(
                primeIdOffset[_primeType],
                primeIds[_primeType].current() + 1,
                primeIdOffset[_primeType + 1]
            ) == true,
            "No more primes left of this type"
        );

        require(
            satIsAvailableForLab(_satId) == true,
            "Sat has already been used in lab"
        );

        // bitfield tracking aggregate parts across monsters
        // (head = 1, eyes = 2, mouth = 4, body = 8)
        uint256 combinedParts;

        uint256[4] memory burnedIds;

        unchecked {
            uint256 burnedIndex;
            for (uint256 i = 0; i < _monsterIds.length; i++) {
                require(
                    verifyMonsterPrimeParts(
                        _monsterIds[i],
                        _monsterPrimeParts[i],
                        _proofs[i]
                    ) == true,
                    "Invalid monster traits proof"
                );

                uint256 theseParts = _monsterPrimeParts[i]
                    >> (_primeType * NUM_PARTS) & HAS_ALL_PARTS;

                if (combinedParts | theseParts != combinedParts) {
                    _burn(
                        _monsterIds[i]
                    );
                    burnedIds[burnedIndex++] = _monsterIds[i];
                    combinedParts |= theseParts;
                    if (combinedParts == HAS_ALL_PARTS) {
                        break;
                    }
                }
            }
        }

        require(
            combinedParts == HAS_ALL_PARTS,
            "Not enough parts for this prime"
        );

        _retireSatFromLab(_satId);
        primeIds[_primeType].increment();

        unchecked {
            uint256 primeId = primeIdOffset[_primeType]
                + primeIds[_primeType].current();

            totalSupply++;

            _safeMint(
                _msgSender(),
                primeId
            );

            emit PrimeCreated(
                _msgSender(),
                primeId,
                _satId,
                burnedIds
            );
        }
    }

    /**
     * @notice Activates or deactivates the sale
     * @param _isActive Whether to activate or deactivate the sale
     */
    function activateSale(
        bool _isActive
    )
        external
        onlyOwner
    {
        saleIsActive = _isActive;

        emit SaleStateChanged(
            _isActive
        );
    }

    /**
     * @notice Starts the public sale before MAX_PRESALE_TOKEN_ID is minted
     */
    function openPublicSaleEarly()
        external
        onlyOwner
    {
        publicSaleOpenedEarly = true;

        emit PublicSaleOpenedEarly();
    }

    /**
     * @notice Modifies the prices in case of major ETH price changes
     * @param _tokenPrice The new default token price
     * @param _discountPrice The new discount token price
     */
    function updateTokenPrices(
        uint256 _tokenPrice,
        uint256 _discountPrice
    )
        external
        onlyOwner
    {
        require(
            _tokenPrice >= _discountPrice,
            "discountPrice cannot be larger"
        );

        require(
            saleIsActive == false,
            "Sale is active"
        );

        tokenPrice = _tokenPrice;
        discountPrice = _discountPrice;
    }

    /**
     * @notice Sets primePartsMerkleRoot summarizing all monster prime parts
     * @param _merkleRoot The new merkle root
     */
    function setPrimePartsMerkleRoot(
        bytes32 _merkleRoot
    )
        external
        onlyOwner
    {
        primePartsMerkleRoot = _merkleRoot;
    }

    /**
     * @notice Turns the laboratory on or off
     * @param _hasElectricity Whether to turn the laboratory on or off
     */
    function electrifyLaboratory(
        bool _hasElectricity
    )
        external
        onlyOwner
    {
        laboratoryHasElectricity = _hasElectricity;

        emit LaboratoryStateChanged(
            _hasElectricity
        );
    }

    /**
     * @notice Mints the final prime token
     */
    function mintFinalPrime()
        external
        onlyOwner
    {
        require(
            _exists(OMEGA) == false,
            "Final prime already exists"
        );

        unchecked {
            totalSupply++;
        }

        _safeMint(
            _msgSender(),
            OMEGA
        );
    }

    /**
     * @notice Sets the provenance URI
     * @param _newProvenanceURI The new provenance URI
     */
    function setProvenanceURI(
        string calldata _newProvenanceURI
    )
        external
        onlyOwner
    {
        require(
            provenanceUriLocked == false,
            "Provenance URI has been locked"
        );

        provenanceURI = _newProvenanceURI;
    }

    /**
     * @notice Prevents further changes to the provenance URI
     */
    function lockProvenanceURI()
        external
        onlyOwner
    {
        provenanceUriLocked = true;
    }

    /**
     * @notice Sets a new base URI
     * @param _newBaseURI The new base URI
     */
    function setBaseURI(
        string calldata _newBaseURI
    )
        external
        onlyOwner
    {
        require(
            baseUriLocked == false,
            "Base URI has been locked"
        );

        baseURI = _newBaseURI;
    }

    /**
     * @notice Prevents further changes to the base URI
     */
    function lockBaseURI()
        external
        onlyOwner
    {
        baseUriLocked = true;
    }

    /**
     * @notice Withdraws sale proceeds
     * @param _amount Amount to withdraw in wei
     */
    function withdraw(
        uint256 _amount
    )
        external
        onlyTeam
    {
        payable(_msgSender()).transfer(
            _amount
        );
    }

    /**
     * @notice Withdraws any other tokens
     * @dev WARNING: Double check token is legit before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _amount Amount to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawOther(
        address _token,
        address _to,
        uint256 _amount,
        bool _hasVerifiedToken
    )
        external
        onlyOwner
    {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        IERC20(_token).transfer(
            _to,
            _amount
        );
    }

    /**
     * @notice Sets token royalties (ERC-2981)
     * @param _recipient Recipient of the royalties
     * @param _value Royalty percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        external
        onlyOwner
    {
        require(
            _value <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /**
     * @notice Checks which Satoshibles can still be used for a discounted mint
     * @dev Uses bitwise operators to find the bit representing each Satoshible
     * @param _satIds Array of original Satoshible token IDs
     * @return Token ID for each of the available _satIds, zero otherwise
     */
    function satsAvailableForDiscountMint(
        uint256[] calldata _satIds
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory satsAvailable = new uint256[](_satIds.length);

        unchecked {
            for (uint256 i = 0; i < _satIds.length; i++) {
                if (satIsAvailableForDiscountMint(_satIds[i])) {
                    satsAvailable[i] = _satIds[i];
                }
            }
        }

        return satsAvailable;
    }

    /**
     * @notice Checks which Satoshibles can still be used to mint a prime
     * @dev Uses bitwise operators to find the bit representing each Satoshible
     * @param _satIds Array of original Satoshible token IDs
     * @return Token ID for each of the available _satIds, zero otherwise
     */
    function satsAvailableForLab(
        uint256[] calldata _satIds
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory satsAvailable = new uint256[](_satIds.length);

        unchecked {
            for (uint256 i = 0; i < _satIds.length; i++) {
                if (satIsAvailableForLab(_satIds[i])) {
                    satsAvailable[i] = _satIds[i];
                }
            }
        }

        return satsAvailable;
    }

    /**
     * @notice Checks if a Satoshible can still be used for a discounted mint
     * @dev Uses bitwise operators to find the bit representing the Satoshible
     * @param _satId Original Satoshible token ID
     * @return isAvailable True if _satId can be used for a discounted mint
     */
    function satIsAvailableForDiscountMint(
        uint256 _satId
    )
        public
        view
        returns (bool isAvailable)
    {
        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            isAvailable = satDiscountBitfields[page] >> shift & 1 == 1;
        }
    }

    /**
     * @notice Checks if a Satoshible can still be used to mint a prime
     * @dev Uses bitwise operators to find the bit representing the Satoshible
     * @param _satId Original Satoshible token ID
     * @return isAvailable True if _satId can still be used to mint a prime
     */
    function satIsAvailableForLab(
        uint256 _satId
    )
        public
        view
        returns (bool isAvailable)
    {
        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            isAvailable = satLabBitfields[page] >> shift & 1 == 1;
        }
    }

    /**
     * @notice Verifies a merkle proof for a monster ID and its prime parts
     * @param _monsterId Monster token ID
     * @param _monsterPrimeParts Bitfield of the monster's prime parts
     * @param _proof Merkle proof be verified
     * @return isVerified True if the merkle proof is verified
     */
    function verifyMonsterPrimeParts(
        uint256 _monsterId,
        uint256 _monsterPrimeParts,
        bytes32[] calldata _proof
    )
        public
        view
        returns (bool isVerified)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _monsterId,
                _monsterPrimeParts
            )
        );

        isVerified = MerkleProof.verify(
            _proof,
            primePartsMerkleRoot,
            node
        );
    }

    /**
     * @notice Gets total count of existing prime tokens for a prime type
     * @param _primeType Prime type
     * @return supply Count of existing prime tokens for this prime type
     */
    function primeSupply(
        uint256 _primeType
    )
        public
        view
        returns (uint256 supply)
    {
        supply = primeIds[_primeType].current();
    }

    /**
     * @notice Gets total count of existing prime tokens
     * @return supply Count of existing prime tokens
     */
    function totalPrimeSupply()
        public
        view
        returns (uint256 supply)
    {
        unchecked {
            supply = primeSupply(FRANKENSTEIN)
                + primeSupply(WEREWOLF)
                + primeSupply(VAMPIRE)
                + primeSupply(ZOMBIE)
                + (_exists(OMEGA) ? 1 : 0);
        }
    }

    /**
     * @notice Gets total count of monsters burned
     * @return burned Count of monsters burned
     */
    function monstersBurned()
        public
        view
        returns (uint256 burned)
    {
        unchecked {
            burned = monsterIds.current() + totalPrimeSupply() - totalSupply;
        }
    }

    /**
     * @notice Gets state of public sale
     * @return publicSaleIsOpen True if public sale phase has begun
     */
    function publicSaleOpened()
        public
        view
        returns (bool publicSaleIsOpen)
    {
        publicSaleIsOpen =
            publicSaleOpenedEarly == true ||
            monsterIds.current() >= MAX_PRESALE_TOKEN_ID;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721, ERC2981Base)
        returns (bool doesSupportInterface)
    {
        doesSupportInterface = super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Verifies a merkle proof for an account's whitelisted tokens
     * @param _account Account to verify
     * @param _whitelistedTokens Number of whitelisted tokens for _account
     * @param _proof Merkle proof to be verified
     * @return isVerified True if the merkle proof is verified
     */
    function verifyWhitelisted(
        address _account,
        uint256 _whitelistedTokens,
        bytes32[] calldata _proof
    )
        public
        pure
        returns (bool isVerified)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _account,
                _whitelistedTokens
            )
        );

        isVerified = MerkleProof.verify(
            _proof,
            WHITELIST_MERKLE_ROOT,
            node
        );
    }

    /**
     * @dev Base monster burning function
     * @param _tokenId Monster token ID to burn
     */
    function _burn(
        uint256 _tokenId
    )
        internal
        override
    {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId) == true,
            "not owner nor approved"
        );

        unchecked {
            totalSupply -= 1;
        }

        super._burn(
            _tokenId
        );
    }

    /**
     * @dev Base URI for computing tokenURI
     * @return Base URI string
     */
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    /**
     * @dev Base monster minting function, calculates price with discounts
     * @param _numberOfTokens Number of monster tokens to mint
     * @param _satsForDiscount Array of Satoshible IDs for discounted mints
     */
    function _doMintTokens(
        uint256 _numberOfTokens,
        uint256[] calldata _satsForDiscount
    )
        private
    {
        require(
            saleIsActive == true,
            "Sale must be active"
        );

        require(
            _numberOfTokens >= 1,
            "Need at least 1 token"
        );

        require(
            _numberOfTokens <= 50,
            "Max 50 at a time"
        );

        require(
            _satsForDiscount.length <= _numberOfTokens,
            "Too many sats for discount"
        );

        unchecked {
            uint256 discountIndex;

            for (; discountIndex < _satsForDiscount.length; discountIndex++) {
                _useSatForDiscountMint(_satsForDiscount[discountIndex]);
            }

            uint256 totalPrice = tokenPrice * (_numberOfTokens - discountIndex)
                + discountPrice * discountIndex;

            require(
                totalPrice == msg.value,
                "Ether amount not correct"
            );
        }

        _mintTokens(
            _numberOfTokens
        );
    }

    /**
     * @dev Base monster minting function.
     * @param _numberOfTokens Number of monster tokens to mint
     */
    function _mintTokens(
        uint256 _numberOfTokens
    )
        private
    {
        unchecked {
            totalSupply += _numberOfTokens;

            for (uint256 i = 0; i < _numberOfTokens; i++) {
                monsterIds.increment();
                _safeMint(
                    _msgSender(),
                    monsterIds.current()
                );
            }
        }
    }

    /**
     * @dev Marks a Satoshible ID as having been used for a discounted mint
     * @param _satId Satoshible ID that was used for a discounted mint
     */
    function _useSatForDiscountMint(
        uint256 _satId
    )
        private
        onlySatHolder(_satId)
    {
        require(
            satIsAvailableForDiscountMint(_satId) == true,
            "Sat for discount already used"
        );

        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            satDiscountBitfields[page] &= ~(1 << shift);
        }
    }

    /**
     * @dev Marks a Satoshible ID as having been used to mint a prime
     * @param _satId Satoshible ID that was used to mint a prime
     */
    function _retireSatFromLab(
        uint256 _satId
    )
        private
    {
        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            satLabBitfields[page] &= ~(1 << shift);
        }
    }

    /**
     * @dev Initializes prime token ID offsets
     */
    function _initializePrimeIdOffsets()
        private
    {
        unchecked {
            primeIdOffset[FRANKENSTEIN] = ALPHA;
            primeIdOffset[WEREWOLF] = ALPHA + 166;
            primeIdOffset[VAMPIRE] = ALPHA + 332;
            primeIdOffset[ZOMBIE] = ALPHA + 498;
            primeIdOffset[INVALID] = ALPHA + 665;
        }
    }

    /**
     * @dev Initializes bitfields of Satoshibles available for discounted mints
     */
    function _initializeSatDiscountAvailability()
        private
    {
        unchecked {
            for (uint256 i = 0; i < 20; i++) {
                satDiscountBitfields[i] = type(uint256).max;
            }
        }
    }

    /**
     * @dev Initializes bitfields of Satoshibles available to mint primes
     */
    function _initializeSatLabAvailability()
        private
    {
        unchecked {
            for (uint256 i = 0; i < 20; i++) {
                satLabBitfields[i] = type(uint256).max;
            }
        }
    }

    /**
     * @dev Helper function used for token ID range checks when minting
     * @param _currentValue Current token ID counter value
     * @param _incrementValue Number of tokens to increment by
     * @param _maximumValue Maximum token ID value allowed
     * @return isBelowMaximum True if _maximumValue is not exceeded
     */
    function belowMaximum(
        uint256 _currentValue,
        uint256 _incrementValue,
        uint256 _maximumValue
    )
        private
        pure
        returns (bool isBelowMaximum)
    {
        unchecked {
            isBelowMaximum = _currentValue + _incrementValue <= _maximumValue;
        }
    }
}