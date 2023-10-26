// SPDX-License-Identifier: MIT

//                      ^->`
//                  .:\B$$$$&}".
//               ` `$$$$v+[M$$$@ .'
//           ."}&$.`$$$?    v$$$ "$z_`
//        'lj$$$$$.`$$$_    n$$$ "$$$$B|:.
//     ^?#$$$@$$$$.`$$$_    n$$$ "$$$B@$$$v~`
//    u$$$*_` }$$$.`$$$_    n$$$ "$$$: "[&$$$?
//    u$$*    }$$$.`$$$_    n$$$ "$$$:   .$$$]
//    u$$z    }$$$.`$$$_    n$$$ "$$$:   .$$$]
//    u$$*    }$$$.`$$$_    n$$$ "$$$:   .$$$]
//    n$$$u<` `?#$.`$$$$r!' "(%$ "$$$B|:. ;t@]
//    ."18$$$81,.'  'lj$$$$M[".`  `<u$$$$v~`.'
//    }i' `+c$$$$n.`n>`."}&$$$@f `|:..:|B$$$8;
//    u$$u   .j$$$.`$$$+   `#$$$ ^$$$,   ,$$$]
//    u$$z    }$$$.`$$$_    n$$$ ^$$$:   '$$$]
//    u$$*    }$$$.`$$$_    n$$$ ^$$$:   '$$$]
//    u$$%!'  }$$$.`$$$_    n$$$ ^$$$:  `]$$$]
//    ")8$$$M}z$$$.`$$$_    n$$$ ^$$$j(%$$$%(`
//       `~c$$$$$$.`$$$_    n$$$ ^$$$$$$c+`
//          .:\B$$.`$$$_    n$$$ ^$$B\:.
//              ^?.`$$$zI'`<%$$$ `-^
//                 .lj$$$$$$$@fI
//                    ."{8M]"

// Access Certificate Claiming System Developed by NFT Elite Consulting x MisterSausage for Swanky Space Squad

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract SSS is ERC721Enumerable, Ownable {}

contract DigitalAccessCertificate is ERC721A, Ownable  {
    using SafeMath for uint256;
    using Strings for uint256;
    SSS public sss;
    string public baseTokenURI;
    mapping(uint256 => bool) public claimed;
	bool public claimWindowStatus = false;

    constructor() ERC721A("Digital Access Certificate", "DAC") { }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSSSAddress(address _addr) external onlyOwner {
        sss = SSS(_addr);
    }
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function claim(uint256[] memory tokenIds) external callerIsUser {
		require(claimWindowStatus,"Claim window not open");
        uint len = tokenIds.length;
        for(uint i; i < len; i++) {
            require(msg.sender == sss.ownerOf(tokenIds[i]), "Caller not owner of SSS tokenId.");
            require(!claimed[tokenIds[i]],"Access Certificate already claimed");
            claimed[tokenIds[i]] = true;
        }

        _safeMint(msg.sender, len);

    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getSSSowner(uint256 tokenId) external callerIsUser view returns(address) {
        return sss.ownerOf(tokenId);
    }

	 function flipClaimWindowStatus() public onlyOwner {
        claimWindowStatus = !claimWindowStatus;
    }
}