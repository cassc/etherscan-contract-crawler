//
//  ________  ___       ___      ___
// |\   __  \|\  \     |\  \    /  /|
// \ \  \|\  \ \  \    \ \  \  /  / /
//  \ \   ____\ \  \    \ \  \/  / /
//   \ \  \___|\ \  \____\ \    / /
//    \ \__\    \ \_______\ \__/ /
//     \|__|     \|_______|\|__|/
//
// Paralverse Asami Metadata
//
// by @G2#5600
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../../utils/PLVErrors.sol";

contract PLVAsamiMeta is Initializable, OwnableUpgradeable {
    uint256 public constant bitWidth = 8;
    address public manager;
    uint256 public traitCount;

    struct Info {
        string name;
        uint256 meta;
        uint256 birth;
        uint256 level;
    }

    /// @dev metadata
    mapping(uint256 => uint256) public traits;
    /// @dev token meta data
    mapping(uint256 => Info) public tokens;

    /* ==================== EVENTS ==================== */

    event Build(address indexed who, uint256 startId, uint256 qty);
    event Rebuild(address indexed who, uint256 id, uint256 attr);

    /* ==================== MODIFIERS ==================== */

    modifier onlyManager() {
        if (_msgSender() != manager) revert InvalidCaller();
        _;
    }

    /* ==================== METHODS ==================== */

    /**
     * @dev contract intializer
     */
    function initialize() external initializer {
        __Context_init();
        __Ownable_init();
    }

    /**
     * @dev set asami's own name
     *
     * @param _id asami token id
     * @param _name new name
     */
    function setName(uint256 _id, string memory _name) external onlyManager {
        tokens[_id].name = _name;
    }

    /**
     * @dev build nft meta attributes randomly
     *
     * @param _who minter address
     * @param _startId, minted token id
     * @param _qty minted quantity
     */
    function build(
        address _who,
        uint256 _startId,
        uint256 _qty
    ) external onlyManager {
        uint256 lastId = _startId + _qty;
        for (uint256 i = _startId; i < lastId; ) {
            tokens[i].meta = _buildAttribute(_who, i);
            tokens[i].birth = block.timestamp;
            tokens[i].level = 1;
            unchecked {
                ++i;
            }
        }

        emit Build(_who, _startId, _qty);
    }

    /**
     * @dev rebuid meta attribute randomly
     *
     * @param _who minter address
     * @param _id nft id
     */
    function rebuild(address _who, uint256 _id) external onlyManager {
        uint256 attr = _buildAttribute(_who, _id);
        tokens[_id].meta = attr;

        emit Rebuild(_who, _id, attr);
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev build the random attribute for nft meta data
     *
     * @param _who minter address
     * @param _id nft id
     */
    function _buildAttribute(address _who, uint256 _id) internal view returns (uint256 result) {
        result = 0;
        uint256 length = traitCount;
        uint256 random = _random(_who, _id);
        for (uint256 i = 0; i < length; ) {
            result = result << bitWidth;
            random = _nextRandom(random, i);
            result += ((random % traits[i]) + 1);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev returns the random number base on minter address and block information
     *
     * @param _who minter address
     */
    function _random(address _who, uint256 _id) internal view returns (uint256 random) {
        random = uint256(
            keccak256(abi.encodePacked(_who, _id, block.coinbase, block.difficulty, block.gaslimit, block.timestamp))
        );
    }

    /**
     * @dev returns the next random id base on previous random number and id
     *
     * @param _prev previous random number
     * @param _id trait iterator
     */
    function _nextRandom(uint256 _prev, uint256 _id) internal pure returns (uint256 random) {
        random = uint256(keccak256(abi.encodePacked(_prev, _id)));
    }

    /* ==================== GETTER METHODS ==================== */

    /**
     * @dev returns the nft info
     *
     * @param _id nft id
     */
    function infoOf(uint256 _id) external view returns (Info memory) {
        return tokens[_id];
    }

    /**
     * @dev returns the nft meta attribute detail in numer format
     *
     * @param _id nft id
     */
    function metaOf(uint256 _id) external view returns (uint256) {
        return (tokens[_id].meta);
    }

    /**
     * @dev returns the custom asami name
     *
     * @param _id nft id
     */
    function nameOf(uint256 _id) external view returns (string memory) {
        return (tokens[_id].name);
    }

    /**
     * @dev returns the asami brithday
     *
     * @param _id nft id
     */
    function birthOf(uint256 _id) external view returns (uint256) {
        return (tokens[_id].birth);
    }

    /**
     * @dev returns the asami level
     *
     * @param _id nft id
     */
    function levelOf(uint256 _id) external view returns (uint256) {
        return (tokens[_id].level);
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev owner can set the details of traits
     *
     * @param _count total trait count
     * @param _traits possible count of each trait
     */
    function setDB(uint256 _count, uint256[] memory _traits) external onlyOwner {
        traitCount = _count;
        for (uint256 i = 0; i < _count; ) {
            traits[i] = _traits[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev owner can set the manager address
     *
     * @param _manager manager contract address
     */
    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }
}