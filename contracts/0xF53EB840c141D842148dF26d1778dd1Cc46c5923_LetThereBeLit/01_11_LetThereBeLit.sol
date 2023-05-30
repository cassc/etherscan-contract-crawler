// SPDX-License-Identifier: MIT

/*

 (                                                                  (     (            
 )\ )           )    *   )    )                       )             )\ )  )\ )  *   )  
(()/(    (   ( /(  ` )  /( ( /(    (   (      (    ( /(    (    ||_(()/( (()/(` )  /(  
 /(_))  ))\  )\())  ( )(_)))\())  ))\  )(    ))\   )\())  ))\  (_-< /(_)) /(_))( )(_)) 
(_))   /((_)(_))/  (_(_())((_)\  /((_)(()\  /((_) ((_)\  /((_) / _/(_))  (_)) (_(_())  
| |   (_))  | |_   |_   _|| |(_)(_))   ((_)(_))   | |(_)(_))    || | |   |_ _||_   _|  
| |__ / -_) |  _|    | |  | ' \ / -_) | '_|/ -_)  | '_ \/ -_)      | |__  | |   | |    
|____|\___|  \__|    |_|  |_||_|\___| |_|  \___|  |_.__/\___|      |____||___|  |_|    

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LetThereBeLit is ERC1155, Ownable {
    using Strings for uint256;

    string public constant name = "Let There Be $LIT";

    constructor()
        ERC1155(
            "https://gateway.pinata.cloud/ipfs/QmX7R3WkKzmtHpNVXvw9XyQnvkBeLEntty3GFgSq4CAkdX/{id}.json"
        )
    {}

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function batchMint(address[] memory _addresses, uint256 _tokenId)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _tokenId, 1, "");
        }
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://gateway.pinata.cloud/ipfs/QmX7R3WkKzmtHpNVXvw9XyQnvkBeLEntty3GFgSq4CAkdX/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }
}