//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 *    ██████╗ ██████╗  █████╗ ██╗███████╗███████╗
 *    ██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██╔════╝
 *    ██████╔╝██████╔╝███████║██║███████╗█████╗
 *    ██╔═══╝ ██╔══██╗██╔══██║██║╚════██║██╔══╝
 *    ██║     ██║  ██║██║  ██║██║███████║███████╗
 *    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝
 *
 *     ██████╗  ██████╗ ██╗     ██████╗ ███████╗███╗   ██╗
 *    ██╔════╝ ██╔═══██╗██║     ██╔══██╗██╔════╝████╗  ██║
 *    ██║  ███╗██║   ██║██║     ██║  ██║█████╗  ██╔██╗ ██║
 *    ██║   ██║██║   ██║██║     ██║  ██║██╔══╝  ██║╚██╗██║
 *    ╚██████╔╝╚██████╔╝███████╗██████╔╝███████╗██║ ╚████║
 *     ╚═════╝  ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═══╝
 *
 *    ███╗   ███╗███████╗███╗   ███╗██████╗ ███████╗██████╗ ███████╗██╗  ██╗██╗██████╗
 *    ████╗ ████║██╔════╝████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║██║██╔══██╗
 *    ██╔████╔██║█████╗  ██╔████╔██║██████╔╝█████╗  ██████╔╝███████╗███████║██║██████╔╝
 *    ██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗╚════██║██╔══██║██║██╔═══╝
 *    ██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║██████╔╝███████╗██║  ██║███████║██║  ██║██║██║
 *    ╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝
 *
 *     ██████╗ █████╗ ██████╗ ██████╗
 *    ██╔════╝██╔══██╗██╔══██╗██╔══██╗
 *    ██║     ███████║██████╔╝██║  ██║
 *    ██║     ██╔══██║██╔══██╗██║  ██║
 *    ╚██████╗██║  ██║██║  ██║██████╔╝
 *     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
 */

import "./IPraiseGoldenMembershipCard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Praise Golden Membership Card
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
contract PraiseGoldenMembershipCard is
    IPraiseGoldenMembershipCard,
    ERC1155,
    ERC2981ContractWideRoyalties,
    TokenRescuer
{
    /// The maximum token supply.
    uint256 public constant MAX_SUPPLY = 888;

    /// The maximum number of minted tokens per address.
    uint256 public constant MAX_USER_MINT = 2;

    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 1000; // 10%

    /// The token name.
    string public name;

    /// The token symbol.
    string public symbol;

    /// The current token supply.
    uint256 public totalSupply;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// The token sale state (0=Paused, 1=Open).
    SaleState public saleState;

    /// The address of the OpenSea proxy registry contract.
    address public proxyRegistry;

    /// The address which signs the mint coupons.
    address public couponSigner;

    /// Whether an address has revoked the automatic OpenSea proxy approval.
    mapping(address => bool) public userRevokedRegistryApproval;

    /// The total tokens minted by an address.
    mapping(address => uint256) public userMinted;

    /// Reverts if the current sale state is not `_saleState`.
    modifier onlyInSaleState(SaleState _saleState) {
        if (saleState != _saleState) revert SalePhaseNotActive();
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
        address _couponSigner,
        string memory _contractURI,
        string memory _baseURI,
        address _proxyRegistry,
        address _royaltiesReceiver,
        uint256 _royaltiesPercent
    )
        ERC1155(_baseURI)
    {
        name = _name;
        symbol = _symbol;
        couponSigner = _couponSigner;
        contractURI = _contractURI;
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
    function mint(
        uint256 _mintAmount,
        bytes calldata _signature
    )
        external
        onlyInSaleState(SaleState.Open)
        onlyWithValidSignature(_signature, SaleState.Open)
    {
        unchecked {
            userMinted[_msgSender()] += _mintAmount;
        }
        if (userMinted[_msgSender()] > MAX_USER_MINT)
            revert ExceedsMintPhaseAllocation();

        _doMint(_mintAmount);
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
     * @notice (only owner) Mints `_mintAmount` tokens.
     * @param _mintAmount The number of tokens to mint.
     */
    function mintPromo(
        uint256 _mintAmount
    )
        external
        onlyOwner
    {
        _doMint(_mintAmount);
    }

    /**
     * @notice (only owner) Sets the saleState to `_newSaleState`.
     * @param _newSaleState The new sale state
     * (0=Paused, 1=Open).
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
     * @notice (only owner) Sets the token URI for token metadata.
     * @param _newURI The new URI.
     */
    function setURI(
        string calldata _newURI
    )
        external
        onlyOwner
    {
        _setURI(_newURI);
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
        override
        returns (bool)
    {
        if (!userRevokedRegistryApproval[_owner]) {
            OpenSeaProxyRegistry reg = OpenSeaProxyRegistry(proxyRegistry);
            if (address(reg.proxies(_owner)) == _operator) return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC1155, ERC2981Base)
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
     * @notice Mints `_mintAmount` tokens to the caller.
     * @param _mintAmount The number of tokens to mint.
     */
    function _doMint(
        uint256 _mintAmount
    )
        internal
    {
        unchecked {
            totalSupply += _mintAmount;
        }
        if (totalSupply > MAX_SUPPLY) revert ExceedsMaxSupply();

        _mint(_msgSender(), 0, _mintAmount, "");
    }
}

/// Stub for OpenSea's per-user-address proxy contract.
contract OwnableDelegateProxy {}

/// Stub for OpenSea's proxy registry contract.
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}