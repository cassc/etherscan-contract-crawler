// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract DNA is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private baseURI = "";
    string private baseExtension = ".json";

    uint256 private maxSupply = 777;
    uint256 private maxBlueSupply = 54;
    uint256 private maxAdvisorSupply = 77;
    uint256 private maxDNASelfSupply = 77;

    uint256 private maxDNASupply = 77;       // each start mint number
    uint256 private currentDNASupply = 0;    // current amount of minted in each starting

    uint256 public mintAddressLimit = 2;   //  limit amount of each address is able to mint
    uint256 public cost = 0.36 ether;

    bool public paused = true;              // start / stop 

    address private walletA = 0x6222B964651998e49b6dE26e59D977147254213D; // bluechip wallet
    address private walletB = 0x7dd92296299F6fC47E8F3C62b9989e2d7E6d6277; // airdrop 77 token to self
    
    address[] private airdropAddressList = [                              // advisor airdrop addresses 
        0xb75C8Ccd983161Da5904daf915d0d98877106B82,
        0x4c64f00192DA89486C1Eec2f12bFA74CbeC413e1,
        0x87a95295B64c1ea849e38c3849Da60A40f4f7E76,
        0x5cae83C312B67AeF18CBD0627c0Eb67F4524A7c2,
        0x7040d76C32765F1bd8D5C7f2cc8288076CC2b956,
        0x295fF892A2B5941ED26Ff8a10FEcF90554092719,
        0x752F405BDaF1fA55519E3F3C0c0BD155821bEed5,
        0x79163A65F37129Cc8160623D64a06aA06DBB12B2,
        0x9c840914715Db95DD6773155788eF1e316c4E579,
        0xB9cF551E73bEC54332D76A7542FdacBb77BFA430,
        0x36837e2c2893b2d34fA80694B70eb53677aa6D4a,
        0x819A899c0325342CD471A485c1196d182F85860D,
        0x25B7da55E37c6e02c6ED560FEAA9aeB68dbbfa65,
        0x114ddEdBaD20dc9c4625776aBd17896e0D18FB26,
        0x76f838819F33606393E40A8188Cf2B279cB98dF6,
        0xF0504B013159a9eA19741D0A38AA29b9cc3Cf436,
        0x049b916dac9b8e3C3Ee573B8df491fb2132288d0,
        0xFE67FC74E3845A8352000D20A3AA200Cf4e963c3,
        0x0172B6b3cB56A9B71d63C86A6B7F6d9105f5DE33
    ];

    mapping(address => bool) public whitelisted; // whitelist address 
    mapping(address => uint256) private addressMintedBalance; // amount of current minted address  
    mapping(address => uint256 []) private addressMintedTokenId; // tokenIds of current minted address  


    constructor( string memory _deployURI ) ERC721("DNA PASS", "DNAP") {
        uint256 supply = totalSupply();
        baseURI = _deployURI;
        console.log("start supply num : ", supply);
        console.log("baseURI : ", baseURI);
        deployTask(); 
    }

    function deployTask() private{

        uint256 supply = totalSupply();
        /* lock token to walletA */
        for (uint256 i = 1; i <= maxBlueSupply; i++) {
            _safeMint(walletA, supply + i);
            // console.log("Mint To WalletA - Supply num : ", totalSupply());
        }

        supply = totalSupply();
        /* mint advisors */
        for (uint256 i = 1; i <= airdropAddressList.length; i++) {
            address airdropAddress = airdropAddressList[i - 1];
            _safeMint(airdropAddress, supply + i);
            // console.log("Mint To Advisor Address - Supply num : ", totalSupply());
        }

        uint256 remainSupply = maxAdvisorSupply - airdropAddressList.length;
        uint256 selfSupply = maxDNASelfSupply + remainSupply;
        supply = totalSupply();
        /* mint token to WalletB */
        for (uint256 i = 1; i <= selfSupply; i++) {
            _safeMint(walletB, supply + i);
            // console.log("Mint To WalletB - Supply num : ", totalSupply());
        }
        
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable {
        
        require( paused == false, "The collection is currently on sale" );

        uint256 supply = totalSupply();
 
        require(_mintAmount > 0, "Mint amount cannot less than 1");
        require(currentDNASupply + _mintAmount <= maxDNASupply, "Max DNA supply exceeded");
        require(supply + _mintAmount <= maxSupply, "Max total supply exceeded");
        require(isWhitelisted(msg.sender), "User is not whitelisted");
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
        require(addressMintedBalance[msg.sender] + _mintAmount <= mintAddressLimit, "Max mint amount of address limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            addressMintedTokenId[msg.sender].push(supply + i);
            console.log("mint token : ", supply + i);
            _safeMint(msg.sender, supply + i);
            currentDNASupply++;
        }    

    }

    function isWhitelisted(address _user) public view returns (bool) {
        if(whitelisted[_user] == true){
            return true;
        }
        return false;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function walletOfMintedOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerMintedTokenCount = addressMintedTokenId[_owner].length;
        uint256[] memory tokenIds = new uint256[](ownerMintedTokenCount);
        for (uint256 i; i < ownerMintedTokenCount; i++) {
            tokenIds[i] = addressMintedTokenId[_owner][i];
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /* start mint */
    function startMint( uint256 _saleNum ) public onlyOwner {

        uint256 _currentSupply = totalSupply();
        require( _currentSupply + _saleNum <= maxSupply, "The amount of sale token is over the totalSupply" );

        paused = false;
        maxDNASupply = _saleNum;
        currentDNASupply = 0;

    }

    /* pause mint */
    function stopMint() public onlyOwner {
        require( paused == false, "The collection is currently not on sale" );
        paused = true;
    }

    /* set amount limit of address mint max token */
    function setMintLimit( uint256 _saleNum ) public onlyOwner {
        require( _saleNum > mintAddressLimit, "New mint-limit must be more than now" );
        mintAddressLimit = _saleNum;
    }

    /* set whitelist */
    function addWhitelistUsers(address[] calldata _users) public onlyOwner {
         for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    /* 0: total / 1: current minting */
    function getMaxSupply( uint256 _type ) public view virtual returns (uint256) {
        uint256 _totalSupply;
        if( _type == 0 ){
            _totalSupply = maxSupply;
        }else if( _type == 1 ){
            _totalSupply = maxDNASupply;
        }
        return _totalSupply;
    }

    /* 0: total / 1: current minting */
    function getCurrentSupply( uint256 _type ) public view virtual returns (uint256) {
        uint256 _currentSupply;
         if( _type == 0 ){
            _currentSupply = totalSupply();
        }else if( _type == 1 ){
            _currentSupply = currentDNASupply;
        }
        return _currentSupply;
    }

    function getBalance() public onlyOwner view virtual returns (uint256) {
        uint256 totalBalance = address(this).balance;
        return totalBalance;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}