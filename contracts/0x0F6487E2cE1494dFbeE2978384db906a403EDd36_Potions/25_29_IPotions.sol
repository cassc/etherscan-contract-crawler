// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IPotions is IERC721Metadata {
    event Created(address indexed owner, uint256 indexed id, uint256 indexed level);
    event Opened(address indexed owner, uint256 indexed id);
    event ChildsDefined(uint256 indexed childs);
    event TokenUriDefined(uint256 indexed id, string tokenUri);

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view returns (uint256);

    /**
@notice Get the amount of the actors remains to be created
@return The current value
*/
    function unissued() external view returns (uint256);

    /**
@notice Get the level of the potion
@param id_ potion id
@return The level of the potion
*/
    function level(uint256 id_) external view returns (uint256);

    /**
@notice Set the maximum amount of the childs for the woman actor
@param childs_ New childs amount
*/
    function setChilds(uint256 childs_) external;

    /**
@notice Get the current  maximum amount of the childs
@return The current value
*/
    function getChilds() external view returns (uint256);

    /**
@notice Open the packed id with the random values
@param id_ The pack id
@return The new actor id
*/
    function open(uint256 id_) external returns (uint256);

    /**
@notice return max potion level
@return The max potion level (1-based)
*/

    function getMaxLevel() external view returns (uint256);

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
    ) external returns (uint256);

    /**
@notice Create the packed potion with desired level (admin only)
@param target The pack owner
@param level The pack level
@param id_ The id of a new token
@return The new pack id
*/
    function createPotion(
        address target,
        uint256 level,
        uint256 id_
    ) external returns (uint256);

    /**
@notice get the last pack for the address
@param target The  owner 
@return The  pack id
*/
    function getLast(address target) external view returns (uint256);

    /**
@notice Decrease the amount of the common or rare tokens or fails
*/
    function decreaseAmount(bool rare) external returns (bool);

    /**
    @notice Set an uri for the token
    @param id_ token id
    @param metadataHash_ ipfs hash of the metadata
    */
    function setMetadataHash(uint256 id_, string calldata metadataHash_)
        external;
}