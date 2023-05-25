// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Structures} from "../../lib/Structures.sol";

interface IActors is IERC721Metadata {
    event Minted(address indexed owner, uint256 indexed id);

    event MintedImmaculate(address indexed owner, uint256 indexed id);

    event TokenUriDefined(uint256 indexed id, string kidUri, string adultUri);

    event ActorWasBorn(uint256 indexed id, uint256 bornTime);

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view returns (uint256);

    /**
    @notice Set an uri for the adult token (only for non immaculate)
    @param id_ token id
    @param adultHash_ ipfs hash of the kids metadata
    */
    function setMetadataHash(uint256 id_, string calldata adultHash_) external;

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
    ) external;

    /**
    @notice Get an uri for the kid token
    @param id_ token id
    @return Token uri for the kid actor
    */
    function tokenKidURI(uint256 id_) external view returns (string memory);

    /**
    @notice Get an uri for the adult token
    @param id_ token id
    @return Token uri for the adult actor
    */
    function tokenAdultURI(uint256 id_) external view returns (string memory);

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
    ) external returns (uint256);

    /**
@notice Get the person props
@param id_ Person token id
@return Array of the props
*/
    function getProps(uint256 id_) external view returns (uint16[10] memory);

    /**
    @notice Get the actor
    @param id_ Person token id
    @return Structures.ActorData full struct of actor
    */
    function getActor(uint256 id_)
        external
        view
        returns (Structures.ActorData memory);

    /**
@notice Get the person sex
@param id_ Person token id
@return true = male, false = female
*/
    function getSex(uint256 id_) external view returns (bool);

    /**
@notice Get the person childs
@param id_ Person token id
@return childs and possible available childs
*/
    function getChilds(uint256 id_) external view returns (uint8, uint8);

    /**
@notice Breed a child
@param id_ Person token id
*/
    function breedChild(uint256 id_) external;

    /**
@notice Get the person immaculate status
@param id_ Person token id
*/
    function getImmaculate(uint256 id_) external view returns (bool);

    /**
@notice Get the person born time
@param id_ Person token id
@return 0 = complete adult, or amount of tokens needed to be paid for
*/
    function getBornTime(uint256 id_) external view returns (uint256);

    /**
@notice Get the person born state
@param id_ Person token id
@return true = person is born
*/
    function isBorn(uint256 id_) external view returns (bool);

    /**
@notice Birth the person
@param id_ Person token id 
@param adultTime_ When person becomes adult
*/
    function born(uint256 id_, uint256 adultTime_) external;

    /**
@notice Get the person adult timestamp
@param id_ Person token id
@return timestamp
*/
    function getAdultTime(uint256 id_) external view returns (uint256);

    /**
@notice Grow the 
@param id_ Person token id 
@param time_ the deadline to grow
*/
    function setAdultTime(uint256 id_, uint256 time_) external;

    /**
@notice Get the person adult state
@param id_ Person token id
@return true = person is adult (price is 0 and current date > person's grow deadline)
*/
    function isAdult(uint256 id_) external view returns (bool);

    /**
@notice Get the person rank
@param id_ Person token id
@return person rank value
*/
    function getRank(uint256 id_) external view returns (uint16);
}