// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract SFPCollection is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    AggregatorV3Interface internal priceFeed;

   
    address public admin;
    address public paymentWallet ; 
    string private _baseUri;


    uint256 public collectionSize ;
    uint256 private countryCount;
    uint256 public walletLimit;
    uint256 public maxLimitPerMint;
    uint256 public nftPriceInUsd;
    uint256 public totalMinted;

    mapping(uint256 => uint256) private countryTokenIndex;
   
    mapping(address=> uint[]) private userNftIds;
    mapping(uint => uint) private countryId;
    
    modifier onlyOwnerAndAdmin() {
        require(owner() == _msgSender() || _msgSender() == admin, "Ownable: caller is not the owner or admin");
        _;
    }

    
    event NftSale(uint256[] countryId,uint256[] tokenId,address buyer,uint256 quantity,uint256 totalPriceInEth,uint256 totalPriceInUsd);

    function initialize(string memory _name, string memory _symbol,address _paymentWallet) initializer public {
        __ERC721_init(_name,_symbol);
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        setAdmin(_msgSender());
        nftPriceInUsd = 90;
        paymentWallet = _paymentWallet;
        collectionSize = 6400;
        countryCount = 0;

        for(uint256 j=1;j<33;j++){
            countryTokenIndex[j]=(j-1)* 200;
        }
        totalMinted = 0;
        walletLimit = 10;
        maxLimitPerMint = 5;
        
    }


    function getEthPriceInUsd() public view returns(int256) {
        return (priceFeed.latestAnswer()/1e8);
    }

    function getNftPriceInEth() public view returns(uint256) {

         uint256 priceInUSD = uint256(getEthPriceInUsd());
        return (((1*1e18)/priceInUSD)*nftPriceInUsd) ; 
    }


    function _baseURI() internal view override returns (string memory) {
        return _baseUri; 
    }

    function setBaseUri(string calldata _uri) external onlyOwnerAndAdmin{
        _baseUri = _uri;
    }


    function setAdmin(address _adminAddress) public onlyOwnerAndAdmin {
        admin = _adminAddress;
    }

    function pause() public onlyOwnerAndAdmin {
        _pause();
    }

    function unpause() public onlyOwnerAndAdmin {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwnerAndAdmin
        override
    {}

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable){
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory){
        return super.tokenURI(tokenId);
    }

    function setPaymentWallet(address _paymentWalletAddress) public  onlyOwnerAndAdmin{
        paymentWallet = _paymentWalletAddress ;
    }
    
    function getNftIdsByWallet(address _walletAddress) public view returns(uint[] memory _nftIds){
       return userNftIds[_walletAddress];

    }

    function getCountryIdsByNftId(uint _nftId) public view returns(uint _countryId){
        return countryId[_nftId];
    }

    function setWalletLimitAndMaxLimitPerMint(uint256 _walletLimit,uint256 _maxLimitPerMint) public onlyOwnerAndAdmin{
        walletLimit = _walletLimit;
        maxLimitPerMint = _maxLimitPerMint;
    }

    function setNftPriceInUsd(uint256 _usdPrice) public onlyOwnerAndAdmin{
        nftPriceInUsd = _usdPrice;
    }

    function buyNFT(uint256 _quantity)public payable whenNotPaused{

        require( _quantity>0 && _quantity<= maxLimitPerMint, "Invalid quantity");

        totalMinted+= _quantity;

        require(totalMinted <= collectionSize, "reached max supply");
        require(msg.value >= _quantity*getNftPriceInEth(), "Insufficient funds");
        require(userNftIds[_msgSender()].length+_quantity <= walletLimit,"Exceeded the max mint limit");

        uint256[] memory _countryIds = new uint[](_quantity);
        uint256[] memory _nftIds = new uint[](_quantity);
        uint tokenId;

        for (uint256 i = 0; i < _quantity; i++) {
            countryCount++;
            countryCount = countryCount>32?1:countryCount;
            countryTokenIndex[countryCount] = countryTokenIndex[countryCount]+1;
            tokenId = countryTokenIndex[countryCount];
            
            userNftIds[_msgSender()].push(tokenId);
            countryId[tokenId] = countryCount;
            _countryIds[i] = countryCount;
            _nftIds[i] = tokenId;
            _safeMint( _msgSender(),tokenId);

        }

        payable(paymentWallet).transfer(msg.value);
         emit NftSale(_countryIds,_nftIds,_msgSender(),_quantity,_quantity*getNftPriceInEth(),_quantity*nftPriceInUsd);
    }

    function withdrawFunds() public onlyOwnerAndAdmin{
      payable(msg.sender).transfer(address(this).balance);
    }

}