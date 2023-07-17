//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "../interfaces/IYardboisResources.sol";
import "../interfaces/IGnomeJob.sol";

contract Yardbois is ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    using StringsUpgradeable for uint256;

    error GnomeWorking(uint256 index);
    error GnomeNotWorking(uint256 index);
    error GnomeHiding(uint256 index);
    error GnomeUnpaid(uint256 index);
    error InvalidResource(uint256 index);
    error InvalidLength();

    event GnomeGift(
        uint256 indexed gnomeIndex,
        uint256 indexed resourceIndex,
        uint256 resourceAmount
    );
    event MetadataUpdate(uint256 tokenId);

    struct GnomeStatus {
        uint40 happinessSnapshotTime;
        uint40 happinessCounter;
        address currentJob;
        bool isUnpaid;
    }

    struct ResourceBurn {
        uint256 index;
        uint256 amount;
    }

    struct GnomeGifts {
        uint256 gnomeIndex;
        ResourceBurn[] resources;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant JOB_ROLE = keccak256("JOB_ROLE");

    uint40 public constant HAPPINESS_REGEN_CAP = 3 days;

    IYardboisResources public resources;

    string internal baseURI;
    string internal baseHidingURI;

    mapping(uint256 => GnomeStatus) public gnomeStatus;
    mapping(uint256 => uint40) public resourceHappinessBonus;

    function initialize(IYardboisResources _resources) external initializer {
        __ERC721_init("Yardbois", "YARD");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        resources = _resources;
    }

    function mint(
        address _recipient,
        uint256 _tokenId
    ) external onlyRole(MINTER_ROLE) {
        gnomeStatus[_tokenId] = GnomeStatus(
            uint40(block.timestamp),
            HAPPINESS_REGEN_CAP,
            address(0),
            false
        );
        _mint(_recipient, _tokenId);
    }

    function setGnomeWorking(uint256 _idx) external onlyRole(JOB_ROLE) {
        GnomeStatus memory _status = gnomeStatus[_idx];

        if (_status.currentJob != address(0)) revert GnomeWorking(_idx);

        if (_isHiding(_status)) revert GnomeHiding(_idx);

        _updateHappiness(
            _idx,
            _status.happinessCounter,
            _getCurrentHappiness(_status),
            msg.sender,
            false
        );
    }

    function setGnomeNotWorking(
        uint256 _idx,
        bool _isUnpaid
    ) external onlyRole(JOB_ROLE) {
        GnomeStatus memory _status = gnomeStatus[_idx];

        if (_status.currentJob == address(0)) revert GnomeNotWorking(_idx);

        if (_isUnpaid)
            _updateHappiness(
                _idx,
                _status.happinessCounter,
                0,
                address(0),
                true
            );
        else
            _updateHappiness(
                _idx,
                _status.happinessCounter,
                _getCurrentHappiness(_status),
                address(0),
                false
            );
    }

    function setResourceHappinessBonus(
        uint256 _resourceId,
        uint40 _happinessBonus
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        resourceHappinessBonus[_resourceId] = _happinessBonus;
    }

    function setBaseUris(
        string calldata _baseURI,
        string calldata _baseHidingUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
        baseHidingURI = _baseHidingUri;
    }

    function giftResources(GnomeGifts[] calldata _gifts) external {
        IYardboisResources _resources = resources;

        uint256 _length = _gifts.length;
        if (_length == 0) revert InvalidLength();
        for (uint256 i; i < _length; ++i) {
            GnomeGifts calldata _curr = _gifts[0];
            uint256 _gnomeIndex = _curr.gnomeIndex;

            GnomeStatus memory _status = gnomeStatus[_gnomeIndex];
            if (_status.isUnpaid && _isHiding(_status))
                revert GnomeUnpaid(_gnomeIndex);

            if (_status.currentJob != address(0))
                IGnomeJob(_status.currentJob).signalHappinessBonus(_gnomeIndex);

            uint40 _totalgnomeStatusBonus;
            uint256 _resourcesLength = _curr.resources.length;
            if (_resourcesLength == 0) revert InvalidLength();
            for (uint256 j; j < _resourcesLength; ++j) {
                ResourceBurn calldata _resourceBurn = _curr.resources[j];
                uint40 _bonusHappiness = resourceHappinessBonus[
                    _resourceBurn.index
                ];

                if (_bonusHappiness == 0)
                    revert InvalidResource(_resourceBurn.index);

                _totalgnomeStatusBonus +=
                    _bonusHappiness *
                    uint40(_resourceBurn.amount);
                _resources.burn(
                    msg.sender,
                    _resourceBurn.index,
                    _resourceBurn.amount
                );

                emit GnomeGift(
                    _gnomeIndex,
                    _resourceBurn.index,
                    _resourceBurn.amount
                );
            }

            _updateHappiness(
                _gnomeIndex,
                _status.happinessCounter,
                _getCurrentHappiness(_status) + _totalgnomeStatusBonus,
                _status.currentJob,
                false
            );
        }
    }

    function getGnomeHappiness(uint256 _idx) external view returns (uint40) {
        GnomeStatus memory _happiness = gnomeStatus[_idx];

        return _getCurrentHappiness(_happiness);
    }

    function isHiding(uint256 _idx) public view returns (bool) {
        GnomeStatus memory _happiness = gnomeStatus[_idx];

        return _isHiding(_happiness);
    }

    function tokenURI(
        uint256 _idx
    ) public view override returns (string memory) {
        _requireMinted(_idx);

        string memory _baseURI = isHiding(_idx) ? baseHidingURI : baseURI;

        return string(abi.encodePacked(_baseURI, _idx.toString()));
    }

    function _getCurrentHappiness(
        GnomeStatus memory _status
    ) internal view returns (uint40 _currentHappiness) {
        if (_status.currentJob != address(0)) {
            uint40 _elapsed = uint40(block.timestamp) -
                _status.happinessSnapshotTime;
            _currentHappiness = _elapsed > _status.happinessCounter
                ? 0
                : _status.happinessCounter - _elapsed;
        } else if (_status.happinessCounter <= HAPPINESS_REGEN_CAP) {
            uint40 _elapsed = uint40(block.timestamp) -
                _status.happinessSnapshotTime;
            uint40 _temp = _elapsed + _status.happinessCounter;
            _currentHappiness = _temp > HAPPINESS_REGEN_CAP
                ? HAPPINESS_REGEN_CAP
                : _temp;
        } else _currentHappiness = _status.happinessCounter;
    }

    function _isHiding(
        GnomeStatus memory _happiness
    ) internal view returns (bool) {
        if (_happiness.happinessCounter != 0) return false;

        return _getCurrentHappiness(_happiness) < HAPPINESS_REGEN_CAP;
    }

    function _updateHappiness(
        uint256 _idx,
        uint40 _currentCounter,
        uint40 _newCounter,
        address _currentJob,
        bool _isUnpaid
    ) internal {
        if (
            (_currentCounter == 0 && _newCounter != 0) ||
            (_currentCounter != 0 && _newCounter == 0)
        ) emit MetadataUpdate(_idx);

        gnomeStatus[_idx] = GnomeStatus(
            uint40(block.timestamp),
            _newCounter,
            _currentJob,
            _isUnpaid
        );
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}