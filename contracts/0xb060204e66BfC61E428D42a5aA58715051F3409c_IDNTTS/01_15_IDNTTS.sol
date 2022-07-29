/*

█ ██ |██|█ |█| █
█ ██ |██|█ |█| █
█ ██ |██|█ |█| █
     IDNTTS

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721S/ERC721SLockablePermittable.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";
import "./Base64.sol";

/// @title IDNTTS Project. Featuring Lockable extension by IDNTTS Labs
/// @dev   Check https://github.com/filmakarov/erc721s for details on Lockable NFTs        
/// @author of the contract filio.eth (twitter.com/filmakarov)

contract IDNTTS is ERC721SLockablePermittable, Ownable, ERC2981ContractWideRoyalties {  

    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                                GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_ITEMS = 10000;

    address private minterAddress;
    
    mapping (bool => string) private baseURI;
    string private unrevealedURI;
    string private metadataExtension = ".json";

    string public provenanceHash;

    bool public revealState;

    constructor(string memory _myBaseUnlocked, string memory _myBaseLocked, string memory _unrevBase) ERC721S("IDNTTS", "IDS") {
            baseURI[true] = _myBaseUnlocked;
            baseURI[false] = _myBaseLocked; 
            unrevealedURI = _unrevBase;    
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721SLockablePermittable, ERC2981ContractWideRoyalties)
        returns (bool)
    {
        return ERC721SLockablePermittable.supportsInterface(interfaceId) || 
               ERC2981ContractWideRoyalties.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 qty) public {
        require (msg.sender == minterAddress, "Not allowed to mint");
        require(totalMinted() + qty <= MAX_ITEMS, ">MaxSupply");

        _safeMint(to, qty);
    }

    /*///////////////////////////////////////////////////////////////
                       PUBLIC VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the link to the metadata for the token
    /// @param tokenId token ID
    /// @return string with the link
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NOT_EXISTS");
        if (revealState) {
            return string(abi.encodePacked(baseURI[getLocked(tokenId) == address(0)], tokenId.toString(), metadataExtension));
        } else {
            string memory json = string(abi.encodePacked('{"name": "IDNTTS #', tokenId.toString(), '", "description": "IDNTTS is the only 10k free mint with real utility. Artistic & technological innovation. We are crazy but free!", "image": "',unrevealedURI,'","attributes": [{"trait_type": "Revealed", "value": "No"}]}'));
            return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
        }
    }

    /// @notice Iterates over all the exisitng tokens and checks if they belong to the user
    /// This function uses very much resources.
    /// !!! NEVER USE this function with write transactions DIRECTLY. 
    /// Only read from it and then pass data to the write tx
    /// @param tokenOwner user to get tokens of
    /// @return the array of token IDs 
    function tokensOfOwner(address tokenOwner) external view returns(uint256[] memory) {
        uint256 tokenCount = _balanceOf[tokenOwner];
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 NFTId;
            for (NFTId = _startTokenIndex(); NFTId < nextTokenIndex; NFTId++) { 
                if (_exists(NFTId)&&(ownerOf(NFTId) == tokenOwner)) {  
                    result[resultIndex] = NFTId;
                    resultIndex++;
                } 
            }     
            return result;
        }
    }

    function unclaimedSupply() public view returns (uint256) {
        return MAX_ITEMS - totalMinted();
    }

    function getTokenTimestamp(uint256 tokenId) public view returns (uint256) {
        return uint256(_packedOwnerships[tokenId] >> 160);
    }

    /*///////////////////////////////////////////////////////////////
                       CUSTOM LOCKING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Can not lock tokens before the reveal
    function lock(address unlocker, uint256 id) public override {
        require(revealState, "CANT_LOCK_BEFORE_REVEAL");
        ERC721SLockable.lock(unlocker, id);
    }

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setMinter(address _newMinter) public onlyOwner {
        minterAddress = _newMinter;
    }

    function setRevealState(bool _revealState) public onlyOwner {
        revealState = _revealState;
    }
    
    function setBaseURI(string memory _newBaseUnlocked, string memory _newBaseLocked) public onlyOwner {
        baseURI[true] = _newBaseUnlocked;
        baseURI[false] = _newBaseLocked;
    }

    function setUnrevURI(string memory _newUnrevURI) public onlyOwner {
        unrevealedURI = _newUnrevURI;
    }

    function setMetadataExtension(string memory _newMDExt) public onlyOwner {
        metadataExtension = _newMDExt;
    }

    function setProvenanceHash(string memory _newPH) public onlyOwner {
        if (bytes(provenanceHash).length == 0) {
            provenanceHash = _newPH;
        } else {
            revert("Provenance hash already set");
        }
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev See ERC2981ContractWideRoyalties.sol
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

}

//   That's all, folks!