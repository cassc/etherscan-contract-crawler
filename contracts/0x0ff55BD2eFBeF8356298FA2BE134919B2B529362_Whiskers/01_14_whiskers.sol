// SPDX-License-Identifier: MIT
/*

                                                        ,,s####m
                                                  ,sm############m
                                            ,s#############"^@#####,
                                      ,,m############M"`       ^@####M
                                ,s#############"^                "#####m
                          ,m############M"`                        %#####,
                        ##########""          ]###N                 '@####N
                      ]#####"`                @#####m                 "#####m
                      #####                    @########m               7#####,
                    '####G#p                  j###########Wp            '@####N
                      #####GGp                 j####b "%######             "#####Q
                      \#####GGS                 ####b   !^@####              7#####,
                      ^#####QG#p               @####p :G @####                @#####
                        @####QGGN               @############b                ,######p
                          "#####pG#p              ^%########W             ,##########M
                            @####QGlp                               ,s##########M##m
                            %####QGGS                         ,s##########"^____####,
                              "#####pG#p                 ,,s##########"^[email protected]####N
                                @####QGGp           ,s###########"^__________,s########
                                7#####GGS     ,s##########M"__________,,###########W^
                                  ^#####QG#,##########W"__________,s###########"`
                                    @####Q;#####M"__________,,m##########M"
                                    7########b________,w##########M"`
                                      @######N___,s##########M"
                                        7################"^
                                          "%#######M"

     ...    .     ...                     .       .x+=:.         ..                                 .x+=:.   
  .~`"888x.!**h.-``888h.     .uef^"      @88>    z`    ^%  < [email protected]"`                                z`    ^%  
 dX   `8888   :X   48888>  :d88E         %8P        .   <k  [email protected]                      .u    .        .   <k 
'888x  8888  X88.  '8888>  `888E          .       [email protected]"  '888E   u         .u     .d88B :@8c     [email protected]" 
'88888 8888X:8888:   )?""`  888E .z8k   [email protected]   [email protected]^%8888"    888E [email protected]    ud8888.  ="8888f8888r  [email protected]^%8888"  
 `8888>8888 '88888>.88h.    888E~?888L ''888E` x88:  `)8b.   888E`"88*"  :888'8888.   4888>'88"  x88:  `)8b. 
   `8" 888f  `8888>X88888.  888E  888E   888E  8888N=*8888   888E .dN.   d888 '88%"   4888> '    8888N=*8888 
  -~` '8%"     88" `88888X  888E  888E   888E   %8"    R88   888E~8888   8888.+"      4888>       %8"    R88 
  .H888n.      XHn.  `*88!  888E  888E   888E    @8Wou 9%    888E '888&  8888L       .d888L .+     @8Wou 9%  
 :88888888x..x88888X.  `!   888E  888E   888&  .888888P`     888E  9888. '8888c. .+  ^"8888*"    .888888P`   
 f  ^%888888% `*88888nx"   m888N= 888>   R888" `   ^"F     '"888*" 4888"  "88888%       "Y"      `   ^"F     
      `"**"`    `"**""      `Y"   888     ""                  ""    ""      "YP'                             
                                 J88"                                                                        
                                 @%                                                                          
                               :"                                                                            

*/
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Whiskers is ERC721A, Ownable, Pausable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  uint64  public  immutable _maxSupply = 5555;
  uint64  public            _mintPrice = 0.15 ether;
  bytes32 public            _proofRoot;
  string  public            _tokenURIBase;
  string  public            _tokenURIExtension;

  address public constant xDev     = 0x9B54D1714f85a192723A36f1e8DE9E81dbcBBB1F;
  address public constant xFounder = 0x0fB87C2B4ac21Fb0908F194A1f1f9731d294305C;

  mapping(address => uint) public addressMintBalance;

  constructor(
    string memory _URIBase,
    string memory _URIExtension
  ) ERC721A("Whiskers", "WHISKERS") {
    _tokenURIBase = _URIBase;
    _tokenURIExtension = _URIExtension;
    _pause();
  }

  modifier mintCompliance(
    bytes32[] memory _proof
  )
  {
    require(
      msg.value == _mintPrice,
      "Incorrect payment"
    );
    require(
      totalSupply() + 1 <= _maxSupply,
      "Maximum supply exceeded"
    );
    require(
      addressMintBalance[msg.sender] == 0,
      "Address mint threshold exceeded"
    );
    require(
      MerkleProof.verify(_proof, _proofRoot, keccak256(abi.encodePacked(msg.sender))),
      "Failed allowlist proof"
    );
    _;
  }

  function mint(bytes32[] memory _proof)
    public
    payable
    mintCompliance(_proof)
    whenNotPaused
  {
    addressMintBalance[msg.sender] += 1;
    _safeMint(msg.sender, 1);
  }

  function ownerMint(uint _quantity)
    public
    onlyOwner
  {
    require(
      _quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + _quantity <= _maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(msg.sender, _quantity);
  }

  function setURIBase(string memory _URIBase)
    public
    onlyOwner
  {
    _tokenURIBase = _URIBase;
  }

  function setURIExtension(string memory _URIExtension)
    public
    onlyOwner
  {
    _tokenURIExtension = _URIExtension;
  }

  function setPriceWei(uint64 _priceWei)
    public
    onlyOwner
  {
    _mintPrice = _priceWei;
  }

  function setProofRoot(bytes32 _root)
    public
    onlyOwner
  {
    _proofRoot = _root;
  }

  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    uint devCut = address(this).balance * 9 / 200;
    Address.sendValue(payable(xDev), devCut);
    Address.sendValue(payable(xFounder), address(this).balance);
  }

  function pause()
    public
    onlyOwner
  {
    _pause();
  }

  function unpause()
    public
    onlyOwner
  {
    _unpause();
  }

  function tokenURI(uint _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(_tokenURIBase, _tokenId.toString(), _tokenURIExtension));
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return _tokenURIBase;
  }

  function _startTokenId()
    internal
    view
    virtual
    override
    returns (uint256)
  {
    return 1;
  }
}