// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract StartMining721 is Ownable, ReentrancyGuard, ERC721Pausable {

    using Strings for uint256;
    using SafeERC20 for IERC20Metadata;

    // Stable coin contract address (can be another stable coin)
    IERC20Metadata private stableCoin;

    // Chainlink ETH/USD
    AggregatorV3Interface internal priceFeed;

    // Recipient address used to receive ETH and ERC20
    address private recipient;

    // Default Crossmint Address
    address private crossMintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

    struct Referrer {
        uint256 referredCount;
        uint256 alreadyClaimed;
    }

    // Pause minting, default true.
    bool public salePaused = true;
    
    // Pause referral, default false.
    bool public referralPaused = false;

    // Pause cross minting, default false.
    bool public crossMintPaused = false;
    
    // Pause stable coin minting, default false.
    bool public stableCoinMintPaused = false; 

     // Pause classic minting, default false.
    bool public etherMintPaused = false;

    // Price in $USD
    uint16 public salePrice = 1000; 

    uint256 public limitNFT = 500;
    uint256 public currentNFT;

    string public baseURI;

    mapping(address => Referrer) public referrerByAddress;

    /* ********************************** */
    /*             Events                 */
    /* ********************************** */

    // Chainlink's aggregator address updated
    event ChainlinkUpdated(address addressPriceFeed); 
    
    // Pause updated
    event PauseUpdated(bool paused); 

    // Sale price updated
    event PriceUpdated(uint16 salePrice); 

    // New mint season initialized
    event InitializedMint(uint256 tokenId, uint256 limit, uint16 salePrice); 


    /* ********************************** */
    /*           Constructor              */
    /* ********************************** */


    /*
    * @notice Constructor of the contract ERC721.
    * @param string memory _baseURI : Metadatas URI for the ERC721.
    * @param IERC20Metadata _stableCoin : stableCoin contract address (can be another stable coin)
    * @param address _recipient : Recipient address
    * @param AggregatorV3Interface _priceFeed : Chainlink Goerli ETH/USD
    */
    constructor(string memory _baseURI, IERC20Metadata _stableCoin, address _recipient, AggregatorV3Interface _priceFeed) ERC721("START", "START") {
        baseURI = _baseURI;
        stableCoin = _stableCoin;
        recipient = _recipient;
        priceFeed = _priceFeed;
    }

    /* ********************************** */
    /*             Modifier               */
    /* ********************************** */

    /*
    * @notice Safety checks common to each mint function.
    * @param uint16 _amount : Amount of tokens to mint.
    * @param address _referral : Address of the referral.
    */
    modifier mintModifier(uint16 _amount, address _referral) {
        require(!salePaused, "Sale not opened");
        require(_amount > 0, "Amount must be greater than 0");
        if (!referralPaused) {
            require(_referral != msg.sender, "Not allowed to self-referral");
        }
        _;
    }

    /* ********************************** */
    /*               Mint                 */
    /* ********************************** */

    /*
    * @notice Initialize a new mint season of NFT ready to be minted.
    * @param uint256 _limit : Maximum amount of units.
    * @param uint16 _salePrice : Price value of 1 NFT.
    */
    function initMint(uint256 _limit, uint16 _salePrice) external onlyOwner {
        require(_limit > currentNFT, "Limit must be higher than the currentNFT");
        require(_salePrice > 0, "Price can't be zero");
        limitNFT = _limit;
        salePrice = _salePrice;

        emit InitializedMint(currentNFT, _limit, _salePrice);
    }

    /*
    * @notice Private function to mint during the sale. This function is called by all the public mint functions.
    * @param address _to : Address that will receive the NFT.
    * @param address _referral : Address of the referral.
    */
    function _mintSale(address _to, address _referral) private {
        require(currentNFT < limitNFT, "Sold out");
        if (_referral != address(0) && !referralPaused) {
            referrerByAddress[_referral].referredCount++;
        }
        currentNFT++;
        _mint(_to, currentNFT);
    }

    /*
    * @notice Mint in ETH during the sale.
    * @param uint16 _amount : Amount of tokens to mint.
    * @param address _referral : Address of the referral.
    */
    function mintSale(uint16 _amount, address _referral) external payable nonReentrant mintModifier(_amount, _referral) {

        require(
            !etherMintPaused,
            "Mint in ETH not allowed now."
        );

        require(
            msg.value >= getSalePrice() * uint256(_amount),
            "Not enough funds"
        );

        payable(recipient).transfer(address(this).balance);
        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(msg.sender, _referral);
        }
    }

    /*
    * @notice Mint in stableCoin during the sale.
    * @param uint16 _amount : Amount of tokens to mint.
    * @param address _referral : Address of the referral.
    */
    function mintSaleStableCoin(uint16 _amount, address _referral) external nonReentrant mintModifier(_amount, _referral) {

        require(
            !stableCoinMintPaused,
            "Mint in stableCoin not allowed now."
        );

        stableCoin.safeTransferFrom(msg.sender, recipient, uint256(_amount) * salePrice * 10 ** stableCoin.decimals());
        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(msg.sender, _referral);
        }
    }

    /*
    * @notice Crossmint allows payment by credit card.
    * @param address _to : Address that will receive the NFT.
    * @param uint16 _amount : Amount of tokens to mint.
    * @param address _referral : Adress of the referral.
    */
    function crossMintSale(address _to, uint16 _amount, address _referral) external payable mintModifier(_amount, _referral) {

        require(
            !crossMintPaused,
            "Crossmint not allowed now."
        );

        require(
            msg.sender == crossMintAddress,
            "This function is for Crossmint only."
        );

        require(
            msg.value >= (uint256(_amount) * salePrice * 10**26) / uint256(getLatestPrice()),
            "Not enough funds"
        );

        payable(recipient).transfer(address(this).balance);
        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(_to, _referral);
        }
    }

    /*
    * @notice Allows the owner to offer NFTs.
    * @param address _to : Receiving address.
    * @param uint16 _amount : Amount of tokens to mint.
    */
    function gift(address _to, uint16 _amount) external onlyOwner {

        require(
            _amount > 0,
            "You have to gift at least one NFT"
        );

        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(_to, address(0));
        }
    }

    /* ********************************** */
    /*               Rewards              */
    /* ********************************** */

    /*
    * @notice Allows user to claim rewards.
    */
    function claimReward() external nonReentrant {

        require(
            !referralPaused,
            "Referral paused"
        );

        require(
            !salePaused,
            "Sale not opened"
        );

        uint256 countReferral = referrerByAddress[msg.sender].referredCount;
        require(
            countReferral >= 100,
            "Not enough referral yet"
        );

        uint256 amountNFTClaimable;

        if (countReferral < 1000)
            amountNFTClaimable = (1 + (countReferral - 100) / 34) - referrerByAddress[msg.sender].alreadyClaimed;
        else {
            amountNFTClaimable = (28 + (countReferral - 1000) / 20) - referrerByAddress[msg.sender].alreadyClaimed;
        }

        require(
            amountNFTClaimable > 0,
            "No rewards available"
        );

        referrerByAddress[msg.sender].alreadyClaimed += amountNFTClaimable;

        for (uint16 i = 0; i < amountNFTClaimable; i++) {
            _mintSale(msg.sender, address(0));
        }
    }

    /* ********************************** */
    /*              Getters               */
    /* ********************************** */

    /*
    * @notice Get the current ETH/USD price.
    * @dev The function uses the chainlink aggregator.
    * @return int Price value.
    */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /*
    * @notice Get the current of one NFT in ETH.
    */
    function getSalePrice() public view returns (uint256) {
        return (uint256(salePrice) * 10**26) / uint256(getLatestPrice());
    }

    /*
    * @notice Get total supply
    */
    function totalSupply() public view returns (uint256) {
        return currentNFT;
    }

    /*
    * @notice Returns the list of NFT by a user.
    * @param address _user : Address of the user.
    * @return uint256[] : List of tokenIds.
    */
    function getNFTsByUserAddress(address _user) external view returns (uint256[] memory) {
        uint256[] memory tmpList = new uint256[](currentNFT);
        uint256 counter = 0;

        for (uint256 i = 1; i <= currentNFT; i++) {
            if (ownerOf(i) == _user) {
                tmpList[counter] = i;
                counter++;
            }
        }

        uint256[] memory nftList = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            nftList[i] = tmpList[i];
        }

        return nftList;
    }

    /* ********************************** */
    /*              Setters               */
    /* ********************************** */

    /*
    * @notice Update "stableCoin" variable.
    * @param address _newstableCoin : Address of the new stableCoin contract.
    */
    function setStableCoin(address _newStableCoin) external onlyOwner {
        stableCoin = IERC20Metadata(_newStableCoin);
    }

    /*
    * @notice Update "recipient" variable.
    * @param address _newRecipient : Address of the new recipient.
    */
    function setRecipient(address _newRecipient) external onlyOwner {
        recipient = _newRecipient;
    }

    /*
    * @notice Update "priceFeed" variable.
    * @param address _newPriceFeed : Address of the new priceFeed.
    */
    function setPriceFeed(address _newPriceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_newPriceFeed);
        emit ChainlinkUpdated(_newPriceFeed);
    }

    /*
    * @notice Update "salePrice" variable.
    * @param uint16 _newPrice : New sale price in stableCoin.
    */
    function setSalePrice(uint16 _newPrice) external onlyOwner {
        salePrice = _newPrice;
        emit PriceUpdated(salePrice);
    }

    /*
    * @notice Update "baseURI" variable.
    * @param string calldata _newBaseURI : New base URI.
    */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /*
    * @notice Update "crossMintAddress" variable.
    * @param address _newCrossMintAddress : New crossMintAddress.
    */
    function setCrossMintAddress(address _newCrossMintAddress) external onlyOwner {
        crossMintAddress = _newCrossMintAddress;
    }

    /* ********************************** */
    /*               Pauser               */
    /* ********************************** */

    /*
    * @notice Toggle state of "salePaused" variable. If true, minting is disabled.
    */
    function toggleSalePaused() external onlyOwner {
        salePaused = !salePaused;
        emit PauseUpdated(salePaused);
    }

    /*
    * @notice Toggle state of "referralPaused" variable. If true, referral is disabled.
    */
    function toggleReferralPaused() external onlyOwner {
        referralPaused = !referralPaused;
    }

    /*
    * @notice Toggle state of "crossMintPaused" variable. If true, crossMint is disabled.
    */
    function toggleCrossMintPaused() external onlyOwner {
        crossMintPaused = !crossMintPaused;
    }

    /*
    * @notice Toggle state of "stableCoinMintPaused" variable. If true, stableCoinMint is disabled.
    */
    function toggleStableCoinMintPaused() external onlyOwner {
        stableCoinMintPaused = !stableCoinMintPaused;
    }

    /*
    * @notice Toggle state of "etherMintPaused" variable. If true, classicMint is disabled.
    */
    function toggleEtherMintPaused() external onlyOwner {
        etherMintPaused = !etherMintPaused;
    }

    /*
    * @notice pause the contract. (emergency)
    */
    function pause() public onlyOwner {
        _pause();
    }

    /*
    * @notice unpause the contract.
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /*
    * @notice Allows access to off-chain metadatas.
    * @param _tokenId Id of the token.
    * @return string Token's metadatas URI.
    */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        
        require(
            _tokenId > 0 && _tokenId <= limitNFT,
            "NFT doesn't exist"
        );

        return
        bytes(baseURI).length > 0
        ? string(
            abi.encodePacked(baseURI, _tokenId.toString(), ".json")
        )
        : "";
    }

}