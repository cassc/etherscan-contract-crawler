// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC721PresetMinterPauserAutoIdUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol';

import {IAddressProvider} from '../interfaces/IAddressProvider.sol';
import {IDegenopolyNodeManager} from '../interfaces/IDegenopolyNodeManager.sol';

contract DegenopolyNode is ERC721PresetMinterPauserAutoIdUpgradeable {
    /* ======== STORAGE ======== */

    struct RewardInfo {
        uint256 pending;
        uint256 debt;
    }

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice color family
    string public color;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @notice degenopoly reward per second
    uint256 public rewardPerSec;

    /// @notice purchase price in degenopoly
    uint256 public purchasePrice;

    /// @dev reward accTokenPerShare
    uint256 private accTokenPerShare;

    /// @dev reward lastUpdate
    uint256 private lastUpdate;

    /// @dev mapping account => reward info
    mapping(address => RewardInfo) private rewardInfoOf;
    
    /// @dev new owner
    address newOwner;

    /* ======== ERRORS ======== */

    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error NOT_MANAGER();

    /* ======== EVENTS ======== */

    event AddressProvider(address addressProvider);
    event PurchasePrice(uint256 purchasePrice);
    event NewOwner(address newOwner);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize1(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _color,
        address _addressProvider,
        uint256 _rewardPerSec,
        uint256 _purchasePrice
    ) external initializer {
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();
        if (_rewardPerSec == 0 || _purchasePrice == 0) revert ZERO_AMOUNT();

        // color family
        color = _color;

        // set address provider
        addressProvider = IAddressProvider(_addressProvider);
        _setupRole(MINTER_ROLE, addressProvider.getDegenopolyNodeManager());
        _setupRole(MINTER_ROLE, addressProvider.getDegenopolyPlayBoard());

        // reward per second
        rewardPerSec = _rewardPerSec;

        // purchase price
        purchasePrice = _purchasePrice;

        // init
        __ERC721PresetMinterPauserAutoId_init(_name, _symbol, _baseTokenURI);
    }

    /* ======== MODIFIERS ======== */

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyManager() {
        if (msg.sender != addressProvider.getDegenopolyNodeManager())
            revert NOT_MANAGER();
        _;
    }

    modifier update() {
        if (totalSupply() > 0) {
            accTokenPerShare +=
                (rewardPerSec * (block.timestamp - lastUpdate)) /
                totalSupply();
        }
        lastUpdate = block.timestamp;

        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();

        addressProvider = IAddressProvider(_addressProvider);

        emit AddressProvider(_addressProvider);
    }

    function setPurchasePrice(uint256 _purchasePrice) external onlyOwner {
        if (_purchasePrice == 0) revert ZERO_AMOUNT();

        purchasePrice = _purchasePrice;

        emit PurchasePrice(_purchasePrice);
    }

    function setNewOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;        
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);

        emit NewOwner(_newOwner);
    }
    /* ======== MANAGER FUNCTIONS ======== */

    function syncReward(address _account) external onlyManager update {
        RewardInfo storage rewardInfo = _updateReward(_account);
        rewardInfo.debt = accTokenPerShare * balanceOf(_account);
    }

    function claimReward(
        address _account
    ) external onlyManager update returns (uint256 pending) {
        // update reward
        RewardInfo storage rewardInfo = _updateReward(_account);
        rewardInfo.debt = accTokenPerShare * balanceOf(_account);

        // claim
        pending = rewardInfo.pending;
        rewardInfo.pending = 0;
    }

    /* ======== VIEW FUNCTIONS ======== */

    function claimableReward(
        address _account
    ) external view returns (uint256 pending) {
        // reward multiplier
        uint256 multiplier = IDegenopolyNodeManager(
            addressProvider.getDegenopolyNodeManager()
        ).getMultiplierFor(_account);

        // update reward
        uint256 accTokenPerShare_ = accTokenPerShare;
        if (totalSupply() > 0) {
            accTokenPerShare_ +=
                (rewardPerSec * (block.timestamp - lastUpdate)) /
                totalSupply();
        }
        RewardInfo storage rewardInfo = rewardInfoOf[_account];

        // pending
        pending =
            rewardInfo.pending +
            ((accTokenPerShare_ * balanceOf(_account) - rewardInfo.debt) *
                multiplier) /
            MULTIPLIER;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _batchSize
    ) internal virtual override update {
        super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);

        if (_from != address(0)) {
            RewardInfo storage rewardInfo = _updateReward(_from);
            rewardInfo.debt = accTokenPerShare * (balanceOf(_from) - 1);
        }

        if (_to != address(0)) {
            RewardInfo storage rewardInfo = _updateReward(_to);
            rewardInfo.debt = accTokenPerShare * (balanceOf(_to) + 1);
        }
    }

    function _updateReward(
        address _account
    ) internal returns (RewardInfo storage rewardInfo) {
        if (_account == address(0)) revert ZERO_ADDRESS();

        uint256 multiplier = IDegenopolyNodeManager(
            addressProvider.getDegenopolyNodeManager()
        ).getMultiplierFor(_account);

        rewardInfo = rewardInfoOf[_account];
        rewardInfo.pending +=
            ((accTokenPerShare * balanceOf(_account) - rewardInfo.debt) *
                multiplier) /
            MULTIPLIER;
    }
}