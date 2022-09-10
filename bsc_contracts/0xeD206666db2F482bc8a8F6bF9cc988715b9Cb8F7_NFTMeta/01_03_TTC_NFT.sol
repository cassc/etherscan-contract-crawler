// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
 
import "./TTC_ERC721.sol";
 
import "hardhat/console.sol";
  
 
contract NFTMeta is ERC721,Ownable {
    using Strings for uint256;

    bool public _isSaleActive = true;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 365;
 
    uint256 public maxBalance = 365;

    uint256 public maxMint = 365;
    // INftMarket public nftMaket;

 
    string public notRevealedUri;
    string public baseExtension = ".json";

    address public StageAddress;

    uint256 public CardCreateStageLen=2;
    mapping(uint256 =>uint256[]) public  cardToStageData; 

    mapping(uint256 => string) private _tokenURIs;

    // mapping(uint256=>NFTMetaSub) public cardToSubNft;
 
    constructor(string memory initBaseURI, string memory initNotRevealedUri,address initStageAddress)
        ERC721("TTC Meta", "TTCNFT")
    {
        _setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
        StageAddress=initStageAddress;
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

 
    function _mintNicMeta(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
 
                for(uint256 i=0;i<CardCreateStageLen;i++)
                {
                    cardToStageData[mintIndex].push(stageCount);
                    stageCount+=1;
                    console.log(stageCount);
                }

                transferFrom(msg.sender,address(StageAddress),mintIndex);

   
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