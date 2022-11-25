//
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
// .-------. .-------.        ,-----.         .-./`)     .-''-.      _______ ,---------.         ,--------.     .`````-.                                       //       
// \  _(`)_ \|  _ _   \     .'  .-,  '.       \ '_ .') .'_ _   \    /   __  \\          \        |   _____|    /   ,-.  \                                      //       
// | (_ o._)|| ( ' )  |    / ,-.|  \ _ \     (_ (_) _)/ ( ` )   '  | ,_/  \__)`--.  ,---'        |  )         (___/  |   |                                     //       
// |  (_,_) /|(_ o _) /   ;  \  '_ /  | :      / .  \. (_ o _)  |,-./  )         |   \           |  '----.          .'  /                                      //       
// |   '-.-' | (_,_).' __ |  _`,/ \ _/  | ___  |-'`| |  (_,_)___|\  '_ '`)       :_ _:           |_.._ _  '.    _.-'_.-'                                       //       
// |   |     |  |\ \  |  |: (  '\_/ \   ;|   | |   ' '  \   .---. > (_)  )  __   (_I_)              ( ' )   \ _/_  .'                                          //       
// |   |     |  | \ `'   / \ `"/  \  ) / |   `-'  /   \  `-'    /(  .  .-'_/  ) (_(=)_)           _(_{;}_)  |( ' )(__..--.                                     //       
// /   )     |  |  \    /   '. \_/``".'   \      /     \       /  `-'`-'     /   (_I_)           |  (_,_)  /(_{;}_)      |                                     //       
// `---'     ''-'   `'-'      '-----'      `-..-'       `'-..-'     `._____.'    '---'            `...__..'  (_,_)-------'                                     //       
//  ______          .-./`)     ____    ,---.    ,---..-./`)   .---.        ____             ________ .-./`)     .-''-.  .-------.        .-''-.  .--.   .--.   //       
// |    _ `''.      \ '_ .') .'  __ `. |    \  /    |\ .-.')  | ,_|      .'  __ `.         |        |\ .-.')  .'_ _   \ |  _ _   \     .'_ _   \ |  | _/  /    //       
// | _ | ) _  \    (_ (_) _)/   '  \  \|  ,  \/  ,  |/ `-' \,-./  )     /   '  \  \        |   .----'/ `-' \ / ( ` )   '| ( ' )  |    / ( ` )   '| (`' ) /     //       
// |( ''_'  ) |      / .  \ |___|  /  ||  |\_   /|  | `-'`"`\  '_ '`)   |___|  /  |        |  _|____  `-'`"`. (_ o _)  ||(_ o _) /   . (_ o _)  ||(_ ()_)      //       
// | . (_) `. | ___  |-'`|     _.-`   ||  _( )_/ |  | .---.  > (_)  )      _.-`   |        |_( )_   | .---. |  (_,_)___|| (_,_).' __ |  (_,_)___|| (_,_)   __  //       
// |(_    ._) '|   | |   '  .'   _    || (_ o _) |  | |   | (  .  .-'   .'   _    |        (_ o._)__| |   | '  \   .---.|  |\ \  |  |'  \   .---.|  |\ \  |  | //       
// |  (_.\.' / |   `-'  /   |  _( )_  ||  (_,_)  |  | |   |  `-'`-'|___ |  _( )_  |        |(_,_)     |   |  \  `-'    /|  | \ `'   / \  `-'    /|  | \ `'   / //       
// |       .'   \      /    \ (_ o _) /|  |      |  | |   |   |        \\ (_ o _) /        |   |      |   |   \       / |  |  \    /   \       / |  |  \    /  //       
// '-----'`      `-..-'      '.(_,_).' '--'      '--' '---'   `--------` '.(_,_).'         '---'      '---'    `'-..-'  ''-'   `'-'     `'-..-'  `--'   `'-'   //       
//   .-_'''-.       .-''-.  ,---.   .--.    .-''-.     .-'''-. .-./`)    .-'''-.                                                                               //       
//  '_( )_   \    .'_ _   \ |    \  |  |  .'_ _   \   / _     \\ .-.')  / _     \                                                                              //       
// |(_ o _)|  '  / ( ` )   '|  ,  \ |  | / ( ` )   ' (`' )/`--'/ `-' \ (`' )/`--'                                                                              //       
// . (_,_)/___| . (_ o _)  ||  |\_ \|  |. (_ o _)  |(_ o _).    `-'`"`(_ o _).                                                                                 //       
// |  |  .-----.|  (_,_)___||  _( )_\  ||  (_,_)___| (_,_). '.  .---.  (_,_). '.                                                                               //       
// '  \  '-   .''  \   .---.| (_ o _)  |'  \   .---..---.  \  : |   | .---.  \  :                                                                              //       
//  \  `-'`   |  \  `-'    /|  (_,_)\  | \  `-'    /\    `-'  | |   | \    `-'  |                                                                              //       
//   \        /   \       / |  |    |  |  \       /  \       /  |   |  \       /                                                                               //       
//    `'-...-'     `'-..-'  '--'    '--'   `'-..-'    `-...-'   '---'   `-...-'                                                                                //       
//                                                                                                                                                             //       
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Project52 is     
    ERC1155PresetMinterPauser, 
    Ownable, 
    DefaultOperatorFilterer 
{

    string public name = "Project 52 - Djamila Fierek Genesis";
    string public symbol = "P52";
    
    string public contractUri = "https://nft.djamilafierekart.com/contract"; 

    constructor() ERC1155PresetMinterPauser("https://nft.djamilafierekart.com/{id}") {
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length, "Contract Info: to and id length mismatch");
        require(to.length == amount.length, "Contract Info: to and amount length mismatch");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}