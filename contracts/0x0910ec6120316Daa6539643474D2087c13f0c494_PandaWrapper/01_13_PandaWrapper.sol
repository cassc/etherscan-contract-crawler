// SPDX-License-Identifier: MIT


pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "./IPanda.sol";

/**
 * @title Earth Pandas Wrapper contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 * @author @FrankNFT.eth
 */
contract PandaWrapper is Ownable, ERC721 {

    address public pandaAddress = payable(0x663e4229142a27F00baFB5D087e1e730648314c3);
    string private _baseTokenURI;
    uint256 private _tokenSupply;


    constructor() ERC721("Panda Earth Wrapped", "PEW") {
        _baseTokenURI = "ipfs://QmPq7ds5wrAp4oCoQ1x2DNovDE1a34TXWDjVcpdNBY2v9s/";
    }

    /**
     * @dev transfers the Earth Panda to the wrapper and assigns a wrapped token to msg.sender
     */
    function wrap(uint _pandaId) external {
        // Prereq: owner should call `approve` on the Panda contract
        require(_pandaId<5600,"You can't wrap pandas higher the id 5600");
        require(_pandaId>50,"You can't wrap pandas lower then id 50"); 
        require(_pandaId!=4344  && _pandaId!=4908,"You can't wrap dead pandas");            
        require( IPanda(pandaAddress).ownerOf(_pandaId)==msg.sender,"Only Owner can wrap a panda.");
        // Buy the punk
        IPanda(pandaAddress).transferFrom(msg.sender,address(this),_pandaId);
        _tokenSupply +=1;
        // Mint a wrapped punk
        _mint(msg.sender, _pandaId);
    }

    /**
     * @dev Burns the wrapper token and transfers the underlying Panda to the owner
     **/
    function unwrap(uint256 _pandaId) external {
        require(_isApprovedOrOwner(msg.sender, _pandaId));
        _burn(_pandaId);
        _tokenSupply -=1;
        IPanda(pandaAddress).transfer(msg.sender,_pandaId);
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
     * @dev Set a new base token URI
     */
    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }
    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _tokenSupply;
    }
}