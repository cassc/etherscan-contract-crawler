// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MetaMotorsToken.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MetaMotorsSales is AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    //Max token supply
    uint256 public constant TOTAL_MINT_ALLOCATION = 3260;

    //Price
    uint256[] public tierPriceArray;

    mapping(string => bool) private _processedOrderIds;

    //Address of order signer
    address private _orderSigner;

    //Token contract
    MetaMotorsToken private metaMotorsToken;

    constructor(
        MetaMotorsToken metaMotorsTokenAddress,
        uint256[] memory initialTierPriceArray
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        metaMotorsToken = MetaMotorsToken(metaMotorsTokenAddress);
        tierPriceArray = initialTierPriceArray;
    }

    modifier hasSupply(uint256 quantity) {
        require(
            metaMotorsToken.getTotalMinted() + quantity <=
                TOTAL_MINT_ALLOCATION,
            "Not enough left to mint"
        );
        _;
    }

    /**
     * @dev Update the price for a tier
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setTierPricing(uint256 tierIndex, uint256 tierPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tierIndex < tierPriceArray.length, "Index out of bounds");
        tierPriceArray[tierIndex] = tierPrice;
    }

    /**
     * @dev Update the order signer address with `signer`
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setOrderSigner(address signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _orderSigner = signer;
    }

    /**
     * @dev Validate an order id is signed by the order signer address
     */
    function _isValidOrder(
        string memory orderId,
        uint256 tier,
        uint256 quantity,
        address sender,
        bytes memory signature
    ) internal view returns (bool isValid) {
        bytes32 messagehash = keccak256(
            abi.encodePacked(orderId, tier, quantity, sender)
        );
        address signer = messagehash.toEthSignedMessageHash().recover(
            signature
        );
        return signer == _orderSigner;
    }

    /**
     * @dev mint `quantity` to msg sender
     *
     * Requirements:
     *
     * - order request is valid
     * - price is valid
     */
    function mintMetaMotors(
        string memory orderId,
        uint256 tierIndex,
        uint256 quantity,
        bytes memory signature
    ) external payable nonReentrant hasSupply(quantity) {
        require(
            _isValidOrder(
                orderId,
                tierIndex,
                quantity,
                _msgSender(),
                signature
            ),
            "Invaild order"
        );
        require(
            msg.value == quantity * tierPriceArray[tierIndex],
            "Invalid price"
        );
        require(
            _processedOrderIds[orderId] == false,
            "Order id already processed"
        );

        metaMotorsToken.mint(_msgSender(), quantity);
        _processedOrderIds[orderId] = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Widthraw balance on contact to msg sender
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function withdrawMoney() external onlyRole(DEFAULT_ADMIN_ROLE) {
        address payable to = payable(_msgSender());
        to.transfer(address(this).balance);
    }
}