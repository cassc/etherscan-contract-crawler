// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

error Phasable__NotActive(uint256 phase);
error Phasable__NotPublic(uint256 phase);

/**
 * @dev Contract module which provides a basic support for multi-phased
 * distribution process.
 *
 * Each phase will have its own price, allowed quantity, start & end timestamp,
 * and allowlist if any.
 *
 * This module is used through inheritance. It will make available the modifier
 * `whenPhaseActive` and `whenPhasePublic`, which can be applied to distribution
 * functions to restrict their use.
 */
abstract contract Phasable is Context {
    // Type Declarations
    struct DistributionPhase {
        uint256 price;
        uint256 allowedQuantity;
        uint256 startTime;
        uint256 endTime;
        bytes32 merkleRoot;
        address signerAddress;
    }

    // Variables
    mapping(uint256 => DistributionPhase) private _distributionPhases;

    // Events
    event PhasePriceUpdated(
        uint256 indexed phase,
        uint256 price,
        address account
    );
    event PhaseAllowedQuantityUpdated(
        uint256 indexed phase,
        uint256 allowedQuantity,
        address account
    );
    event PhaseMintTimeUpdated(
        uint256 indexed phase,
        uint256 startTime,
        uint256 endTime,
        address account
    );
    event PhaseMerkleRootUpdated(
        uint256 indexed phase,
        bytes32 merkleRoot,
        address account
    );
    event PhaseSignerAddressUpdated(
        uint256 indexed phase,
        address signerAddress,
        address account
    );

    // Modifier
    /**
     * @dev Modifier to make a function callable only when the phase is active.
     */
    modifier whenPhaseActive(uint256 _phase) {
        if (!getIsPhaseActive(_phase)) {
            revert Phasable__NotActive(_phase);
        }
        _;
    }

    /**
     * @dev Modifier to make a function callable only when not whitelist is set.
     */
    modifier whenPhasePublic(uint256 _phase) {
        if (hasWhitelist(_phase)) {
            revert Phasable__NotPublic(_phase);
        }
        _;
    }

    // Functions
    /**
     * @dev Sets price for specified distribution phase.
     */
    function _setPriceForPhase(uint256 _phase, uint256 _price)
        internal
        virtual
    {
        _distributionPhases[_phase].price = _price;
        emit PhasePriceUpdated(_phase, _price, _msgSender());
    }

    /**
     * @dev Sets total number of tokens allowed per wallet for specified distribution phase.
     */
    function _setAllowedQuantityForPhase(uint256 _phase, uint256 _quantity)
        internal
        virtual
    {
        _distributionPhases[_phase].allowedQuantity = _quantity;
        emit PhaseAllowedQuantityUpdated(_phase, _quantity, _msgSender());
    }

    /**
     * @dev Sets the start and end time for the specified distribution phase.
     */
    function _setMintTimeForPhase(
        uint256 _phase,
        uint256 _startTime,
        uint256 _endTime
    ) internal virtual {
        _distributionPhases[_phase].startTime = _startTime;
        _distributionPhases[_phase].endTime = _endTime;
        emit PhaseMintTimeUpdated(_phase, _startTime, _endTime, _msgSender());
    }

    /**
     * @dev Sets the Merkle Tree Root for specified distribution phase.
     */
    function _setMerkleRootForPhase(uint256 _phase, bytes32 _merkleRoot)
        internal
        virtual
    {
        _distributionPhases[_phase].merkleRoot = _merkleRoot;
        emit PhaseMerkleRootUpdated(_phase, _merkleRoot, _msgSender());
    }

    /**
     * @dev Sets the signerAddress for specified distribution phase.
     */
    function _setSignerAddressForPhase(uint256 _phase, address _signerAddress)
        internal
        virtual
    {
        _distributionPhases[_phase].signerAddress = _signerAddress;
        emit PhaseSignerAddressUpdated(_phase, _signerAddress, _msgSender());
    }

    // Getters
    /**
     * @dev Returns the price of the specified phase.
     */
    function getPrice(uint256 _phase) public view virtual returns (uint256) {
        return _distributionPhases[_phase].price;
    }

    /**
     * @dev Returns the allowed quantity of the specified phase.
     */
    function getAllowedQuantity(uint256 _phase)
        public
        view
        virtual
        returns (uint256)
    {
        return _distributionPhases[_phase].allowedQuantity;
    }

    /**
     * @dev Returns the start time of the specified phase.
     */
    function getStartTime(uint256 _phase)
        public
        view
        virtual
        returns (uint256)
    {
        return _distributionPhases[_phase].startTime;
    }

    /**
     * @dev Returns the end time of the specified phase.
     */
    function getEndTime(uint256 _phase) public view virtual returns (uint256) {
        return _distributionPhases[_phase].endTime;
    }

    /**
     * @dev Returns the merkleRoot of the specified phase.
     */
    function getMerkleRoot(uint256 _phase)
        public
        view
        virtual
        returns (bytes32)
    {
        return _distributionPhases[_phase].merkleRoot;
    }

    /**
     * @dev Returns the merkleRoot of the specified phase.
     */
    function getSignerAddress(uint256 _phase)
        public
        view
        virtual
        returns (address)
    {
        return _distributionPhases[_phase].signerAddress;
    }

    /**
     * @dev Returns if the specified phase is active.
     */
    function getIsPhaseActive(uint256 _phase)
        public
        view
        virtual
        returns (bool)
    {
        uint256 startTime = getStartTime(_phase);
        uint256 endTime = getEndTime(_phase);

        return
            startTime > 0 &&
            endTime > 0 &&
            block.timestamp >= startTime &&
            block.timestamp <= endTime;
    }

    /**
     * @dev Returns if the specified phase has merkleRoot or signerAddress set.
     */
    function hasWhitelist(uint256 _phase) public view virtual returns (bool) {
        return
            getMerkleRoot(_phase) != bytes32("") ||
            getSignerAddress(_phase) != address(0);
    }
}