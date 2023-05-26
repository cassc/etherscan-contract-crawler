/*
              _             __   _                    __            
   ____ ___  (_)___  __  __/ /__(_)  ____ ___  ____ _/ /_____  _____
  / __ `__ \/ /_  / / / / / //_/ /  / __ `__ \/ __ `/ //_/ _ \/ ___/
 / / / / / / / / /_/ /_/ / ,< / /  / / / / / / /_/ / ,< /  __/ /    
/_/ /_/ /_/_/ /___/\__,_/_/|_/_/  /_/ /_/ /_/\__,_/_/|_|\___/_/     
                                                                    
*/

pragma solidity ^0.8.13;

import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error MustOwnThisMizkiMaker();
error MetadataFrozen();
error TokenIsSoulbound();
error MustOwnWithdrawnTokens();
error MismatchedBurnAndWithdrawLength();

contract MizukiMaker is ERC721AQueryable, Ownable {
    // Address of the OG Mizuki NFT contract
    address public _azukiMiladyContract;

    // Metadata to show for an uncustomized Mizuki Maker
    string public _defaultCid;

    // Metadata to show for a frozen Mizuki Maker
    string public _frozenCid;

    // Track which address deposited each OG Mizuki NFT
    mapping(uint256 => address) public depositor;

    // Maps token IDs to IPFS CIDs
    mapping(uint256 => string) public metadataCid;

    // Enables token metadata to be frozen if user points to a malicious IPFS CID
    mapping(uint256 => bool) public frozen;

    constructor(address azukiMiladyContract) ERC721A("Mizuki Maker", "MIZMAKER") {
        // Save a reference to the original Azuki Milady contract
        _azukiMiladyContract = azukiMiladyContract;
    }

    // Gets the token IDs of the original Azuki Milady owned by the given address
    function originalTokensOfOwner(address owner) public view returns (uint256[] memory) {
        // Make an array of appropriate size based on their balance on the original Azuki Milady contract
        uint256 numOwned = IERC721A(_azukiMiladyContract).balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](numOwned);

        // Used for iterating over slots in the return array
        uint16 returnArrayIndex = 0;

        // Look for the tokens they own
        for(uint256 i = 0; i < IERC721A(_azukiMiladyContract).totalSupply(); ++i) {
            if(IERC721A(_azukiMiladyContract).ownerOf(i) == owner) {
                tokenIds[returnArrayIndex] = i;
                ++returnArrayIndex;
            }
        }

        // Return our findings
        return tokenIds;
    }

    // Gets the token IDs of the original Mizuki the user deposited into this contract
    function depositedTokensOfOwner(address owner) public view returns (uint256[] memory) {
        // Make an array of appropriate size based on their balance on the original Azuki Milady contract
        uint256 numOwned = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](numOwned);

        // Used for iterating over slots in the return array
        uint16 returnArrayIndex = 0;

        // Look for the tokens they own
        for(uint256 i = 0; i < IERC721A(_azukiMiladyContract).totalSupply(); ++i) {
            if(IERC721A(_azukiMiladyContract).ownerOf(i) == address(this) && depositor[i] == owner) {
                tokenIds[returnArrayIndex] = i;
                ++returnArrayIndex;
            }
        }

        // Return our findings
        return tokenIds;
    }

    // Deposit an OG Mizuki NFT to mint a soulbound Mizuki Maker
    function deposit(uint256[] calldata tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Transfer the NFT to this contract
            IERC721A(_azukiMiladyContract).transferFrom(msg.sender, address(this), tokenIds[i]);

            // Track who deposited this NFT
            depositor[tokenIds[i]] = msg.sender;
        }

        // Mint them soulbound, customizable NFTs
        _mint(msg.sender, tokenIds.length);
    }

    // Withdraw an OG Mizuki NFT and burn the soulbound Mizuki Maker
    function withdraw(uint256[] calldata withdrawIds, uint256[] calldata burnIds) public {
        // Make sure the burn and withdraw arrays are the same length
        if (withdrawIds.length != burnIds.length) {
            revert MismatchedBurnAndWithdrawLength();
        }

        for (uint16 i = 0; i < withdrawIds.length; ++i) {
            // Ensure the sender owns the NFT they are trying to withdraw
            if(depositor[withdrawIds[i]] != msg.sender) {
                revert MustOwnWithdrawnTokens();
            }

            // Burn the customizable NFTs, _burn() checks ownership for us
            _burn(burnIds[i]);

            // Transfer the OG Mizuki NFT back to the owner
            IERC721A(_azukiMiladyContract).transferFrom(address(this), msg.sender, withdrawIds[i]);
        }
    }

    // Admin rescue function to force a withdrawal of a token back to its rightful owner
    function adminWithdraw(uint256 withdrawId) public onlyOwner {
        // Transfer the OG Mizuki NFT back to the owner
        IERC721A(_azukiMiladyContract).transferFrom(address(this), depositor[withdrawId], withdrawId);
    }

    // Updates the metadata CID for a Mizuki Maker
    function updateMetadata(uint256 tokenId, string memory cid) public {
        if(ownerOf(tokenId) != msg.sender && owner() != msg.sender) revert MustOwnThisMizkiMaker();

        // If the token has frozen metadata, it can't be updated
        if(frozen[tokenId] && owner() != msg.sender) revert MetadataFrozen();

        // Save the updated IPFS CID
        metadataCid[tokenId] = cid;
    }

    // Enables Mizuki team to update the metadata for frozen Mizuki Makers
    function setFrozenCid(string memory cid) public onlyOwner {
        _frozenCid = cid;
    }

    // Enables Mizuki team to update the default metadata for Mizuki Makers
    function setDefaultCid(string memory cid) public onlyOwner {
        _defaultCid = cid;
    }

    // Enables Mizuki team to freeze a Mizuki Maker's metadata if it points to a malicious IPFS CID
    function setFrozen(uint256[] calldata tokenIds, bool isFrozen) public onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            frozen[tokenIds[i]] = isFrozen;
        }
    }

    // Converts a CID to an IPFS URI
    function getIpfsURI(string memory cid) public pure returns (string memory) {
        return string(abi.encodePacked("ipfs://", cid, "/"));
    }

    // Returns the metadata URI for a Mizuki Maker
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if(frozen[tokenId]) {
            return getIpfsURI(_frozenCid);
        }

        // Check if this token has no metadata set
        if(bytes(metadataCid[tokenId]).length == 0) {
            return getIpfsURI(_defaultCid);
        }

        return getIpfsURI(metadataCid[tokenId]);
    }

    // Prevents Mizuki Makers from being transferred except during mints or burns
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 /* startTokenId */,
        uint256 /* quantity */
    ) internal virtual override {
        if(from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }
}