/*
    Blank Token
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./SignedAllowance.sol";
import "./Base64.sol";

/// @title Blank Token
/// @author of the contract filio.eth (twitter.com/filmakarov)

contract BlankToken is ERC721, Ownable, SignedAllowance {  

    using Strings for uint256;
    using Counters for Counters.Counter;

    /*///////////////////////////////////////////////////////////////
                                GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    // _tokenIds.current() will always return the last minted tokenId # + 1
    // it is actually the amount of minted tokens as we mint consistently startin from #0
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_ITEMS = 1400;

    string public baseURI;
    bool public saleState;
    bool public mergingActive;

    uint256 public totalBurned;
    
    /*///////////////////////////////////////////////////////////////
                                INITIALISATION
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _myBase) ERC721("Blank Token", "BLT") {
            baseURI = _myBase; 
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 nonce, bytes memory signature) public {
        require (saleState, "Presale not active");
 
        require(totalSupply() + 1 <= MAX_ITEMS, ">MaxSupply");
        
        // this will throw if the allowance has already been used or is not valid
        _useAllowance(to, nonce, signature);

        // If you try to re-enter here thru onERC721Received, function will revert
        // Counter won't increment and your token will be overminted by the next minter.
        // Your allowance will be marked as used at this moment, i.e. wasted 
        _safeMint(to, _tokenIds.current()); 
        _tokenIds.increment();        
    }

    // adminMint
    function adminMint(address to, uint256 qty) public onlyOwner {
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to, _tokenIds.current()); 
            _tokenIds.increment();
        }
    }

    // burn 2 get 1
    function mergeTokens(uint256 tokenId1, uint256 tokenId2) public {
        require(mergingActive, "Blank Token: Merging has not started yet");
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "Blank Token: must own tokens to merge");
        _burn(tokenId1);
        _burn(tokenId2);
        totalBurned += 2;

        // If you try to re-enter here thru onERC721Received, function will revert
        // Counter won't increment and your token will be overminted by the next minter.
        // So you will burn two of your tokens and get nothing, so you better do not try to re-enter 
        _safeMint(msg.sender, _tokenIds.current()); 
        _tokenIds.increment();
    }

    /*///////////////////////////////////////////////////////////////
                       PUBLIC METADATA VIEWS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Blank token: this token does not exist");

        string memory json = string(abi.encodePacked('{"name": "Blank Token #', tokenId.toString(), '", "description": "Blank Studio is a curation platform enabling artists from a plethora of backgrounds to disrupt the digital world. Join our collective today to participate in future drops from our talented artists.", "external_url": "https://blankstudio.art", "image": "',baseURI, tokenMediaId(tokenId).toString(), '.mp4","attributes": [{"trait_type": "Category", "value": "', tokenCategory(tokenId) ,'"}]}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));

        //return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function tokenMediaId(uint256 tokenId) internal pure returns (uint256) {
        if (tokenId < MAX_ITEMS) {
            return 0;
        } else {
            // from 1 to 5
            return random(string(abi.encodePacked("MEDIA ID", tokenId.toString()))) % 5 + 1;
        }
    }

    function tokenCategory(uint256 tokenId) internal pure returns (string memory) {
        string[6] memory categories = ["Blank Token", "Vinyl token: Focusing Partially", 
                                        "Vinyl token: Goon Squad", "Vinyl token: Snack",
                                        "Vinyl token: Sneep Deep", "Vinyl token: Stars Falling"];
        return categories[tokenMediaId(tokenId)];
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /*///////////////////////////////////////////////////////////////
                       VIEWS
    //////////////////////////////////////////////////////////////*/

    function totalSupply() public view returns (uint256) {
        return (_tokenIds.current() - totalBurned);
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
            for (NFTId = 0; NFTId < _tokenIds.current(); NFTId++) { 
                if (_exists(NFTId)) { 
                    if (_ownerOf[NFTId] == tokenOwner) {
                        result[resultIndex] = NFTId;
                        resultIndex++;
                    }
                } 
            }     
            return result;
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return (_ownerOf[tokenId] != address(0));
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
        require (_exists(tokenId), "Blank Token: Not minted or burned");
        return (_ownerOf[tokenId]);
    }

    function nextTokenIndex() public view returns (uint256) {
        return _tokenIds.current();
    }

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function switchSaleState() public onlyOwner {
        saleState = !saleState;
    }

    function switchMergeState() public onlyOwner {
        mergingActive = !mergingActive;
    }

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    /// @notice Withdraws funds from the contract to msg.sender who is always the owner.
    /// No need to use reentrancy guard as receiver is always owner
    /// @param amt amount to withdraw in wei
    function withdraw(uint256 amt) public onlyOwner {
         address payable beneficiary = payable(owner());
        (bool success, ) = beneficiary.call{value: amt}("");
        if (!success) revert ("Withdrawal failed");
    }    

}

//   That's all, folks!