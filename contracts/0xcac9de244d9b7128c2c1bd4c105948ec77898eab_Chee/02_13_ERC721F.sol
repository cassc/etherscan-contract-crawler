// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "../openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";
import "../openzeppelin-contracts/contracts/utils/Counters.sol";


/**
 * @title ERC721F
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumerable , but still provide a totalSupply() and walletOfOwner(address _owner) implementation.
 * @author @FrankNFT.eth
 * 
 */

contract ERC721F is Ownable, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenSupply;

    // Base URI for Meta data
    string private _baseTokenURI;

    
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    /** 
     * @dev walletofOwner
     * @return tokens id owned by the given address
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function walletOfOwner(address _owner) external view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;

        while ( ownedTokenIndex < ownerTokenCount && currentTokenId < _tokenSupply.current() ) {
            if (ownerOf(currentTokenId) == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                unchecked{ ownedTokenIndex++;}
            }
            unchecked{ currentTokenId++;}
        }
        return ownedTokenIds;
    }
    
    /**
     * To change the starting tokenId, override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    /**
     * @dev Set the base token URI
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     *    
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     */
    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        _tokenSupply.increment();
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    /**
    * Helper method to allow ETH withdraws.
    */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    // contract can recieve Ether
    receive() external payable { }
}