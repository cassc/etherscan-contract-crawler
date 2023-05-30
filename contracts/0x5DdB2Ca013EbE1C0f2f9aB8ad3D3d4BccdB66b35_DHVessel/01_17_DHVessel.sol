// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract DeadTickets {
  function ownerOf(uint tokenId) public virtual view returns (address);
  function balanceOf(address owner) external virtual view returns (uint balance);
  function burn(uint tokenId) public virtual;
}

contract DHVessel is ERC721, ERC721Enumerable, ERC721Burnable, EIP712, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter private _tokenIdCounter;
    
    string baseURI;
    
    IERC721 _deadHeads = IERC721(0x6fC355D4e0EE44b292E50878F49798ff755A5bbC);
    DeadTickets _deadTickets = DeadTickets(0x78f28143902e9346526933e3C2EdA2662d1cD1F7);
    address _signerAddress;
    
    mapping(uint => uint) public tokenToTokenType;
    
    event Evolve(uint dhTokenId, uint ticketId, uint newTokenId, address owner);

    constructor() ERC721("DeadHeads Vessels", "DeadVessels") EIP712("VESSEL", "1.0.0") {}

    function safeMint(address to) internal returns (uint) {
        uint newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _tokenIdCounter.increment();
        return newTokenId;
    }
    
    function onERC721Received(address operator, address, uint256, bytes calldata) external returns(bytes4) {
        require(operator == address(this));
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    function evolve(uint dhTokenId, uint ticketId, uint tokenType, bytes calldata signature) public {
        require(_deadHeads.ownerOf(dhTokenId) == msg.sender, "sender not own deadhead token");
        require(_deadTickets.ownerOf(ticketId) == msg.sender, "sender not own ticket token");
        require(_signerAddress == recoverAddress(msg.sender, tokenType, dhTokenId, ticketId, signature), "user cannot mint");
        
         _deadHeads.safeTransferFrom(msg.sender, address(this), dhTokenId);
         _deadTickets.burn(ticketId);
        
        uint newTokenId = safeMint(msg.sender);
        
        tokenToTokenType[newTokenId] = tokenType;
        
        emit Evolve(dhTokenId, ticketId, newTokenId, msg.sender);
    }
    
    function _hash(address account, uint tokenType, uint dhTokenId, uint ticketId) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 tokenType,uint256 dhTokenId,uint256 ticketId,address account)"),
                        tokenType,
                        dhTokenId,
                        ticketId,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint tokenType, uint dhTokenId, uint ticketId, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, tokenType, dhTokenId, ticketId), signature);
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "query for non existent token");
        
        return string(abi.encodePacked(baseURI, tokenId.toString(), '?t=', tokenToTokenType[tokenId].toString()));
    }
                                                                                                                                                                                                                                                           
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function withdrawDH(uint tokenId, address receiver) external onlyOwner {
        _deadHeads.safeTransferFrom(address(this), receiver, tokenId);
    }
}