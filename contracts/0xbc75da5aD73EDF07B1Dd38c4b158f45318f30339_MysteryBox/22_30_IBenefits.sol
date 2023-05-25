// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

import "../../lib/Structures.sol";

interface IBenefits {
    event BenefitAdded(
        address indexed target,
        uint256 from,
        uint256 to,
        uint256 price,
        uint16 id,
        uint16 amount,
        uint8 level
    );
    event BenefitUsed(address indexed target, uint256 id);
    event BenefitsCleared(address indexed target);

    /**
@notice Add a new benefit 
@param target_ target address 
@param price_ Price of the token
@param id_ The token id 
@param amount_ The tokens amount
@param level_ The locked tokens level
@param from_ The timestamp of start of rule usage
@param until_ The timestamp of end of rule usage
*/

    function add(
        address target_,
        uint256 price_,
        uint16 id_,
        uint16 amount_,
        uint8 level_,
        uint256 from_,
        uint256 until_
    ) external;

    /**
@notice Clear user's benefits for the contract 
@param target_ target address 
*/
    function clear(address target_) external;

    /**
@notice Check denied id 
@param current_ current id 
*/
    function denied(uint256 current_) external view returns (bool);

    /**
@notice Get available user benefit 
@param target_ target address 
@param current_ current tested token id
@param price_ the received price
@return benefit id, benefit price, benefit token id, benefit level  (all items can be 0)
*/
    function get(
        address target_,
        uint256 current_,
        uint256 price_
    )
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint16,
            uint8,
            bool // is fenefit found
        );

    /** 
@notice Set  user benefit 
@param target_ target address 
@param id_ benefit id
*/
    function set(address target_, uint256 id_) external;

    /**
@notice Read specific benefit 
@param target_ target address 
@param id_  benefit id
@return benefit 
*/
    function read(address target_, uint256 id_)
        external
        view
        returns (Structures.Benefit memory);

    /**
@notice Read total count of users received benefits 
@return count 
*/
    function totalReceivers() external view returns (uint256);

    /**
@notice Read list of the addresses received benefits 
@return addresses 
*/
    function listReceivers() external view returns (address[] memory);
}