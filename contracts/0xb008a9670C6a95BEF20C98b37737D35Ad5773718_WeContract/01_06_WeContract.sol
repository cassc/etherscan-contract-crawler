//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;


//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeContract is ERC721A, Ownable {
    using Strings for uint256;
    mapping(address => bool) whitelistedAddresses;
    
    uint256 public minPrice;
    uint256 public mintedSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet; // not used yet
    uint256 public maxMintAmount = 5;
    bool public isMysterybox = false; // not used yet
    bool public isPublicMintEnabled = false;
    bool public isWhiteListEnabled = true;
    bool public paused = false;
    

    string public baseTokenUri;
    string public baseExtension = ".json";
    
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _baseTokenUri
    ) payable ERC721A(_name, _symbol) {
        setBaseTokenUri(_baseTokenUri);
        
        minPrice = 0.1 ether;
        //mintedSupply = 0;
        maxSupply = 100;
        //test only
        //addWhiteListUser(msg.sender);
        
    }
      function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }
    
    
    function getMaxSupply() public view returns (uint256)
    {
        return maxSupply;
    }

    function isWhitelistOnly() public view returns(bool) {
        return (isWhiteListEnabled == true && isPublicMintEnabled == false);
    }

    function checkOnWhitelist() public view returns(bool) {
        if(isWhitelistOnly()){
            return verifyUser(msg.sender);
        }
        return false;
    }
    
    function tokenURI(uint256 _tokenId) override virtual public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exits");
        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    Strings.toString(_tokenId),
                    baseExtension
                )
            );
    }

    

    function mint(uint256 _quantity) public payable {
        
        require(paused == false, "Minting is paused");

        if( msg.sender != owner() ) {
        
            require(maxMintAmount > _quantity, string(abi.encodePacked("Max mint amount is 100")));
                // require(verifyUser(msg.sender) , "White list only");
                // public mint
            if(isWhitelistOnly() == false){
                require((isPublicMintEnabled), "Public minting is disabled");
            }
            
            
            
            require(totalSupply() + _quantity <= maxSupply, "Max supply reached");
            require(
                msg.value == _quantity * minPrice,
                "Minting price is not correct"
            );
        }
        // require(
        //     walletMints[msg.sender] + _quantity <= maxPerWallet,
        //     "Max per wallet reached"
        // );

        
            _mint(msg.sender, _quantity);
        
    }
    
    // setter function owner only
    function setIsPublicMintEnabled(bool _isPublicMintEnabled)
        external
        onlyOwner
    {
        isPublicMintEnabled = _isPublicMintEnabled;
    }
    
    function setPaused(bool _state)
        external
        onlyOwner
    {
        paused = _state;
    }

    function setBaseTokenUri(string memory _baseTokenUri) public onlyOwner {
        baseTokenUri = _baseTokenUri;
    }
    
    function setMintPrice(uint256 _minPrice) public onlyOwner {
        minPrice = _minPrice;
    }
    
    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }
    
    function setmintedSupply(uint256 _mintedSupply) public onlyOwner {
        mintedSupply = _mintedSupply;
    }
    
    function setIsMysterybox(bool _isMysterybox) public onlyOwner {
        isMysterybox = _isMysterybox;
    }
    
    function setWithdrawWallet(address payable _withdrawWallet) public onlyOwner {
        withdrawWallet = _withdrawWallet;
    }
    
    

    function setIsWhiteListEnabled (bool _isWhiteListEnabled) public onlyOwner {
      isWhiteListEnabled = _isWhiteListEnabled;
    }
    
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Faile");
    }

    // white list
    function addWhiteListUser(address[] calldata _addressToWhitelist) public onlyOwner {
        for (uint i = 0; i < _addressToWhitelist.length; i++) {
            whitelistedAddresses[_addressToWhitelist[i]] = true;
        }
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "You need to be whitelisted");
        _;
    }
}