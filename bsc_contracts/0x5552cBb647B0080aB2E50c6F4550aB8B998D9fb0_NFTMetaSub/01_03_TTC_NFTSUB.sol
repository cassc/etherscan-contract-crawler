// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
 
import "./TTC_ERC721.sol";
 
import "hardhat/console.sol";
 


interface IMarkNft
{
    function autoCreateMarketItem(address nftContract,uint256 tokenId,uint256 price,address sender) external;
} 

interface ICardNFT
{

    function getOpenBoxFee() external view returns(uint256);
    function getOpenBoxFeeAddress() external view returns(address);
    function getMarkFee() external view returns(uint256);
    function getStageMarkAddress() external view returns(address);
    function getTokenAddress() external view returns(address);

   

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

    ICardNFT public CardNftContract;

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
    
  

    mapping(uint256 => string) private _tokenURIs;


 
   
 
    constructor(string memory initBaseURI,string memory initNotRevealedUri)
        ERC721("TTC MetaSub", "TTCNFT")
    {
        _setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);

 
    }

    function setBaseUrl(string memory baseurl) public onlyOwner
    {
        _setBaseURI(baseurl);
    }

 
 

    mapping(uint256=>uint256) public subNftToCard;

  


    function setCardNft(ICardNFT card) public onlyOwner
    {
        CardNftContract=card;
    }
     
 
    function mint(uint256 cardId, uint256 tokenQuantity) external returns (uint256[] memory) 
    {
        require(address(CardNftContract)==msg.sender,'No administrative authority');

        uint256[] memory result=new uint256[](tokenQuantity);
        for (uint256 i = 0; i < tokenQuantity; i++) {

            uint256 mintIndex = totalSupply();
            console.log('xxxxxxxx');
            console.log(mintIndex);
            if (totalSupply() < MAX_SUPPLY) {
                result[i]=mintIndex;
              
                _mint(msg.sender, mintIndex);
                subNftToCard[mintIndex]=cardId;//当前道具对应的是哪个卡牌
            }
        }
        return result;
        
    }


    function getCardCount() view public  returns (uint256)
    {
       uint256[]memory nfts= CardNftContract.getAllToken(address(this),MAX_SUPPLY);
       return nfts.length;
    }
  
    function getCardStageList(uint256 cardId) public view returns(uint256[] memory)
    {
        uint256[] memory cardTokens= CardNftContract.getCardToStageData(cardId);
        return cardTokens;
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
            uint256[] memory cardNfts=CardNftContract.getCardToStageData(cardId);
            for(uint256 i=0;i<cardNfts.length;i++)
            {
                uint256 tokenId=cardNfts[i];

                address owner = ERC721.ownerOf(tokenId); // internal owner
 
                _hide(owner, address(0), tokenId);
   
            }
      
        }
         
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


      
        if (_isSaleActive==false) {
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

    function withdraw_nft(uint256[] memory tokens, address to) public onlyOwner {
        for(uint256 i=0;i<tokens.length;i++)
        {
            _transfer(address(this),to,tokens[i]);
        } 
    }
 
}