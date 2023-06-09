// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import this file to use console.log
// import "hardhat/console.sol";
import './interfaces/ISignerVerification.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./libs/SignerVerification.sol";
import "./interfaces/IERC20.sol";

/**
 * @notice Errors list
 */
error Incorrect_Signature(); 
error Signature_Expired();
error Not_Enough_Allowance();
error Auction_Completed();
error Not_Existent_Token();
error IncorrectCaller();
error Sold_Out();


/**
 * @title FSN Marketplace contract 
 */
contract FSNMarketplace is Initializable, ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable{
   
    /**
     * @notice Address of signer for sig verification
     */
    address private s_signer;

    /**
     * @notice Address of ERC20 token for payment
     */
    address private s_payment_token_address;

     /**
     * @notice Percentage amount for marketplace
     * @dev You need to mul the value by 10, in terms of solidity doesn's support floats
     * @dev Example: if you want to set 5% as fee precent you need to pass 50(5*10);
     */
    uint256 private s_marketplace_percentage; // 2.5%

     /**
     * @notice Fee denominator
     */
    uint256 constant private FEE_DENOMINATOR = 1000;

      /**
     * @notice Fee which marketplace earned
     */
    uint256 private s_marketplace_funds;

    /**
     * @notice SignerVerification
     */
    ISignerVerification public signer_verification;

    /**
     * @notice Info about auctions's statuses
     */
    mapping(uint256 => bool) private s_auctionToStatus;

     /**
     * @notice Info about royalties statuses
     */
    mapping(string => bool) private s_royaltyToStatus;

     /**
      * @notice mapping 
     */
    mapping (uint256 => string) private s_tokenURIs;

    /**
      * @notice mapping for MultipleArt NFTs
     */
    mapping (uint256 => MupltipleArtStats) public s_idToMultipleArt;


    /**
     * @title Initial Details about a Collection
     * @property auctionID - Id of an auction
     * @property price Price of the NFT
     * @property buyer address of person why buys
     * @property artist address of an artist
     * @property tokenURI 
     * @property signatureTimestampExpiration
     */
    struct AuctionDetails {
        uint256 auctionID;
        uint256 price;
        address buyer;
        address artist;
        string tokenURI;
        uint256 signatureTimestampExpiration;
    }

    /**
     * @title Initial Details about a Multiple NFTs
     * @property id - Id of art
     * @property price Price of the NFT
     * @property amount amount of NFTs
     * @property buyer address of person why buys
     * @property artist address of an artist
     * @property tokenURI 
     * @property signatureTimestampExpiration 
     * @property totalSupply 
     */
    struct MultipleArtParams {
        uint256 id;
        uint256 price;
        uint256 amount;
        address buyer;
        address artist;
        string tokenURI;
        uint256 signatureTimestampExpiration;
        uint256 totalSupply;
    }
    
    /**
     * @title Stats about multiple art
     * @property id - Id of art
     * @property totalSupply - total amount of NFTs
     * @property currentSupply - current amount of sold NFTs
     */
    struct MupltipleArtStats {
        uint256 id;
        uint256 totalSupply;
        uint256 currentSupply;
    }

    /**
     * @title Info about royalty
     * @property id - Id of royalty
     * @property amount - amount of roalty
     * @property signatureExpirationTimestamp - expiration timestamp of signature
     */
    struct RoyaltyParams {
        string id;
        uint256 amount;
        uint256 signatureExpirationTimestamp;
    }

    
     /**
     * @notice Allows to call method only when sig is valid - when it is not expired
     */
    modifier beforeSigExpiration(uint256 _expirationTimestamp){
      if(block.timestamp > _expirationTimestamp){
         revert Signature_Expired();
      }
      _;
    }
    
   function initialize(address _s_payment_token_address, address _signer_verification) initializerERC721A initializer public {
        __ERC721A_init("FSN Marketplace", "FSN");
         __Ownable_init();
        __UUPSUpgradeable_init();
       s_signer = msg.sender;
       s_payment_token_address = _s_payment_token_address;
       signer_verification = ISignerVerification(_signer_verification);
       s_marketplace_percentage = 25;
    }

    /**
     * @notice Function to get ETH outside(royalties from Open Sea)
    */
    receive() external payable {}

    /**
     * @notice Creates collection, accepts bid and mint NFT for buyer
     * @param _auctionDetails Auction information
     * @param _signature Signature
    */
    function acceptBid(
      AuctionDetails memory _auctionDetails,
      bytes calldata _signature
      ) external beforeSigExpiration(_auctionDetails.signatureTimestampExpiration){

      if(msg.sender == _auctionDetails.artist || msg.sender == _auctionDetails.buyer){
           
         onlyWithAllowance(_auctionDetails.buyer, _auctionDetails.price);

         bool isVerified = verifyParamsForAuction(_auctionDetails, _signature);

         if(!isVerified){
            revert Incorrect_Signature();
         }

         if(s_auctionToStatus[_auctionDetails.auctionID]){
             revert Auction_Completed();
          }
          
        uint256 mintedTokenId = totalSupply();

         
         mint(_auctionDetails.tokenURI, _auctionDetails.buyer, mintedTokenId);

        s_auctionToStatus[_auctionDetails.auctionID] = true;

         transferTokensWithFee(_auctionDetails.buyer, _auctionDetails.artist, _auctionDetails.price);

         emit Minted(
              _auctionDetails.auctionID, 
              _auctionDetails.price, 
              _auctionDetails.buyer, 
              _auctionDetails.artist, 
              block.timestamp,
              mintedTokenId
        );
        }else{
            revert IncorrectCaller();
        }
    }

    /**
     * @notice Mints multiple art NFT
     * @param _artDetails Art information
     * @param _signature Signature
    */
    function buyMultipleArt(
      MultipleArtParams memory _artDetails,
      bytes calldata _signature
      ) external beforeSigExpiration(_artDetails.signatureTimestampExpiration){

      if(msg.sender == _artDetails.buyer){
           
         onlyWithAllowance(_artDetails.buyer, _artDetails.price);

         bool isVerified = verifyParamsForMultipleArt(_artDetails, _signature);

         if(!isVerified){
            revert Incorrect_Signature();
         }

         transferTokensWithFee(_artDetails.buyer, _artDetails.artist, _artDetails.price * _artDetails.amount);

         MupltipleArtStats memory m_multipleArt = s_idToMultipleArt[_artDetails.id];

         if(m_multipleArt.currentSupply + _artDetails.amount > _artDetails.totalSupply){
            revert Sold_Out();
         }

         m_multipleArt.currentSupply+=_artDetails.amount;

         s_idToMultipleArt[_artDetails.id] = m_multipleArt;

        uint256 currentTokenSupply = totalSupply();

        uint256[] memory tokenIds = mintMultiple(_artDetails.tokenURI, _artDetails.buyer, currentTokenSupply, _artDetails.amount);
         
        emit MultipleArtMint(
              _artDetails.id, 
              _artDetails.price, 
              _artDetails.buyer, 
              _artDetails.artist, 
              block.timestamp,
              _artDetails.amount,
              m_multipleArt.currentSupply,
              tokenIds
        );
        }else{
            revert IncorrectCaller();
        }
    }

        /**
     * @notice Withdraws royalty for an artist
     * @param _roayltyParams Royalty information
     * @param _signature Signature
    */
    function claimRoyalty(
      RoyaltyParams memory _roayltyParams,
      bytes calldata _signature
      ) external beforeSigExpiration(_roayltyParams.signatureExpirationTimestamp) nonReentrant {
         require(!s_royaltyToStatus[_roayltyParams.id], "This id was already used");
         string memory concatenatedParams = signer_verification.concatParamsForRoyalty(_roayltyParams.id, _roayltyParams.amount, msg.sender, _roayltyParams.signatureExpirationTimestamp);
         bool isVerified = signer_verification.isMessageVerified(s_signer, _signature, concatenatedParams);
         if(!isVerified){
            revert Incorrect_Signature();
         }
         uint256 wethBalance = IERC20(s_payment_token_address).balanceOf(address(this));

         uint256 ethBalance = address(this).balance;

         require(wethBalance + ethBalance >= _roayltyParams.amount, "Insufficient funds");
         
         if(wethBalance >= _roayltyParams.amount){
            IERC20(s_payment_token_address).transfer(msg.sender, _roayltyParams.amount);
         }else if(ethBalance >= _roayltyParams.amount){
            (bool success, ) = msg.sender.call{value:_roayltyParams.amount}("");
         }else{
            IERC20(s_payment_token_address).transfer(msg.sender, wethBalance);
            (bool success, ) = msg.sender.call{value:_roayltyParams.amount - wethBalance}("");
            require(success, "Marketplace:Failed transfer");
         }

         emit RoyaltyClaimed(_roayltyParams.id, _roayltyParams.amount, msg.sender, block.timestamp);
      }

     /**
     * @notice Mints NFT for specific auction
     * @param _tokenURI URI for token metadata
     * @param _buyer Buyer of NFT
     * @param _tokenId id of token for mint
    */
    function mint(string memory _tokenURI, address _buyer, uint256 _tokenId) internal {

          _mint(_buyer, 1);

          _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @notice Mints several NFTs
     * @param _tokenURI URI for token metadata
     * @param _buyer Buyer of NFT
     * @param _currentTokenSupply id of token for mint
     * @param _amount amount of NFTs
    
    */
    function mintMultiple(string memory _tokenURI, address _buyer, uint256 _currentTokenSupply, uint256 _amount) internal returns(uint256[] memory) {

        _mint(_buyer, _amount);

        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint256 i = 0; i < _amount;) {

            tokenIds[i] = _currentTokenSupply + i;

             _setTokenURI(_currentTokenSupply + i, _tokenURI);

             unchecked {
                ++i;
            }
        }

        return tokenIds;
    }

    /**
     * @notice Transfers fee to the marketplace and an artist
     * @param _buyer address of auction buyer
     * @param _artist address of artist
     * @param _price amount of token
    */
    function transferTokensWithFee(address _buyer, address _artist, uint256 _price) internal {
        uint256 marketplaceShare = _price * s_marketplace_percentage / FEE_DENOMINATOR;

        uint256 artistShare = _price - marketplaceShare;

        s_marketplace_funds += marketplaceShare;
        // Transfering fee to marketplace
        IERC20(s_payment_token_address).transferFrom(_buyer, address(this), marketplaceShare);
        // Transfering  artist share
        IERC20(s_payment_token_address).transferFrom(_buyer, _artist, artistShare);
    }

       /**
	 * Withdraw ERC20 from contract to owner address
	 * @notice only owner can withdraw
	 */
    function withdrawMarketplaceIncome() external onlyOwner {
        uint256 marketplaceWETHBalance = IERC20(s_payment_token_address).balanceOf(address(this));
        uint256 marketplaceETHBalance = address(this).balance;
        uint256 marketplaceFunds = s_marketplace_funds;
        if(marketplaceWETHBalance >= marketplaceFunds){
            bool succeed = IERC20(s_payment_token_address).transfer(msg.sender, marketplaceFunds);
            require(succeed, "WETH withdraw failed");
        }else{
            uint256 reminder = marketplaceFunds - marketplaceWETHBalance;
            bool succeed = IERC20(s_payment_token_address).transfer(msg.sender, marketplaceWETHBalance);
            require(succeed, "WETH withdraw failed");
            (bool sent, ) = msg.sender.call{value: reminder}('');
            require(sent, 'ETH withdraw failed');
        }
        s_marketplace_funds = 0;
         emit Withdrawed(marketplaceFunds, block.timestamp);
	}
    

    /**
	 * Withdraw ERC20 from contract to owner address
	 * @notice only owner can withdraw
	 */
    function withdrawERC20(address contractAddress, uint256 _amount) external onlyOwner {
		bool succeded = IERC20(contractAddress).transfer(msg.sender, _amount);
		require(succeded, 'Withdrawable: Transfer did not happen');
        emit Withdrawed(_amount, block.timestamp);
	}

	/**
	 * Withdraw ETH from contract to owner address
	 * @notice only owner can withdraw
	 */
	function withdrawETH(uint256 _amount) external onlyOwner {
		(bool sent, ) = msg.sender.call{value: _amount}('');
		require(sent, 'Failed to withdraw ETH');
         emit Withdrawed(_amount, block.timestamp);
	}
    
    /**
     * @notice Sets new payment ERC20 token address
     * @param _newPaymentToken auction Details
     * @dev You need to mul the value by 10, in terms of solidity doesn's support floats
     * @dev Example: if you want to set 5% as fee precent you need to pass 50(5*10);
    */
    function setPaymentTokenAddress(address _newPaymentToken) external onlyOwner{
          s_payment_token_address = _newPaymentToken;
    }

    /**
     * @notice Sets new marketplace percentage
     * @param _newMarketplacePercentage percentage amount
    */
    function setMarketplacePercentage(uint256 _newMarketplacePercentage) external onlyOwner{
        s_marketplace_percentage = _newMarketplacePercentage;
    }

    /**
     * @notice Sets token URI for specifc one
     * @param tokenId token ID :)
     * @param _tokenURI URI for token metadata
    */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        if(!_exists(tokenId)){
          revert Not_Existent_Token();
        }
        s_tokenURIs[tokenId] = _tokenURI;
    }

    function setSignerVerification(address _signerVerificationAddress) external onlyOwner {
         signer_verification = ISignerVerification(_signerVerificationAddress);
    }

    function setSigner(address _signer) external onlyOwner {
         s_signer = _signer;
    }

     function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /* --------------------------------------------------------- VIEWS () ---------------------------------------------------------- */
    
      /**
     * @notice Returns token URI for specifc one
     * @param tokenId token ID :)
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            if(!_exists(tokenId)){
              revert Not_Existent_Token();
            }
            string memory _tokenURI = s_tokenURIs[tokenId];
            
            return _tokenURI;
    }

    /**
     * @notice Returns payment token address
    */
    function getPaymentToken() external view returns(address) {
        return s_payment_token_address;
    }

   /**
     * @notice Returns signer address
    */
    function getSignerAddress() external view returns(address) {
        return s_signer;
    }

     /**
     * @notice Returns marketplace percentage
    */
    function getMarketplacePercentage() external view returns(uint256) {
        return s_marketplace_percentage;
    }
    

    // @-test
    /**
     * @notice Returns marketplace funds
    */
    function getMarketplaceFunds() external view returns(uint256) {
        return s_marketplace_funds;
    }

    /**
      * @notice Returns auction completed status for a specific auction id
      * @param auctionId id of an auction
    */
    function isAuctionCompleted(uint256 auctionId) external view returns(bool) {
        return s_auctionToStatus[auctionId];
    }


    
    /* --------------------------------------------------------- UTILS () ---------------------------------------------------------- */

     /**
     * @param _buyer Address of buyer
     * @param _price Price of NFT
     */
    function onlyWithAllowance(address _buyer, uint256 _price) internal view{
          uint256 buyerAllowance = IERC20(s_payment_token_address).allowance(_buyer, address(this));

         if(buyerAllowance < _price){
            revert Not_Enough_Allowance();
         }
    }

      /**
     * @notice Verifies signature
     * @param _auctionDetails auction Details
     * @param _signature sig
    */
    function verifyParamsForAuction(AuctionDetails memory _auctionDetails, bytes calldata _signature) internal view returns(bool) {
       
       string memory concatenatedParams = signer_verification.concatParams(
            _auctionDetails.auctionID,
            _auctionDetails.price,
            _auctionDetails.buyer,
             _auctionDetails.artist,
            _auctionDetails.tokenURI,
            _auctionDetails.signatureTimestampExpiration
        );
        return verifyMessage(concatenatedParams, _signature);     
    }

    /**
     * @notice Verifies signature
     * @param _multipleArtParams auction Details
     * @param _signature sig
    */
    function verifyParamsForMultipleArt(MultipleArtParams memory _multipleArtParams, bytes calldata _signature) internal view returns(bool) {
       
       string memory concatenatedParams = signer_verification.concatParamsForMultipleArt(
            _multipleArtParams.id,
            _multipleArtParams.price,
            _multipleArtParams.amount,
            _multipleArtParams.buyer,
             _multipleArtParams.artist,
            _multipleArtParams.tokenURI,
            _multipleArtParams.signatureTimestampExpiration,
            _multipleArtParams.totalSupply
        );
         return verifyMessage(concatenatedParams, _signature);    
    }


    function verifyMessage(string memory _concatenatedParams, bytes calldata _signature) internal view returns(bool){
         return signer_verification.isMessageVerified(s_signer, _signature, _concatenatedParams);
    }

    /* -------------------------------------------------------------- EVENTS ------------------------------------------------------------ */

      /**
        *@notice Emmits when after withdraw
   
      */
    event Withdrawed(
        uint256 indexed amount,
        uint256 timestamp
    );

        /**
        *@notice Emmits when after mint
        *@param auctionId Id of auction
        *@param price Price of the bid
        *@param buyer address of buyer
        *@param artist address of artist
        *@param timestamp mint timestamp
        *@param nftId id of minted NFT
      */
    event Minted(
        uint256 indexed auctionId,
        uint256 indexed price,
        address buyer,
        address indexed artist,
        uint256 timestamp,
        uint256 nftId
    );

    /**
        *@notice Emmits after multipleArt Mint
        *@param id Id of multiple art
        *@param price Price of the nft
        *@param buyer address of buyer
        *@param artist address of artist
        *@param timestamp mint timestamp
        *@param amount amount of minted multiple arts
        *@param currentSupply currentSupply
        *@param tokenIds array of minted ids 
    */
    event MultipleArtMint(
        uint256 indexed id,
        uint256 indexed price,
        address buyer,
        address indexed artist,
        uint256 timestamp,
        uint256 amount,
        uint256 currentSupply,
        uint256[] tokenIds
    );

     /**
        *@notice Emmits after Roaylty claim
        *@param id Id of multiple art
        *@param amount Price of the nft
        *@param artist address of artist
        *@param timestamp address of buyer
    */
    event RoyaltyClaimed(
        string id,
        uint256 indexed amount,
        address indexed artist,
        uint256 indexed timestamp
    );
}