//SPDX-License-Identifier: BSD 
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// *tips fedora* m'lady
//                          /&&&@&@&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@,           
//                         %%&&%%&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@           
//                        %%&%&&&%&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@           
//                      (&&%&%&%%&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@#          
//                     %%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@          
//                    %%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&@&&@@@@@@@@@@@@@@@@@          
//                 .#%%%%&%%%%%&&%%%%&&&&&&&&&&&&&&@&@&@&@@@@@@@@@@@@@@@@@@@@(     
//          [email protected]@@@@@@@@@&@&&&&&&&%%%%&&&&&&&&&&&&&&&&&&&@&@@@@@@@@@@@@@@@@@@@@@@@@/ 
//      [email protected]@@@@@@@@@@&&&&&&&&&&%%%%%&%&&&&&&@@&@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
//   ,*(#**,*/%@@&&&&&&&&&&&&&%&%%&&&&&&&&&@@&&@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   
// /((*,,**(#**/#@&&@&&&&&&&&&&&&%&%%&&&&&&@&&&@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(    
// ,,*(#*,*/#%,**(#@&@&@&&@&@&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@(       
// .,*/(#,,/((/*,/%&&&&&&&&&&&&&@@&@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&%       
// .,,/(&*,/(%*,,,/,,*/(#%%/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&&&&&&&&&&&&&&&&       
// .,*/#%/(((,,*(//((/*,,,,,,,,,,,,,,,,,&&&&%(,,,,,,,,,,,,,,%&&&&&&&&&&&&&&&       
// */#%(*/(,,*/#*,,*&@@@@#&/,,,,,,,,,,,,,,,,*##((/**,,,,,,,,/&&&&&&&&&&&&&&%       
// */((*,.,,*(#,,,(@@@@. [email protected](,,,,,,,,,,,,,,//**(&@%,,,,,,,,,,,&&&&&&&&&&&&&&        
// .,,,*/,*/#  ,,*%@@@@@@&@@,,,,,,,,,,,,,,%@@@@(%@@/,,,,,,,,#&&&&&&&&&&&&&%        
// ,,***#(#    .,,,*%@@@@@@@*,,,,,,,,,,,,@@@@@@(.*@@@@,,,,,*&&&&&&&&&&&&&&*        
// *//(%*       ,,,,@ *@@@@@,,,,,,,,,,,,,@@@@@@@@@&@@[email protected],,,,*#&&&&&&&&%(*,,,        
// (%.          ,,,,,*&&@*,,,,*,,,,,,,,,,@@#@@@@&&@@ ,,,,,,,/%&&&%/,,,,,,,,,       
//               ,,,,,****,,**,,,,,,,,,,,,@&%(#%%@..,,,,,,,,/#%%%%(*,,,,*,         
//               .,,,,,,,,,,,,,.,,,,,*,,,,,,,,(@&,,,,,,,,,,/((%%%%/*,,,            
//                /(*,,,,,,,,*////*****/((*,,,,,,,,,,,,,,/##//((((/*,,*@@@@&,      
//                 */(*****(/,,,,,,,*&,,,,/*,,,,,,,,,,,,/#%#((((((/*,,*@@@@@@@@@@@ 
//                  ,%%(***/*,,,,,,,,,,,,*/(/*//*,,,,,,**#%((#####/**(*,,&@@@@@@@@&
//            ./#%&%((((/(((/,,,,,,,,,,,*,/(#(%((*,,,,/*/(####%##(*((*,,,,%@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&%(#%%%#/*,,,,,,,//####(((/**///((#%%%%%%%(#(,,,,,(@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&%#%%%%%%####%%%%%%%###/***//##%%&&&&%%&%*&@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@&&%%%%%%%%%%%%%##(//*///(%%%&&&%&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#**/((##%%%%##(#%%%%%%&&@&@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@&@@@@@@@@@@@@@@@@@&&&&&(###%%%%%#%&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@&@@@&&@@@@@@&@@@&@@@@@@@&&&&@@&&&&&@@@@&&&@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@
// @@@@&&@@@&&@@@@@@@&@@@@@@&@@@@@&&&@@@@((@@@@&@@@@@@@@@@@@@@@&@&@&&@@@@@@&@@@@@@@
// @@&&&@@@@&&@@@@@@@&@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@&&&@@@&&&@@@@@@&&@@@@&@@&@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@&&@@@@@&&&@@@@@&@@@@@@@@@@@@@@&&@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// &@@@&@&&&&&@@@@@@&&@@@@@&&@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@
// &@@@@@@@@&@@@@@@@&&@@@@&&&&@@@&@@@@@@@@@@@&&@@@@@@@@@&&@@@@@@@@@&&&@@@@@@@@@@@@@
// @@@@@@@@&&@@@@@@@&&@@@@&&&&&&(,&&@@@@@@@@@@&&@@@@@@@@@@@&&@@@@@@@@&&@@@@@@@@@@@@

abstract contract MiladyMaker {
        function balanceOf(address owner) view public virtual returns (uint);
        function tokenOfOwnerByIndex(address owner, uint256 index) view public virtual returns (uint256);
        function ownerOf(uint256 idx) view public virtual returns (address);
}

contract Soylads is Ownable, ReentrancyGuard, ERC721A {

    address private _milady_maker;
    string private _URI;

    bool private _halt_mint = true;
    bool private _is_revealed;
    

    uint256 constant TOTAL_TOKEN_SUPPLY = 5050;
    uint256 constant RATWELL_TAX_MINT_PRICE  = 0.1 ether;
    uint256 constant MINT_PRICE = 0.03 ether;
    uint256 constant MILADY_DISCOUNT = 0.01 ether;
    uint256 constant RATWELL_CUTOFF = 20;
    
    mapping(address => uint256) private _num_minted;


    constructor(address miladyMakerContract_) ERC721A("Soylads", "SLS") {
        _milady_maker = miladyMakerContract_;
    }

    function mint(uint256 numTokens) payable external nonReentrant {
        require(_halt_mint == false, "soylads: halted");
        require(numTokens > 0, "soylads: >0");
        require(totalSupply() + numTokens < TOTAL_TOKEN_SUPPLY, "soylads: >supply");

        MiladyMaker milady = MiladyMaker(_milady_maker);
        bool ownsMilady = milady.balanceOf(msg.sender) > 0;

        uint256 totalPrice = _computePrice(numTokens, msg.sender, ownsMilady);
        require(msg.value == totalPrice, "soylads: incorrect price");

        _num_minted[msg.sender] += numTokens;

        _safeMint(msg.sender, numTokens);
        
    }

    function adminMint(uint256 numTokens) external onlyOwner {
        _safeMint(msg.sender, numTokens);
    }


    function computePrice(uint256 numTokens) public view returns (uint256){
        MiladyMaker milady = MiladyMaker(_milady_maker);
        bool ownsMilady = milady.balanceOf(msg.sender) > 0;
        return _computePrice(numTokens, msg.sender, ownsMilady);
    }

    function _computePrice(uint256 numTokens, address addr, bool ownsMilady) public view returns (uint256) {
        uint256 numAlreadyMinted = _num_minted[addr];
        uint256 IND = ownsMilady ? 1 : 0;

        if ( numAlreadyMinted >= RATWELL_CUTOFF ) {
            return ((RATWELL_TAX_MINT_PRICE - IND*MILADY_DISCOUNT) * numTokens);
        }

        if ( (numAlreadyMinted + numTokens) > RATWELL_CUTOFF ) {
            uint256 nAbove = (numAlreadyMinted + numTokens) - RATWELL_CUTOFF; // LHS will be gt so this > 0
            uint256 nUnder = numTokens - nAbove;
        
            return ((MINT_PRICE - IND*MILADY_DISCOUNT) * nUnder) + ((RATWELL_TAX_MINT_PRICE - IND*MILADY_DISCOUNT) * nAbove);
        }

        return ((MINT_PRICE - IND*MILADY_DISCOUNT) * numTokens);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'tokenId?');

        // include the token index if revealed
        if (_is_revealed) {
            return string(abi.encodePacked(_URI, toString(tokenId)));
        } 

        // otherwise return the URI
        return string(_URI);
    }

    /**
     * @dev Halt minting 
    */
    function setHaltMint(bool v) public onlyOwner() {
        _halt_mint = v;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    **/
    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Set URI 
    */
    function setURI(string memory v) public onlyOwner() {
        _URI = v;
    }

    /**
     * @dev Set reveal 
    */
    function setIsReveal(bool v) public onlyOwner() {
        _is_revealed = v;
    }

	/////////////////////////////////////////////
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

}