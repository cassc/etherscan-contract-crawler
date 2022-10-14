// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/security/PausableUpgradeable.sol";
import {IERC721} from "@oz/token/ERC721/IERC721.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";
import {IBeepBoop} from "./interfaces/IBeepBoop.sol";

contract ProxyYield is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IBeepBoop public beepBoop;
    IBattleZone public battleZone;
    mapping(address => uint256) public _accumulatedAmount;
    mapping(address => bool) private _authorised;

    event Yield(address indexed userAddress, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address beepBoop_, address _staking)
        external
        initializer
    {
        beepBoop = IBeepBoop(beepBoop_);
        battleZone = IBattleZone(_staking);
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    modifier onlyAuthorised() {
        require(_authorised[msg.sender], "Not authorised!");
        _;
    }

    function yield() public whenNotPaused {
        uint256 accumulatedAmount = battleZone.getAccumulatedAmount(msg.sender);
        uint256 netYield = accumulatedAmount - _accumulatedAmount[msg.sender];
        _accumulatedAmount[msg.sender] = accumulatedAmount;
        beepBoop.depositBeepBoopFor(msg.sender, netYield);
        emit Yield(msg.sender, netYield);
    }

    function getAccumulatedAmount(address _user) public view returns (uint256) {
        return
            battleZone.getAccumulatedAmount(_user) - _accumulatedAmount[_user];
    }

    function authorise(address address_, bool toggle) public onlyOwner {
        _authorised[address_] = toggle;
    }

    function changeBattleZoneContract(address battleZone_) public onlyOwner {
        battleZone = IBattleZone(battleZone_);
    }

    function pause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}