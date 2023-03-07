// contracts/TokenMT760.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetFixedSupplyUpgradeable.sol";

contract TokenMT760 is
    OwnableUpgradeable,
    ERC20PresetFixedSupplyUpgradeable //ERC1404
{
    uint256 public constant MAX_SUPPLY = 10e12 ether;
    uint8 public constant DECIMALS_DECENT = 4;

    address private _issuer; // _issuer: Assign / Revoke Admin + Everything Below
    bool private _paused;
    uint256 _max_transfer_value;

    mapping(uint8 => string) public restrictionMap;

    mapping(address => bool) whiteList;
    // mapping(address => bool) blackList;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);

    function initialize(address _issuerAddress) external initializer {
        _issuer = _issuerAddress;
        restrictionMap[0] = "SUCCESS";
        restrictionMap[1] = "MT760 token is pausing";
        //  restrictionMap[2] = "sender has been banned";
        //  restrictionMap[3] = "receiver has been banned";
        restrictionMap[2] = "sender not in whitelist";
        restrictionMap[3] = "receiver not in whitelist";
        restrictionMap[4] = "max transfer value exceeded";
        _paused = false;
        _max_transfer_value = 0;

        __Ownable_init();
        __ERC20PresetFixedSupply_init(
            "MT760",
            "MT760",
            MAX_SUPPLY,
            _issuerAddress
        );
        emit Initialized(msg.sender, block.number);
    }

    modifier notRestricted(
        address from,
        address to,
        uint256 value
    ) {
        uint8 restrictionCode = _detectTransferRestriction(from, to, value);
        require(restrictionCode == 0, _messageForTransferRestriction(restrictionCode));
        _;
    }

    modifier onlyAdminOrIssuer() {
        require(msg.sender == owner() || msg.sender == _issuer, "Permission denied");
        _;
    }

    function addToWhitelist(address addr) external onlyAdminOrIssuer {
        require(!whiteList[addr], "address already in whiteList");
        whiteList[addr] = true;
    }

    function deleteFromWhitelist(address addr) external onlyAdminOrIssuer {
        require(whiteList[addr], "address not in whiteList");
        whiteList[addr] = false;
    }

    function setPause(bool value) external onlyAdminOrIssuer {
        require(_paused != value, "paused not changed");
        _paused = value;
    }

    function getIssuer() external view returns (address) {
        return _issuer;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override notRestricted(from, to, value) returns (bool success) {
        success = super.transferFrom(from, to, value);
    }

    function transfer(
        address to,
        uint256 value
    ) public override notRestricted(msg.sender, to, value) returns (bool success) {
        success = super.transfer(to, value);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS_DECENT;
    }

    function _messageForTransferRestriction(
        uint8 restrictionCode
    ) private view returns (string memory message) {
        if (bytes(restrictionMap[restrictionCode]).length == 0) {
            message = "unused";
            //incorrect!"; unused restriction code
        } else {
            message = restrictionMap[restrictionCode];
        }
    }

    function _detectTransferRestriction(
        address from,
        address to,
        uint256 value
    ) private view returns (uint8 restrictionCode) {
        if (_paused) {
            restrictionCode = 1;
        } else if (!whiteList[from]) {
            restrictionCode = 2;
        } else if (!whiteList[to]) {
            restrictionCode = 3;
        } else if (_max_transfer_value > 0 && _max_transfer_value < value) {
            restrictionCode = 4;
        } else {
            restrictionCode = 0;
        }
    }
}