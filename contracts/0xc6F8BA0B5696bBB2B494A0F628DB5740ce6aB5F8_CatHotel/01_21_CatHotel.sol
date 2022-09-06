// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract CatHotel is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DAO_MANAGER_ROLE = keccak256("DAO_MANAGER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _lasercat) public initializer {
        __ERC721_init("StakeLaserCat", "sCAT");
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(DAO_MANAGER_ROLE, msg.sender);

        lasercat = IERC721Upgradeable(_lasercat);
    }

    IERC721Upgradeable public lasercat;

    EnumerableSetUpgradeable.UintSet private stakedTokenList;

    mapping(uint256 => Booster) public boosters;

    mapping(uint256 => CatRoom) public checkinBooks;

    mapping(uint256 => bool) public blackList;

    struct Booster {
        uint64 boostRate;
        uint64 boostTime;
    }

    struct CatRoom {
        address owner;
        uint64 catId;
        uint64 boostRate;
        uint64 unlockTime;
    }

    // ========== EVENTS ==========
    event Staked(
        address indexed user,
        uint256 indexed catId,
        uint256 boostRate,
        uint256 unlockTime
    );

    event Unstaked(
        address indexed user,
        uint256 indexed catId,
        uint256 aliveAt
    );

    event Claimed(address indexed user, uint256 indexed catId, uint256 claimAt);

    event EmergencyWithdraw(address indexed user, uint256 indexed catId);

    modifier eoaOnly() {
        require(tx.origin == msg.sender);
        _;
    }

    modifier notInBlacklisted(uint256 catId) {
        require(!blackList[catId]);
        _;
    }

    function stake(uint64 _catId, uint256 _boostType)
        external
        eoaOnly
        nonReentrant
        notInBlacklisted(_catId)
    {
        require(
            lasercat.ownerOf(_catId) == msg.sender,
            "catHotel: this cat not belong to you"
        );

        Booster memory booster = boosters[_boostType];

        require(
            booster.boostRate != 0 && booster.boostTime != 0,
            "catHotel: boost config not set"
        );

        lasercat.safeTransferFrom(msg.sender, address(this), _catId);

        stakedTokenList.add(_catId);

        checkinBooks[_catId] = CatRoom(
            msg.sender,
            _catId,
            booster.boostRate,
            uint64(block.timestamp) + booster.boostTime
        );

        _safeMint(msg.sender, _catId);

        emit Staked(
            msg.sender,
            _catId,
            booster.boostRate,
            checkinBooks[_catId].unlockTime
        );
    }

    function unstake(uint256 _catId)
        external
        eoaOnly
        nonReentrant
        notInBlacklisted(_catId)
    {
        CatRoom storage room = checkinBooks[_catId];

        require(
            room.owner == msg.sender,
            "catHotel: unstaked token not owned by sender"
        );
        require(
            room.unlockTime < block.timestamp,
            "catHotel: cat in a cooling off period"
        );
        require(
            ownerOf(_catId) == msg.sender,
            "catHotel: not approved or owner"
        );

        stakedTokenList.remove(_catId);

        _burn(room.catId);

        lasercat.safeTransferFrom(address(this), msg.sender, _catId);

        emit Unstaked(msg.sender, _catId, block.timestamp);
    }

    function emergencyWithdraw(uint256 _catId)
        external
        onlyRole(DAO_MANAGER_ROLE)
    {
        CatRoom memory room = checkinBooks[_catId];

        stakedTokenList.remove(room.catId);

        _burn(room.catId);

        lasercat.safeTransferFrom(address(this), room.owner, room.catId);

        emit EmergencyWithdraw(room.owner, _catId);
    }

    function setBoosters(
        uint64[] calldata _ids,
        uint64[] calldata _boostRates,
        uint64[] calldata _boostTime
    ) external onlyRole(DAO_MANAGER_ROLE) {
        for (uint256 i = 0; i < _ids.length; i++) {
            boosters[_ids[i]] = Booster(_boostRates[i], _boostTime[i]);
        }
    }

    function setBlackList(uint256[] calldata _ids, bool _state)
        external
        onlyRole(DAO_MANAGER_ROLE)
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            blackList[_ids[i]] = _state;
        }
    }

    function totalStaked(address _user) public view returns (uint256[] memory) {
        uint256 num = 0;
        for (uint256 i = 0; i < stakedTokenList.length(); i++) {
            CatRoom memory room = checkinBooks[stakedTokenList.at(i)];
            if (room.owner == _user) {
                num++;
            }
        }

        if (num == 0) {
            uint256[] memory empty = new uint256[](num);
            return empty;
        }

        uint256[] memory result = new uint256[](num);
        uint256 index = 0;
        for (uint256 i = 0; i < stakedTokenList.length(); i++) {
            CatRoom memory room = checkinBooks[stakedTokenList.at(i)];
            if (room.owner == _user) {
                result[index] = stakedTokenList.at(i);
                index++;
            }
        }

        return result;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("transfer function is locked");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("transfer function is locked");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        revert("transfer function is locked");
    }
}