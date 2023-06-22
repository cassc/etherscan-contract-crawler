// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721ALockable.sol";
import "./SignedAllowance.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";

/// @title Moonthers implementing ERC721A with Permits
/// @author of contract Fil Makarov (@filmakarov)

contract Moonthers is ERC721ALockable, Ownable, SignedAllowance, ERC2981ContractWideRoyalties {  

using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private constant MAX_ITEMS = 6666;
    uint256 public maxPerMint = 1;

    string private baseURI;
    string private unrevealedURI;
    string private metadataExtension = ".json";

    bool public publicSaleActive;
    bool public presaleActive;
    bool public revealState;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _myBase, string memory _unrevBase) ERC721A("Moonthers", "MTR") {
        baseURI = _myBase; 
        unrevealedURI = _unrevBase;     
    }

    // for testing purposes. 
    // if you want your collection to start from token #0, you can just remove this override
    // if you want it to start from token #1, change to 'return 1;' instead of 'return 5;'
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function presaleOrder(address to, uint256 nonce, bytes memory signature) public {
        require (presaleActive, "Presale not active");

        //_mintQty is stored in the right-most 128 bits of the nonce
        uint256 qty = uint256(uint128(nonce));
 
        require(_totalMinted() + qty <= MAX_ITEMS, ">MaxSupply");
        
        // this will throw if the allowance has already been used or is not valid
        _useAllowance(to, nonce, signature);

        _safeMint(to, qty); 
    }

    function publicOrder(address to, uint256 qty) public {
        
        require (publicSaleActive, "Public sale not active");
        require(_totalMinted() + qty <= MAX_ITEMS, ">MaxSupply");
        require (qty <= maxPerMint, ">Max per mint");

        _safeMint(to, qty);
    }

    function adminMint(address to, uint256 qty) public onlyOwner {
        require(_totalMinted() + qty <= MAX_ITEMS, ">MaxSupply");
        _safeMint(to, qty);
    }

    /*///////////////////////////////////////////////////////////////
                       PUBLIC METADATA VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the link to the metadata for the token
    /// @param tokenId token ID
    /// @return string with the link
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NOT_EXISTS");
        if (revealState) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), metadataExtension));
        } else {
            return unrevealedURI;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function unclaimedSupply() public view returns (uint256) {
        return MAX_ITEMS - totalSupply();
    }

    /// @notice  returns the Id of the last minted token
    function lastTokenId() public view returns (uint256) {
        require(_totalMinted() > 0, "No tokens minted");
        return _nextTokenId() - 1;
    }

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setUnrevURI(string memory _newUnrevURI) public onlyOwner {
        unrevealedURI = _newUnrevURI;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMetadataExtension(string memory _newMDExt) public onlyOwner {
        metadataExtension = _newMDExt;
    }

    function setMaxPerMint(uint256 _newMaxPerMint) public onlyOwner {
        maxPerMint = _newMaxPerMint;
    }

    function switchPresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function switchPublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setRevealState(bool _revealState) public onlyOwner {
        revealState = _revealState;
    }

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev See ERC2981ContractWideRoyalties.sol
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    /*///////////////////////////////////////////////////////////////
                       IERC165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ALockable, ERC2981ContractWideRoyalties)
        returns (bool)
    {
        return ERC721ALockable.supportsInterface(interfaceId) || 
               ERC2981ContractWideRoyalties.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                       ERC721Receiver interface compatibility
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes calldata
    ) external pure returns(bytes4) {
        return bytes4(keccak256("I do not receive ERC721"));
    } 

}

//   That's all, folks!