// contracts/walkingpoets.sol
// SPDX-License-Identifier: MIT
/** 
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░██╗░░░░░░░██╗░█████╗░██╗░░░░░██╗░░██╗██╗███╗░░██╗░██████╗░
░██║░░██╗░░██║██╔══██╗██║░░░░░██║░██╔╝██║████╗░██║██╔════╝░
░╚██╗████╗██╔╝███████║██║░░░░░█████═╝░██║██╔██╗██║██║░░██╗░
░░████╔═████║░██╔══██║██║░░░░░██╔═██╗░██║██║╚████║██║░░╚██╗
░░╚██╔╝░╚██╔╝░██║░░██║███████╗██║░╚██╗██║██║░╚███║╚██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░
   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
                            ██████╗░░█████╗░███████╗████████╗░██████╗
                            ██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔════╝
                            ██████╔╝██║░░██║█████╗░░░░░██║░░░╚█████╗░
                            ██╔═══╝░██║░░██║██╔══╝░░░░░██║░░░░╚═══██╗
                            ██║░░░░░╚█████╔╝███████╗░░░██║░░░██████╔╝
                            ╚═╝░░░░░░╚════╝░╚══════╝░░░╚═╝░░░╚═════╝░

*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract WalkingPoets is ERC721, Ownable, DefaultOperatorFilterer, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private totalTokens;
    address public signingAddress;
    string public baseURI;
    string private collectionURI;
    event NewPoetAwaked(uint256 tokenId, address owner);


    constructor(address _signingAdress, address _receiver, uint96 _feeNumerator, string memory _baseURI, string memory _collectionURI) ERC721("Walking Poets", "wPoets") {
        signingAddress = _signingAdress;
        baseURI = _baseURI;
        collectionURI = _collectionURI;
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

   function awakePoet(uint8 v, bytes32 r,bytes32 s,uint256 tokenId) external payable {
        require(verifySignature(v,r,s,tokenId), "Invalid signature");
        _safeMint(msg.sender, tokenId);
        totalTokens.increment();

    emit NewPoetAwaked(tokenId, msg.sender);        
    }

    function ownerAwakePoet(address to, uint256 tokenId) external onlyOwner {
    _safeMint(to, tokenId);
    totalTokens.increment();

    emit NewPoetAwaked(tokenId, to);
    }

    function setSigningAddress(address _signingAddress) external onlyOwner {
    signingAddress = _signingAddress;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function totalSupply() public view returns (uint256) {
    return totalTokens.current();
    }

    /**
        * toEthSignedMessageHash
        * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
        * and hash the result 
        */
    function toEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verifySignature(uint8 v, bytes32 r, bytes32 s, uint256 tokenId) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, tokenId));
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(messageHash);
        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        require(signer != address(0), "invalid signature");
        if(signer == signingAddress){
            return true;
        }
        return false;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    /**
        * @dev show the contractURI
        */
    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
  }
 
    /**
     * @dev change the contractURI
     */
    function setContractURI(string memory _contractURI) external onlyOwner {
        collectionURI = _contractURI;
    }

     
    /**
     * @dev override the transfer functions to only allow the owner or the operator to transfer the token
     */

   function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    


   /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}