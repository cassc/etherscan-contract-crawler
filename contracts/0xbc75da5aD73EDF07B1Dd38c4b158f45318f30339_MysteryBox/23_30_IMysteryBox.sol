// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../utils/interfaces/IClaimableFunds.sol";

interface IMysteryBox is IERC721Metadata, IClaimableFunds {
    event Created(address indexed owner, uint256 indexed id, bool indexed rare);
    event Opened(address indexed owner, uint256 indexed id);
    event CommonLimitDefined(uint256 commonLimit);
    event CommonPriceDefined(uint256 commonPrice);
    event RareLimitDefined(uint256 rareLimit);
    event RarePriceDefined(uint256 rarePrice);
    event RarePriceIncreaseDefined(uint256 rarePriceIncrease);

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view returns (uint256);

    /**
@notice Set the maximum amount of the common potions saled for one account
@param value_ New amount
*/
    function setCommonLimit(uint256 value_) external;

    /**
@notice Set the price of the common potions for the account
@param value_ New price
*/
    function setCommonPrice(uint256 value_) external;

    /**
@notice Set the maximum amount of the rare potions saled for one account
@param value_ New amount
*/
    function setRareLimit(uint256 value_) external;

    /**
@notice Set the maximum amount of the common potions saled for one account
@param value_ New amount
*/
    function setRarePrice(uint256 value_) external;

    /**
@notice Set the increase of the rare price
@param value_ New amount
*/
    function setRarePriceIncrease(uint256 value_) external;

    /**
@notice Get the amount of the tokens account can buy
@return The two uint's - amount of the common potions and amount of the rare potions
*/

    /**
@notice Get the current rare price
@return Current rare price level
*/
    function getRarePrice() external view returns (uint256);

    function getIssued(address account_)
        external
        view
        returns (uint256, uint256);

    /**
@notice Create the packed id with rare or not (admin only)
@param target_ The box owner
@param rare_ The rarity flag
@return The new box id
*/
    function create(address target_, bool rare_) external returns (uint256);

    /**
@notice Get the rarity of the box
@param tokenId_ The id of the token
@return The rarity flag
*/
    function rarity(uint256 tokenId_) external view returns (bool);

    /**
@notice Deposit the funds (payable function)
*/
    function deposit() external payable;

    /**
@notice Open the packed box 
@param id_ The box id
@return The new potion id
*/
    function open(uint256 id_) external returns (uint256);
}