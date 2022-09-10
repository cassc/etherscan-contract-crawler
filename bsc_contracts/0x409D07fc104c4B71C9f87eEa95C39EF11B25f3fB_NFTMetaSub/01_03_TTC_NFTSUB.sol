// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
 
import "./TTC_ERC721.sol";
 
import "hardhat/console.sol";
 

 

interface ICardNFT
{
     function transferFrom(address from, address to, uint256 tokenId) external;
     function getCardToStageData(uint256 cardid) external view returns(uint256[] memory) ;
     function getAllToken(address owner,uint256 _pagesize) external view  returns (uint256[] memory) ;
}
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


 contract NFTMetaSub is ERC721,Ownable {
    using Strings for uint256;
 

    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 5162;
    uint256 public mintPrice = 0.0001 ether;
    uint256 public maxBalance = 1;
    // uint256 public maxMint = 5162;
    uint256 public maxMint = 1;
   
    string public notRevealedUri;
    string public baseExtension = ".json";
    ICardNFT CardNftContract;

    address public officialAddress;

    mapping(uint256 => string) private _tokenURIs;

    mapping (address => bool) public whiteList;

    mapping(uint256=>bool) public mangheBox;

    mapping(uint256=>uint256[]) public cardNft;
 
    mapping(uint256=>uint256) public subNftToCard;

    mapping(address=>bool) public addressToOpenBox;
   
 
    constructor(
        string memory initBaseURI,
        string memory initNotRevealedUri,
        address initOfficialAddress
        )
        ERC721("TTC MetaSub", "TTCNFT")
    {
        _setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
        officialAddress=initOfficialAddress;
    }

    function setBaseUrl(string memory baseurl) public onlyOwner
    {
        _setBaseURI(baseurl);
    }

    function setCardNft(ICardNFT card) public onlyOwner
    {
        CardNftContract=card;
    }
     
    function setOfficialAddress(address addr) public onlyOwner
    {
        officialAddress=addr;
    }
      

    function getCardCount() view public  returns (uint256)
    {
       uint256[]memory nfts= CardNftContract.getAllToken(address(this),MAX_SUPPLY);
       return nfts.length;
    }
 
    uint256 CardCount;

    function  getCurrenCardId() public view  returns(uint256){
         return CardCount;
    //    uint256[]memory nfts= CardNftContract.getAllToken(address(this),MAX_SUPPLY);
    //    console.log('xxx',nfts.length);
    //    require(nfts.length>0,'Insufficient number of cards');
    //    return nfts[0];
    }


    function getCardStageList(uint256 cardId) public view returns(uint256[] memory)
    {
        uint256[] memory cardTokens= CardNftContract.getCardToStageData(cardId);
        return cardTokens;
    }

    //设置白名单
    function setWhiteList(address userAddress, bool _states) public  onlyOwner {
        whiteList[userAddress] = _states;
    }
 
    function batchSetWhiteList(address[] memory addresList, bool states) public onlyOwner  {
        for(uint256 i=0;i<addresList.length;i++)
        {
            address userAddress=addresList[i];
            whiteList[userAddress] = states;
        }        
    }
    function openBox() public payable {
        require(address(CardNftContract)!=address(0),'need set CardNftContract address');

        address userAddress=msg.sender;
        require(whiteList[userAddress],"whiteList error");
        require(addressToOpenBox[msg.sender]==false,'box has open');
        // require(keccak256(abi.encodePacked((signature))) == keccak256(abi.encodePacked((_signature))), "Invalid signature");

        require(_isSaleActive, "Sale must be active to TTC");
 
 
  
        uint256 cardId=getCurrenCardId();
        console.log('getCurrenCardId',cardId);
        uint256 tokenQuantity=getCardStageList(cardId).length;
        console.log('tokenQuantity',tokenQuantity);

        require(tokenQuantity>0,'CardStage Insufficient length');
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY,"Sale would exceed max supply");
        // require(balanceOf(msg.sender) + tokenQuantity <= maxBalance,"Sale would exceed max balance");

        _mintNicMeta(tokenQuantity,cardId);
        // _autoSentToMark(tokenQuantity);
        CardCount+=1;

        // nftMaket.createMarketItem(address(this),)
    }

 

    
    function _mintNicMeta(uint256 tokenQuantity,uint256 cardId) internal {
        require(officialAddress!=address(0),'Need set officialAddress');

        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                
                if(i==0)
                {
                    _safeMint(msg.sender, mintIndex);
 
                }else{
                    _safeMint(officialAddress, mintIndex);
                
                }
            
                mangheBox[mintIndex]=true;
                addressToOpenBox[msg.sender]=true;
                          
                cardNft[cardId].push(mintIndex);//当前卡牌总共开启几个了
                subNftToCard[mintIndex]=cardId;//当前道具对应的是哪个卡牌
 
            }
        }
    }

    function getCardAllSubNft(uint256 cardid, address owner,uint256 pageSize) public view returns(uint256[] memory)
    {
        uint256[] memory nfts=getAllToken(owner,pageSize) ;   
 

        uint256[] memory cardNfs=new uint256[](pageSize);
        uint256 len=0;
        for(uint256 i=0;i< nfts.length;i++)
        {
            if(subNftToCard[nfts[i]]==cardid)
            {
                uint256 f=nfts[i];
                cardNfs[i]=f;
                len+=1;
            }
        }

        uint256[] memory result=new uint256[](len);
        for(uint256 i=0;i< result.length;i++)
        {
            result[i]= cardNfs[i];
        }
        return result;
        
    }

    function getNftLengthByCardId(uint256 cardid, address owner,uint256 pageSize) public view returns(uint256 )
    {
        uint256[] memory nfts=getAllToken(owner,pageSize) ;     

        uint256 len=0;
        for(uint256 i=0;i< nfts.length;i++)
        {
            if(subNftToCard[nfts[i]]==cardid)
            {
                len+=1;
            }
        }

 
        return  len;
    }

    
    function hasStage(uint256 tokenId, uint256[] memory stages) private returns(bool)
    {
        
        for(uint256 i=0;i<stages.length;i++)
        {
            if(stages[i]==tokenId)
            {
                return true;
            }
        }

        return false;

    }

    function veryComposeNft(address cardAddress, uint256 cardId) private  returns(bool)
    {
        uint len;
        uint256[] memory cardTokens= ICardNFT(cardAddress). getCardToStageData(cardId);
        uint256[] memory tokens=  getAllToken(msg.sender,MAX_SUPPLY);


        for(uint256 i=0;i<cardTokens.length;i++)
        {
            if(hasStage(cardTokens[i], tokens))
            {
                len+=1;
            }
        }
        return len==cardTokens.length;
    }

    //合成
    function composeNft(address cardAddress, uint256 cardId) public
    {
 
        require (veryComposeNft(cardAddress,cardId),'Insufficient nftStage');
        {            
            IERC721(cardAddress). transferFrom(address(this), msg.sender, cardId);

            for(uint256 i=0;i<cardNft[cardId].length;i++)
            {
                uint256 tokenId=cardNft[cardId][i];
                _burn(tokenId);
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


      
        if (mangheBox[tokenId]==false) {
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

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
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