// SPDX-License-Identifier: MIT

// Metasuites Claim smart contract developed by namasteLabs.io

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract MOFC is ERC721Enumerable, Ownable {}

contract MOFCClaim is ERC721A, Ownable  {
    using SafeMath for uint256;
    using Strings for uint256;
    MOFC public mofc;
    string public baseTokenURI;
    mapping(uint256 => uint256) public claimedCount;
	mapping(uint256 => uint256) public lastClaimedAt;
	mapping(uint256 => bool) public founderList;
	bool public claimWindowStatus = false;
	uint256 monthlyQuota;
	uint256 claimCycle = 2592000;
	uint256 claimWindowOpen ;
	

    constructor() ERC721A("MetaPlugs", "MOFCC") {}

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

    function setMOFCAddress(address _addr) external onlyOwner {
        mofc = MOFC(_addr);
    }
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function claim(uint256 tokenId) external callerIsUser {
		require(claimWindowStatus,"Claim window not open");
		
		 require(msg.sender == mofc.ownerOf(tokenId), "Caller not owner of MOFC tokenId.");
		 require(founderList[tokenId],"NFT not Founder series");
		 
		uint256 expectedCount;
		if(lastClaimedAt[tokenId] == 0) {
			expectedCount = (block.timestamp - claimWindowOpen).div(claimCycle) ;
			}
		else {
			expectedCount = (block.timestamp - lastClaimedAt[tokenId]).div(claimCycle) ;
			}
        uint256 actualCount = expectedCount - claimedCount[tokenId] ;
       
          
            require((monthlyQuota - actualCount) >= 0,"Monthly Quota Exhausted");
            _safeMint(msg.sender, actualCount);
		    claimedCount[tokenId] += actualCount ;
			monthlyQuota -= actualCount;

    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getMOFCowner(uint256 tokenId) external callerIsUser view returns(address) {
        return mofc.ownerOf(tokenId);
    }
	
	function isFounder(uint256 tokenId) public view returns (bool) {
		return (founderList[tokenId]);
		
	}
	
	function setMonthlyQuota(uint256 quota) public onlyOwner {
		monthlyQuota = quota;
	}
	
	function setFounderList(uint256[] memory tokenIds) public onlyOwner {
		for(uint i=0; i<tokenIds.length ; i++){
			founderList[tokenIds[i]] = true ;
		}
	}

	 function flipClaimWindowStatus() public onlyOwner {
        claimWindowStatus = !claimWindowStatus;
        claimWindowOpen = block.timestamp - claimCycle ;       
    }
	
	 function getEligibilityCount(uint256 tokenId) external callerIsUser view returns(uint) {
		 uint expectedCount;
        if(lastClaimedAt[tokenId] == 0) {
			expectedCount = (block.timestamp - claimWindowOpen).div(claimCycle) ;
			}
		else {
			expectedCount = (block.timestamp - lastClaimedAt[tokenId]).div(claimCycle) ;
			}
        uint actualCount = expectedCount - claimedCount[tokenId] ;
		return(actualCount);
    } 
}