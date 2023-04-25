// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
    _  _  _  _  _  _           _   _  _  _  _   _  _  _  _  _  _  _        _          
   (_)(_)(_)(_)(_)(_)_       _(_)_(_)(_)(_)(_)_(_)(_)(_)(_)(_)(_)(_)     _(_)_        
   (_)              (_)_   _(_) (_)          (_)(_)      (_)_ (_)      _(_) (_)_      
   (_) _  _           (_)_(_)   (_)          (_)(_)        (_)(_)    _(_)     (_)_    
   (_)(_)(_)           _(_)_    (_)          (_)(_)        (_)(_)   (_) _  _  _ (_)   
   (_)               _(_) (_)_  (_)          (_)(_)       _(_)(_)   (_)(_)(_)(_)(_)   
   (_) _  _  _  _  _(_)     (_)_(_)_  _  _  _(_)(_)_  _  (_)_ (_) _ (_)         (_)   
   (_)(_)(_)(_)(_)(_)         (_) (_)(_)(_)(_) (_)(_)(_)(_)(_)(_)(_)(_)         (_)   
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";

error InvalidTokenId();
error TokensCurrentlySoulbound();

 /**
 * @dev The ExodiaNft Contract creates a sudo soulbound token. The tokens
 * can only be minted to the owner, and then it is up to the owner on how
 * to distribute the tokens.
 *
 * The tokens can not be transfered out of a holders wallet until the owner
 * toggles the `exodia.soulbound` variable.
 */

contract ExodiaNft is Ownable, ERC721A {
    struct Exodia { 
        string baseUri;
        string postUri;
        bool soulbound;
    }

    Exodia public exodia;

    receive() external payable {}
    constructor() payable ERC721A("Exodia", "EXODIA") {
        exodia.soulbound = true;
    }

    function toggleIsSoulbound() external onlyOwner {
        exodia.soulbound = !exodia.soulbound;
    }

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
        exodia.baseUri = _baseTokenUri;
    }

    function setPostTokenUri(string calldata _postTokenUri) external onlyOwner {
        exodia.postUri = _postTokenUri;
    }

    function ownerMint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert InvalidTokenId();

        return
            string(
                abi.encodePacked(
                    exodia.baseUri,
                    "/",
                    _toString(_tokenId),
                    exodia.postUri
                )
            );
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }

    /***
     * SOULBOUND
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (exodia.soulbound && from != owner() && from != address(0))
            revert TokensCurrentlySoulbound();

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        if (exodia.soulbound && msg.sender != owner()) revert TokensCurrentlySoulbound();
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address to, 
        uint256 tokenID
    ) public override payable {
        if (exodia.soulbound && msg.sender != owner()) revert TokensCurrentlySoulbound();
        super.approve(to, tokenID);
    }
}