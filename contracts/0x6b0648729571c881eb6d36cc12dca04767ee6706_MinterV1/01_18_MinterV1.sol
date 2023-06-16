// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IPRTCLCollections721V1.sol";

/// @title Minter contract version 1
/// @author Particle Collection - valdi.eth
/// @notice Mint tokens for any collection in the core ERC721 contract
/// @dev Based on Artblock's Minter suite of contracts: https://github.com/ArtBlocks/artblocks-contracts/tree/main/contracts/minter-suite/Minters
/// Modifications to the original design:
/// - Max mints per wallet functionality
/// - Added pre sale and live sale minting phases
/// - Modified allowed currencies design
/// @dev The MinterV1 contract contains the following privileged access for the following functions:
/// - The owner can update pricePerToken using updatePricePerToken().
/// - The owner can update the maximum mint per wallet using updateMaxMints().
/// - The owner can update the minting phase using holderPreMintDone().
/// - The owner can update the payment currency of collection using updateCollectionCurrencyInfo().
/// - The owner can add or remove holders of collections using setAllowedHoldersofCollections().
/// - The owner can add or remove holders of external tokens using setAllowedExternalHolders().
/// - The owner can update update the whitelist signer through setSigner().
/// @custom:security-contact [email protected]
contract MinterV1 is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice Price per token updated for collection `_collectionId` to
     * `_pricePerToken`.
     */
    event PricePerTokenUpdated(
        uint256 indexed _collectionId,
        uint256 indexed _pricePerToken
    );

    /**
     * @notice Max mints per wallet for collection `_collectionId` 
     * updated to `_maxMints`.
     */
    event MaxMintsUpdated(
        uint256 indexed _collectionId,
        uint24 indexed _maxMints
    );

    /**
     * @notice Currency updated for collection `_collectionId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event CollectionCurrencyInfoUpdated(
        uint256 indexed _collectionId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /**
     * @notice Allow holders of NFTs at addresses `collCoreContract`, collection
     * IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`.
     */
    event AllowedHoldersOfCollections(
        uint256 indexed _collectionId,
        uint256[] _ownedNFTCollectionIds
    );

    /**
     * @notice Allow holders of NFTs at addresses `_tokenAddresses to mint on collection `_collectionId`.
     */
    event AllowedExternalHolders721(
        uint256 indexed _collectionId,
        address[] _tokenAddresses
    );

    /**
     * @notice Removed holders of NFTs at collection IDs `_ownedNFTCollectionIds` 
     * from allowlist to mint on collection `_collectionId`.
     */
    event RemovedHoldersOfCollections(
        uint256 indexed _collectionId,
        uint256[] _ownedNFTCollectionIds
    );

    /**
     * @notice Allow holders of NFTs at addresses `_tokenAddresses to mint on collection `_collectionId`.
     */
    event AllowedExternalHolders1155(
        uint256 indexed _collectionId,
        address[] _tokenAddresses,
        uint256[][] _tokenIds
    );

    /**
     * @notice Removed holders of NFTs at addresses `_tokenAddresses`,from allowlist to mint on collection `_collectionId`.
     */
    event RemovedExternalHolders721(
        uint256 indexed _collectionId,
        address[] _tokenAddresses
    );

    /**
     * @notice Removed holders of NFTs at addresses `_tokenAddresses`,from allowlist to mint on collection `_collectionId`.
     */
    event RemovedExternalHolders1155(
        uint256 indexed _collectionId,
        address[] _tokenAddresses,
        uint256[][] _tokenIds
    );

    /**
     * @notice Pre mint done status updated to true for
     * collection `_collectionId`.
     */
    event HolderPreMintDone(uint256 indexed _collectionId);

    /**
     * @dev Emitted when the signer address is updated.
     */
    event SignerUpdated(address signer);

    /// This contract handles cores with interface IPRTCLCollections721V1
    IPRTCLCollections721V1 public immutable collCoreContract;

    /// Collection configuration
    struct CollectionConfig {
        address currencyAddress;
        uint256 pricePerToken;
        string currencySymbol;
        uint24 maxMintsPerWallet;
        bool hasMaxPerWallet;
        bool holderPreMintDone;
    }

    mapping(uint256 => CollectionConfig) public collectionConfigs;

    // Number of tokens minted by a given wallet in a collection
    // CollectionId => wallet address => number of minted tokens
    mapping(uint256 => mapping(address => uint256)) public walletMintedPerCollection;

    /// @notice Used to validate whitelist addresses
    address public whitelistSigner;

    /**
     * collectionId => allowedCollectionIds
     * collections whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => EnumerableSet.UintSet) private allowedCollectionIds;

    /**
     * collectionId => address set
     * token addresses whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => EnumerableSet.AddressSet) private allowedExternalHolders721;

    /**
     * collectionId => address set
     * token addresses whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => EnumerableSet.AddressSet) private allowedExternalHolders1155;

    /**
     * collectionId => address => token id set
     * token ids in a ERC1155 token address, whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => mapping (address => EnumerableSet.UintSet)) private allowedTokenIds1155;

    modifier onlyValidCollectionId(uint256 _collectionId) {
        require(
            collCoreContract.collectionExists(_collectionId),
            "Collection ID does not exist"
        );
        _;
    }

    modifier onlyNonZeroAddress(address _address) {
        require(_address != address(0), "Must input non-zero address");
        _;
    }

    modifier onlyERC20Collection(uint256 _collectionId) {
        require(collectionConfigs[_collectionId].currencyAddress != address(0), "Collection uses ETH");
        _;
    }

    /**
     * @notice Initializes contract to be a Minter
     * integrated with Particle's core contract at 
     * address `_collCore721Address`.
     * @param _collCore721Address Particle's core contract for which this
     * contract will be a minter.
     */
    constructor(address _collCore721Address, address _signer)
        onlyNonZeroAddress(_collCore721Address)
        onlyNonZeroAddress(_signer)
        ReentrancyGuard()
    {
        collCoreContract = IPRTCLCollections721V1(_collCore721Address);
        whitelistSigner = _signer;
    }

    /**
     * @notice Gets the _address's balance of the ERC-20 token currently set
     * as the payment currency for collection `_collectionId`.
     * @param _address Address to be queried.
     * @param _collectionId Collection ID to be queried.
     * @return balance Balance of ERC-20
     */
    function balanceOfCollectionERC20(address _address, uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        onlyERC20Collection(_collectionId)
        returns (uint256 balance)
    {
        balance = IERC20(collectionConfigs[_collectionId].currencyAddress).balanceOf(
            _address
        );
    }

    /**
     * @notice Gets the _address's allowance for this minter of the ERC-20
     * token currently set as the payment currency for collection
     * `_collectionId`.
     * @param _address Address to be queried.
     * @param _collectionId Collection ID to be queried.
     * @return remaining Remaining allowance of ERC-20
     */
    function allowanceOfCollectionERC20(address _address, uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        onlyERC20Collection(_collectionId)
        returns (uint256 remaining)
    {
        remaining = IERC20(collectionConfigs[_collectionId].currencyAddress).allowance(
            _address,
            address(this)
        );
    }

    /**
     * @notice Updates this minter's price per token of collection `_collectionId`
     * to be '_pricePerToken`.
     */
    function updatePricePerToken(
        uint256 _collectionId,
        uint256 _pricePerToken
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        require(_pricePerToken > 0, "Price must be > 0");
        collectionConfigs[_collectionId].pricePerToken = _pricePerToken;
        emit PricePerTokenUpdated(_collectionId, _pricePerToken);
    }

    /**
     * @notice Updates this minter's max mints per wallet 
     * of collection `_collectionId` to be '_maxMints`
     */
    function updateMaxMints(
        uint256 _collectionId,
        uint24 _maxMints
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        // 0 max mints == no limit
        // (max token ids enforced by core contract)
        (,uint256 maxParticles,,,,,) = collCoreContract.collectionData(_collectionId);
        require(_maxMints < maxParticles, "Max mints must be < max particles for collection");
        collectionConfigs[_collectionId].maxMintsPerWallet = _maxMints;
        collectionConfigs[_collectionId].hasMaxPerWallet = true;
        emit MaxMintsUpdated(_collectionId, _maxMints);
    }

    /**
     * @notice Updates this minter's minting phase 
     * of collection `_collectionId` to be past pre mint
     */
    function holderPreMintDone(
        uint256 _collectionId
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        collectionConfigs[_collectionId].holderPreMintDone = true;
        emit HolderPreMintDone(_collectionId);
    }

    /**
     * @notice Updates payment currency of collection `_collectionId` to be
     * `_currencySymbol` at address `_currencyAddress`.
     * @param _collectionId Collection ID to update.
     * @param _currencySymbol Currency symbol.
     * @param _currencyAddress Currency address.
     */
    function updateCollectionCurrencyInfo(
        uint256 _collectionId,
        string memory _currencySymbol,
        address _currencyAddress
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        require(bytes(_currencySymbol).length != 0, "Symbol must be non-empty");

        // require null address if symbol is "ETH"
        require(
            (keccak256(abi.encodePacked(_currencySymbol)) ==
                keccak256(abi.encodePacked("ETH"))) ==
                (_currencyAddress == address(0)),
            "ETH is only null address"
        );
        collectionConfigs[_collectionId].currencySymbol = _currencySymbol;
        collectionConfigs[_collectionId].currencyAddress = _currencyAddress;
        emit CollectionCurrencyInfoUpdated(
            _collectionId,
            _currencyAddress,
            _currencySymbol
        );
    }

    /**
     * @dev Update signer address.
     * Can only be called by owner.
     */
    function setSigner(address _signer) external onlyNonZeroAddress(_signer) onlyOwner {
        whitelistSigner = _signer;
        emit SignerUpdated(_signer);
    }

    /**
     * @notice Verify signature
     */
    function verifyAddressSigner(bytes memory _signature, uint256 _collectionId, address _address, uint256 _expirationBlock) public 
    view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_collectionId, _address, _expirationBlock));
        return block.number < _expirationBlock && whitelistSigner == messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Allows holders of NFTs from
     * collection IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _ownedNFTCollectionIds Collection IDs on `collCoreContract`
     * whose holders shall be allowlisted to mint collection `_collectionId`.
     * @param _isAllowed Whether to allow or disallow holders of `_ownedNFTCollectionIds`
     */
    function setAllowedHoldersOfCollections(
        uint256 _collectionId,
        uint256[] memory _ownedNFTCollectionIds,
        bool _isAllowed
    ) public onlyValidCollectionId(_collectionId) onlyOwner {
        require(_ownedNFTCollectionIds.length > 0, "Must send at least one collection ID");
        require(!collectionConfigs[_collectionId].holderPreMintDone, "Pre mint done");

        uint256 ownedIdsLength = _ownedNFTCollectionIds.length;
        // for each approved collection
        for (uint256 i = 0; i < ownedIdsLength;) {
            uint256 toAllowCollectionId = _ownedNFTCollectionIds[i];

            require(
                collCoreContract.collectionExists(toAllowCollectionId),
                "Collection ID does not exist"
            );

            if (_isAllowed) {
                // add to allowed collection holders
                allowedCollectionIds[_collectionId].add(toAllowCollectionId);
            } else {
                // remove from allowed collection holders
                allowedCollectionIds[_collectionId].remove(toAllowCollectionId);
            }

            unchecked { i++; }
        }

        if (_isAllowed) {
            // emit approve event
            emit AllowedHoldersOfCollections(
                _collectionId,
                _ownedNFTCollectionIds
            );
        } else {
            // emit disapprove event
            emit RemovedHoldersOfCollections(
                _collectionId,
                _ownedNFTCollectionIds
            );
        }
    }

    /**
     * @notice Allows or disallows holders of NFTs from
     * `_tokenAddresses` to mint on collection `_collectionId`,
     * depending on `_isAllowed`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _tokenAddresses Tokens whose holders shall be allowlisted 
     * to mint collection `_collectionId`.
     * @param _isAllowed Whether to allow or disallow holders of tokens `_tokenAddresses`
     */
    function setAllowedExternalHolders721(
        uint256 _collectionId,
        address[] memory _tokenAddresses,
        bool _isAllowed
    ) public onlyValidCollectionId(_collectionId) onlyOwner {
        require(_tokenAddresses.length > 0, "Must send at least one token address");
        require(!collectionConfigs[_collectionId].holderPreMintDone, "Pre mint done");

        uint256 tokenAddressesLength = _tokenAddresses.length;

        // for each approved token
        for (uint256 i = 0; i < tokenAddressesLength;) {
            address tokenAddress = _tokenAddresses[i];

            require(tokenAddress != address(0), "Must input non-zero address");
            require(IERC721(tokenAddress).supportsInterface(type(IERC721).interfaceId), "Address is not ERC721");


            if (_isAllowed) {
                // add to allowed token holders
                allowedExternalHolders721[_collectionId].add(tokenAddress);
            } else {
                // remove from allowed token holders
                allowedExternalHolders721[_collectionId].remove(tokenAddress);
            }

            unchecked { i++; }
        }

        if (_isAllowed) {
            // emit approve event
            emit AllowedExternalHolders721(
                _collectionId,
                _tokenAddresses
            );
        } else {
            // emit disapprove event
            emit RemovedExternalHolders721(
                _collectionId,
                _tokenAddresses
            );
        }
    }

    /**
     * @notice Allows or disallows holders of NFTs from
     * `_tokenAddresses` and `_tokenIds` to mint on collection `_collectionId`,
     * depending on `_isAllowed`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _tokenAddresses Tokens whose holders shall be allowlisted 
     * to mint collection `_collectionId`.
     * @param _tokenIds Tokens ids whose holders shall be allowlisted
     * to mint collection `_collectionId`.
     * @param _isAllowed Whether to allow or disallow holders of tokens `_tokenAddresses`
     */
    function setAllowedExternalHolders1155(
        uint256 _collectionId,
        address[] memory _tokenAddresses,
        uint256[][] memory _tokenIds,
        bool _isAllowed
    ) public onlyValidCollectionId(_collectionId) onlyOwner {
        require(_tokenAddresses.length > 0, "Must send at least one token address");
        require(_tokenAddresses.length == _tokenIds.length, "Must send same amount of token addresses and token ids arrays");
        require(!collectionConfigs[_collectionId].holderPreMintDone, "Pre mint done");

        uint256 tokenAddressesLength = _tokenAddresses.length;

        // for each approved token
        for (uint256 i = 0; i < tokenAddressesLength;) {
            address tokenAddress = _tokenAddresses[i];

            require(tokenAddress != address(0), "Must input non-zero address");
            require(IERC1155(tokenAddress).supportsInterface(type(IERC1155).interfaceId), "Address is not ERC1155");
            
            uint256 tokenIdsLength = _tokenIds[i].length;
            require(tokenIdsLength > 0, "Must send at least one token id");

            for (uint256 j = 0; j < tokenIdsLength;) {
                uint256 tokenId = _tokenIds[i][j];
                if (_isAllowed) {
                    // add to allowed token holders
                    allowedTokenIds1155[_collectionId][tokenAddress].add(tokenId);
                } else {
                    // remove from allowed token holders
                    allowedTokenIds1155[_collectionId][tokenAddress].remove(tokenId);
                }

                unchecked { j++; }
            }

            if (_isAllowed) {
                // add to allowed token holders
                allowedExternalHolders1155[_collectionId].add(tokenAddress);
            } else if (allowedTokenIds1155[_collectionId][tokenAddress].length() == 0) {
                // remove from allowed token holders
                allowedExternalHolders1155[_collectionId].remove(tokenAddress);
            }

            unchecked { i++; }
        }

        if (_isAllowed) {
            // emit approve event
            emit AllowedExternalHolders1155(
                _collectionId,
                _tokenAddresses,
                _tokenIds
            );
        } else {
            // emit disapprove event
            emit RemovedExternalHolders1155(
                _collectionId,
                _tokenAddresses,
                _tokenIds
            );
        }
    }

    /**
     * @notice Returns true if user holds an allowlisted NFT for collection `_collectionId`.
     * @param _collectionId Collection ID to be checked.
     * @return bool User is allowlisted
     * @dev does not check if held token has been used to purchase a token from `_collectionId`
     */
    function isAllowlistedFor(
        address _address,
        uint256 _collectionId
    ) public view onlyValidCollectionId(_collectionId) returns (bool) {
        uint256 numAllowedCollectionIds = allowedCollectionIds[_collectionId].length();
        for (uint256 i = 0; i < numAllowedCollectionIds; i++) {
            if (collCoreContract.balanceOf(_address, allowedCollectionIds[_collectionId].at(i)) > 0) {
                return true;
            }
        }

        uint256 numAllowedExternalHolders721 = allowedExternalHolders721[_collectionId].length();
        for (uint256 i = 0; i < numAllowedExternalHolders721; i++) {
            if (IERC721(allowedExternalHolders721[_collectionId].at(i)).balanceOf(_address) > 0) {
                return true;
            }
        }

        uint256 numAllowedExternalHolders1155 = allowedExternalHolders1155[_collectionId].length();
        for (uint256 i = 0; i < numAllowedExternalHolders1155; i++) {
            address tokenAddress = allowedExternalHolders1155[_collectionId].at(i);
            uint256 numAllowedTokenIds1155 = allowedTokenIds1155[_collectionId][tokenAddress].length();
            for (uint256 j = 0; j < numAllowedTokenIds1155; j++) {
                uint256 tokenId = allowedTokenIds1155[_collectionId][tokenAddress].at(j);
                if (IERC1155(tokenAddress).balanceOf(_address, tokenId) > 0) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * @notice Purchase a token from a collection during minting.
     * @param _to Receiver of the purchased token.
     * @param _collectionId Collection ID to be minted from.
     * @param _signature Signature to verify buyer is whitelisted.
     * @param _signatureExpirationBlock Signature expiration block.
     * @return tokenId First token id purchased.
     */
    function purchase(
        address _to,
        uint256 _collectionId,
        uint24 _amount,
        bytes memory _signature,
        uint256 _signatureExpirationBlock
    )
        external
        payable
        nonReentrant
        onlyValidCollectionId(_collectionId)
        returns (uint256 tokenId)
    {
        // CHECKS
        require(_amount > 0, "Must purchase at least one token");

        // require valid signature for minting in any phase
        require(verifyAddressSigner(_signature, _collectionId, msg.sender, _signatureExpirationBlock), "Invalid signature");

        CollectionConfig storage _collectionConfig = collectionConfigs[_collectionId];
        uint256 _pricePerToken = _collectionConfig.pricePerToken;

        // require price of token to be configured on this minter
        require(_pricePerToken > 0 && _collectionConfig.hasMaxPerWallet, "Collection not configured");

        // require user to hold an allowlisted token during holder pre mint phase
        require(_collectionConfig.holderPreMintDone || (isAllowlistedFor(msg.sender, _collectionId)),
            "Only allowlisted NFT holders"
        );

        uint256 newMintedAmount = walletMintedPerCollection[_collectionId][msg.sender] + _amount;
        uint256 maxMints = _collectionConfig.maxMintsPerWallet;
        require(maxMints == 0 || newMintedAmount <= maxMints, "Maximum amount exceeded");

        // EFFECTS
        walletMintedPerCollection[_collectionId][msg.sender] = newMintedAmount;
        tokenId = collCoreContract.mint(_to, _collectionId, _amount);

        // INTERACTIONS
        // Moving money after mint to pass core checks first
        uint256 _totalPrice = _pricePerToken * _amount;
        address _currencyAddress = _collectionConfig.currencyAddress;
        if (_currencyAddress != address(0)) {
            require(
                msg.value == 0,
                "This collection accepts a different currency and cannot accept ETH"
            );
            require(
                IERC20(_currencyAddress).allowance(msg.sender, address(this)) >=
                    _totalPrice,
                "Insufficient Funds Approved for TX"
            );
            require(
                IERC20(_currencyAddress).balanceOf(msg.sender) >=
                    _totalPrice,
                "Insufficient balance"
            );
            _splitFundsERC20(_collectionId, _totalPrice, _currencyAddress);
        } else {
            require(
                msg.value >= _totalPrice,
                "Must send minimum value to mint"
            );
            _splitFundsETH(_collectionId, _totalPrice);
        }

        return tokenId;
    }

    /**
     * @dev splits ETH funds between sender (if refund), 4JM,
     * DAO, and artist for a token purchased on
     * collection `_collectionId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * admin-accepted artist payment addresses.
     */
    function _splitFundsETH(uint256 _collectionId, uint256 _totalPrice)
        internal
    {
        if (msg.value > 0) {
            bool success_;
            // send refund to sender
            uint256 refund = msg.value - _totalPrice;
            if (refund > 0) {
                (success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split remaining funds between 4JM, DAO and artist
            (
                uint256 fjmRevenue_,
                address payable fjmAddress_,
                uint256 daoRevenue_,
                address payable daoAddress_,
                uint256 artistRevenue_,
                address payable artistAddress_
            ) = collCoreContract.getPrimaryRevenueSplits(
                    _collectionId,
                    _totalPrice
                );
            // 4JM payment
            if (fjmRevenue_ > 0) {
                (success_, ) = fjmAddress_.call{value: fjmRevenue_}(
                    ""
                );
                require(success_, "Particle payment failed");
            }
            // Particle DAO payment
            if (daoRevenue_ > 0) {
                (success_, ) = daoAddress_.call{
                    value: daoRevenue_
                }("");
                require(success_, "DAO payment failed");
            }
            // artist payment
            if (artistRevenue_ > 0) {
                (success_, ) = artistAddress_.call{value: artistRevenue_}("");
                require(success_, "Artist payment failed");
            }
        }
    }

    /**
     * @dev splits ERC-20 funds between 4JM, Particle DAO and artist, for a token purchased on collection `_collectionId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * admin-accepted artist payment addresses.
     */
    function _splitFundsERC20(
        uint256 _collectionId,
        uint256 _totalPrice,
        address _currencyAddress
    ) internal {
        // split remaining funds between 4JM, Particle DAO and artist
        (
            uint256 fjmRevenue_,
            address payable fjmAddress_,
            uint256 daoRevenue_,
            address payable daoAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        ) = collCoreContract.getPrimaryRevenueSplits(
                _collectionId,
                _totalPrice
            );
        IERC20 _collectionCurrency = IERC20(_currencyAddress);
        // 4JM payment
        if (fjmRevenue_ > 0) {
            _collectionCurrency.safeTransferFrom(
                msg.sender,
                fjmAddress_,
                fjmRevenue_
            );
        }
        // Particle DAO payment
        if (daoRevenue_ > 0) {
            _collectionCurrency.safeTransferFrom(
                msg.sender,
                daoAddress_,
                daoRevenue_
            );
        }
        // artist payment
        if (artistRevenue_ > 0) {
            _collectionCurrency.safeTransferFrom(
                msg.sender,
                artistAddress_,
                artistRevenue_
            );
        }
    }

    /**
     * @notice collectionId => maximum mints per allowlisted address. 
     * If a value of 0 is returned, there is no limit on the number of mints per allowlisted address.
     * Default behavior is no limit mint per address.
     */
    function collectionMaxMintsPerAddress(
        uint256 _collectionId
    ) public view onlyValidCollectionId(_collectionId) returns (uint256) {
        return uint256(collectionConfigs[_collectionId].maxMintsPerWallet);
    }

    /**
     * @notice Returns remaining mints for a given address.
     * Returns 0 if no maximum per address is set for collection `_collectionId`.
     * Note that max mints per address can be changed at any time by the owner.
     * Also note that all max mints per address are limited by a 
     * collections's maximum mints as defined on the core contract. 
     * This function may return a value greater than the collection's remaining mints.
     */
    function collectionRemainingMintsForAddress(
        uint256 _collectionId,
        address _address
    )
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (
            uint256 mintsRemaining,
            bool hasLimit
        )
    {
        uint256 maxMintsPerAddress = collectionMaxMintsPerAddress(
            _collectionId
        );
        if (maxMintsPerAddress == 0) {
            // project does not limit mint invocations per address, so leave `mintsRemaining` at
            // solidity initial value of zero, and hasLimit as false
        } else {
            hasLimit = true;
            uint256 walletMints = walletMintedPerCollection[
                _collectionId
            ][_address];
            // if user has not reached max mints per address, return
            // remaining mints
            if (maxMintsPerAddress > walletMints) {
                unchecked {
                    // will never underflow due to the check above
                    mintsRemaining = maxMintsPerAddress - walletMints;
                }
            }
            // else user has reached their maximum invocations, so leave
            // `mintsRemaining` at solidity initial value of zero
        }
    }

    /**
     * @notice If price of token is configured, returns price of minting a
     * token on collection `_collectionId`, and currency symbol and address 
     * to be used as payment.
     * @param _collectionId Collection ID to get price information for.
     * @return isConfigured true only if token price has been configured on
     * this minter
     * @return tokenPrice current price of token on this minter - invalid
     * if price has not yet been configured
     * @return currencySymbol currency symbol for purchases of collection on this
     * minter. "ETH" reserved for ether.
     * @return currencyAddress currency address for purchases of collection on
     * this minter. Null address reserved for ether.
     */
    function getPriceInfo(uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (
            bool isConfigured,
            uint256 tokenPrice,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        CollectionConfig storage _collectionConfig = collectionConfigs[_collectionId];
        tokenPrice = _collectionConfig.pricePerToken;
        isConfigured = tokenPrice > 0 && _collectionConfig.hasMaxPerWallet;
        currencyAddress = _collectionConfig.currencyAddress;
        if (currencyAddress == address(0)) {
            currencySymbol = "ETH";
        } else {
            currencySymbol = _collectionConfig.currencySymbol;
        }
    }

    /**
     * @notice Returns true if collection `_collectionId` has ended it's pre-mint phase.
     */
    function getCollectionPreMintDone(uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (bool)
    {
        return collectionConfigs[_collectionId].holderPreMintDone;
    }
}