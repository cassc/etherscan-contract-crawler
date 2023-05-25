// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IActors.sol";
import "./interfaces/IMaternity.sol";
import "../lib/Structures.sol";
import "../utils/GuardExtension.sol";
import "../utils/EIP2981.sol";
import "../utils/OperatorFiltererERC721.sol";

/**
@title The Actor NFT contract
@author Ilya A. Shlyakhovoy
@notice This contract manage properties of the game actor, including birth and childhood.
The new actor comes from the Breed or Box contracts
 */
abstract contract Actors is
    OperatorFiltererERC721,
    EIP2981,
    GuardExtension,
    IActors
{
    using Counters for Counters.Counter;
    Counters.Counter private _total;
    uint256 private _counter;
    bytes32 private constant ZERO_STRING = keccak256(bytes(""));
    string private constant WRONG_ID = "Actor: wrong id";
    string private constant ALREADY_SET = "Actor: already set";
    string private constant NOT_BORN = "Actor: not borned yet";
    string private constant META_ALREADY_USED = "Actor: meta already used";
    string private constant ONLY_NON_IMMACULATE = "Actor: only nonimmaculate";
    string private constant ONLY_IMMACULATE = "Actor: only immaculate";
    string private constant IPFS_PREFIX = "ipfs://";
    string private constant TOO_MUCH_CHILDS = "Actor: too much childs";
    string private constant FALLBACK_META_HASH =
        "QmZ9bCTRBNwgyhuaX6P7Xfm8D1c7jcUMZ4TFUDggGBE6hb";
    mapping(uint256 => Structures.ActorData) private _actors;
    mapping(bytes32 => bool) private _usedMetadata;

    /// @notice validate the id
    modifier correctId(uint256 id_) {
        require(_exists(id_), WRONG_ID);
        _;
    }

    /**
@notice constructor
@param name_ The name of the token
@param symbol_ The short name (symbol) of the token
@param rights_ The address of the rights contract
@param start_ The first started id for counting
*/
    constructor(
        string memory name_,
        string memory symbol_,
        address rights_,
        uint256 start_
    ) ERC721(name_, symbol_) GuardExtension(rights_) {
        _counter = start_;
    }

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view override returns (uint256) {
        return _total.current();
    }

    /**
    @notice Set an uri for the adult token (only for non immaculate)
    @param id_ token id
    @param adultHash_ ipfs hash of the kids metadata
    */
    function setMetadataHash(uint256 id_, string calldata adultHash_)
        external
        override
        haveRights
        correctId(id_)
    {
        require(_actors[id_].immaculate, ONLY_IMMACULATE);
        require(
            keccak256(bytes(_actors[id_].adultTokenUriHash)) == ZERO_STRING,
            ALREADY_SET
        );
        require(
            !_usedMetadata[keccak256(bytes(adultHash_))],
            META_ALREADY_USED
        );
        _usedMetadata[keccak256(bytes(adultHash_))] = true;
        _actors[id_].adultTokenUriHash = adultHash_;
        emit TokenUriDefined(
            id_,
            "",
            string(abi.encodePacked(IPFS_PREFIX, adultHash_))
        );
    }

    /**
    @notice Set an uri for the adult and kid token (only for immaculate)
    @param id_ token id
    @param kidHash_ ipfs hash of the kids metadata
    @param adultHash_ ipfs hash of the adult metadata
    */
    function setMetadataHashes(
        uint256 id_,
        string calldata kidHash_,
        string calldata adultHash_
    ) external override haveRights correctId(id_) {
        require(!_actors[id_].immaculate, ONLY_NON_IMMACULATE);
        require(
            keccak256(bytes(_actors[id_].adultTokenUriHash)) == ZERO_STRING,
            ALREADY_SET
        );
        require(!_usedMetadata[keccak256(bytes(kidHash_))], META_ALREADY_USED);
        require(
            !_usedMetadata[keccak256(bytes(adultHash_))],
            META_ALREADY_USED
        );
        _usedMetadata[keccak256(bytes(kidHash_))] = true;
        _usedMetadata[keccak256(bytes(adultHash_))] = true;
        _actors[id_].kidTokenUriHash = kidHash_;
        _actors[id_].adultTokenUriHash = adultHash_;
        emit TokenUriDefined(
            id_,
            string(abi.encodePacked(IPFS_PREFIX, kidHash_)),
            string(abi.encodePacked(IPFS_PREFIX, adultHash_))
        );
    }

    /**
    @notice Get an uri for the token
    @param id_ token id
    @return The current payment token address
    */
    function tokenURI(uint256 id_)
        public
        view
        override(ERC721, IERC721Metadata)
        correctId(id_)
        returns (string memory)
    {
        string memory tokenHash;
        if (_isAdult(id_)) {
            tokenHash = _actors[id_].adultTokenUriHash;
        } else {
            tokenHash = _actors[id_].kidTokenUriHash;
        }
        if (keccak256(bytes(tokenHash)) == ZERO_STRING) {
            Structures.ActorData memory actor = _actors[id_];
            string memory personType;
            if (_isAdult(id_)) {
                // am - adult male, af - adult female
                personType = actor.sex ? "am" : "af";
            } else {
                personType = "kid";
            }
            return
                string(
                    abi.encodePacked(
                        IPFS_PREFIX,
                        FALLBACK_META_HASH,
                        "/",
                        _getPlaceholderSubFolder(),
                        "/",
                        personType,
                        "/",
                        "meta.json"
                    )
                );
        }
        return string(abi.encodePacked(IPFS_PREFIX, tokenHash));
    }

    /**
    @notice Get an uri for the kid token
    @param id_ token id
    @return The current payment token address
    */
    function tokenKidURI(uint256 id_)
        external
        view
        correctId(id_)
        returns (string memory)
    {
        string memory tokenHash = _actors[id_].kidTokenUriHash;
        if (keccak256(bytes(tokenHash)) == ZERO_STRING) {
            return "";
        }
        return string(abi.encodePacked(IPFS_PREFIX, tokenHash));
    }

    /**
    @notice Get an uri for the adult token
    @param id_ token id
    @return The current payment token address
    */
    function tokenAdultURI(uint256 id_)
        external
        view
        correctId(id_)
        returns (string memory)
    {
        Structures.ActorData memory actor = _actors[id_];
        string memory tokenHash = actor.adultTokenUriHash;
        if (keccak256(bytes(tokenHash)) == ZERO_STRING) {
            return "";
        }
        return string(abi.encodePacked(IPFS_PREFIX, tokenHash));
    }

    /**
    @notice Method that returns sub folder for placeholders metadata
    */
    function _getPlaceholderSubFolder()
        internal
        pure
        virtual
        returns (string memory);

    /**
@notice Create a new person token (not born yet)
@param id_ The id of new minted token
@param owner_ Owner of the token
@param props_ Array of the actor properties
@param sex_ The person sex (true = male, false = female)
@param born_ Is the child born or not
@param adultTime_ When child become adult actor, if 0 actor is not born yet
@param childs_ The amount of childs can be born (only for female)
@param immaculate_ True only for potion-breeded
@return The new id
*/
    function mint(
        uint256 id_,
        address owner_,
        uint16[10] memory props_,
        bool sex_,
        bool born_,
        uint256 adultTime_,
        uint8 childs_,
        bool immaculate_
    ) external override haveRights returns (uint256) {
        _total.increment();
        uint256 newId;
        if (id_ > 0) {
            newId = id_;
        } else {
            _counter = _counter + 1;
            newId = _counter;
        }
        _mint(owner_, newId);
        uint16 rank = (props_[0] +
            props_[1] +
            props_[2] +
            props_[3] +
            props_[4] +
            props_[5] +
            props_[6] +
            props_[7] +
            props_[8] +
            props_[9]) / 10;
        uint256 bornTime = 0;
        uint256 adultTime = 0;
        if (born_) {
            bornTime = block.timestamp;
            if (adultTime_ > block.timestamp) {
                adultTime = adultTime_;
            } else {
                adultTime = block.timestamp;
            }
        }

        _actors[newId] = Structures.ActorData({
            bornTime: bornTime,
            adultTime: adultTime,
            kidTokenUriHash: "",
            adultTokenUriHash: "",
            props: props_,
            sex: sex_,
            childs: childs_,
            childsPossible: childs_,
            born: born_,
            immaculate: immaculate_,
            rank: rank,
            initialOwner: owner_
        });
        if (immaculate_) {
            emit MintedImmaculate(owner_, newId);
        } else {
            emit Minted(owner_, newId);
        }
        return newId;
    }

    /**
@notice Get the person props
@param id_ Person token id
@return Array of the props
*/
    function getProps(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (uint16[10] memory)
    {
        return _actors[id_].props;
    }

    /**
@notice Get the actor
@param id_ Person token id
@return Structures.ActorData full struct of actor
*/
    function getActor(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (Structures.ActorData memory)
    {
        return _actors[id_];
    }

    /**
@notice Get the person sex
@param id_ Person token id
@return true = male, false = female
*/
    function getSex(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (bool)
    {
        return _actors[id_].sex;
    }

    /**
@notice Get the person childs
@param id_ Person token id
@return childs and possible available childs
*/
    function getChilds(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (uint8, uint8)
    {
        return (_actors[id_].childs, _actors[id_].childsPossible);
    }

    /**
@notice Breed a child
@param id_ Person token id
*/
    function breedChild(uint256 id_)
        external
        override
        haveRights
        correctId(id_)
    {
        if (!_actors[id_].sex) {
            require(_actors[id_].childsPossible > 0, TOO_MUCH_CHILDS);
            _actors[id_].childsPossible = _actors[id_].childsPossible - 1;
        }
    }

    /**
@notice Get the person immaculate status
@param id_ Person token id
*/
    function getImmaculate(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (bool)
    {
        return (_actors[id_].immaculate);
    }

    /**
@notice Get the person adult state
@param id_ Person token id
@return 0 = complete adult, or amount of tokens needed to be paid for
*/
    function getBornTime(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (uint256)
    {
        require(_actors[id_].born, NOT_BORN);
        return _actors[id_].bornTime;
    }

    /**
@notice Get the person born state
@param id_ Person token id
@return true = person is born
*/
    function isBorn(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (bool)
    {
        return _actors[id_].born;
    }

    /**
@notice Birth the person
@param id_ Person token id 
@param adultTime_ When person becomes adult
*/
    function born(uint256 id_, uint256 adultTime_)
        external
        override
        haveRights
        correctId(id_)
    {
        require(!_actors[id_].born, ALREADY_SET);
        _actors[id_].born = true;
        _actors[id_].bornTime = block.timestamp;
        emit ActorWasBorn(id_, block.timestamp);

        if (adultTime_ < block.timestamp) {
            _actors[id_].adultTime = block.timestamp;
        } else {
            _actors[id_].adultTime = adultTime_;
        }
    }

    /**
    @notice Grow the 
    @param id_ Person token id 
    @param time_ the deadline to grow
    */
    function setAdultTime(uint256 id_, uint256 time_)
        external
        override
        haveRights
        correctId(id_)
    {
        require(_actors[id_].born, NOT_BORN);
        _actors[id_].adultTime = time_;
    }

    function _isAdult(uint256 id_) internal view returns (bool) {
        return _actors[id_].born && _actors[id_].adultTime <= block.timestamp;
    }

    /**
@notice Get the person adult time
@param id_ Person token id
@return timestamp
*/
    function getAdultTime(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (uint256)
    {
        return _actors[id_].adultTime;
    }

    /**
@notice Get the person adult state
@param id_ Person token id
@return true = person is adult (price is 0 and current date > person's grow deadline)
*/
    function isAdult(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (bool)
    {
        return _isAdult(id_);
    }

    /**
@notice Get the person rank
@param id_ Person token id
@return person rank value
*/
    function getRank(uint256 id_)
        external
        view
        override
        correctId(id_)
        returns (uint16)
    {
        return _actors[id_].rank;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}