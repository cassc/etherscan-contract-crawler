// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/MediaEyeOrders.sol";
import "./interfaces/IMinter.sol";

contract MediaEyeMarketplaceInfo is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using MediaEyeOrders for MediaEyeOrders.Royalty;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_SETTER = keccak256("ROLE_SETTER");

    EnumerableSet.AddressSet private paymentMethods;
    mapping(address => address) public chainlinkAggregator;

    uint256 public maxRoyaltyBasisPoint;

    mapping(address => mapping(uint256 => MediaEyeOrders.Royalty))
        public royalties;
    mapping(address => mapping(uint256 => bool)) public sold;

    event RoyaltySet(
        address nftTokenAddresses,
        uint256 nftTokenIds,
        address recipient,
        uint256 royaltyAmount
    );

    event PaymentAdded(address paymentMethod);

    event PaymentRemoved(address paymentMethod);

    modifier onlyAdmin() {
        require(
            hasRole(ROLE_ADMIN, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "admin"
        );
        _;
    }

    modifier onlySetter() {
        require(hasRole(ROLE_SETTER, msg.sender), "setter");
        _;
    }

    /**
     * @dev Constructor
     *
     * Params:
     * _owner: address of the owner
     * _admins: addresses of initial admins
     * _setters: addresses of marketplace setters
     * _paymentMethods: initial payment methods to accept
     * _maxRoyaltyBasisPoint: max allowed for royalty
     */
    constructor(
        address _owner,
        address[] memory _admins,
        address[] memory _setters,
        address[] memory _paymentMethods,
        uint256 _maxRoyaltyBasisPoint
    ) {
        require(_maxRoyaltyBasisPoint <= 2500, "Max royalties");

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        for (uint256 i = 0; i < _admins.length; i++) {
            _setupRole(ROLE_ADMIN, _admins[i]);
        }
        for (uint256 i = 0; i < _setters.length; i++) {
            _setupRole(ROLE_SETTER, _setters[i]);
        }
        _setRoleAdmin(ROLE_SETTER, ROLE_ADMIN);
        for (uint256 i = 0; i < _paymentMethods.length; i++) {
            paymentMethods.add(_paymentMethods[i]);
        }
        maxRoyaltyBasisPoint = _maxRoyaltyBasisPoint;
    }

    /**
     * @dev Add single payment method
     *
     * Params:
     * _paymentMethod: the payment method to add
     */
    function addPaymentMethod(address _paymentMethod) external onlyAdmin {
        require(!paymentMethods.contains(_paymentMethod), "Payment method");
        paymentMethods.add(_paymentMethod);
        emit PaymentAdded(_paymentMethod);
    }

    /**
     * @dev Removes single payment method
     *
     * Params:
     * _paymentMethod: the payment method to remove
     */
    function removePaymentMethod(address _paymentMethod) external onlyAdmin {
        require(paymentMethods.contains(_paymentMethod), "Payment method");
        paymentMethods.remove(_paymentMethod);
        emit PaymentRemoved(_paymentMethod);
    }

    /**
     * @dev updates the maximum royalty percentage that artists can set
     *
     * Params:
     * _basisPoint: basis point, must be less than 2500 (25%)
     */
    function updateMaxRoyaltyBasisPoint(uint256 _basisPoint)
        external
        onlyAdmin
    {
        require(_basisPoint <= 2500, "Max royalties");
        maxRoyaltyBasisPoint = _basisPoint;
    }

    /********************** Get Functions ********************************/

    // Get number of listings
    function getNumPaymentMethods() external view returns (uint256) {
        return paymentMethods.length();
    }

    // Get if is payment method
    function isPaymentMethod(address _paymentMethod)
        external
        view
        returns (bool)
    {
        return paymentMethods.contains(_paymentMethod);
    }

    /**
     * @dev gets royalties for existing erc721/1155
     *
     * Params:
     * _nftTokenAddress: address of token to list
     * _nftTokenId: id of token
     */
    function getRoyalty(address _nftTokenAddress, uint256 _nftTokenId)
        external
        view
        returns (MediaEyeOrders.Royalty memory)
    {
        return royalties[_nftTokenAddress][_nftTokenId];
    }

    // get sold
    /**
     * @dev Gets sold status for existing erc721/1155
     *
     * Params:
     * _nftTokenAddress: address of token to list
     * _nftTokenId: id of token
     */
    function getSoldStatus(address _nftTokenAddress, uint256 _nftTokenId)
        external
        view
        returns (bool)
    {
        return sold[_nftTokenAddress][_nftTokenId];
    }

    /**
     * @dev Sets royalties for existing erc721/1155
     *
     * Params:
     * _nftTokenAddress: address of token to list
     * _nftTokenId: id of token
     * _royalty: royalty amount for secondary sales (creator only)
     */
    function setRoyalty(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        uint256 _royalty,
        address _caller
    ) external onlySetter {
        require(_royalty <= maxRoyaltyBasisPoint, "max royalty");
        require(!sold[_nftTokenAddress][_nftTokenId], "sold");
        address minter = IMinter(_nftTokenAddress).getCreator(_nftTokenId);
        require(minter == _caller, "minter only");
        royalties[_nftTokenAddress][_nftTokenId] = MediaEyeOrders.Royalty(
            payable(minter),
            _royalty
        );

        emit RoyaltySet(_nftTokenAddress, _nftTokenId, minter, _royalty);
    }

    /**
     * @dev Sets sold status for existing erc721/1155
     *
     * Params:
     * _nftTokenAddress: address of token to list
     * _nftTokenId: id of token
     */
    function setSoldStatus(address _nftTokenAddress, uint256 _nftTokenId)
        external
        onlySetter
    {
        require(!sold[_nftTokenAddress][_nftTokenId], "sold");
        sold[_nftTokenAddress][_nftTokenId] = true;
    }
}