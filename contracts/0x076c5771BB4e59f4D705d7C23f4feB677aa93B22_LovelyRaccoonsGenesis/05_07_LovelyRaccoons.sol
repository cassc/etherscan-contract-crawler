// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error OnlyOnePerWallet(); 

contract LovelyRaccoonsGenesis is ERC721A, Ownable {

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    using Strings for uint256;

    string private _baseTokenURI;
    address public communityWallet;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor (address _communityWallet, string memory baseTokenURI_) ERC721A("Lovely Raccoons Genesis", "GRACCS") {
        communityWallet = _communityWallet;
        _baseTokenURI = baseTokenURI_;
        _mintERC2309(_communityWallet, 100);
    }

    /*///////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseURI(),  _tokenId.toString())) : '';
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setCommunityWallet (address _communityWallet) external onlyOwner {
        communityWallet = _communityWallet;
    }

    /*///////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/


    function _beforeTokenTransfers(address, address to, uint256, uint256) internal view override {
        if (to != communityWallet && balanceOf(to) > 0) revert OnlyOnePerWallet();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }


}