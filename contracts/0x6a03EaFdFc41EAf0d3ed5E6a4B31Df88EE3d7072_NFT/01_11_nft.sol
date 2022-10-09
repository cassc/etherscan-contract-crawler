// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;
 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable
{
	// Constants
	uint256 public constant TOTAL_SUPPLY = 987;
	
    uint256 public cou_Token;

	/// @dev Base token URI used as a prefix by tokenURI().
	string public baseTokenURI;

	constructor() ERC721("Goobrrz", "GOOB") 
	{
		cou_Token = 0;
		baseTokenURI = "https://tan-secret-tiger-14.mypinata.cloud/ipfs/QmdYjiEud8zG3SGGNDs1NDi5dD6MKxd5TNiaHaZPi8aej7/";
	}

	function mintTo(address recipient) public returns (uint256) 
	{
		require(cou_Token < TOTAL_SUPPLY, "No more Goobrrz left sorry :(");
		cou_Token++;
		
		_safeMint(recipient, cou_Token);
		return cou_Token;
	}

	/// @dev Returns an URI for a given token ID
	function _baseURI() internal view virtual override returns (string memory) 
	{
		return baseTokenURI;
	}

	/// @dev Sets the base token URI prefix.
	function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner 
	{
		baseTokenURI = _baseTokenURI;
	}
	
    function contractURI() public view returns (string memory) 
	{
        return "https://tan-secret-tiger-14.mypinata.cloud/ipfs/QmcoMSA6pNUPkNt382hCAWtW6yNaF5Nb4yx4oW8zyehSJN";
	}
}