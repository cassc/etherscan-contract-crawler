//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RoyaltyByToken.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTFactoryNode is ERC1155PresetMinterPauser, Ownable, RoyaltyByToken
{

    //Token collection URI
    string private constant _token_uri = 'ipfs://QmaQgp3yPNePqEBt4WUWiBw9w7sYRwxvvfh4xo8qeoC1qa/{id}.json';

    //Open sea metadata URI
    string private constant _contract_uri = 'ipfs://QmbCV5jRVjKJuBCRszwBvYt8PBrhoH4Ky5nSSne4SZGmG7/contract.json';

    //Token collection data
    string private constant _name = 'NFT Factory Community Node';
    string private constant _symbol = 'NFTCN';

    //Token owner restriction
    uint256 private _maxTokenByWallet = 1;

    //Constructor
    constructor() 
        ERC1155PresetMinterPauser(_token_uri) 
         RoyaltyByToken() 
    {
        
    }

     /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external pure returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    //Open Sea meta-data
    function contractURI() external pure returns (string memory) {
        return _contract_uri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauser, RoyaltyByToken) returns (bool) {
        return ERC1155PresetMinterPauser.supportsInterface(interfaceId) || RoyaltyByToken.supportsInterface(interfaceId);
    } 

    //Redefine to limit tokens by wallet
    function _beforeTokenTransfer(
            address operator,
            address from,
            address to,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) internal virtual override(ERC1155PresetMinterPauser) {
    
        //Only owner can have more
        if (to != owner())
        {
            for (uint256 i = 0; i < ids.length; i++) {
                require(balanceOf(to, ids[i]) + amounts[i] <= _maxTokenByWallet, "max tokens by user exceeded");
            }
        }
        
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
}