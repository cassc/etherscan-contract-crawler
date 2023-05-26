// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title PocketCow
 * PocketCow - a contract for my non-fungible PocketCow.
 */
contract PocketCow is ERC721Tradable {
    
		string private m_strContractURI;
		
		constructor()
        ERC721Tradable("PocketCows", "PKC")
    {
			
		}

    function _baseURI() override internal pure returns (string memory) 
		{
        return "https://ipfs.io/ipfs/QmeJWJveaR54jQr3PeyddLbUmWBBL7oqTmaFKRhrFpW9j2/";
    }

		function contractURI() external view returns (string memory) 
		{
        return m_strContractURI;
    }

		function setContractURI(string memory strNewURI) external onlyOwner 
		{
			m_strContractURI = strNewURI;
		}
}

/*{
  "name": "Herbie Starbelly",
  "description": "Friendly OpenSea Creature that enjoys long swims in the ocean.",
	"external_url": "https://openseacreatures.io/3",
  "image": "https://storage.googleapis.com/opensea-prod.appspot.com/creature/50.png"
}*/