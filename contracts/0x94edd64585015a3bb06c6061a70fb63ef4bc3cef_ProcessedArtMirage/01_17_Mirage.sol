// SPDX-License-Identifier: MIT
                                                                                                                                     
      //(,@                                            @.,&            
    // (/                                  (@%  &       &@//            
    //@(       %*@(*(@& #     &#&   @,.@  @@#@#@,@.      @&//          
   //@/         @@#   ./@. .  &%( *@& ,*  @@ &, @ &.      %(@//         
   //@/          *#(/(%%  &   ( ,*.&       %@% @           (@./         
   //#&       @ *@@, .(  #@   ( %&         (@.#/           %&//          
   //@       ...&      %  @   # **         (& ,@/          ,@*         
    //&      &# * #@*&     @#  %.#         # &* ,@@@      %@//         
    //%&       /( .#%     #/   @&            # *         &(@          
     //*@@,                                             @.%/%           
       //&                                             #@%             
                                                                                
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC2981.sol";

contract ProcessedArtMirage is ERC721Enumerable, ERC721URIStorage, AccessControl, Ownable {
    using SafeMath for uint256;

    event mintedMirage(bytes32 indexed tokenHash);
    event PermanentURI(string _value, uint256 indexed _id);

    string internal _currentBaseURI = "https://api.processed.art/mirage/";
    string public scriptArweave = "https://arweave.net/A4Kl5j-uIMxm3G5WUBnBHi6AK4DAaJzjuOjJfhjTXsI";
    string public scriptIPFS = "ipfs://QmXcmaUnv6RBQzMmefgb6YTkaNHzz5hHWavYvWurvxGQY5";
    
    bool public mintIsActive = false;
    uint256 public totalMints = 0;
    uint256 public constant maxMirages = 768;
    uint public reserveMints = 15;
    uint256 public constant royaltiesPercentage = 10;
    address private _royaltiesReceiver;
    mapping (address => bool) private _addressMinted;
    mapping (uint256 => bytes32) public tokenHash;

    constructor() ERC721("processed (art): mirage", "MIRAGE")  {
        _royaltiesReceiver = msg.sender;
        transferOwnership(msg.sender);
    }

    function baseURI() public view virtual returns (string memory) {
        return _currentBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory theURI) public onlyOwner {  
        _currentBaseURI = theURI;
    }

    function freezeMetadata(string memory theURI, uint256 token_id) public onlyOwner {  
        emit PermanentURI(theURI, token_id);
    }

    function setScriptIPFS(string memory _scriptIPFS) public onlyOwner {  
        scriptIPFS = _scriptIPFS;
    }

    function setScriptArweave(string memory _scriptArweave) public onlyOwner {  
        scriptArweave = _scriptArweave;
    }

    function royaltiesReceiver() external view returns(address) {
        return _royaltiesReceiver;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens ) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            for (uint256 i=0; i<tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _generateRandomHash() internal view returns (bytes32) {
        return keccak256(abi.encode(blockhash(block.number-1), block.coinbase, totalMints, tokenHash[totalMints-1]));
    }

    function flipState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function reserveMint(address _to, uint256 _reserveAmount) public onlyOwner {      
        require(_reserveAmount > 0 && _reserveAmount <= reserveMints, "not enough reserve");
        for (uint i = 0; i < _reserveAmount; i++) {
            totalMints = totalMints + 1;
            tokenHash[totalMints] = _generateRandomHash();
            _safeMint(_to, totalMints);
            emit mintedMirage(tokenHash[totalMints]);
        }
        reserveMints = reserveMints.sub(_reserveAmount);
    }

    function mintMirage() public {
        require(mintIsActive, "chill, the minting is not yet active");
        require(!_addressMinted[msg.sender], 'each address may only mint one mirage, slick');
        require(totalMints < maxMirages, "sorry, the total mint limit is 768");
        totalMints = totalMints + 1;
        tokenHash[totalMints] = _generateRandomHash();
        _addressMinted[msg.sender] = true;
        _safeMint(msg.sender, totalMints);
        emit mintedMirage(tokenHash[totalMints]);
    }
 
    function sweep() public onlyOwner {  
        uint balance = address(this).balance;
        address payable to;
        to.transfer(balance);
    }

    function setRoyaltiesReceiver(address newRoyaltiesReceiver) external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}