// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../EIP712Allowlisting.sol";
import "../FlexibleMetadata.sol";
import "./LockableA.sol";

abstract contract HordeMintableA is EIP712Allowlisting, LockableA, FlexibleMetadata {  
  
    mapping(address => uint256) private allow_minted;
    mapping(address => uint256) private public_minted;

    address payable private HORDE_AI_WALLET = payable(0xa399Ffb1C1244FA6B583a20c53FF85501Fb91086);

    uint256 private MAX_TOKENS = 400;
    uint256 private MAX_HORDE = 400;
    uint256 private MAX_ALLOW = 3;
    uint256 private MAX_PUBLIC = 2;

    uint256 private PUBLIC_FEE = 0.02 ether;

    bool private HORDE_LIVE = true;
    bool private PUBLIC_LIVE = false;


    string private INVALID_QUANT = "invalid quantity";
    string private INACTIVE_MINT = "mint is not active";
    string private ALLOC_OVER = "mint overallocation";
    string private FEE_UNDER = "insufficient funds";

    mapping(uint256 => bool) private flagged;  

    bool private revealed = false;

    string private flaggedBaseURI="ipfs://QmSUii5oFiBPu94UB3vqS6gDCJhuScAL6d6x9kgGqkh9E9";
    string private unrevealedBaseURI="ipfs://QmSUii5oFiBPu94UB3vqS6gDCJhuScAL6d6x9kgGqkh9E9"; 
    string private revealedBaseURI="ipfs://Qmbw9vH1a9Vadc58Zu5sfNRXUHzAgG1ToMVwkTCFboEbuP";      


    function setLive(bool isLive, bool isPublic) external onlyOwner {        
        if (isPublic) {
            PUBLIC_LIVE = isLive;
        } else {
            HORDE_LIVE = isLive;
        }        
    }

    function setRecipient(address recip) external onlyOwner {        
        HORDE_AI_WALLET = payable(recip);    
    }  

    function setURI(string calldata uri, uint256 uriType) external onlyOwner {    
        if (uriType == 0) { revealedBaseURI = uri; }
        if (uriType == 1) { unrevealedBaseURI = uri; }
        if (uriType == 2) { flaggedBaseURI = uri; }
    }     

    function mint(
        bytes calldata sig, 
        uint256 quant,
        bool isPublic) external payable requiresSig(sig, msg.sender) {  
        uint256 askSize = totalSupply()+quant;
        bool publicMint = PUBLIC_LIVE ? PUBLIC_LIVE : isPublic;
        require(quant <= (publicMint ? MAX_PUBLIC : MAX_ALLOW), INVALID_QUANT);     
        require(publicMint ? PUBLIC_LIVE : HORDE_LIVE, INACTIVE_MINT); 
        require(askSize <= (publicMint ? MAX_TOKENS : MAX_HORDE), ALLOC_OVER);
        require(
            (publicMint ? public_minted[msg.sender] : allow_minted[msg.sender])+quant 
            <= (publicMint ? MAX_PUBLIC : MAX_ALLOW), ALLOC_OVER);
        
        if (publicMint) {
            require(msg.value >= (PUBLIC_FEE * quant), FEE_UNDER);
            public_minted[msg.sender] = public_minted[msg.sender] + quant;
            HORDE_AI_WALLET.transfer(msg.value);
        } else {
            allow_minted[msg.sender] = allow_minted[msg.sender] + quant;
        }

        _safeMint(msg.sender,quant);
        
    }  

   // Reveal unrevealed tokens
    function reveal() public onlyOwner {                 
        revealed = true;
    }

    function setFlag(uint256 tokenId, bool flag) public onlyOwner {                 
        flagged[tokenId] = flag;
    }    

    // Determine if token is flagged
    function isFlagged(uint256 tokenId)
        public
        view
        returns (bool)
    {     
        return flagged[tokenId];
    }

    // Determine if tokens are revealed
    function isRevealed()
        public
        view
        returns (bool)
    {     
        return revealed;
    }   

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        
        string memory baseURI = isFlagged(tokenId) ?
                this._flaggedBaseURI() :
                isRevealed() ?
                    this._revealedBaseURI():
                    this._unrevealedBaseURI();
        
        string memory uri = (isRevealed() && !isFlagged(tokenId)) ?
            string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId))):
            string(abi.encodePacked(baseURI));
        return uri;
    }      

    function _unrevealedBaseURI() external virtual override view returns (string memory){
        return unrevealedBaseURI;
    }
    function _flaggedBaseURI() external virtual override view returns (string memory){
        return flaggedBaseURI;
    }
    function _revealedBaseURI() external virtual override view returns (string memory){
        return revealedBaseURI;
    }      

}