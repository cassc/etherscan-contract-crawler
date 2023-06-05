//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@1001-digital/erc721-extensions/contracts/RandomlyAssigned.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract TORIX is ERC721URIStorage, RandomlyAssigned, VRFConsumerBase,  Ownable {

    using Strings for uint256;
    using SafeMath for uint256;
    uint256 internal fee;
    uint256 public teamSupplyMinted;
    uint256 public whitelistSupplyMinted;
    uint256 public constant maxSupply = 9999;
    uint256 public constant maxTeamSupply = 149;
    uint256 public constant maxWhitelistSupply = 3400;
    uint256 public constant salePrice = 0.15 ether;
    uint256 public firstWinnerMetadataShuffleRandomResult;
    uint256 public secondWinnerMetadataShuffleRandomResult;
    uint256[] private _allTokens;
    string public baseURI;
    string public baseExtension = ".json";

    /**
    * @dev Each TORIX image is hashed using SHA-256. 
    * These hashes are then, in order 1 - 9999, concatenated into a string which is then hashed using SHA-256 into provenceHash.  
    */
    string public provenanceHash = "ea7f691c1a1a95a617805076904035dcbf8e1f0878f47caa53c51ad309d1c062";
    string public notRevealedURI;
    bool public revealed;
    bool public mintStatus;
    bool public mintWhitelistStatus;
    bool public secondSale;
    bytes32 internal keyHash;
    
    mapping(address => bool) public firstWinnerList;
    mapping(address => uint256) public firstWinnerListClaimed;
    mapping(address => bool) public secondWinnerList;
    mapping(address => uint256) public secondWinnerListClaimed;
    mapping(address => bool) public whiteList;
    mapping(address => uint256) public whiteListClaimed;


    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;


    modifier mintable() {
        require(mintStatus, "mintable must be true.");
        _;
    }
    modifier mintableWhitelist() {
        require(mintWhitelistStatus, "mintWhitelistStatus must be true.");
        _;
    }

    event RequestRandomnessFulfilled(bytes32 indexed requestId, uint256 indexed randomness);
    event RequestAddWinnListEvent(address[] indexed addresses, uint256[] indexed mintcount);
    event RequestRemoveWinnerList(address[] indexed addresses);
    event RequestOwnerMint(address indexed ownerAddress, uint256 indexed tokenId);
    event RequestReserveMint(address indexed ownerAddress, uint256 indexed tokenId);
    event RequestWinnerMint(address indexed winnerAddress, uint256 indexed tokenId);
    event RequestWhitelistMint(address indexed winnerAddress, uint256 indexed tokenId);
    
    constructor(
        string memory _name, 
        string memory _symbol,
        address _VRFCoordinator, 
        address _LinkToken, 
        bytes32 _keyhash, 
        uint256 _fee
    )  
        ERC721(_name, _symbol) 
        RandomlyAssigned(maxSupply,1)
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
    {
        keyHash = _keyhash;
        fee = _fee;
    }

    /**
    * @dev Requests randomness 
    */ 
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
    * @dev Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if(secondSale){
            secondWinnerMetadataShuffleRandomResult = randomness;
        }else{
            firstWinnerMetadataShuffleRandomResult = randomness;
        }
        emit RequestRandomnessFulfilled(requestId, randomness);
    }

    /**
    * @dev Adds the provided address(mint count) to the whitelist
    */
    function addWhiteList(address[] calldata addresses, uint256[] calldata mintcount) external onlyOwner  {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "You can't add the null address");
            whiteList[addresses[i]] = true;
            whiteListClaimed[addresses[i]] = mintcount[i];
        }
    }

    /**
    * @dev Removes the provided address to the whitelist
    */
    function removeWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "You can't add the null address");
            whiteList[addresses[i]] = false;
            whiteListClaimed[addresses[i]] = 0;
        }
    }

    /**
    * @dev Adds the provided address(mint count) to the winnerlist
    */
    function addWinnerList(address[] calldata addresses, uint256[] calldata mintcount) external onlyOwner  {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "You can't add the null address");
            if(secondSale){
                secondWinnerList[addresses[i]] = true;
                secondWinnerListClaimed[addresses[i]] = mintcount[i];
            }else{
                firstWinnerList[addresses[i]] = true;
                firstWinnerListClaimed[addresses[i]] = mintcount[i];
            }
        }
    }

    /**
    * @dev Removes the provided address to the winnerlist
    */
    function removeWinnerList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "You can't add the null address");
            if(secondSale){
                secondWinnerList[addresses[i]] = false;
                secondWinnerListClaimed[addresses[i]] = 0;
            }else{
                firstWinnerList[addresses[i]] = false;
                firstWinnerListClaimed[addresses[i]] = 0;
            }
        }
    }

    /**
    * @dev Returns check whether the address is whitelisted
    */
    function checkWhitelistWinner(address _address) public view returns(bool, uint256) {
        return (whiteList[_address], whiteListClaimed[_address]);
    }

    /**
    * @dev Returns check whether the address is first sale winnerlisted
    */
    function checkFirstWinner(address _address) public view returns(bool, uint256) {
        return (firstWinnerList[_address], firstWinnerListClaimed[_address]);
    }

    /** 
    * @dev Returns check whether the address is second sale winnerlisted
    */
    function checkSecondWinner(address _address) public view returns(bool, uint256) {
        return (secondWinnerList[_address], secondWinnerListClaimed[_address]);
    }

    /**
    * @dev minted by only owner
    */
    function mintOwnerTorix(uint256 mintcount) 
        external 
        onlyOwner 
        ensureAvailability 
    {        
        require(availableTokenCount() >= mintcount, "You can not mint more than availableMintCount");
        for (uint i = 1; i <= mintcount; i++) {
            uint256 id = nextToken();
            _safeMint(msg.sender, id);
            emit RequestOwnerMint(msg.sender, id);
        }
    }
    
    /**
    * @dev minted by the teamlist
    */
    function mintTeamTorix(address[] calldata addresses, uint256[] calldata mintcount) 
        external 
        onlyOwner 
        ensureAvailability 
    {             
        uint256 totalMintCount;
        for(uint256 i = 0; i < mintcount.length; i++){
            totalMintCount += mintcount[i];
        }
        require( availableTokenCount() >= totalMintCount, "You can not mint more than availableMintCount");
        require( maxTeamSupply - teamSupplyMinted >= totalMintCount, "You can not mint more than team supply");
        for (uint256 i = 0; i < addresses.length; i++) {
            teamSupplyMinted = teamSupplyMinted.add(mintcount[i]);
            for (uint j = 1; j <= mintcount[i]; j++) {
                uint256 id = nextToken();
                _safeMint(addresses[i], id);
                emit RequestReserveMint(addresses[i], id);
            }
        }
    }
   
    /**
    * @dev minted by the whitelist
    */
    function mintWhitelistTorix(uint256 mintcount) 
      public
      payable
      mintableWhitelist
      ensureAvailability
    {
        require( whiteListClaimed[msg.sender] > 0, "You are not on the whitelist");
        require( whiteListClaimed[msg.sender] >= mintcount, "You can not mint more than TORIX[whiteListClaimed]");
        require( whitelistSupplyMinted + mintcount <= maxWhitelistSupply, "You can not mint more than maxWhitelistSupply");
        require( msg.value >= salePrice * mintcount, "ETH amount is not sufficient");

        whiteListClaimed[msg.sender] -= mintcount;
        whitelistSupplyMinted = whitelistSupplyMinted.add(mintcount);
        for (uint i = 1; i <= mintcount; i++) {
            uint256 id = nextToken();
            _safeMint(msg.sender, id);
            emit RequestWhitelistMint(msg.sender, id);
        }
    }

    /**
    * @dev minted by the winner
    */
    function mintTorix()
      public
      payable
      mintable
      ensureAvailability
    {
        uint256 availableMintCount;
        require( tx.origin == msg.sender, "You can't mint through a external contract");
        require( msg.sender != owner(), "Owner can not mint");
        if(secondSale){
            require( secondWinnerList[msg.sender], "You are not on the second winnerlist");
        }else{
            require( firstWinnerList[msg.sender], "You are not on the first winnerlist");
        }
        
        if(secondSale){
            availableMintCount = secondWinnerListClaimed[msg.sender];
        }else{
            availableMintCount = firstWinnerListClaimed[msg.sender];
        }
        require( msg.value >= salePrice * availableMintCount, "ETH amount is not sufficient");
       
        if(secondSale){
            secondWinnerList[msg.sender] = false;
        }else{
            firstWinnerList[msg.sender] = false;
        }
        
        for(uint8 i=0;i<availableMintCount;i++){
            uint256 id = nextToken();
            _safeMint(msg.sender, id);
            emit RequestWinnerMint(msg.sender, id);
        }
    }

    /**
    * @dev Enable the second sale flag
    */
    function onSecondSale() public onlyOwner {
      secondSale = true;
    } 
    
    /**
    * @dev Enable reveal
    */
    function reveal() public onlyOwner {
      revealed = true;
    } 

    /**
    * @dev Disable not reveal
    */
    function notReveal() public onlyOwner {
      revealed = false;
    } 

    /**
    * @dev Set not reveal URI
    */
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    /**
    * @dev Enable or disable the mintable status
    */
    function toggleMintable(bool _mintStatus) public onlyOwner {
        mintStatus = _mintStatus;
    }

    /**
    * @dev Enable or disable the whitelist mintable status
    */
    function toggleWhitelistMintable(bool _mintWhitelistStatus) public onlyOwner {
        mintWhitelistStatus = _mintWhitelistStatus;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override
        returns (string memory){
            require(_exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
            );
        if(revealed == false) {
            return notRevealedURI;
        }   
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length >0 ? string(abi.encodePacked(currentBaseURI, "/", tokenId.toString(), baseExtension)) : "";
    }

    /**
    * @dev IERC721Enumerable
    */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    
     function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
          uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    
    function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }    
     
    function burnTorix(uint256 tokenId) public {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistant token"
        );
        require(_isApprovedOrOwner(msg.sender, tokenId),"Owner or Approved address can burn");
        super._burn(tokenId);
    }

    function ethBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function linkBalance() public view onlyOwner returns (uint256) {
        return LINK.balanceOf(address(this));
    }

    function withdrawETH() public payable onlyOwner {
        require(ethBalance() > 0, "not exist ETH" );
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawLINK() external onlyOwner {
        require(linkBalance() > 0, "not exist LINK" );
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }
    
}