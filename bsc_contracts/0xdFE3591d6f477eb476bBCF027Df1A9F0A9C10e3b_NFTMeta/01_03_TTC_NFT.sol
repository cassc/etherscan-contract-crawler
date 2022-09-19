// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
 
import "./TTC_ERC721.sol";
 
import "hardhat/console.sol";
  

interface ICardSubNFT{
    function mint(uint256 cardId, uint256 tokenQuantity) external returns (uint256[] memory) ;
}


interface IMarkNFT{
    function setMangheBox(uint256 tokenId,bool f) external;
}
interface IRouterFeeAdapter
{
    function getDefaultFee() external  view  returns(uint256) ;
}
 

contract NFTMeta is ERC721,Ownable {
    using Strings for uint256;

    bool public _isSaleActive = true;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 365;
 
    uint256 public maxBalance = 365;

    uint256 public maxMint = 365;
    // INftMarket public nftMaket;

    address public officialAddress;
 
    string public notRevealedUri;
    string public baseExtension = ".json";



    uint256 public CardCreateStageLen=2;
    mapping(uint256 =>uint256[]) public  cardToStageData; 


  
    address public openBoxFeeAddress;//开盲盒手续费收取地址 
    address public stageMarkAddress;//道具市场合约地址
    uint256 public markFee=5;//市场手续费
    address public markFeeAddress;
    address public stageAddress;
    uint256 public openBoxFee=6128403671903880;

    address public tokenAddress;  

    address public routerAddress;
    
    function getRouterAddress () public view returns(address)
    {
        return routerAddress;
    }

    function getMarkFeeAddress() public  view returns(address){
        return markFeeAddress;
    }
    
    function getOpenBoxFee() public  view returns(uint256){
        
        if(routerAddress==address(0)) return openBoxFee;

        IRouterFeeAdapter feeRouterAddress=IRouterFeeAdapter(routerAddress);

        return feeRouterAddress.getDefaultFee();
        
    }

    function getOpenBoxFeeAddress() public view returns(address){
        return openBoxFeeAddress;
    }
    
    function getMarkFee() public view returns(uint256){
        return markFee;
    }
    function getStageMarkAddress() public view returns(address){
        return stageMarkAddress;
    }
    function getTokenAddress() public view returns(address){
        return tokenAddress;
    }

    function getStageAddress() public view returns(address)
    {
        return stageAddress;
    }

 
    function setRouterAddress (address addr) public  onlyOwner
    {
        routerAddress=addr;
    }
    function setOpenBoxFeeAddress(address val) public  onlyOwner{
          openBoxFeeAddress=val;
    }


    function setOpenBoxFee(uint256 val) public  onlyOwner{
          openBoxFee=val;
    }
    
    
    function setMarkFee(uint256 val) public  onlyOwner{
          markFee=val;
    }

    function setMarkFeeAddress(address val) public onlyOwner {
          markFeeAddress=val;
    }

    function setStageMarkAddress(address val) public onlyOwner {
          stageMarkAddress=val;
    }
    function setTokenAddress(address val) public  onlyOwner{
          tokenAddress=val;
    }

 

    mapping(uint256 => string) private _tokenURIs;

    // mapping(uint256=>NFTMetaSub) public cardToSubNft;
 
    constructor(
    string memory initBaseURI, 
    string memory initNotRevealedUri,
    address initTokenAddress ,
    address initOfficialAddress)
        ERC721("TTC Meta", "TTCNFT")
    {
        _setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
 
        officialAddress=initOfficialAddress;
        openBoxFeeAddress=initOfficialAddress;
        markFeeAddress=initOfficialAddress;
        tokenAddress=initTokenAddress;
    }
 
    function setBaseUrl(string memory baseurl) public onlyOwner
    {
        _setBaseURI(baseurl);
    }
     

    function getCardToStageData(uint256 cardid) public view returns(uint256[] memory)
    {
        return cardToStageData[cardid];
    }

    function setCardToStageData(uint256 cardTokenId,uint256[] memory stageData) public onlyOwner
    {

        cardToStageData[cardTokenId]=stageData;
    }

    function setCardCreateStageLen(uint256 len) public  onlyOwner
    {
        CardCreateStageLen=len;
    }

    uint256 stageCount;    
   

    function ttc_mint(uint256 tokenQuantity) public payable {
 
        // require(keccak256(abi.encodePacked((signature))) == keccak256(abi.encodePacked((_signature))), "Invalid signature");
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY,"Sale would exceed max supply");
        require(_isSaleActive, "Sale must be active to TTC");
        require(balanceOf(msg.sender) + tokenQuantity <= maxBalance,"Sale would exceed max balance");
 
 
        // console.log("$s %s",tokenQuantity * mintPrice , msg.value);
        // require(tokenQuantity * mintPrice <= msg.value,"Not enough ether sent");
        require(tokenQuantity <= maxMint, "Can only mint 365 tokens at a time");
        _mintNicMeta(tokenQuantity);
    }

    function setOfficialAddress(address addr) public onlyOwner
    {
        officialAddress=addr;
    }

    function setStageAddress(address addr) public onlyOwner 
    {
        stageAddress=addr;
    }
      
 
    function _mintNicMeta(uint256 tokenQuantity) internal {
      

        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
                transferFrom(msg.sender,address(stageAddress),mintIndex);
               
    
                uint256[] memory stagesNFT= ICardSubNFT(stageAddress).mint(mintIndex,CardCreateStageLen);
                
                
                for(uint256 i=0;i<stagesNFT.length;i++)
                {
             
                    if(i==0)
                    {
                        IMarkNFT(stageMarkAddress).setMangheBox(stagesNFT[i],true);
                        ERC721(stageAddress).transferFrom(address(this),officialAddress,stagesNFT[i]);
                    }
                    else{
                         ERC721(stageAddress).transferFrom(address(this),stageMarkAddress,stagesNFT[i]);
                    }
                    cardToStageData[mintIndex].push(stagesNFT[i]);
                  
               
                }
 
                // cardToSubNft[mintIndex]=new NFTMetaSub('','');
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (_revealed == false  ) {
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

 
    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

 

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

  

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}