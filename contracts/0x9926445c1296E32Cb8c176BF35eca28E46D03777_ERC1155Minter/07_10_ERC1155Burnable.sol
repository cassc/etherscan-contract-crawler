/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC1155.sol";

/*************************************************************
 * @title ERC1155Burnable                                    *
 *                                                           *
 * @notice  ERC-1155 burnable extension                      *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract ERC1155Burnable is ERC1155 {
    function burn(address _from, uint256 _id, uint256 _value) public virtual {
        require(msg.sender == _from || isApprovedForAll[_from][msg.sender]);

        _burn(_from, _id, _value);
    }
}