// SPDX-License-Identifier: MIT
/*
     $$$$$$$\  $$$$$$$$\  $$$$$$\  $$$$$$$$\ $$\   $$\  $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\  $$$$$$$$\
     $$  __$$\ $$  _____|$$  __$$\ $$  _____|$$$\  $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  _____|
     $$ |  $$ |$$ |      $$ /  \__|$$ |      $$$$\ $$ |$$ /  \__|$$ /  \__|$$ /  $$ |$$ |  $$ |$$ |
     $$ |  $$ |$$$$$\    $$ |$$$$\ $$$$$\    $$ $$\$$ |\$$$$$$\  $$ |      $$ |  $$ |$$$$$$$  |$$$$$\
     $$ |  $$ |$$  __|   $$ |\_$$ |$$  __|   $$ \$$$$ | \____$$\ $$ |      $$ |  $$ |$$  __$$< $$  __|
     $$ |  $$ |$$ |      $$ |  $$ |$$ |      $$ |\$$$ |$$\   $$ |$$ |  $$\ $$ |  $$ |$$ |  $$ |$$ |
     $$$$$$$  |$$$$$$$$\ \$$$$$$  |$$$$$$$$\ $$ | \$$ |\$$$$$$  |\$$$$$$  | $$$$$$  |$$ |  $$ |$$$$$$$$\
     \_______/ \________| \______/ \________|\__|  \__| \______/  \______/  \______/ \__|  \__|\________|



     $$$$$$$\  $$$$$$$$\  $$$$$$\   $$$$$$\   $$$$$$\  $$\   $$\
     $$  __$$\ $$  _____|$$  __$$\ $$  __$$\ $$  __$$\ $$$\  $$ |
     $$ |  $$ |$$ |      $$ /  $$ |$$ /  \__|$$ /  $$ |$$$$\ $$ |
     $$$$$$$\ |$$$$$\    $$$$$$$$ |$$ |      $$ |  $$ |$$ $$\$$ |
     $$  __$$\ $$  __|   $$  __$$ |$$ |      $$ |  $$ |$$ \$$$$ |
     $$ |  $$ |$$ |      $$ |  $$ |$$ |  $$\ $$ |  $$ |$$ |\$$$ |
     $$$$$$$  |$$$$$$$$\ $$ |  $$ |\$$$$$$  | $$$$$$  |$$ | \$$ |
     \_______/ \________|\__|  \__| \______/  \______/ \__|  \__|
*/

pragma solidity ^0.8.16;

import "./interfaces/IDegenScoreBeaconReader.sol";
import "./interfaces/IDegenScoreBeaconWriter.sol";
import "./SoulboundERC1155.sol";
import "./structs/Contract.sol";
import "./structs/Submit.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title DegenScore Beacon
 * @author DegenScore Team
 * @notice The DegenScore Beacon is an Ethereum soulbound token that highlights your on-chain skills & traits across one or more wallets.
 * @dev This contract is the implementation of the DegenScore Beacon
 */
contract DegenScoreBeacon is
    Initializable,
    IDegenScoreBeaconReader,
    IDegenScoreBeaconWriter,
    SoulboundERC1155,
    OwnableUpgradeable,
    PausableUpgradeable
{
    /// @dev the signer who signs `UserPayload` used in `submitTraits`
    address private signer;

    /// @dev receives the fees payed by users when calling `submitTraits`
    address payable private feeCollector;

    /// @dev the TTL of how long signatures used in `submitTraits` are valid
    uint32 private signatureTTLSeconds;

    /// @dev the URL base for fetching metadata for a primary Trait
    string private primaryTraitURI;

    /// @dev the URL base for fetching off chain traits and metadata of a user's Beacon
    string private beaconURI;

    /// @dev stores the traits of a user
    mapping(address => mapping(uint256 => Trait)) private _traits;

    /// @dev stores metadata of a user
    mapping(address => BeaconData) private beaconData;

    /// @dev reverse lookup for a Beacon ID
    mapping(uint128 => address) private beaconIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _signer,
        address payable _feeCollector,
        uint32 _signatureTTLSeconds,
        string calldata _primaryURI,
        string calldata _beaconURI
    ) public initializer {
        __Ownable_init();
        __Pausable_init();

        _transferOwnership(_owner);
        signer = _signer;
        feeCollector = _feeCollector;
        signatureTTLSeconds = _signatureTTLSeconds;
        primaryTraitURI = _primaryURI;
        beaconURI = _beaconURI;
    }

    /// External methods

    function submitTraits(UserPayload calldata payload, bytes memory signature) external payable whenNotPaused {
        require(
            ECDSAUpgradeable.recover(
                ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encode(payload))),
                signature
            ) == signer,
            "Invalid signature"
        );

        unchecked {
            require(payload.createdAt > (block.timestamp - signatureTTLSeconds), "Signature expired");

            BeaconData memory metadata = beaconData[payload.account];
            bool isFirstSubmission = metadata.updatedAt == 0;

            require(payload.createdAt > metadata.updatedAt, "Invalid data");

            require(msg.value == payload.price, "Wrong value sent");
            feeCollector.transfer(msg.value);

            metadata = BeaconData({
                updatedAt: payload.createdAt,
                beaconId: payload.beaconId,
                traitIds: new uint256[](payload.traits.length)
            });

            for (uint256 i = 0; i < payload.traits.length; i++) {
                uint256 traitId = payload.traits[i].id;

                // check if is first submission in case user has burned before
                uint192 oldTraitValue = isFirstSubmission ? 0 : _traits[payload.account][payload.traits[i].id].value;
                uint192 newTraitValue = payload.traits[i].value;

                _traits[payload.account][traitId] = Trait({value: newTraitValue, updatedAt: payload.createdAt});
                metadata.traitIds[i] = traitId;

                _triggerTransferEvent(traitId, payload.account, oldTraitValue, newTraitValue);
            }

            beaconData[payload.account] = metadata;

            // emit mint event if submitted data for the first time
            if (isFirstSubmission) {
                beaconIds[payload.beaconId] = payload.account; // mapping only needs to be done on first submission
                emit TransferSingle(address(this), address(0), payload.account, payload.beaconId, 1);
            }

            emit SubmitTraits(payload.beaconId, payload.createdAt);
        }
    }

    function burn() external override {
        BeaconData memory metadata = beaconData[msg.sender];
        require(metadata.updatedAt != 0, "Address does not own a Beacon");

        delete beaconIds[metadata.beaconId];
        delete beaconData[msg.sender];

        emit TransferBatch(
            address(this),
            msg.sender,
            address(0),
            metadata.traitIds,
            new uint256[](metadata.traitIds.length) // set all traits to 0
        );
        emit TransferSingle(address(this), msg.sender, address(0), metadata.beaconId, 0);
        emit Burn(metadata.beaconId);
    }

    /// Public methods

    function getTrait(
        address account,
        uint256 traitId,
        uint64 maxAge
    ) public view override returns (uint192) {
        return _getTrait(account, traitId, maxAge);
    }

    function getTraitBatch(
        address[] memory accounts,
        uint256[] memory traitIds,
        uint64[] memory maxAges
    ) public view override returns (uint192[] memory) {
        return _getTraitBatch(accounts, traitIds, maxAges);
    }

    function getAllTraitsOf(address account)
        public
        view
        override
        returns (
            uint256[] memory traitIds,
            uint192[] memory traitValues,
            uint64 updatedAt
        )
    {
        require(account != address(0), "address zero is not a valid owner");
        BeaconData memory data = beaconData[account];
        uint192[] memory _traitValues = new uint192[](data.traitIds.length);

        for (uint256 i = 0; i < data.traitIds.length; ++i) {
            _traitValues[i] = _getTrait(account, data.traitIds[i], 0);
        }

        return (data.traitIds, _traitValues, data.updatedAt);
    }

    function beaconDataOf(address account) public view override returns (BeaconData memory) {
        require(account != address(0), "address zero is not a valid owner");
        return beaconData[account];
    }

    function ownerOfBeacon(uint128 beaconId) public view override returns (address owner) {
        return _ownerOfBeacon(beaconId);
    }

    function getTraitURI(uint256 traitId) public view override returns (string memory) {
        return string.concat(primaryTraitURI, StringsUpgradeable.toString(traitId), ".json");
    }

    function getBeaconURI(uint128 beaconId) public view override returns (string memory) {
        address beaconAddress = beaconIds[beaconId];
        require(beaconAddress != address(0), "No Beacon found");
        return string.concat(beaconURI, StringsUpgradeable.toHexString(beaconAddress), ".json");
    }

    /// ERC1155 methods

    /**
     * @dev Should not be used for Beacon integrations.
     * It to display the Beacon on existing platforms using the ERC1155 interface.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");

        return _getTraitOrBeacon(account, id);
    }

    /**
     * @dev Should not be used for Beacon integrations.
     * It to display the Beacon on existing platforms using the ERC1155 interface.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = _getTraitOrBeacon(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Should not be used for Beacon integrations.
     * It to display the Beacon on existing platforms using the ERC1155 interface.
     */
    function uri(uint256 id) public view override returns (string memory) {
        if (beaconIds[uint128(id)] == address(0)) {
            return getTraitURI(id);
        } else {
            return getBeaconURI(uint128(id));
        }
    }

    /// Management methods

    /**
     * @return address the address of the DegenScore signer
     */
    function getSigner() public view returns (address) {
        return signer;
    }

    /**
     * @notice updates the DegenScore signer
     */
    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "New signer is the zero address");
        signer = _signer;
    }

    /**
     * @return address address of the fee collector
     */
    function getFeeCollector() public view returns (address) {
        return feeCollector;
    }

    /**
     * @notice updates the fee collector
     */
    function setFeeCollector(address payable _feeCollector) public onlyOwner {
        require(_feeCollector != address(0), "New feeCollector is the zero address");
        feeCollector = _feeCollector;
    }

    /**
     * @return ttl the signature TTL in seconds
     */
    function getSignatureTTL() public view returns (uint32) {
        return signatureTTLSeconds;
    }

    /**
     * @notice updates the signature TTL
     */
    function setSignatureTTL(uint32 _TTLSeconds) public onlyOwner {
        signatureTTLSeconds = _TTLSeconds;
    }

    /**
     * @notice updates the primary Trait URL base
     */
    function setPrimaryTraitURI(string calldata _uri) public onlyOwner {
        primaryTraitURI = _uri;
    }

    /**
     * @notice updates the Beacon URL base
     */
    function setBeaconURI(string calldata _uri) public onlyOwner {
        beaconURI = _uri;
    }

    /**
     * @notice pauses the Beacon contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice unpauses the Beacon contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /// Internal methods

    function _triggerTransferEvent(
        uint256 traitId,
        address owner,
        uint256 oldTraitValue,
        uint256 newTraitValue
    ) internal {
        unchecked {
            if (oldTraitValue == newTraitValue) return;

            bool isGreaterValue = newTraitValue > oldTraitValue;
            address operator = address(this);
            address from = isGreaterValue ? address(0) : owner;
            address to = isGreaterValue ? owner : address(0);
            uint256 value = isGreaterValue ? newTraitValue - oldTraitValue : oldTraitValue - newTraitValue;

            // if isGreaterValue is true, function triggers mint event. Otherwise triggers burn event.
            emit TransferSingle(operator, from, to, traitId, value);
        }
    }

    function _getTraitBatch(
        address[] memory accounts,
        uint256[] memory traitIds,
        uint64[] memory maxAges
    ) internal view returns (uint192[] memory) {
        require(accounts.length == traitIds.length, "accounts and traitIds length mismatch");
        require(accounts.length == maxAges.length, "accounts and maxAges length mismatch");

        uint192[] memory batchBalances = new uint192[](accounts.length);

        for (uint192 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = _getTrait(accounts[i], traitIds[i], maxAges[i]);
        }

        return batchBalances;
    }

    function _getTrait(
        address account,
        uint256 traitId,
        uint64 maxAge
    ) internal view whenNotPaused returns (uint192) {
        BeaconData memory metadata = beaconData[account];

        Trait memory trait = _traits[account][traitId];
        if (trait.updatedAt != metadata.updatedAt) {
            return 0;
        }

        if (maxAge == 0) {
            return trait.value;
        }

        if ((trait.updatedAt + maxAge) <= block.timestamp) {
            return 0;
        }

        return trait.value;
    }

    function _getTraitOrBeacon(address account, uint256 id) internal view returns (uint256) {
        uint256 trait = _getTrait(account, id, 0);
        if (trait != 0) return trait;

        BeaconData memory metadata = beaconData[account];

        if (metadata.updatedAt == 0) {
            return 0;
        } else {
            return 1;
        }
    }

    function _ownerOfBeacon(uint128 beaconId) internal view returns (address account) {
        return beaconIds[beaconId];
    }
}