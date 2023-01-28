// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "../tokens/IFungibleSBT.sol";
import "./EnumerableSalesSet.sol";
import "../wallet/IWallet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketSeller is ReentrancyGuard, AccessControl, Ownable {
    using Address for address payable;
    using BitMaps for BitMaps.BitMap;
    using EnumerableSalesSet for EnumerableSalesSet.Set;

    event Bought(
        address indexed collection,
        uint256 indexed id,
        address indexed buyer,
        uint256 amount
    );

    event Repayment(
        address indexed collection,
        uint256 indexed id,
        address indexed buyer,
        uint256 amount
    );

    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant ACCOUNTANT = "ACCOUNTANT";

    // ==================================================
    // Variables
    // ==================================================
    mapping(address => mapping(uint256 => uint256)) public cost;
    mapping(address => mapping(uint256 => uint256)) public salesAmount;
    mapping(address => mapping(uint256 => EnumerableSalesSet.Set))
        private _salesSet;
    mapping(address => BitMaps.BitMap) private _paused;
    mapping(address => BitMaps.BitMap) private _isCompleteAccount;
    IWallet public wallet;

    // ==================================================
    // constractor
    // ==================================================
    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    // ==================================================
    // Functions for sale
    // ==================================================
    modifier whenNotPaused(address collection, uint256 id) {
        require(_paused[collection].get(id) == false, "paused.");
        _;
    }

    modifier enoughEth(address collection, uint256 id) {
        require(msg.value >= cost[collection][id], "not enough eth.");
        _;
    }

    function buy(address collection, uint256 id)
        external
        payable
        whenNotPaused(collection, id)
        enoughEth(collection, id)
    {
        IFungibleSBT(collection).mint(msg.sender, id);

        if (_isCompleteAccount[collection].get(id)) {
            _account(payable(IFungibleSBT(collection).owner()), msg.value);
        } else {
            _escrow(collection, id);
        }

        emit Bought(address(collection), id, msg.sender, msg.value);
    }

    function _escrow(address collection, uint256 id) private {
        salesAmount[collection][id] += msg.value;
        _salesSet[collection][id].add(
            EnumerableSalesSet.Sales(msg.sender, msg.value)
        );
    }

    function _account(address payable organizer, uint256 amount)
        private
        nonReentrant
    {
        wallet.account{value: amount}(organizer);
    }

    modifier notCompleteAccount(address collection, uint256 id) {
        require(
            _isCompleteAccount[collection].get(id) == false,
            "the account is already complete."
        );
        _;
    }

    // ==================================================================
    // for accountant operation
    // ==================================================================
    function account(address collection, uint256 id)
        external
        onlyRole(ACCOUNTANT)
        notCompleteAccount(collection, id)
    {
        _isCompleteAccount[collection].set(id);

        _account(
            payable(IFungibleSBT(collection).owner()),
            salesAmount[collection][id]
        );

        delete salesAmount[collection][id];
        delete _salesSet[collection][id];
    }

    modifier onlyOrganizorOrAccountant(address collection) {
        require(
            msg.sender == IFungibleSBT(collection).owner() ||
                hasRole(ACCOUNTANT, msg.sender),
            "you are not organizer or accountant."
        );
        _;
    }

    function repayment(
        address collection,
        uint256 id,
        uint256 maxIndex
    )
        external
        onlyOrganizorOrAccountant(collection)
        notCompleteAccount(collection, id)
        nonReentrant
    {
        _paused[collection].setTo(id, true);

        EnumerableSalesSet.Sales[] memory sales = _salesSet[collection][id]
            .values();
        for (uint256 i = 0; i < maxIndex && i < sales.length; i++) {
            _salesSet[collection][id].remove(sales[i]);
            salesAmount[collection][id] -= sales[i].amount;
            payable(sales[i].buyer).sendValue(sales[i].amount);

            emit Repayment(collection, id, sales[i].buyer, sales[i].amount);
        }
    }

    function getSales(address collection, uint256 id)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        EnumerableSalesSet.Sales[] memory sales = _salesSet[collection][id]
            .values();

        address[] memory buyers = new address[](sales.length);
        uint256[] memory amounts = new uint256[](sales.length);

        for (uint256 i = 0; i < sales.length; i++) {
            buyers[i] = sales[i].buyer;
            amounts[i] = sales[i].amount;
        }

        return (buyers, amounts);
    }

    // ==================================================================
    // for organizer operation
    // ==================================================================
    modifier onlyCollectionOwner(address collection) {
        require(IFungibleSBT(collection).owner() == msg.sender, "not owner.");
        _;
    }

    function setCost(
        address collection,
        uint256 id,
        uint256 value
    ) external onlyCollectionOwner(collection) {
        uint256 nextId = IFungibleSBT(collection).nextId();
        require(id <= nextId, "invalid id.");

        cost[collection][id] = value;

        if (id == nextId) {
            IFungibleSBT(collection).add();
            IFungibleSBT(collection).mint(msg.sender, id);
        }
    }

    function pause(
        address collection,
        uint256 id,
        bool isPaused
    ) external onlyCollectionOwner(collection) {
        _paused[collection].setTo(id, isPaused);
    }

    function paused(address collection, uint256 id)
        external
        view
        returns (bool)
    {
        return _paused[collection].get(id);
    }

    // ==================================================================
    // for admin operations
    // ==================================================================
    function setWallet(address value) external onlyRole(ADMIN) {
        wallet = IWallet(value);
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 role, address target) public override onlyOwner {
        _grantRole(role, target);
    }

    function revokeRole(bytes32 role, address target)
        public
        override
        onlyOwner
    {
        _revokeRole(role, target);
    }
}