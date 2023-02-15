// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import 'abdk-libraries-solidity/ABDKMathQuad.sol'; 
 
contract TreasureHuntNFT is ERC721Royalty,Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 private cost = 0.01 ether ; // 
    bool public privateSale = false;
    bool public publicSale = false;
    bool public revealed = false ;
    uint256 public maxSupply = 1023 ; //   1024 NFTs available (starting at 0)  
    uint256 public publicSaleStartDate ;
    uint256 public unlockDate ; 
    string private baseURI = '';
    string private hiddenMetadataUri = 'https://bafybeicej5f4a6h6h62a53ekkikzrzvgu4dleraxybynnrkyyptrglp4mm.ipfs.w3s.link/waiting_json/';
    bytes32 private hashedSecretCode ; 
    bytes32 private hashedSecretWords;   

    address payable TreasureHuntCreatorAddress;
    address payable public WinnerAddress;
    mapping(address => bool) public whitelist;
   
    struct NftItem {
        uint256 tokenId;
        address payable owner;
    }
    mapping(uint256 => NftItem) private ethNFTS;

    event NewMint(address buyer, uint256 tokenId);
    event AddedToWhitelist(address user);
    constructor() ERC721("ETH TreasureHunt NFT Game", "ETHTreasure") {
        _setDefaultRoyalty(payable(msg.sender),500); //5% of royalties 
        TreasureHuntCreatorAddress = payable(msg.sender);
      
    } 
 
    // checkCode : check NFT revealed ,  code, and if ok  
    function checkCode(string memory _code) public  view returns (bool) {
       
        if (revealed){
            //check own nft 
            if (this.balanceOf(msg.sender) > 0) {
                     bytes32 hashedCode = sha256(bytes(_code));
                 
                  if (hashedCode == hashedSecretCode){
                    return true;
                  }
            }
        }
       return false;
    }
    // check secretKey  : check Contrat NFT revealed , check own nft, check unlock date and check secret  
    function checkWin(string memory _secret) public {
        require(revealed,"NFT not yet revealed");
        require(WinnerAddress==address(0),"Already a winner");
        require(this.balanceOf(msg.sender) > 0,"Dont have an nft");
        require(block.timestamp >= unlockDate,"Treasure not yet unlock");
       
        bytes32 hashedCode = sha256(bytes(_secret));
        if (hashedCode == hashedSecretWords){
              WinnerAddress = payable(msg.sender);
              //Send money to winner 
              WinnerAddress.transfer(address(this).balance);
        }
    }
   
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
            maxSupply = _maxSupply;
    }

     function setBaseUri(string memory _baseurl) public onlyOwner {
            baseURI = _baseurl;
    }

    function setHashes(bytes32 _cc, bytes32 _wd) public onlyOwner {
            hashedSecretCode = _cc;
            hashedSecretWords = _wd;
    }
    
    modifier mintCompliance(uint256 _mintAmount) {
            require(_mintAmount>0,"1 mint minimum");

            require(
                _tokenIds.current() + _mintAmount <= maxSupply,
                "Max supply exceeded!"
            );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= (cost * _mintAmount), "Not paid enough !");
        _;
    }

    function addWhitelist(address _newEntry) public {
        require(!privateSale, "Private sale started");
        whitelist[_newEntry] = true;
        emit AddedToWhitelist(_newEntry);
    }

    

    function mintNFT(address _to, uint256 _mintAmount) internal{
        
        for (uint256 i = 0; i < _mintAmount; i++) {
             uint256 tokenId = _tokenIds.current();
            _safeMint(_to, tokenId);
            ethNFTS[tokenId] = NftItem(
                tokenId,
                payable(msg.sender)
            );
            _tokenIds.increment(); 
            emit NewMint(msg.sender, tokenId);
        }
    }
 
    
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(privateSale || publicSale,"Private or Public sale not started");
        
        // Si private mint , whitelist required
        if (privateSale){
             // check si public sale ouvert
             if (publicSale==false){
                  // NON => check date et ouvre si besoin
                  if(block.timestamp >= publicSaleStartDate) { 
                    publicSale = true;
                    privateSale = false;
                  }
                  else{
                    // si pas ouvert check dans whitelist
                    require( whitelist[msg.sender],"Not in whitlist for minting");
                  
                  }
             }
       }
        
        mintNFT(_msgSender(), _mintAmount);
        // Send 31% to TreasureHuntCreatorAddress 
        uint256 amountPercent = mulDiv(31,msg.value, 100);
        payable(TreasureHuntCreatorAddress).transfer(amountPercent);
        
        //70% stays in the contract and is for the winner of the hunt 

        // check if max supply reached and if so, revealed MAP
        uint256 tokenId = _tokenIds.current();
        if (tokenId>= maxSupply){
            revealed = true;
            //Calculer la date de unlock du smart contract (+48H)
            unlockDate =  block.timestamp+2 days; // 
        }
    }
 
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

   function getNbTokenMinted() public view returns (uint256) {
        return  _tokenIds.current();
    }
   

    function tokenURI(uint256 _tokenId)
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

         if (revealed == false) {
            string memory currentBaseURI = hiddenMetadataUri;
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            '.json'
                        )
                    )
                    : "";
        }
        else{
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            '.json'
                        )
                    )
                    : "";
        }
       
    }
     
     function setPrivateSale(bool _state) public onlyOwner {
        privateSale = _state;
        //Calculer la date de public Sales = private Sales + 4 days
        publicSaleStartDate = block.timestamp+4 days;
          
    }

    

     function setCost(uint256 _newcost) public onlyOwner {
        cost = _newcost;
    }

  

    function fetchTokenForOwner(address owner)
        public
        view
        returns (NftItem[] memory)
    {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i <totalItemCount; i++) {
         
            if (ethNFTS[i].owner == owner) {
                itemCount += 1;
            }
        }

        NftItem[] memory items = new NftItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (ethNFTS[i].owner == owner) {
                uint256 currentId = i;
                NftItem storage currentItem = ethNFTS[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
  
    function mulDiv (uint x, uint y, uint z)
        public pure returns (uint) {
        return
            ABDKMathQuad.toUInt (
            ABDKMathQuad.div (
                ABDKMathQuad.mul (
                ABDKMathQuad.fromUInt (x),
                ABDKMathQuad.fromUInt (y)
                ),
                ABDKMathQuad.fromUInt (z)
            )
            );
        }


    function withdrawIfNoWinner() public onlyOwner nonReentrant {
        require(revealed,"Not all NFT minted");
        require (block.timestamp >= unlockDate,"not yet"); 
        //Pick a random winner 
        uint256 randomWinner = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % 1024;
        randomWinner = randomWinner-1;
        WinnerAddress = ethNFTS[randomWinner].owner;
        WinnerAddress.transfer(address(this).balance);
    }

    function random(uint num) public view returns(uint){
            return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % num;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
 
 
     
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        //call the original function that you wanted.
        super.safeTransferFrom(from, to, tokenId, data);

        //update
        uint256 totalItemCount = _tokenIds.current();

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (ethNFTS[i].tokenId == tokenId) {
                NftItem storage currentItem = ethNFTS[i];
                currentItem.owner = payable(to);

                break;
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //call the original function that you wanted.
        super.safeTransferFrom(from, to, tokenId);

        //update
        uint256 totalItemCount = _tokenIds.current();

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (ethNFTS[i].tokenId == tokenId) {
                NftItem storage currentItem = ethNFTS[i];
                currentItem.owner = payable(to);

                break;
            }
        }
    }

      function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //call the original function that you wanted.
        super.transferFrom(from, to, tokenId);

        //update
        uint256 totalItemCount = _tokenIds.current();

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (ethNFTS[i].tokenId == tokenId) {
                NftItem storage currentItem = ethNFTS[i];
                currentItem.owner = payable(to);

                break;
            }
        }
    }
   
}