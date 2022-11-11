//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeContract is ERC721, Ownable {
    using Strings for uint256;
    mapping(address => bool) whitelistedAddresses;
    
    uint256 public minPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet; // not used yet
    uint256 public maxMintAmount = 5;
    bool public isMysterybox = false; // not used yet
    bool public isPublicMintEnabled;
    bool public paused = false;
    uint256 public whiteListEnabledTime = 1668096000;
    uint256 public publicMintEnabledTime = 1668182400;

    string public baseTokenUri;
    string public baseExtension = ".json";
    
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenUri
    ) payable ERC721(_name, _symbol) {
        setBaseTokenUri(_baseTokenUri);
        
        minPrice = 0.1 ether;
        totalSupply = 0;
        maxSupply = 100;
        //test only
        //addWhiteListUser(msg.sender);
        
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }
    
    function getTotalSupply() public view returns (uint256)
    {
        return totalSupply;
    }
    function getMaxSupply() public view returns (uint256)
    {
        return maxSupply;
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
        
            require(maxMintAmount >= _quantity, string(abi.encodePacked("Max mint amount is", maxMintAmount)));
            
            if(block.timestamp > whiteListEnabledTime && block.timestamp < publicMintEnabledTime){
                // whitelist mint
                require(verifyUser(msg.sender) , "White list only");
            }else{
                // public mint
                require((isPublicMintEnabled && block.timestamp > publicMintEnabledTime), "Public minting is disabled");
            }
            
            require(totalSupply + _quantity <= maxSupply, "Max supply reached");
            require(
                msg.value == _quantity * minPrice,
                "Minting price is not correct"
            );
        }
        // require(
        //     walletMints[msg.sender] + _quantity <= maxPerWallet,
        //     "Max per wallet reached"
        // );

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
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
    
    function setTotalSupply(uint256 _totalSupply) public onlyOwner {
        totalSupply = _totalSupply;
    }
    
    function setIsMysterybox(bool _isMysterybox) public onlyOwner {
        isMysterybox = _isMysterybox;
    }
    
    function setWithdrawWallet(address payable _withdrawWallet) public onlyOwner {
        withdrawWallet = _withdrawWallet;
    }
    
    function setWhiteListEnabledTime (uint256 _whiteListEnabledTime) public onlyOwner {
      whiteListEnabledTime = _whiteListEnabledTime;
    }
    function setPublicMintEnabledTime (uint256 _publicMintEnabledTime) public onlyOwner {
      publicMintEnabledTime = _publicMintEnabledTime;
    }
    
    function withdraw() public payable onlyOwner {
        setWithdrawWallet(payable(msg.sender));
        require(payable(withdrawWallet).send(address(this).balance),"Withdraw failed");
        
        
    }

    // white list
     function addWhiteListUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
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