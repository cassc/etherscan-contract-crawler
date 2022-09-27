// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "solady/src/auth/OwnableRoles.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./interfaces/IBaseCollection.sol";
import "./interfaces/INiftyKit.sol";

abstract contract BaseCollection is
    OwnableRoles,
    ContextUpgradeable,
    ERC2981Upgradeable,
    IBaseCollection
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 public constant ADMIN_ROLE = 1 << 0;
    uint256 public constant MANAGER_ROLE = 1 << 1;
    uint256 public constant BURNER_ROLE = 1 << 2;

    INiftyKit internal _niftyKit;
    address internal _treasury;
    uint256 internal _totalRevenue;

    // Operators
    mapping(address => bool) internal _allowedOperators;
    mapping(address => bool) internal _blockedOperators;

    function __BaseCollection_init(
        address owner_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) internal onlyInitializing {
        _initializeOwner(owner_);
        __ERC2981_init();

        _niftyKit = INiftyKit(_msgSender());
        _treasury = treasury_;
        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function withdraw() external {
        require(address(this).balance > 0, "0 balance");

        INiftyKit niftyKit = _niftyKit;
        uint256 balance = address(this).balance;
        uint256 fees = niftyKit.getFees(address(this));
        niftyKit.addFeesClaimed(fees);
        AddressUpgradeable.sendValue(payable(address(niftyKit)), fees);
        AddressUpgradeable.sendValue(payable(_treasury), balance.sub(fees));
    }

    function setTreasury(address newTreasury)
        external
        onlyRolesOrOwner(ADMIN_ROLE)
    {
        _treasury = newTreasury;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRolesOrOwner(ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setAllowedOperator(address operator, bool allowed)
        external
        onlyRolesOrOwner(MANAGER_ROLE)
    {
        _allowedOperators[operator] = allowed;
        emit OperatorAllowed(operator, allowed);
    }

    function setBlockedOperator(address operator, bool blocked)
        external
        onlyRolesOrOwner(MANAGER_ROLE)
    {
        _blockedOperators[operator] = blocked;
        emit OperatorBlocked(operator, blocked);
    }

    function isAllowedOperator(address operator) external view returns (bool) {
        return _allowedOperators[operator];
    }

    function isBlockedOperator(address operator) external view returns (bool) {
        return _blockedOperators[operator];
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function totalRevenue() external view returns (uint256) {
        return _totalRevenue;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IBaseCollection).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}