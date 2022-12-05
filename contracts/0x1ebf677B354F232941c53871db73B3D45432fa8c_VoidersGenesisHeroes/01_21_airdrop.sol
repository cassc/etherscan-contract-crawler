// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "./ERC721A/ERC721A.sol";

import {IERC721A} from "./ERC721A/IERC721A.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {DefaultOperatorFilterer} from "./src/DefaultOperatorFilterer.sol";

contract VoidersGenesisHeroes is  DefaultOperatorFilterer, ERC721A, ERC2981, Ownable {
    using ECDSA for bytes32;

    uint256 public constant maxTotalSupply = 444;
    // uint256 public idCount;
    string private _baseTokenURI1;
    string private _baseTokenURI2;
    string private _baseTokenURI3;
    string private _baseTokenURI4;
    string private _unrevealedURI;
    string private _contractURI;
    bool public revealed = true;
    address nftContract;

    uint public counter = 0;
 
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _newTokenURI1,
        string memory _newContractURI,
        string memory _newUnrevealedURI,
        uint96 _royaltyFeesInBips,
        address _feerecipient,
        address _nftContract
    ) ERC721A(_name, _symbol) {
        _baseTokenURI1 = _newTokenURI1;
        _contractURI = _newContractURI; 
        _unrevealedURI = _newUnrevealedURI;
        nftContract = _nftContract; 

        setRoyaltyInfo(_feerecipient, _royaltyFeesInBips);
    }

    function doAirdrop(uint amount) public onlyOwner {
        
        require(totalSupply() + amount <= maxTotalSupply, "Exceeds max supply of tokens");
         
        for(uint i = 0; i < amount; i++) {
            _mintTo(IERC721A(nftContract).ownerOf(counter), 1);
                counter++;
                if (counter == 111) {
                    counter = 0;
            }
        } 
        
    }

    function reveal(bool _reveal) external onlyOwner {
        revealed = _reveal;
    }

    function approve(address operator, uint256 tokenId) public  override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

      function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
 
    /**
     * @dev Royalty.
     */

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

      function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981).interfaceId || // ERC2981 interface
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Changes baseTokenURI1
     * @param _newBaseTokenURI new URI for all tokens
     */
    function changeBaseTokenURI1(string memory _newBaseTokenURI)
        public
        onlyOwner
    {
        _baseTokenURI1 = _newBaseTokenURI;
    }

        function changeBaseTokenURI2(string memory _newBaseTokenURI)
        public
        onlyOwner
    {
        _baseTokenURI2 = _newBaseTokenURI;
    }

        function changeBaseTokenURI3(string memory _newBaseTokenURI)
        public
        onlyOwner
    {
        _baseTokenURI3 = _newBaseTokenURI;
    }

            function changeBaseTokenURI4(string memory _newBaseTokenURI)
        public
        onlyOwner
    {
        _baseTokenURI4 = _newBaseTokenURI;
    }

    /**
     * @dev Changes baseContractURI.
     * @param _newContractURI new URI for all tokens
     */
    function changeContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }

        /**
     * @dev Changes unrevealedURI.
     */
    function changeUnrevealedURI(string memory _newUnrevealedURI) public onlyOwner {
        _unrevealedURI = _newUnrevealedURI;
    }


    /**
     * @dev Returns contractURI.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns baseTokenURI.
     */
    function baseTokenURI1() public view returns (string memory) {
        return _baseTokenURI1;
    }

       function baseTokenURI2() public view returns (string memory) {
        return _baseTokenURI2;
    }

       function baseTokenURI3() public view returns (string memory) {
        return _baseTokenURI3;
    }

       function baseTokenURI4() public view returns (string memory) {
        return _baseTokenURI4;
    }

        /**
     * @dev Returns unrevealedURI.
     */

    function unrevealedURI() public view returns (string memory) {
        return _unrevealedURI;
    }

    /**
     * @dev Returns baseTokenURI.
     */
    // function _baseURI() internal view override returns (string memory) {
    //     return _baseTokenURI1;
    // }

    /**
     * @dev Returns URI for exact token.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return unrevealedURI();
        }

        string memory baseURI;

        if (_tokenId >= 0 &&  _tokenId < 111) {
        baseURI = baseTokenURI1();
            
        } else if(_tokenId >= 111 &&  _tokenId < 222) {
        baseURI = baseTokenURI2();
            
        } else if(_tokenId >= 222 &&  _tokenId < 333) {
        baseURI = baseTokenURI3();
            
        } else if(_tokenId >= 333 &&  _tokenId < 444) {
        baseURI = baseTokenURI4();
        }



        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(_tokenId), ".json")
                )
                : "";
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     */
    function _mintTo(address _to, uint256 _quantity) internal {
        require(totalSupply() < maxTotalSupply, "Exceeds max supply of tokens");

        _mint(_to, _quantity);
    }
}