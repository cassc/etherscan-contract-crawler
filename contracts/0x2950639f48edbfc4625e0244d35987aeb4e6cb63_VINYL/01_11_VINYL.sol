// SPDX-License-Identifier: MIT
/// @dev SOUNDMINT VINYL
///
/********************************************************************************
*                                                                               *
*                           ,%@@@&&&&&&&&&&&&&&&&@%*                            *
*                      /@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&@@(                       *
*                  [email protected]@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&%%#%#&@*                   *
*                @@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&%%%%%%###&@.                *
*             *@&&&@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&%#%%%#%%#####(@#              *
*            @&&&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&&&%%#%###%##%#####(@%            *
*          @%&&&&&&&@@@@@@@@@@@@@@@@@@@&&&&&&&&&%%%#######%##%######&           *
*         @&&&&&&&&&&@@@@@@@@@@@@@@@@@@&&&&&&&@%%%%#%###%###%##%#####@/         *
*        &@@@@@&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@%%%######%###%#####%####(@#        *
*       @@@@@@@@@@@&&&@@@@@@@@@@@/.,,,,,,,,.(@@@%##(####%##########%%%&@,       *
*      @@@@@@@@@@@@@@@@@@@@@@@/,,,,,,,,,,,,,,,.(&@%##%######%%&&&@@@@@@@@       *
*      @@@@@@@@@@@@@@@@@@@@@@.,,,,,,,,,,,,,,,,,,[email protected]@@%%@&@&@@@@@@@@@@@@@@@(      *
*     /@@@@@@@@@@@@@@@@@@@@@.,,,,,,,,,,,,,,,,,,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@      *
*     (@@@@@@@@@@@@@@@@@@@@&,,,,,,,,,,* ,,,,,,,,,,&@@@@@@@@@@@@@@@@@@@@@@@      *
*     /@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@      *
*      @@@@@@@@@@@@&@&&&%&&@@,,,,,,,,,,,,,,,,,,,,&@@@@@@@@@@@@@@@@@@@@@@@#      *
*      &@@@@&@&&%%##%%%%%%%&@@*,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@.      *
*       @%%%#%###%%%%%%%%%&%%@@@@*.,,,,,,,,,,@@@@&&&&&&@@@@@@@@@@@@@@@@@%       *
*        @####%%%%%%%%%%%&&&@&&&@@@@@@@@@@@@@@&&&&&&&&&&&&&@@@@@@@@@@@@&        *
*         @#%%#%%#%%%%&%&&@&&@&@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&@@@@@@@&         *
*          @&%#%%%%%%%%&&@&&&@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&@,          *
*            @###%%%&&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&&&@&&&&&&&&&@@            *
*              @#%%%%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&@@              *
*                &@%%&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&@&                *
*                   @@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@                   *
*                      *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                      *
*                           ,%@@@@@@@@@@@@@@@@@@@@@%,                           *
*                                                                               *
*********************************************************************************/
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./subContracts/ERC1155PackedBalance.sol";

contract VINYL is ERC1155PackedBalance, Ownable {
    using Address for address;
    using Strings for uint256;

    string private baseURI;
    bytes32 public merkleRoot = 0xdb9f7b75bd7be5081adf28065e8d2dd1322f281c829a80c122d483779b958616;

    mapping (uint256 => uint256) _redeemed;

    bool public isActive = false;
    
    enum VINYLTYPE {
        MINT,
        GOLD,
        ONYX
    }
    string public name = "SoundMint Vinyl";

    /*
     * Function to mint NFTs (internal)
    */
    function mint(address to, uint mint_type) internal 
    {
        if (mint_type == 1)
	{
		_mint(to, uint(VINYLTYPE.MINT), 1, "");
        } 
        else if (mint_type == 2)
        {
        	_mint(to, uint(VINYLTYPE.MINT), 2, "");
        } 
        else
	{
            uint256[] memory Collect = new uint256[](2);
            uint256[] memory Count = new uint256[](2);
            if (mint_type == 5)
            {
                Collect[0] = uint(VINYLTYPE.GOLD);
                Collect[1] = uint(VINYLTYPE.ONYX);
                Count[0] = 10;
                Count[1] = 10;
            }
            else
	    {
                Collect[0] = uint(VINYLTYPE.MINT);
                Collect[1] = uint(VINYLTYPE.GOLD);
                if (mint_type == 3)
                {
                    Count[0] = 2;
                    Count[1] = 1;
                }
                else if(mint_type == 4)
                {
                    Count[0] = 4;
                    Count[1] = 2;
                }
            }
            _batchMint(to, Collect, Count, "");
        }
    }
    
    
    /*
     * Function to burn NFTs (public)
    */

    function burn(uint _id, uint amount) external 
    {
        require(isActive, "Contract is not active");
       _burn(msg.sender, _id, amount);
    }
    /*
     * Function toggleActive to activate/desactivate the smart contract
    */

    function toggleActive() external onlyOwner 
    {
        isActive = !isActive;
    }

    /*
     * Function to set Base URI
    */
    function setURI(string memory _URI) external onlyOwner 
    {
        require(keccak256(abi.encodePacked(baseURI)) != keccak256(abi.encodePacked(_URI)), "baseURI is already the value being set.");
        baseURI = _URI;
    }

    /*
     * Function to set the merkle root
    */

    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner 
    {
	    require(merkleRoot != merkleRootHash,"merkelRoot already being set.");
        merkleRoot = merkleRootHash;
    }

    function hasNotMinted(uint256 index) external view returns (bool)
    {
      uint256 redeemedBlock = _redeemed[index / 256];
      uint256 redeemedMask = (uint256(1) << uint256(index % 256));
      return ((redeemedBlock & redeemedMask) == 0);
    }

    /*
     * Function to mint new NFTs during presale/raffle
     */
  
    function mintNFT(uint256 index, uint256 mint_type, bytes32[] memory _proof) external
    {
        require(isActive, "Contract is not active");
      
      	// Check Allowlist
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mint_type, index));
        require(verify(merkleRoot, _proof, leaf), "Not Allowlisted");
      
        // To prevent several mint
	uint256 redeemedBlock = _redeemed[index / 256]; 
        uint256 redeemedMask = (uint256(1) << uint256(index % 256)); 
        require((redeemedBlock & redeemedMask) == 0, "Drop already claimed");
        _redeemed[index / 256] = redeemedBlock | redeemedMask;
	
        mint(msg.sender, mint_type);
        
    }

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT_PUBLIC
    */

    function uri(uint256 _tokenId) external view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /*
     * Function to verify the Merkle Tree Proof
    */
    function verify(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 leaf
    ) public pure returns (bool) 
    {
        bytes32 hash = leaf;

        for (uint i = 0; i < proof.length; i++) 
	    {
            bytes32 proofElement = proof[i];

            if (hash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }            
        }

        return hash == root;
    }
}