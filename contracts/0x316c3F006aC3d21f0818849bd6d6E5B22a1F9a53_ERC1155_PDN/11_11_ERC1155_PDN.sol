// SPDX-License-Identifier: UNLICENSED

/*
  _____               _     _               _____          ____  
 |  __ \             (_)   | |             |  __ \   /\   / __ \ 
 | |__) ___  ___  ___ _  __| | ___  _ __   | |  | | /  \ | |  | |
 |  ___/ _ \/ __|/ _ | |/ _` |/ _ \| '_ \  | |  | |/ /\ \| |  | |
 | |  | (_) \__ |  __| | (_| | (_) | | | | | |__| / ____ | |__| |
 |_|   \___/|___/\___|_|\__,_|\___/|_| |_| |_____/_/    \_\____/ 
                                                                 
*/

pragma solidity ^0.8.3; 

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol'; 
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

contract ERC1155_PDN is ERC1155Upgradeable { 

    using SafeMathUpgradeable for uint;
    
    address public owner;
    address public ERC20Address;

    /*
    * @dev: This function allows to initialize the smart contract setting { uri }, { ERC20Address } and { owner }
    *       from the address signature
    *
    * Requirements:
    *       - { ERC20Address } can not be null
    * Events:
    *       - initialize
    */

    function initialize(string memory _uri, address _ERC20Address) initializer public {
        require(_ERC20Address != address(0), "CANT_SET_NULL_ADDRESS");
        __ERC1155_init(_uri);
        ERC20Address = _ERC20Address;
        owner = msg.sender;
    }

    /*
    * @dev: This function allows to mint a specific token erc1155
    *
    * Requirements:
    *       - { to }, { amount } can not have 0 values
    *       - The ERC20Address is the only one that can run this function
    * Events:
    *       - erc1155 mint event
    */

    function mint(address _to, uint _id, uint _amount, bytes memory _data) public returns(bool){
        require(msg.sender == ERC20Address, "ADDRESS_DISMATCH");
        require(_amount > 0, "CANT_SET_NULL_AMOUNT");
        require(_to != address(0), "CANT_SET_NULL_ADDRESS");
        _mint(_to, _id, _amount, _data);
        return(true);
    }

    /*
    * @dev: Reverted to avoid transfer
    */

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        revert();
    }

    /*
    * @dev: Reverted to avoid transfer
    */
    
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        revert();
    }
    
}