// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./lib/WattsBurnerUpgradable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Slotieverse is WattsBurnerUpgradable, PausableUpgradeable {
    mapping(uint256 => uint256) public ammoPrice;
    uint256 public juniorNameChangePrice;
    address public slotieJuniorAddress;

    event BuyAmmo(address indexed buyer, uint256 indexed ammoId, uint256 indexed amount, uint256 wattsBurned);
    event AddAmmoIdEvent(address indexed sender, uint256 indexed ammoId, uint256 indexed ammoPrice, bytes32 identifier);
    event UpdateAmmoIdEvent(address indexed sender, uint256 indexed ammoId, uint256 indexed ammoPrice, bytes32 identifier);
    event RemoveAmmoIdEvent(address indexed sender, uint256 indexed ammoId, bytes32 identifier);

    event ChangeJuniorName(address indexed buyer, uint256 indexed juniorId, string newName, uint256 indexed burnFee);

    constructor(address[] memory _admins, address _watts, address _transferExtender)
    WattsBurnerUpgradable(_admins, _watts, _transferExtender) {}

    modifier validAmmo(uint256 ammoId) {
        require(ammoPrice[ammoId] > 0, "Invalid ammo Id");
        _;
    }

    function initialize(address[] memory _admins, address _watts, address _transferExtender) public initializer {
       watts_burner_initialize(_admins, _watts, _transferExtender);
       __Pausable_init();
    }

    function onUpgrade(
        address _slotieJuniorAddress,
        uint256 _juniorNameChangePrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        slotieJuniorAddress = _slotieJuniorAddress;
        juniorNameChangePrice = _juniorNameChangePrice;
    }

    function PurchaseAmmo(uint256 ammoId, uint256 amount) external whenNotPaused() validAmmo(ammoId) {
        uint256 burnFee = ammoPrice[ammoId] * amount;
        _burnWatts(burnFee);
        emit BuyAmmo(msg.sender, ammoId, amount, burnFee);
    }

    function PurchaseNameChange(
        uint256 slotieJuniorTokenId,
        string memory newName
    ) external whenNotPaused() {
        require(IERC721(slotieJuniorAddress).ownerOf(slotieJuniorTokenId) == msg.sender, "Sender does not own the specified junior");
        uint256 burnFee = juniorNameChangePrice;
        _burnWatts(burnFee);
        emit ChangeJuniorName(msg.sender, slotieJuniorTokenId, newName, burnFee);
    }

    function AddAmmoId(uint256 ammoId, uint256 price, bytes32 identifier) external onlyRole(GameAdminRole) {
        require(ammoPrice[ammoId] == 0, "Ammo ID already registered. Please call update function");
        ammoPrice[ammoId] = price;
        emit AddAmmoIdEvent(msg.sender, ammoId, price, identifier);        
    }

    function UpdateAmmoId(uint256 ammoId, uint256 price, bytes32 identifier) external onlyRole(GameAdminRole) validAmmo(ammoId) {
        require(price > 0, "Price cannot be zero. Please call delete function");
        ammoPrice[ammoId] = price;
        emit UpdateAmmoIdEvent(msg.sender, ammoId, price, identifier);        
    }

    function DeleteAmmoId(uint256 ammoId, bytes32 identifier) external onlyRole(GameAdminRole) validAmmo(ammoId) {
        delete ammoPrice[ammoId];
        emit RemoveAmmoIdEvent(msg.sender, ammoId, identifier);        
    }

    function ChangeJuniorNameChangePrice(uint256 newPrice) external onlyRole(GameAdminRole) {
        juniorNameChangePrice = newPrice;
    }

    function pauseContract() external onlyRole(GameAdminRole) {
        _pause();
    }

    function unpauseContract() external onlyRole(GameAdminRole) {
        _unpause();
    }
}