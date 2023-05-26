//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 *    ███████╗██╗   ██╗██████╗ ██████╗ ███████╗███╗   ███╗███████╗
 *    ██╔════╝██║   ██║██╔══██╗██╔══██╗██╔════╝████╗ ████║██╔════╝
 *    ███████╗██║   ██║██████╔╝██████╔╝█████╗  ██╔████╔██║█████╗
 *    ╚════██║██║   ██║██╔═══╝ ██╔══██╗██╔══╝  ██║╚██╔╝██║██╔══╝
 *    ███████║╚██████╔╝██║     ██║  ██║███████╗██║ ╚═╝ ██║███████╗
 *    ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝
 *
 *    ███████╗██╗  ██╗██╗   ██╗██╗     ██╗     ███████╗
 *    ██╔════╝██║ ██╔╝██║   ██║██║     ██║     ██╔════╝
 *    ███████╗█████╔╝ ██║   ██║██║     ██║     ███████╗
 *    ╚════██║██╔═██╗ ██║   ██║██║     ██║     ╚════██║
 *    ███████║██║  ██╗╚██████╔╝███████╗███████╗███████║
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝
 */

import "./ISupremeSkulls.sol";
import "./token/ERC721Enumerable.sol";
import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Supreme Skulls
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
contract SupremeSkulls is
    ISupremeSkulls,
    ERC721Enumerable,
    ERC2981ContractWideRoyalties,
    TokenRescuer
{
    /// The maximum token supply.
    uint256 public constant MAX_SUPPLY = 6666;

    /// The maximum number of minted tokens per address in the whitelist phase.
    uint256 public constant MAX_WHITELIST_MINT = 2;

    /// The maximum number of minted tokens per transaction.
    uint256 public constant MAX_MINT_PER_TX = 2;

    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 1000; // 10%

    /// The price per token mint (whitelist phase).
    uint256 public priceWhitelist;

    /// The price per token mint (public phase).
    uint256 public pricePublic;

    /// The base URI for token metadata.
    string public baseURI;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// The provenance hash summarizing token order and content.
    bytes32 public provenanceHash;

    /// Whether the provenance hash has been locked forever.
    bool public provenanceIsLocked;

    /// Whether the tokenURI() method returns fully revealed tokenURIs
    bool public isRevealed;

    /// The token sale state (0=Paused, 1=Whitelist, 2=Public, 3=Open).
    SaleState public saleState;

    /// The address of the OpenSea proxy registry contract.
    address public proxyRegistry;

    /// The address which signs the mint coupons.
    address public couponSigner;

    /// Whether an address has revoked the automatic OpenSea proxy approval.
    mapping(address => bool) public userRevokedRegistryApproval;

    /// The total tokens minted by an address in whitelist phase.
    mapping(address => uint256) public whitelistMinted;

    /// Reverts if the current sale state is not `_saleState`.
    modifier onlyInSaleState(SaleState _saleState) {
        if (saleState != _saleState) revert SalePhaseNotActive();
        _;
    }

    /// Reverts if `_mintAmount` exceeds MAX_MINT_PER_TX.
    modifier onlyWithValidMintAmount(uint256 _mintAmount) {
        if (_mintAmount > MAX_MINT_PER_TX) revert ExceedsMaxMintPerTx();
        _;
    }

    /// Reverts if the correct ether value was not sent.
    modifier onlyWithCorrectPayment(uint256 _mintAmount, uint256 _price) {
        unchecked {
            if (msg.value != _mintAmount * _price)
                revert IncorrectPaymentAmount();
        }
        _;
    }

    /// Reverts if the signature is invalid.
    modifier onlyWithValidSignature(
        bytes calldata _signature,
        SaleState _saleState
    ) {
        if (!isValidSignature(
            _signature,
            _msgSender(),
            _saleState,
            block.chainid
        )) revert InvalidSignature();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startingTokenID,
        address _couponSigner,
        uint256 _priceWhitelist,
        uint256 _pricePublic,
        string memory _contractURI,
        string memory _baseURI,
        address _proxyRegistry,
        address _royaltiesReceiver,
        uint256 _royaltiesPercent
    )
        ERC721(_name, _symbol, _startingTokenID)
    {
        couponSigner = _couponSigner;
        priceWhitelist = _priceWhitelist;
        pricePublic = _pricePublic;
        contractURI = _contractURI;
        baseURI = _baseURI;
        proxyRegistry = _proxyRegistry;
        setRoyalties(
            _royaltiesReceiver,
            _royaltiesPercent
        );
    }

    /**
     * @notice Mints `_mintAmount` tokens if the signature is valid.
     * @param _mintAmount The number of tokens to mint.
     * @param _signature The signature to be verified.
     */
    function mintWhitelist(
        uint256 _mintAmount,
        bytes calldata _signature
    )
        external
        payable
        onlyInSaleState(SaleState.Whitelist)
        onlyWithCorrectPayment(_mintAmount, priceWhitelist)
        onlyWithValidSignature(_signature, SaleState.Whitelist)
    {
        unchecked {
            whitelistMinted[_msgSender()] += _mintAmount;
        }
        if (whitelistMinted[_msgSender()] > MAX_WHITELIST_MINT)
            revert ExceedsMintPhaseAllocation();

        _mint(_mintAmount);
    }

    /**
     * @notice Mints `_mintAmount` tokens if the signature is valid.
     * @param _mintAmount The number of tokens to mint.
     * @param _signature The signature to be verified.
     */
    function mintPublic(
        uint256 _mintAmount,
        bytes calldata _signature
    )
        external
        payable
        onlyInSaleState(SaleState.Public)
        onlyWithValidMintAmount(_mintAmount)
        onlyWithCorrectPayment(_mintAmount, pricePublic)
        onlyWithValidSignature(_signature, SaleState.Public)
    {
        _mint(_mintAmount);
    }

    /**
     * @notice Mints `_mintAmount` tokens.
     * @param _mintAmount The number of tokens to mint.
     */
    function mintOpen(
        uint256 _mintAmount
    )
        external
        payable
        onlyInSaleState(SaleState.Open)
        onlyWithValidMintAmount(_mintAmount)
        onlyWithCorrectPayment(_mintAmount, pricePublic)
    {
        _mint(_mintAmount);
    }

    /**
     * @notice Revokes the automatic approval of the caller's OpenSea proxy.
     */
    function revokeRegistryApproval()
        external
    {
        if (userRevokedRegistryApproval[_msgSender()])
            revert AlreadyRevokedRegistryApproval();

        userRevokedRegistryApproval[_msgSender()] = true;
    }

    /**
     * @notice (only owner) Mints `_mintAmount` free tokens to the caller.
     * @param _mintAmount The number of tokens to mint.
     */
    function mintPromo(
        uint256 _mintAmount
    )
        external
        onlyOwner
    {
        _mint(_mintAmount);
    }

    /**
     * @notice (only owner) Sets the saleState to `_newSaleState`.
     * @param _newSaleState The new sale state
     * (0=Paused, 1=Whitelist, 2=Presale, 3=Public).
     */
    function setSaleState(
        SaleState _newSaleState
    )
        external
        onlyOwner
    {
        saleState = _newSaleState;
        emit SaleStateChanged(_newSaleState);
    }

    /**
     * @notice (only owner) Sets the whitelist mint price.
     * @param _newPrice The new whitelist mint price.
     */
    function setPriceWhitelist(
        uint256 _newPrice
    )
        external
        onlyOwner
    {
        priceWhitelist = _newPrice;
    }

    /**
     * @notice (only owner) Sets the public mint price.
     * @param _newPrice The new public mint price.
     */
    function setPricePublic(
        uint256 _newPrice
    )
        external
        onlyOwner
    {
        pricePublic = _newPrice;
    }

    /**
     * @notice (only owner) Sets the OpenSea proxy registry contract address.
     * @param _newProxyRegistry The OpenSea proxy registry contract address.
     */
    function setProxyRegistry(
        address _newProxyRegistry
    )
        external
        onlyOwner
    {
        proxyRegistry = _newProxyRegistry;
    }

    /**
     * @notice (only owner) Sets the coupon signer address.
     * @param _newCouponSigner The new coupon signer address.
     */
    function setCouponSigner(
        address _newCouponSigner
    )
        external
        onlyOwner
    {
        couponSigner = _newCouponSigner;
    }

    /**
     * @notice (only owner) Sets the contract URI for contract metadata.
     * @param _newContractURI The new contract URI.
     */
    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /**
     * @notice (only owner) Sets the base URI for token metadata.
     * @param _newBaseURI The new base URI.
     * @param _doReveal If true, this reveals the full tokenURIs.
     */
    function setBaseURI(
        string calldata _newBaseURI,
        bool _doReveal
    )
        external
        onlyOwner
    {
        baseURI = _newBaseURI;
        isRevealed = _doReveal;
    }

    /**
     * @notice (only owner) Sets the provenance hash, optionally locking it.
     * @param _newProvenanceHash The new provenance hash.
     * @param _lockForever Whether to lock this new provenance hash forever.
     */
    function setProvenanceHash(
        bytes32 _newProvenanceHash,
        bool _lockForever
    )
        external
        onlyOwner
    {
        if (provenanceIsLocked) revert ProvenanceHashAlreadyLocked();

        provenanceHash = _newProvenanceHash;
        if (_lockForever) provenanceIsLocked = true;
    }

    /**
     * @notice (only owner) Withdraws all ether to the caller.
     */
    function withdrawAll()
        external
        onlyOwner
    {
        withdraw(address(this).balance);
    }

    /**
     * @notice (only owner) Withdraws `_weiAmount` wei to the caller.
     * @param _weiAmount The amount of ether (in wei) to withdraw.
     */
    function withdraw(
        uint256 _weiAmount
    )
        public
        onlyOwner
    {
        (bool success, ) = payable(_msgSender()).call{value: _weiAmount}("");
        if (!success) revert FailedToWithdraw();
    }

    /**
     * @notice (only owner) Sets ERC-2981 royalties recipient and percentage.
     * @param _recipient The address to which to send royalties.
     * @param _value The royalties percentage (two decimals, e.g. 1000 = 10%).
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        public
        onlyOwner
    {
        if (_value > MAX_ROYALTIES_PCT) revert ExceedsMaxRoyaltiesPercentage();

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /**
     * @notice Determines whether `_account` owns all token IDs `_tokenIDs`.
     * @param _account The account to be checked for token ownership.
     * @param _tokenIDs An array of token IDs to be checked for ownership.
     * @return True if `_account` owns all token IDs `_tokenIDs`, else false.
     */
    function isOwnerOf(
        address _account,
        uint256[] calldata _tokenIDs
    )
        external
        view
        returns (bool)
    {
        unchecked {
            for (uint256 i; i < _tokenIDs.length; ++i) {
                if (ownerOf(_tokenIDs[i]) != _account)
                    return false;
            }
        }

        return true;
    }

    /**
     * @notice Returns an array of all token IDs owned by `_owner`.
     * @param _owner The address for which to return all owned token IDs.
     * @return An array of all token IDs owned by `_owner`.
     */
    function walletOfOwner(
        address _owner
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIDs = new uint256[](tokenCount);
        unchecked {
            for (uint256 i; i < tokenCount; i++) {
                tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
            }
        }
        return tokenIDs;
    }

    /**
     * @notice Checks if `_operator` can transfer tokens owned by `_owner`.
     * @param _owner The address that may own tokens.
     * @param _operator The address that would transfer tokens of `_owner`.
     * @return True if `_operator` can transfer tokens of `_owner`, else false.
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        override (ERC721, IERC721)
        returns (bool)
    {
        if (!userRevokedRegistryApproval[_owner]) {
            OpenSeaProxyRegistry reg = OpenSeaProxyRegistry(proxyRegistry);
            if (address(reg.proxies(_owner)) == _operator) return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @notice Returns the token metadata URI for token ID `_tokenID`.
     * @param _tokenID The token ID whose metadata URI should be returned.
     * @return The metadata URI for token ID `_tokenID`.
     */
    function tokenURI(
        uint256 _tokenID
    )
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenID)) revert TokenDoesNotExist();
        if (!isRevealed) return baseURI;
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenID),
                ".json"
            )
        );
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Checks validity of the signature, sender, and saleState.
     * @param _signature The signature to be verified.
     * @param _sender The address part of the signed message.
     * @param _saleState The saleState part of the signed message.
     * @param _chainId The chain ID part of the signed message.
     */
    function isValidSignature(
        bytes calldata _signature,
        address _sender,
        SaleState _saleState,
        uint256 _chainId
    )
        public
        view
        returns (bool)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _sender,
                    _saleState,
                    _chainId
                )
            )
        );
        return couponSigner == ECDSA.recover(hash, _signature);
    }

    /**
     * @notice Mints `_mintAmount` tokens to caller, emits actual token IDs.
     */
    function _mint(
        uint256 _mintAmount
    )
        internal
    {
        uint256 totalSupply = _owners.length;
        unchecked {
            if (totalSupply + _mintAmount > MAX_SUPPLY)
                revert ExceedsMaxSupply();
            for (uint256 i; i < _mintAmount; i++) {
                _owners.push(_msgSender());
                emit Transfer(
                    address(0),
                    _msgSender(),
                    _startingTokenID + totalSupply + i
                );
            }
        }
    }
}

/// Stub for OpenSea's per-user-address proxy contract.
contract OwnableDelegateProxy {}

/// Stub for OpenSea's proxy registry contract.
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}