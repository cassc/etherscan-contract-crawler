// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IInbox.sol";


interface IOutbox {
    function l2ToL1Sender() external view returns (address);
}

interface IBridge {
    function activeOutbox() external view returns (address);
}


contract L1Gateway is
    Initializable,  // initializer
    ContextUpgradeable,  // _msgSender, _msgData
    ERC165Upgradeable,  // supportsInterface
    AccessControlUpgradeable,  // RBAC
    AccessControlEnumerableUpgradeable,  // RBAC enumeration
    ERC1967UpgradeUpgradeable,  // delegate slots, proxy admin, private upgrade
    UUPSUpgradeable  // public upgrade
{
    // in case we add more contracts in the inheritance chain
    uint256[500] private __gap0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // initializes the logic contract without any admins
    // safeguard against takeover of the logic contract
    constructor() initializer {}

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only admin");
        _;
    }

//-------------------------------- Overrides start --------------------------------//

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, AccessControlUpgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _grantRole(bytes32 role, address account) internal virtual override(AccessControlUpgradeable, AccessControlEnumerableUpgradeable) {
        super._grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override(AccessControlUpgradeable, AccessControlEnumerableUpgradeable) {
        super._revokeRole(role, account);

        // protect against accidentally removing all admins
        require(getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0, "Cannot be adminless");
    }

    function _authorizeUpgrade(address /*account*/) onlyAdmin internal view override {}

//-------------------------------- Overrides end --------------------------------//

//-------------------------------- Initializer start --------------------------------//

    uint256[50] private __gap1;

    function initialize(
        address _inbox,
        address _tokenL1,
        address _gatewayL2
    ) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setInbox(_inbox);
        _setTokenL1(_tokenL1);
        _setGatewayL2(_gatewayL2);
    }

//-------------------------------- Initializer end --------------------------------//

//-------------------------------- Gateway start --------------------------------//

    IInbox public inbox;
    IERC20 public tokenL1;
    address public gatewayL2;
    address public outbox;

    uint256[46] private __gap2;

    event InboxChanged(address indexed _oldInbox, address indexed _newInbox);
    event TokenL1Changed(address indexed _oldTokenL1, address indexed _newTokenL1);
    event GatewayL2Changed(address indexed _oldGatewayL2, address indexed _newGatewayL2);
    event OutboxChanged(address indexed _oldOutbox, address indexed _newOutbox);

    event TransferL2(
        uint256 indexed ticketId,
        address indexed from,
        address indexed to,
        uint256 tokenAmount,
        uint256 ethAmount
    );

    event TransferL1(
        address indexed to,
        uint256 amount
    );

    function setInbox(address _newInbox) onlyAdmin external {
        _setInbox(_newInbox);
    }

    function _setInbox(address _newInbox) internal {
        address _oldInbox = address(inbox);
        inbox = IInbox(_newInbox);

        emit InboxChanged(_oldInbox, _newInbox);
    }

    function setTokenL1(address _newTokenL1) onlyAdmin external {
        _setTokenL1(_newTokenL1);
    }

    function _setTokenL1(address _newTokenL1) internal {
        address _oldTokenL1 = address(tokenL1);
        tokenL1 = IERC20(_newTokenL1);

        emit TokenL1Changed(_oldTokenL1, _newTokenL1);
    }

    function setGatewayL2(address _newGatewayL2) onlyAdmin external {
        _setGatewayL2(_newGatewayL2);
    }

    function _setGatewayL2(address _newGatewayL2) internal {
        address _oldGatewayL2 = gatewayL2;
        gatewayL2 = _newGatewayL2;

        emit GatewayL2Changed(_oldGatewayL2, _newGatewayL2);
    }

    function setOutbox(address _newOutbox) onlyAdmin external {
        _setOutbox(_newOutbox);
    }

    function _setOutbox(address _newOutbox) internal {
        address _oldOutbox = outbox;
        outbox = _newOutbox;

        emit OutboxChanged(_oldOutbox, _newOutbox);
    }

    modifier onlyOutbox() {
        require(_msgSender() == outbox, "only outbox");
        _;
    }

    function transferL2(
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) external payable returns (uint256) {
        tokenL1.transferFrom(_msgSender(), address(this), _amount);

        bytes memory _data = abi.encodeWithSignature(
            "transferL2(address,uint256)",
            _to,
            _amount
        );
        uint256 _ticketId = inbox.createRetryableTicket{ value: msg.value }(
            // send msg to corresponding gateway on L2
            gatewayL2,
            // do not need to send eth to gateway
            0,
            // send all eth minus gas as submission cost, excess will be refunded
            msg.value - _maxGas * _gasPriceBid,
            // all refunds and ticket ownership to _to
            _to,
            _to,
            _maxGas,
            _gasPriceBid,
            _data
        );

        emit TransferL2(
            _ticketId,
            _msgSender(),
            _to,
            _amount,
            msg.value
        );

        return _ticketId;
    }

    function transferL1(
        address _to,
        uint256 _amount
    ) external onlyOutbox returns (bool) {
        require(IOutbox(IBridge(_msgSender()).activeOutbox()).l2ToL1Sender() == gatewayL2, "only l2 gateway");

        tokenL1.transfer(_to, _amount);
        emit TransferL1(_to, _amount);
        return true;
    }

    function withdraw() onlyAdmin public {
        uint256 _balance = tokenL1.balanceOf(address(this));
        tokenL1.transfer(_msgSender(), _balance);
        payable(_msgSender()).transfer(address(this).balance);
    }

//-------------------------------- Gateway end --------------------------------//
}