// SPDX-License-Identifier: MIT

//                                                         ...::^^: ^????JJJ?7~.  :^:::.              
//    :?7~^:                                   ...:. :!77???JJJJJY? 75YYYYYYYYYY!..~~~~~^.            
//    !5555Y!  ^!~^^^.  ........       :^^~~~~!!!!7! !YYYYYJYYYYYY? 75YYYYY5YYYY5J.:~~~~~~.  .^~^:..  
//    ?YYYYY~ ~Y5555J^ ~~~~~~~~~~^:   :777!!!!!!!!7! ~YJJJJJJJJ???^ !5YYYY7~JYYYY57 ^~~~~~^ .~~~~~~~^ 
//   .YYYYY? !YYYYY!  .~~~~~~~~~~~~^. :!!!!!!!!!~~~: !YJJJY!..      !5YYYY: :YYYYYY. ^~~~~~^~~~~~~~^. 
//   ^YYYYY7!YYYYY!   :~~~~~^^~~~~~~^ ^7!!!!~.       !YJJJJ?!!!.    !5YYYY~.7YYYYYJ.  ^~~~~~~~~~~~^   
//   75YYYYYYYYYYJ.   :~~~~~. :~~~~~^ ^7!!!!!~~~.    7YJJJJYYYY!    !5YYYYYYYYYY5Y^    ^~~~~~~~~~:    
//   JYYYYYYYYYYY?    ^~~~~~..^~~~~~. ~!!!!!!777^    7YJJJJJJJ?:    !5YYYYYY555Y7:     .~~~~~~~~:     
//  :YYYYYYYYYYYYJ    ^~~~~~~~~~~~~.  ~!!!!!!!~~.    ?YJJJJ^ .      75YYYYY?7!^.        ^~~~~~~^      
//  ~5YYYYY5YYYYYY^  .~~~~~~~~~~~~.   !!!!!!.   ...  ?YJJJJ?7?????~ 75YYY57             :~~~~~~:      
//  ?YYYYYY7JYYYY57  :~~~~~~~~~~~~:  .!!!!!!~~!!!!!:.JJJJJJYYYYYYY! J5YYY57             ^~~~~~~:      
// .YYYYYY~ !5YYYYJ. ^~~~~~:^~~~~~~  :7!!!!!!!!!!!7.:YYYYYYYJJJJJJ^ JYYJJJ~             ^~~~~~~^      
// ~5YYYY?  ~5YYYYY: ~~~~~~..~~~~~~: ~7777!!!!!!!!^ .!!~^^^:::.... .....:::::...        .:::^^~:      
// 7555557  :55YY55~.~~~~~~. ~~~~~~^ :^^::::...     ::::::    :^^~~~~: ~!!!!!!!!!~:.                  
// .~!!!!:   ~???77^.^^:::.  ...  . .^^~!!~        ^~~~~~~.   ^~~~~~~^ ~!!!!!!!!!!7!:                 
//                     .^~7????!^. .J55555J.      .~~~~~~~.   ^~~~~~~^ ~!!!!7:^7!!!7!                 
//                   :!JYYYYYYYYYJ^.YYYYY5!       :~~~~~~~    ^~~~~~~: ~!!!!!~!!!!!!:                 
//                 .7JYJJYYYYYYYJ7::YYYYY5~       ^~~~~~~^    ~~~~~~~. ~!!!!!!!!!!!:                  
//                ~JYJJJY?~~7?7^.  ^YYYYYY^       ^~~~~~~^   .~~~~~~~  ~!!!!!7!!!!!~.                 
//               !YJJJYJ^          ~5YYYYY:       ^~~~~~~^   :~~~~~~:  !!!!!!^!!!!!!!                 
//              ~YJJJJJ:           75YYYYJ.       ^~~~~~~~..:~~~~~~~  .!!!!!~ :7!!!!7:                
//             :JJJJJY~            ?YYYY5?        :~~~~~~~~~~~~~~~~.  ^7!!!7^ ~!!!!!!.                
//             7YJJJJJ:           :YYYYY57..::^^~: ~~~~~~~~~~~~~~~.   !!!!!!!!!!!!!7~                 
//            :YJJJJJY~   :7?7!~: ~5YYYYYYYYYYY55? .~~~~~~~~~~~~:    :7!!!!!!!!!!!!~                  
//            ^YJJJJJJJ?7?JYYYYY~ JYYYYYYYYYYYYY5~  .:^~~~~~^^:.     ^!!!!!!77!!!~:                   
//            .JYJJJJJJYYYJYYJ7^ ~5555555YYYYJJJ7.     .....          ....:::::..                     
//             ^?YYYYYYYYYJ?!:   7?77!~~^^::..                                                        
//              .^!77?7!~^.                                                                           

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity 0.8.9;
pragma abicoder v2;

contract KreepyClaim is ERC1155, Ownable {

    bool public claimIsActive = false;

    bytes32 public claimRoot; // Merkle Root for Claim

    uint256 public currentClaim = 0;

     // Claim Tracking
    mapping(address => uint256) claimedToken;

    string public _baseURI = "";

    constructor() ERC1155(_baseURI) { }
    
   function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function setCurrentClaim(uint256 newClaim) public onlyOwner {
        currentClaim = newClaim;
    }

    function setClaimRoot(bytes32 root) external onlyOwner {
        claimRoot = root;
    }

	// Utility 

    function hasClaimed(address _address) external view returns (uint) {
    return claimedToken[_address];
    }

    // Minting

    function kreepyClaimMint(bytes32[] calldata proof) external {
        require(claimIsActive, "Claim window is not active");
        require(MerkleProof.verify(proof, claimRoot, keccak256(abi.encodePacked(_msgSender()))), "Not Eligible");
        require(claimedToken[msg.sender] < currentClaim, "You have already claimed this piece");

            _mint(msg.sender, currentClaim, 1, "0x0000");
            claimedToken[msg.sender] = currentClaim;
    } 

}