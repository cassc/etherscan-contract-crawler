/* SPDX-License-Identifier: MIT
......................................:@@@@@@@@@@@@@@@@@;,,,,,,,,,,.......................
...........................+S##########SSSSSSSSSSSSSSSS%S##########*......................
...........................*@@@@@@@@@@@%%%%%%%%%%%%%%%%%@@@@@@@@@@@?......................
......................,,,,,[email protected]@@@@@@@@@@%%%%%%%%%%%%%%%%%#@@@@@@@@@@?,,,,,.................
.....................:####@S%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%S#####;................
.....................;@@@@@S%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%[email protected]@@@@;................
................:::::[email protected]@@@@S%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%[email protected]@@@@*;;;;;,..........
...............,#@@@@#%%%%%%%%%%%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%#@@@@@;..........
...............,@@@@@@%%%%%%%%%%%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%#@@@@@;..........
..........,+++++######%%%%%SSSSSS%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%#@@@@@;..........
..........;@@@@@%%%%%%%%%%%#@@@@@*+++++++++++++++++++++++++++*@@@@@#%%%%%#@@@@@;..........
..........:@@@@@%%%%%%%%%%%#@@@@@*+***************************@@@@@@%%%%%#@@@@@:..........
.....*?????SSSSS%%%%%S#####S%%%%%*****************************%%%%%%#####SSSSSS?????*.....
....,#@@@@#%%%%%%%%%%[email protected]@@@@%+++++*****************************[email protected]@@@@S%%%%%@@@@@#,....
....,#@@@@#%%%%%%%%%%[email protected]@@@@%+*************************************[email protected]@@@@S%%%%%#@@@@#,....
....,#@@@@#%%%%%%%%%%[email protected]@@@@%+**************************************[email protected]@@@@S%%%%%#@@@@#,....
....,#@@@@#%%%%%%%%%%[email protected]@@@@%+***********??????????*******[email protected]@@@@S%%%%%#@@@@#,....
....,#@@@@#%%%%%%%%%%[email protected]@@@@%+***********???????????******??????????%@@@@@S%%%%%#@@@@#,....
....,#@@@@#%%%%%S####@@@@@@%+**********?????%@@@@@S+****??????#@@@@@@@@@@S%%%%%#@@@@#,....
.....#@@@@#%%%%%#@@@@@@@@@@%+**********?????%@@@@@S+****[email protected]@@@@@@@@@@S%%%%%#@@@@#.....
,,,,,#@@@@#%%%%%#@@@@@@@@@@%+**********?????%#@@@@%+****??????#@@@@@@@@@@#%%%%%#@@@@#,,,,,
#####%%%%%[email protected]@@@@@@@@@@@@@@@%+***********?????************?????*****[email protected]@@@@@@@@@@%%%%%[email protected]####
@@@@@%%%%%[email protected]@@@@@@@@@@@@@@@%+***********?????*********++*?????*+**[email protected]@@@@@@@@@@%%%%%[email protected]@@@@
@@@@@%%%%%[email protected]@@@@@@@@@@@@@@@%+*************************?*????******[email protected]@@@@@@@@@@%%%%%[email protected]@@@@
@@@@@%%%%%[email protected]@@@@@@@@@@@@@@@%+***********************+%@@@@@%+*****[email protected]@@@@@@@@@@%%%%%[email protected]@@@@
@@@@@%%%%%[email protected]@@@@@@@@@@@@@@@%+***********************+%@@@@@%+*****[email protected]@@@@@@@@@@%%%%%[email protected]@@@@
@@@@@%%%%%[email protected]@@@@@@@@@@@@@@@%+***********************+?#####?+*****[email protected]@@@@@@@@@@%%%%%[email protected]@@@@
@@@@@%%%%%[email protected]@@@@@@@@@@@@@@@%+*************************+++++*******[email protected]@@@@@@@@@@%%%%%[email protected]@@@@
@@@@@%%%%%[email protected]@@@@@@@@@@@@@@@%+**********************+++++++++++****[email protected]@@@@@@@@@@%%%%%[email protected]@@@@
@@@@@%%%%%S#####@@@@@@@@@@@%+**********************%%%%%%%%%%%****[email protected]@@@@######SSSSSS?????
@@@@@%%%%%%%%%%%#@@@@@@@@@@%+********************[email protected]@@@@@@@@@@?+**[email protected]@@@@S%%%%%@@@@@#.....
@@@@@%%%%%%%%%%%#@@@@@@@@@@%+*********************[email protected]@@@@@@@@@@[email protected]@@@@S%%%%%@@@@@#,....
*****S####S%%%%%S#####@@@@@%+***************+:::::+S%%%%%%%%%%SSSSS%SSSSSS#####*++++;.....
.....#@@@@#%%%%%%%%%%[email protected]@@@@?+***************+.....:?*****[email protected]@@@@#%%%%%[email protected]@@@@:..........
....,#@@@@#%%%%%%%%%%[email protected]@@@@?+***************+.....:?????*+**+*#@@@@#%%%%%[email protected]@@@@;..........
.....:::::%#####%%%%%[email protected]@@@@?+**********######SSSSSS###########[email protected]@@@@?:::::,..........
[email protected]@@@@%%%%%[email protected]@@@@?+********+*@@@@@@@@@@@@@@@@@@@@@@@%%%%%[email protected]@@@@?................
[email protected]@@@@%%%%%[email protected]@@@@?+********+*@@@@@@@@@@@@@@@@@@@@@@@%%%%%[email protected]@@@@*................
[email protected]@@@@%%%%%[email protected]@@@@?+********[email protected]@@@@#%%%%%%%%%%%%%%%%%#@@@@S:,,,,,................
[email protected]@@@@%%%%%[email protected]@@@@?+********[email protected]@@@@#%%%%%%%%%%%%%%%%%@@@@@#......................
[email protected]@@@@%%%%%[email protected]@@@@?+********[email protected]@@@@#%%%%%%%%%%%%%%%%%@@@@@#......................             
					,--.             .      ,-,---.     .      .-,--.         .       
					| `-' ,-. . . ,-. |- ,-.  '|___/ ,-. |-. . . '|__/ . . ,-. | , ,-. 
					|   . |   | | | | |  | |  ,|   \ ,-| | | | | ,|    | | | | |<  `-. 
					`--'  '   `-| |-' `' `-' `-^---' `-^ ^-' `-| `'    `-^ ' ' ' ` `-' 
										/| |                           /|                       
										`-' '                          `-'                       
*/

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected],com
contract CryptoBabyPunks is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    bool contractLocked = false;
    string baseUri = "ipfs://QmeNFdcKW6McnrT5MhVrTah4MTcoybZLKTyDQpovjXApyg/";


    constructor() ERC721("CryptoBabyPunks", "CBP") {
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function airdropBaby(address to, uint256 cbpId) public onlyOwner {
        _safeMint(to, cbpId);
    }

    function secureBaseUri(string memory newUri) public onlyOwner {
        require(!contractLocked, "Contract has been locked and URI can't be changed");
        baseUri = newUri;
    }
    
    function lockContract() public onlyOwner {
        require(contractLocked, "Contract is already locked");
        contractLocked = true;   
    }
    
	/*
	 * Helper function
	 */
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) return new uint256[](0);
		else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}