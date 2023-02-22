// SPDX-License-Identifier: UNLICENSED

/*

by Wumbo Labs
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { DefaultOperatorFilterer, OperatorFilterer } from "./DefaultOperatorFilterer.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract WILDERS is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 constant maxSupply = 4444;
    uint256 constant mintPrice = 0.015 ether;
    uint256 public maxPerAddressWaitlistPublic = 50;
    string public baseURI = "https://ipfs.filebase.io/ipfs/QmcYz9ZbDahJGXmWaEeKf3MYWmveSNc65Axn3U1Vb29dtG";
    string public baseExtension = ".json";

    bytes32 public waitlistRoot = 0xd831d80038b6f1e5003f9fbd36a6c0b7089ae458c57d73c26c723ec14a67793c;

    enum Status {
        NOTSTARTED,
        WAITLIST,
        PUBLIC,
        REVEAL
    }

    Status public state;

    constructor() ERC721A("Wilders", "WILDERS") {
    }
    
    function getNumberMinted(address _address) external view returns(uint256) {
      return _numberMinted(_address);
    }

    function setState(Status _state) external onlyOwner {
        state = _state;
    }
    

    function isWaitlist(address sender, bytes32[] calldata proof) public view returns(bool) {
        return MerkleProof.verify(proof, waitlistRoot, keccak256(abi.encodePacked(sender)));
    }


    function mintWaitlist(bytes32[] calldata proof, uint256 amount) public payable {
      require(state == Status.WAITLIST, "Wilders: Waitlist mint not started");
      require(isWaitlist(msg.sender, proof), "Wilders: Cannot mint waitlist");
      require(amount + totalSupply() <= maxSupply, "Wilders: Max supply exceeded");
      require(_numberMinted(msg.sender) + amount < 2, "Wilders: Exceeded total amount per address");
      _safeMint(msg.sender, amount);
    }

    function mintPublic(uint256 amount) public payable {
      require(state == Status.PUBLIC, "Wilders: Public mint not started");
      require(amount + totalSupply() <= maxSupply, "Wilders: Max supply exceeded");
      require(_numberMinted(msg.sender) + amount <= maxPerAddressWaitlistPublic, "Wilders: Exceeded total amount per address");
      _safeMint(msg.sender, amount);
    }

    function mintDev(address _address, uint256 _quantity) external onlyOwner {
      require(totalSupply() + _quantity <= maxSupply, "Wilders: Exceeds total supply");
      _safeMint(_address, _quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        if (state != Status.REVEAL) {
          return currentBaseURI;
        }

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

      function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721A, ERC2981, IERC721A)
        returns (bool) 
    {
        return
            ERC2981.supportsInterface(interfaceId)
            || ERC721A.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setWaitlistRoot(bytes32 _newRoot) public onlyOwner {
      waitlistRoot = _newRoot;
    }

    function setDefaultRoyalty(
      address _receiver,
      uint96 _feeNumerator
    )
      external
      onlyOwner
    {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty()
      external
      onlyOwner
    {
      _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
      uint256 _tokenId,
      address _receiver,
      uint96 _feeNumerator
    )
      external
      onlyOwner
    {
      _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(
      uint256 tokenId
    )
      external
      onlyOwner
    {
      _resetTokenRoyalty(tokenId);
    }

    /* ------------ OpenSea Overrides --------------*/
    function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    )
      public
      payable
      override(ERC721A, IERC721A)  
      onlyAllowedOperator(_from)
    {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    ) 
      public
      payable
      override(ERC721A, IERC721A) 
      onlyAllowedOperator(_from)
    {
      super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
      address _from,
      address _to,
      uint256 _tokenId,
      bytes memory _data
    )
      public
      payable
      override(ERC721A, IERC721A) 
      onlyAllowedOperator(_from)
    {
      super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}