// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";






contract FXBToken is ERC721, ERC721Enumerable, ERC721URIStorage,Pausable, Ownable, ERC721Burnable, ERC721Royalty {
    using Counters for Counters.Counter;
    using Math for uint;
    using SafeMath for uint;


    Counters.Counter private _tokenIdCounter;

   
    mapping(uint256 => uint256) private _nftIdToken;

    constructor() ERC721("FXBToken", "FXB") {}



    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    event safeMintEvent(
        address indexed to,uint256 indexed tokenId,
        string uri,uint96 feeNumerator, uint256 indexed nftId
    );

    event exchangeNftEvent(
        address indexed from, address indexed to,
        uint256 indexed tokenId, uint256 amount,
        uint96 payfee,uint256 nftId,uint256 orderId
    );


   
    struct SigMessage {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function safeMint(address to, string memory uri,uint96  feeNumerator,uint256  amount,uint96  payfee,uint256 nftId,SigMessage calldata sigMessage) public  payable  returns (uint256){

        require(verify(owner(),getSafeMintMessageHash(to, uri,feeNumerator,amount,payfee, nftId,msg.value),sigMessage.r,sigMessage.s,sigMessage.v),"verify fail");
        require(to==msg.sender,"mint must be to address");
        require(nftId>0 ,"NftId must greater than zero");
        require(_nftIdToken[nftId]==0,"nftId has been minted");
        uint256 payfeeAmount=amount.mulDiv(payfee,10000);
        require(msg.value==amount.add(payfeeAmount),"mint pay amount is not right");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, uri);
        _setTokenRoyalty(newTokenId, to, feeNumerator);
        _nftIdToken[nftId]=newTokenId;
        emit safeMintEvent(to,newTokenId,uri,feeNumerator,nftId);


        return newTokenId;
    }



   
    function exchangeNft(address  from, address to, uint256 tokenId, uint256  amount,uint96  payfee,uint256  nftId,uint256  orderId,SigMessage calldata sigMessage) public  payable returns (bool){
        require(verify(owner(),getExchangeNftMessageHash(from, to,tokenId, amount,payfee,nftId,orderId,msg.value),sigMessage.r,sigMessage.s,sigMessage.v),"verify fail");
        require(to==msg.sender,"to must be sender");

        (address author , uint256 royaltyamount) =royaltyInfo(tokenId,amount);
        uint256 payfeeAmount=amount.mulDiv(payfee,10000);
        require(msg.value==amount.add(payfeeAmount),"pay amount is not right");
        require(amount>royaltyamount,"amount must greater than royaltyamount");

       
        address payable fromAddress = payable(from);
        fromAddress.transfer(amount.sub(royaltyamount));
       
        address payable authorAddress=payable(author);
        authorAddress.transfer(royaltyamount);

      
        IERC721(address(this)).safeTransferFrom(from, to, tokenId);
      
        emit exchangeNftEvent(from, to, tokenId, amount,payfee,nftId, orderId);
        return true;


    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

  

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage,ERC721Royalty) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable,ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


 
    function withdrawPayments(address  payee) external  onlyOwner  {
        require(address(this).balance>0,"no amount can withdraw");
        payable(payee).transfer(address(this).balance);
    }



   
    function verify(address _signer, bytes32  messageHash, bytes32  r, bytes32  s, uint8  v) internal pure returns (bool)
    {

      
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

       
        return recover(ethSignedMessageHash,  r,  s,  v) == _signer;
    }




    function getSafeMintMessageHash(address  to, string memory uri,uint96  feeNumerator,uint256  amount,uint96  payfee,uint256  nftId,uint256  value) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(to,uri,feeNumerator,amount,payfee,nftId,value));
    }

    function getExchangeNftMessageHash(address  from, address to, uint256  tokenId, uint256  amount,uint96  payfee,uint256  nftId,uint256  orderId,uint256  value) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(from,to,tokenId,amount,payfee,nftId,orderId,value));
    }

    
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                _messageHash
            ));
    }

    function recover(bytes32 _ethSignedMessageHash, bytes32  r, bytes32  s, uint8  v)
    internal pure returns (address)
    {
       
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }



}