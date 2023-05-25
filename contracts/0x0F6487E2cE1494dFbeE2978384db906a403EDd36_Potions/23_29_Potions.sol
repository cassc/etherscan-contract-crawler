// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IRandomizer.sol";
import "../interfaces/ICalculator.sol";
import "./interfaces/IActors.sol";
import "./interfaces/IPotions.sol";
import "../utils/EIP2981.sol";
import "../lib/Constants.sol";
import "../utils/GuardExtension.sol";
import {
    OperatorFiltererERC721,
    ERC721
} from "../utils/OperatorFiltererERC721.sol";

contract Potions is OperatorFiltererERC721, IPotions, EIP2981, GuardExtension {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds; 
    uint256 private _childs;
    uint256 private _unissued;
    uint256[] private _amounts;
    mapping(uint256 => uint256) private _total;
    mapping(uint256 => uint256) private _women;
    IActors private _zombie;
    IRandomizer private _random;
    address private _mysteryBoxAddress;
    bytes32 private constant ZERO_STRING = keccak256(bytes(""));
    string private constant WRONG_LEVEL = "Potion: wrong level";
    string private constant WRONG_OWNER = "Potion: wrong owner";
    string private constant NOT_A_BOX = "Potions: Not a box";
    string private constant TRY_AGAIN = "Potion: try again";
    string private constant SOLD_OUT = "Potion: sold out";
    string private constant WRONG_ID = "Potion: wrong id";
    string private constant NO_ZERO_LEVEL = "Potion: no zero level";
    string private constant META_ALREADY_USED = "Potion: meta already used";
    string private constant ALREADY_SET = "Potion: already set";
    string private constant BOX_NOT_SET = "Potion: box not set";
    string private constant SAME_VALUE = "Potion: same value";
    string private constant ZERO_ADDRESS = "Potion: zero address";
    string private constant IPFS_PREFIX = "ipfs://";
    string private constant PLACEHOLDERS_META_HASH =
        "QmZ9bCTRBNwgyhuaX6P7Xfm8D1c7jcUMZ4TFUDggGBE6hb";
    mapping(bytes32 => bool) private _usedMetadata;
    mapping(uint256 => string) private _tokensHashes;
    mapping(uint256 => uint256) private _issuedLevels;
    uint256[] private _limits;
    mapping(address => uint256) private _last;

    /// @notice only if one of the admins calls
    modifier onlyBox() {
        require(_mysteryBoxAddress != address(0), BOX_NOT_SET);
        require(
            _mysteryBoxAddress == msg.sender ||
                _rights().haveRights(address(this), msg.sender),
            NOT_A_BOX
        );
        _;
    }

    /// @notice validate the id
    modifier correctId(uint256 id_) {
        require(_exists(id_), WRONG_ID);
        _;
    }

    /**
@notice Constructor
@param name_ The name
@param symbol_ The symbol
@param rights_ The address of the rights contract
@param zombie_ The address of the zombie contract 
@param random_ The address of the random contract 
@param limits_ The maximum possible limits for the each parameter 
@param amounts_ The amounts of the actors according level (zero-based)   
@param childs_ The maximum number of the childs (for woman actors only)
*/
    constructor(
        string memory name_,
        string memory symbol_,
        address rights_,
        address zombie_,
        address random_,
        uint256[] memory limits_,
        uint256[] memory amounts_,
        uint256[] memory women_,
        uint256 childs_
    ) ERC721(name_, symbol_) GuardExtension(rights_) {
        require(random_ != address(0), ZERO_ADDRESS);
        require(zombie_ != address(0), ZERO_ADDRESS);

        _childs = childs_;
        _random = IRandomizer(random_);
        _zombie = IActors(zombie_);
        _saveAmounts(amounts_);
        _saveLimits(limits_);
        _saveWomen(women_);
    }

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view override returns (uint256) {
        return _tokenIds.current();
    }

    function _saveAmounts(uint256[] memory amounts_) private {
        uint256 len = amounts_.length;
        _unissued = 0;
        _amounts = amounts_;
        for (uint256 i = 0; i < len; ++i) {
            _unissued = _unissued + amounts_[i];
        }
    }

    function _saveWomen(uint256[] memory women_) private {
        for (uint256 i = 0; i < women_.length; i++) {
            _women[i] = women_[i];
        }
    }

    function _saveLimits(uint256[] memory limits_) private {
        _limits = limits_;
    }

    /**
@notice Get the amount of the actors remains to be created
@return The current value
*/
    function unissued() external view override returns (uint256) {
        return _unissued;
    }

    /**
@notice Get the level of the potion
@param id_ potion id
@return The level of the potion
*/
    function level(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (uint256)
    {
        return _issuedLevels[id_];
    }

    function _create(
        address owner_,
        uint256 level_,
        uint256 id_
    ) private returns (uint256) {
        require(level_ > 0, NO_ZERO_LEVEL);
        _tokenIds.increment();
        _issuedLevels[id_] = level_;
        _mint(owner_, id_);
        emit Created(owner_, id_, level_);
        return id_;
    }

    /**
@notice Set the maximum amount of the childs for the woman actor
@param childs_ New childs amount
*/
    function setChilds(uint256 childs_) external override haveRights {
        _childs = childs_;
        emit ChildsDefined(childs_);
    }

        /**
@notice Set new address of Zombie contract
@param value_ New address value
*/
    function setZombie(address value_) external haveRights {
        require(address(_zombie) != value_, SAME_VALUE);
        require(value_ != address(0), ZERO_ADDRESS);
        _zombie = IActors(value_);
    }

            /**
@notice Set new address of Randomizer contract
@param value_ New address value
*/
    function setRandom(address value_) external haveRights {
        require(address(_random) != value_, SAME_VALUE);
        require(value_ != address(0), ZERO_ADDRESS);
        _random = IRandomizer(value_);
    }

            /**
@notice Set new address of MysteryBox contract
@param value_ New address value
*/
    function setMysteryBox(address value_) external haveRights {
        require(address(_mysteryBoxAddress) != value_, SAME_VALUE);
        require(value_ != address(0), ZERO_ADDRESS);
        _mysteryBoxAddress = value_;
    }

    /**
@notice Get the current  maximum amount of the childs
@return The current value
*/
    function getChilds() external view override returns (uint256) {
        return _childs;
    }

    function _getLimits(uint256 level_)
        private
        view
        returns (uint256, uint256)
    {
        require(level_ > 0, NO_ZERO_LEVEL);
        require(level_ <= _limits.length, WRONG_LEVEL);
        if (level_ == 1) {
            return (Constants.MINIMAL, _limits[0]);
        }
        return (_limits[level_ - 2], _limits[level_ - 1]);
    }

    /**
@notice Get the limits of the properties for the level
@param level_ The desired level
@return Minimum and maximum level available
*/

    function getLimits(uint256 level_)
        external
        view
        returns (uint256, uint256)
    {
        return _getLimits(level_);
    }

    function calcSex(
        IRandomizer random_,
        uint256 total_,
        uint256 womenAvailable_
    ) internal returns (bool) {
        uint256[] memory weights = new uint256[](2);
        weights[0] = total_ - womenAvailable_;
        weights[1] = womenAvailable_;
        uint256 isWoman = random_.distributeRandom(total_, weights);
        return (isWoman == 0);
    }

    function calcProps(
        IRandomizer random,
        uint256 minRange,
        uint256 maxRange
    ) internal returns (uint256, uint16[10] memory) {
        uint16[10] memory props;
        uint256 range = maxRange - minRange;
        uint256 power = 0;

        for (uint256 i = 0; i < 10; i++) {
            props[i] = uint16(random.randomize(range) + minRange);
            power = power + props[i];
        }
        return (power, props);
    }

    function callMint(
        uint256 id_,
        uint16[10] memory props_,
        bool sex_,
        uint256 power_,
        uint8 childs_
    ) internal returns (uint256) {
        _zombie.mint(
            id_,
            msg.sender,
            props_,
            sex_,
            true,
            0,
            childs_,
            true
        );
        emit Opened(msg.sender, id_);
        return id_;
    }

    /**
@notice Open the packed id with the random values
@param id_ The pack id
@return The new actor id
*/
    function open(uint256 id_)
        external
        override
        correctId(id_)
        returns (uint256)
    {
        require(ownerOf(id_) == msg.sender, WRONG_OWNER);
        uint256 level_ = _issuedLevels[id_];
        IRandomizer random = _random;
        (uint256 minRange, uint256 maxRange) = _getLimits(level_);
        (uint256 power, uint16[10] memory props) = calcProps(
            random,
            minRange,
            maxRange
        );
        bool sex = true;
        if (_women[level_ - 1] > 0) {
            sex = calcSex(
                random,
                _total[level_ - 1] + _amounts[level_ - 1],
                _women[level_ - 1]
            );
            if (!sex) {
                _women[level_ - 1] = _women[level_ - 1] - 1;
            }
        }
        uint8 childs = sex ? 0 : uint8(random.randomize(_childs + 1));
        _burn(id_);
        delete _issuedLevels[id_];
        return callMint(id_, props, sex, power, childs);
    }

    /**
@notice return max potion level
@return The max potion level (1-based)
*/

    function getMaxLevel() external view override returns (uint256) {
        return _amounts.length - 1;
    }

    /**
@notice Create the potion by box (rare or not)
@param target The potion owner
@param rare The rarity sign
@param id_ The id of a new token
@return The new pack id
*/
    function create(
        address target,
        bool rare,
        uint256 id_
    ) external override onlyBox returns (uint256) {
        uint256 level_ = _amounts.length - 1;
        if (!rare) {
            level_ = _random.distributeRandom(_unissued, _amounts);
            require(_amounts[level_] > 0, TRY_AGAIN);
            _amounts[level_] = _amounts[level_] - 1;
        }
        require(_amounts[level_] > 0, SOLD_OUT);
        _total[level_] = _total[level_] + 1;
        return _create(target, level_ + 1, id_);
    }

    /**
@notice Create the packed potion with desired level (admin only)
@param target The pack owner
@param level_ The pack level
@param id_ The id of a new token
@return The new pack id
*/
    function createPotion(
        address target,
        uint256 level_,
        uint256 id_
    ) external override haveRights returns (uint256) {
        require(level_ > 0, NO_ZERO_LEVEL);
        require(_unissued > 0, SOLD_OUT);
        require(_amounts[level_ - 1] > 0, SOLD_OUT);
        _amounts[level_ - 1] = _amounts[level_ - 1] - 1;
        _unissued = _unissued - 1;
        uint256 created = _create(target, level_, id_);
        _last[target] = created;
        return created;
    }

    /**
@notice get the last pack for the address
@param target The  owner 
@return The  pack id
*/
    function getLast(address target) external view override returns (uint256) {
        return _last[target];
    }

    /**
@notice Decrease the amount of the common or rare tokens or fails
*/
    function decreaseAmount(bool rare)
        external
        override
        onlyBox
        returns (bool)
    {
        if(_unissued == 0) return false;
        if (rare) {
            uint256 aLevel = _amounts.length - 1;
            if(_amounts[aLevel] == 0) return false;
            _amounts[aLevel] = _amounts[aLevel] - 1;
        }
        _unissued = _unissued - 1;
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC2981, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 id_)
        public
        view
        override(ERC721, IERC721Metadata)
        correctId(id_)
        returns (string memory)
    {
        uint256 level_ = _issuedLevels[id_];
        if (keccak256(bytes(_tokensHashes[id_])) == ZERO_STRING) {
            return
                string(
                    abi.encodePacked(
                        IPFS_PREFIX,
                        PLACEHOLDERS_META_HASH,
                        "/po/",
                        level_.toString(),
                        "/meta.json"
                    )
                );
        } else {
            return string(abi.encodePacked(IPFS_PREFIX, _tokensHashes[id_]));
        }
    }

    /**
    @notice Set an uri for the token
    @param id_ token id
    @param metadataHash_ ipfs hash of the metadata
    */
    function setMetadataHash(uint256 id_, string calldata metadataHash_)
        external
        override
        haveRights
        correctId(id_)
    {
        require(
            keccak256(bytes(_tokensHashes[id_])) == ZERO_STRING,
            ALREADY_SET
        );
        require(
            !_usedMetadata[keccak256(bytes(metadataHash_))],
            META_ALREADY_USED
        );
        _usedMetadata[keccak256(bytes(metadataHash_))] = true;
        _tokensHashes[id_] = metadataHash_;
        emit TokenUriDefined(
            id_,
            string(abi.encodePacked(IPFS_PREFIX, metadataHash_))
        );
    }
}