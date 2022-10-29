// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ChampionsAscensionPet.sol";

contract ChampionsAscensionPetTrap is Pausable, AccessControl {

    // Emitted when Trap event parameters are set
    event EventParametersSet(
        uint256 start,
        uint256 duration
    );

    // Emitted when the Trap is run
    event TrapResult(address player, uint256[] petsInTrap, uint256 result);

    // The ChampionsAscensionPet ERC721 contract
    address public immutable nftAddress;

    // New owner of the burned pets: Hêla
    address public immutable hela = address(0xdead);

    // Minimum number of pets in trap
    uint32 MIN_PETS_IN_TRAP = 1;

    // Maximum number of pets in trap
    uint32 MAX_PETS_IN_TRAP = 10;

    // Event parameters
    TimeSpan public eventSpan;

    struct TimeSpan {
        uint256 start; // time of event start in seconds since the epoch
        uint256 duration; // duration of event in seconds
    }

    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRAP_ADMIN_ROLE = keccak256("TRAP_ADMIN_ROLE");

    constructor(address _nftAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(TRAP_ADMIN_ROLE, msg.sender);
        nftAddress = _nftAddress;
    }

    /**
     * @notice Load pets into trap, burns them, and mint the trap result.
     * @notice The caller must be the owner of the pets to be burned
     * @notice The trap result will be minted to the caller's address
     * @param _petsInTrap array of pet token IDs for the pets to be burned
     */
    function setTrap(uint256[] calldata _petsInTrap) external whenEventActive whenNotPaused {
        require(eventActive(), "event not active");
        require(!paused(), "event paused");
        require(MIN_PETS_IN_TRAP <= _petsInTrap.length, "insufficient pets in trap");
        require(_petsInTrap.length <= MAX_PETS_IN_TRAP, "too many pets in trap");

        ChampionsAscensionPet cap = ChampionsAscensionPet(nftAddress);

        // "Burn" the pets being used as bait
        for (uint32 i = 0; i < _petsInTrap.length; ++i) {
            // @dev we rely on transfer failing if 'from' is not the pet owner
            cap.safeTransferFrom(msg.sender, hela, _petsInTrap[i]);
        }

        // Mint the new pet (Beadol or Ash)
        cap.safeMint(msg.sender, 1);

        emit TrapResult(msg.sender, _petsInTrap, cap.totalSupply());
    }

    /**
     * @notice Set the event parameters.
     * @param _eventSpan the time span of the event
     */
    function setEventParameters(TimeSpan calldata _eventSpan) external onlyRole(TRAP_ADMIN_ROLE) {
        eventSpan = _eventSpan;
        emit EventParametersSet(
            _eventSpan.start,
            _eventSpan.duration
        );
    }

    function _eventInitialized() internal view returns (bool) {
        return !(eventSpan.start == 0 && eventSpan.duration == 0);
    }

    function eventActive() public view returns (bool) {
        if (!_eventInitialized()) return false;
        uint256 _now = block.timestamp;
        return
            eventSpan.start < _now &&
            _now < (eventSpan.start + eventSpan.duration);
    }

    modifier whenEventActive() {
        require(eventActive(), "event is not active");
        _;
    }
}