// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
********************          ********************          ********************
********************          ********************          ******************((
********************          ********************          ***************(((((
********************          ********************          *************(((((((
********************          ********************          **********((((((((((
********************          ********************          ********((((((((((((
********************          ********************          *****(((((((((((((((
********************          ********************          ***(((((((((((((((((
                                                                                
                                                                                
                                                                                
                                                                                
********************          ********************          ((((((((((((((((((((
********************          ******************((          ((((((((((((((((((((
********************          ***************(((((          ((((((((((((((((((((
********************          *************(((((((          ((((((((((((((((((((
********************          **********((((((((((          ((((((((((((((((((((
********************          ********((((((((((((          ((((((((((((((((((((
********************          *****(((((((((((((((          ((((((((((((((((((((
********************          ***(((((((((((((((((          ((((((((((((((((((((
********************                                                            
********************                                                            
********************                                                            
********************                                                            
********************((((((((((((((((((((((((((((((          ((((((((((((((((((((
******************((((((((((((((((((((((((((((((((          ((((((((((((((((((((
***************(((((((((((((((((((((((((((((((((((          ((((((((((((((((((((
*************(((((((((((((((((((((((((((((((((((((          ((((((((((((((((((((
**********((((((((((((((((((((((((((((((((((((((((          ((((((((((((((((((((
********((((((((((((((((((((((((((((((((((((((((((          ((((((((((((((((((((
*****(((((((((((((((((((((((((((((((((((((((((((((          ((((((((((((((((((((
***(((((((((((((((((((((((((((((((((((((((((((((((          ((((((((((((((((((((
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct NftInfo {
    string uri;
    string originalCreator;
    bytes4 jsonId;
    bool isSecondaryCreation;
}

contract MoeErc721 is ERC721 {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    uint256 public constant fee = 10**18;
    address public immutable moeErc20Address;

    mapping (uint256 => NftInfo) public nftInfo;
    
    constructor(string memory _name, string memory _symbol, address _moeErc20Address) ERC721(_name, _symbol) {
        moeErc20Address = _moeErc20Address;
    }

    function mint(address to, string memory uri, string memory originalCreator, bytes4 jsonId,  bool isSecondaryCreation) public {
        ERC20 moeErc20 = ERC20(moeErc20Address);
        require(moeErc20.balanceOf(msg.sender) >= fee, "MOE: insufficient MOE balance");
        moeErc20.transferFrom(msg.sender, address(this), fee);
        _mint(to, _tokenIdTracker.current());
        nftInfo[_tokenIdTracker.current()] = NftInfo(uri, originalCreator, jsonId, isSecondaryCreation);
        _tokenIdTracker.increment();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return nftInfo[tokenId].uri;
    }

    function tokenOriginalCreator(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);

        return nftInfo[tokenId].originalCreator;
    }

    function tokenJsonId(uint256 tokenId) public view returns (bytes4) {
        _requireMinted(tokenId);

        return nftInfo[tokenId].jsonId;
    }

    function tokenIsSecondaryCreation(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);

        return nftInfo[tokenId].isSecondaryCreation;
    }

    function totalBurnt() public view returns (uint256) {
        ERC20 moeErc20 = ERC20(moeErc20Address);

        return  moeErc20.balanceOf(address(this));
    }

}