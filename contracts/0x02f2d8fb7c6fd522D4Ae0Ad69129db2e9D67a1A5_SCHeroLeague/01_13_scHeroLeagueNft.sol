// SPDX-License-Identifier: SCHeroLeague

pragma solidity ^0.8.13;

import "./openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract SCHeroLeague is ERC721URIStorage, Ownable {

     /**
     * @dev Base Uri variable
     */   
    string public baseUri;

    uint256 public idCount = 0;

     /**
     * @dev
     * constructor
     */
    constructor(string memory _name, string memory _symbol, string memory _initialBaseUri) ERC721 (_name, _symbol) Ownable() {
        baseUri = _initialBaseUri;
    }

    /**
     * @dev
     * Setter for the baseuri variable, callable by the owner of the contract
     */
    function setBaseUri(string calldata _newBaseUri) public onlyOwner {
        console.log("Set URI to %s", _newBaseUri);
        baseUri =  _newBaseUri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev
     * public function which allows the owner to mint a single new nft
     */
    function mintSingle(address _to, string calldata _tokenURI) public onlyOwner {
        _mint(_to, idCount);
        _setTokenURI(idCount, _tokenURI);
        idCount++;
    }

     /**
     * @dev
     * public function which allows the owner to batch mint new nfts
     */
    function mintMultiple(address[] calldata _to, string[] calldata _tokenURI) public onlyOwner {
        require(_to.length == _tokenURI.length && _tokenURI.length > 0, "The length of the to array must be the same as the length of the URI array and bigger than zero");
        for(uint x = 0 ; x < _tokenURI.length ; x++) {
            _mint(_to[x], idCount);
            _setTokenURI(idCount, _tokenURI[x]);
            idCount++;
        }
    }

    /**
    * @dev
    * method to transfer a batch of tokenids and their respective amounts to an array of addresses
    */
    function batchTransfer(address[] calldata _to, uint256[] calldata _tokenId) public {
        require(_to.length == _tokenId.length,"The length of the provided arrays do not match");
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to[i], _tokenId[i], "");
        }
    }

    /**
    * @dev
    * method to transfer a batch of tokenids and their respective amounts to the same address
    */
    function transferAll(address _to, uint256[] calldata _tokenId) public {
        require(_tokenId.length > 0, "The length of the URI array must be bigger than zero");
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to, _tokenId[i], "");
        }
    }
}