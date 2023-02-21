// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Discounter is AccessControl, Ownable, Pausable {

    bytes32 public constant ADMIN = "ADMIN";

    struct Discount {
        address conditionCollection;
        uint256 discountRate;
    }

    // ==================================================
    // Variables
    // ==================================================
    // ticket => condition collection(only ERC721) => discountRate(100% = 10000)
    mapping(address => mapping(uint256 => Discount)) public discountRate;

    // ==================================================
    // constractor
    // ==================================================
    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    // ==================================================
    // Functions for discount
    // ==================================================
    function discount(address ticketAddress, uint256 id, uint256 cost, address buyer)
        external view returns(uint256)
    {
        Discount memory discountInfo = discountRate[ticketAddress][id];

        if(discountInfo.conditionCollection == address(0)) {
            return cost;
        } else {
            if(IERC721(discountInfo.conditionCollection).balanceOf(buyer) > 0){
                return cost * (10000 - discountInfo.discountRate) / 10000;
            } else {
                return cost;
            }
        }
    }

    // ==================================================================
    // for organizer operation
    // ==================================================================
    modifier onlyCollectionOwnerOrAdmin(address ticketAddress) {
        require(
            Ownable(ticketAddress).owner() == msg.sender ||
                hasRole(ADMIN, msg.sender),
            "not owner or admin."
        );
        _;
    }

    function setDiscount(
        address ticketAddress,
        uint256 id,
        address conditionCollection,
        uint256 rate
    ) external onlyCollectionOwnerOrAdmin(ticketAddress) whenNotPaused {
        require(rate <= 10000, "discount rate is over 100%");
        discountRate[ticketAddress][id] = Discount(conditionCollection, rate);
    }

    function setContractPause(bool value) external onlyRole(ADMIN) {
        if (value) {
            _pause();
        } else {
            _unpause();
        }
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