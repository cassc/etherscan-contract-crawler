// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoolTypes.sol";
import "../interfaces/IMetaAlgorithm.sol";
import "../interfaces/IMetaFactory.sol";
import "../interfaces/IMSPool.sol";

/// @title MSPoolBasic a basic pool template implementations
/// @author JorgeLpzGnz & CarlosMario714
/// @notice Basic implementation based on IEP-1167
abstract contract MSPoolBasic is IMSPool, ReentrancyGuard, Ownable {

    /// @notice Used to calculate the swap price
    uint128 public multiplier;

    /// @notice Used to calculate the swap price
    /// @notice Start Price is just a name, depending of the algorithm it will take it at different ways
    uint128 public startPrice;

    /// @notice Fee charged per swap ( only available in trade pools )
    uint128 public tradeFee;

    /// @notice Fee charged per swap ( only available in trade pools )
    uint128 public constant MAX_TRADE_FEE = 0.9e18;

    /// @notice The address that will receive the tokens depending of the pool type
    address public recipient;

    /// @notice The collection that the pool trades
    address public NFT;

    /// @notice The address of the factory that creates this pool
    IMetaFactory public factory;

    /// @notice The type of the pool ( Sell, Buy, Trade )
    /// @dev See [ PoolTypes.sol ] for more info
    PoolTypes.PoolType public currentPoolType;

    /// @notice The algorithm that calculates the price
    /// @dev See [ IMetaAlgorithm.sol ] for more info
    IMetaAlgorithm public Algorithm;

    /*************************************************************************/
    /******************************* EVENTS **********************************/

    /// @param user User who sold nfts
    /// @param inputNFTs Amount of NFTs entered into the pool
    /// @param amountOut Amount of tokens sent to user
    event SellLog( address indexed user, uint inputNFTs, uint amountOut );

    /// @param user User who bought nfts
    /// @param amountIn Amount of tokens that entered the pool
    /// @param outputNFTs Amount of NFTs sent to user
    event BuyLog( address indexed user, uint amountIn, uint outputNFTs );

    /// @param newStartPrice The new start price
    event NewStartPrice( uint128 newStartPrice );

    /// @param newMultiplier The new multiplier
    event NewMultiplier( uint128 newMultiplier );

    /// @param newRecipient The new recipient
    event NewAssetsRecipient( address newRecipient );

    /// @param newFee The new trade fee
    event NewTradeFee( uint newFee );

    /// @param owner Pool owner
    /// @param withdrawAmount amount of tokens withdrawn
    event TokenWithdrawal( address indexed owner, uint withdrawAmount );

    /// @param owner Pool owner
    /// @param AmountOfNFTs amount of NFTs withdrawn
    event NFTWithdrawal( address indexed owner, uint AmountOfNFTs );

    /// @param amount Amount of token deposited
    event TokenDeposit( uint amount );

    /// @param nft Address of the NFT Collection
    /// @param tokenID NFT deposited
    event NFTDeposit( address nft, uint tokenID );

    /*************************************************************************/
    /*************************** PRIVATE FUNCTIONS ***************************/

    /// @notice Returns the address of the user that is interacting with the pool
    /// @param _user The address passed as param in the Trade functions
    /// @return caller Address to interact with the pool
    function _getUser( address _user ) private view returns ( address caller ) {

        if( factory.isRouterAllowed( msg.sender ) ) caller = _user;

        else caller = msg.sender;

    }

    /// @notice Returns the info to sell NFTs and updates the params
    /// @param _numNFTs Number of NFTs to sell at pool
    /// @param _minExpectedOut The minimum number of tokens expected to be returned to the user
    /// @return outputValue Amount of Tokens to send to the user
    /// @return protocolFee Fee charged in a trade
    /// @return newStartPrice New pool startPrice
    /// @return newMultiplier New pool multiplier
    function _getSellNFTInfo( uint _numNFTs, uint _minExpectedOut ) private view returns ( 
            uint256 outputValue, 
            uint256 protocolFee,
            uint128 newStartPrice,
            uint128 newMultiplier
        ) 
    {

        bool isValid;

        newStartPrice;

        newMultiplier;

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            outputValue, 
            protocolFee 
        ) = Algorithm.getSellInfo( 
            multiplier, 
            startPrice, 
            _numNFTs,
            factory.PROTOCOL_FEE(),
            tradeFee
            );

        require( isValid, "Swap cannot be traded" );

        require( outputValue >= _minExpectedOut, "Output amount is less than minimum expected" );

    }

    /// @notice Returns the info to buy NFTs and updates the params
    /// @param _numNFTs NFT number to buy at pool
    /// @param _maxExpectedIn The maximum expected cost to buy the NFTs
    /// @return inputValue Amount of tokens to pay the NFTs
    /// @return protocolFee Fee charged in a trade
    /// @return newStartPrice New pool startPrice
    /// @return newMultiplier New pool multiplier
    function _getBuyNFTInfo( uint _numNFTs, uint _maxExpectedIn ) private view returns ( 
            uint256 inputValue, 
            uint256 protocolFee,
            uint128 newStartPrice,
            uint128 newMultiplier
        ) 
    {

        bool isValid;

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            inputValue, 
            protocolFee 
        ) = Algorithm.getBuyInfo( 
            multiplier, 
            startPrice, 
            _numNFTs, 
            factory.PROTOCOL_FEE(),
            tradeFee
            );

        require( isValid, "Swap cannot be traded" );

        require( inputValue <= _maxExpectedIn, "Input amount is greater than max expected" );

    }

    /// @notice Sets a New Start price o Multiplier
    /// @dev Start Price its just a name  see each algorithm to know how it will be take it
    /// @param _newStartPrice New Start Price 
    /// @param _newMultiplier New multiplier
    function _updatePoolPriceParams( uint128 _newStartPrice, uint128 _newMultiplier ) private {

        if( startPrice != _newStartPrice ) {
            
            startPrice = _newStartPrice;

            emit NewStartPrice( _newStartPrice );
            
        }

        if( multiplier != _newMultiplier ) { 
            
            multiplier = _newMultiplier;

            emit NewMultiplier( _newMultiplier );
            
        }

    }

    /*************************************************************************/
    /************************** TRANSFER FUNCTIONS ***************************/

    /// @notice Pay the protocol fee charged per trade
    /// @param _protocolFee Amount of tokens to Send to protocol recipient
    function _payProtocolFee( uint _protocolFee ) private {

        if( _protocolFee > 0 ) {
                
            address feeRecipient = factory.PROTOCOL_FEE_RECIPIENT();

            if( _protocolFee > address( this ).balance ) {
                    
                _protocolFee = address( this ).balance;

            }

            if( _protocolFee > 0 ) {

                ( bool isSended, ) = payable( feeRecipient ).call{ value: _protocolFee }("");
                
                require( isSended, "Tx error" );

            }

        }
        
    }

    /// @notice Return Remaining value to user
    /// @param _inputAmount Amount of tokens that input to the pool
    function _returnRemainingValue( uint _inputAmount ) private {
        
        // If the user sent more tokens than necessary, they are returned

        if ( msg.value > _inputAmount ) {

            ( bool isSended, ) = payable( msg.sender ).call{ value: msg.value - _inputAmount }("");
            
            require( isSended, "Tx error" );
            
        }

    }

    
    /// @notice Receive NFTs from user
    /// @param _from NFTs owner address
    /// @param _tokenIDs NFTs to send
    function _receiveNFTs( address _from, uint[] memory _tokenIDs ) private {

        IERC721 _NFT = IERC721( NFT );

        address _recipient = getAssetsRecipient();

        uint balanceBefore = _NFT.balanceOf( _recipient );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {

            _NFT.safeTransferFrom(_from, _recipient, _tokenIDs[i]);

        }

        uint balanceAfter = _NFT.balanceOf( _recipient );

        require( 
            balanceBefore + _tokenIDs.length == balanceAfter,
            "No NFTs received"
        );

    }

    /// @notice Send tokens to user and pay protocol fee
    /// @param _protocolFee The trade cost
    /// @param _outputAmount Amount of tokens to send
    /// @param _to The address to send the tokens
    function _sendTokensAndPayFee( uint _protocolFee, uint _outputAmount, address _to ) private {

        uint balanceBefore = _to.balance;

        ( bool isSended, ) = payable( _to ).call{ value: _outputAmount }( "" );

        require( isSended, "Tx error" );

        _payProtocolFee( _protocolFee );

        uint balanceAfter = _to.balance;

        require( 
            balanceAfter >= balanceBefore + _outputAmount,
            "Output tokens not Sent"
        );

    }

    /// @notice Send the tokens to the assets recipient and pay the protocol fee
    /// @param _inputAmount Amount of tokens that input to the pool
    /// @param _protocolFee The trade cost
    function _receiveTokensAndPayFee( uint _inputAmount, uint _protocolFee ) private {

        require( msg.value >= _inputAmount, "Insufficient amount of ETH" );

        // receive the tokens

        address _recipient = getAssetsRecipient();

        if( _recipient != address( this ) ) {

            ( bool isAssetSended, ) = payable( _recipient ).call{ value: _inputAmount - _protocolFee }("");

            require( isAssetSended, "Tx error" );

        }

        // send the protocol fee to protocol fee recipient

        _payProtocolFee( _protocolFee );

    }

    /// @notice Send NFTs to the given address
    /// @param _to Address to send the NFTs
    /// @param _tokenIDs NFTs to send
    function _sendOutputNFTs( address _to, uint[] memory _tokenIDs ) internal virtual;

    /// @notice Send NFTs from the pool to the given address
    /// @param _to Address to send the NFTs
    /// @param _numNFTs The number of NFTs to send
    function _sendAnyOutputNFTs( address _to, uint _numNFTs ) internal virtual;

    /*************************************************************************/
    /***************************** SET FUNCTIONS *****************************/

    /// @notice Set a new assets recipient 
    /// @param _newRecipient The new recipient 
    function setAssetsRecipient( address _newRecipient ) external onlyOwner {

        require( currentPoolType != PoolTypes.PoolType.Trade, "Recipient not supported in trade pools");

        require( recipient != _newRecipient, "New recipient is equal than current" );

        recipient = _newRecipient;

        emit NewAssetsRecipient( _newRecipient );

    }

    /// @notice Set a new trade fee 
    /// @param _newFee The new trade fee 
    function setTradeFee( uint128 _newFee ) external onlyOwner {

        require( currentPoolType == PoolTypes.PoolType.Trade, "Fee available only on trade pools");

        require( MAX_TRADE_FEE >= _newFee, "The maximum trade fee is 90%" );

        require( tradeFee != _newFee, "New fee is equal than current" );

        tradeFee = _newFee;

        emit NewTradeFee( _newFee );

    }

    /// @notice Set a new start Price 
    /// @param _newStartPrice The new start Price 
    function setStartPrice( uint128 _newStartPrice ) external onlyOwner {

        require( startPrice != _newStartPrice, "New start price is equal than current");

        require( Algorithm.validateStartPrice( _newStartPrice ), "Invalid Start Price" );

        startPrice = _newStartPrice;

        emit NewStartPrice( _newStartPrice );

    }

    /// @notice Set a new multiplier
    /// @param _newMultiplier The new multiplier
    function setMultiplier( uint128 _newMultiplier ) external onlyOwner {

        require( multiplier != _newMultiplier, "Multiplier is equal than current");

        require( Algorithm.validateMultiplier( _newMultiplier ), "Invalid multiplier" );

        multiplier = _newMultiplier;

        emit NewMultiplier( _newMultiplier );
        
    }

    /*************************************************************************/
    /************************** GET FUNCTIONS ********************************/
 
    /// @notice Return the current pool sell info
    /// @param _numNFTs Number of NFTs to buy
    /// @return isValid Indicate if will be an error calculating the price
    /// @return newStartPrice The pool new Star Price
    /// @return newMultiplier The pool new Multiplier
    /// @return inputValue The amount of tokens to send at pool to buy NFTs
    /// @return protocolFee The trade cost
    function getPoolBuyInfo( uint _numNFTs) public view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint inputValue, uint protocolFee ) {

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            inputValue, 
            protocolFee 
        ) = Algorithm.getBuyInfo( 
            multiplier, 
            startPrice, 
            _numNFTs, 
            factory.PROTOCOL_FEE(),
            tradeFee
            );
    
    }
 
    /// @notice Return the current pool sell info
    /// @param _numNFTs Number of NFTs to buy
    /// @return isValid Indicate if will be an error calculating the price
    /// @return newStartPrice The pool new Star Price
    /// @return newMultiplier The pool new Multiplier
    /// @return outputValue The number of tokens to send to the user when selling NFTs
    /// @return protocolFee The trade cost
    function getPoolSellInfo( uint _numNFTs) public view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint outputValue, uint protocolFee ) {

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            outputValue, 
            protocolFee 
        ) = Algorithm.getSellInfo( 
            multiplier, 
            startPrice, 
            _numNFTs, 
            factory.PROTOCOL_FEE(),
            tradeFee
            );
    
    }

    /// @notice Returns the NFTs hold by the pool 
    function getNFTIds() public virtual view returns ( uint[] memory nftIds );

    /// @notice Returns the recipient of the input assets
    function getAssetsRecipient() public view returns ( address _recipient ) {

        if ( recipient == address( 0 ) ) _recipient = address( this );

        else _recipient = recipient;

    }

    /// @notice Returns the current algorithm info
    /// @return algorithm Name of the algorithm used to calculate trade prices
    /// @return name Name of the algorithm used to calculate trade prices
    function getAlgorithmInfo() public view returns( IMetaAlgorithm algorithm, string memory name ) {

        algorithm = Algorithm;

        name = Algorithm.name();
        
    }

    /// @notice Returns the pool info
    /// @return poolMultiplier Current multiplier
    /// @return poolStartPrice Current start price 
    /// @return poolTradeFee Trade fee multiplier 
    /// @return poolNft NFT trade collection
    /// @return poolNFTs NFTs of the pool
    /// @return poolAlgorithm Address of the algorithm
    /// @return poolAlgorithmName Name of the algorithm
    /// @return poolPoolType The type of the pool
    /// @return assetsRecipient Recipient of the trade assets
    function getPoolInfo() public view returns( 
        uint128 poolMultiplier,
        uint128 poolStartPrice,
        uint128 poolTradeFee,
        address poolNft,
        uint[] memory poolNFTs,
        IMetaAlgorithm poolAlgorithm,
        string memory poolAlgorithmName,
        PoolTypes.PoolType poolPoolType,
        address assetsRecipient
    ){
        poolMultiplier = multiplier;

        poolStartPrice = startPrice;

        poolTradeFee = tradeFee;

        poolNft = NFT;

        poolNFTs = getNFTIds();

        ( poolAlgorithm, poolAlgorithmName ) = getAlgorithmInfo();

        poolPoolType = currentPoolType;

        assetsRecipient = getAssetsRecipient();

    }
    
    /*************************************************************************/
    /***************************** INIT POOL *********************************/

    /// @notice Set the initial params of the pool
    /// @dev It is expected that the parameters have already been verified
    /// @param _multiplier Multiplier to calculate price
    /// @param _startPrice The Star Price ( depending of the algorithm it will be take it by different ways )
    /// @param _recipient The recipient of the input assets
    /// @param _owner The owner of the pool
    /// @param _NFT The NFT collection that will be trade
    /// @param _fee Pool fee charged per trade
    /// @param _Algorithm Address of the algorithm to calculate the price
    /// @param _poolType The type of the pool
    function init(
        uint128 _multiplier, 
        uint128 _startPrice, 
        address _recipient, 
        address _owner, 
        address _NFT, 
        uint128 _fee, 
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType 
        ) public payable 
    {

        require( owner() == address(0), "Pool it's already initialized");

        _transferOwnership( _owner );

        // in a trade pool the recipient is the address 0

        if( recipient != _recipient ) recipient = _recipient;

        // In a non-trade pool, the fee is 0

        if( tradeFee != _fee) tradeFee = _fee;

        Algorithm = _Algorithm;

        multiplier = _multiplier;

        startPrice = _startPrice;

        NFT = _NFT;

        currentPoolType = _poolType;

        factory = IMetaFactory( msg.sender );

    }

    /*************************************************************************/
    /**************************** TRADE FUNCTIONS ****************************/

    /// @notice Sell NFTs for tokens
    /// @param _tokenIDs NFTs to sell
    /// @param _minExpectedOut The minimum expected that the pool will return to the user
    /// @param _user Address to send the tokens
    /// @return outputAmount The amount of tokens that output from the pool
    function swapNFTsForToken( uint[] memory _tokenIDs, uint _minExpectedOut, address _user ) external nonReentrant returns( uint256 outputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Sell || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on buy-type pool" );

        require( address( this ).balance >= _minExpectedOut, "Insufficient token balance");

        // in case the trade caller is not a router approved the user is the msg.sender

        address user = _getUser( _user );

        uint256 protocolFee;

        uint128 newStartPrice;

        uint128 newMultiplier;

        ( 
            outputAmount, 
            protocolFee, 
            newStartPrice,
            newMultiplier
        ) = _getSellNFTInfo( _tokenIDs.length, _minExpectedOut );

        // receive NFTs and send Tokens

        _receiveNFTs( user, _tokenIDs );

        _sendTokensAndPayFee( protocolFee, outputAmount, user );

        // update Start Price and Multiplier if is needed

        _updatePoolPriceParams( newStartPrice, newMultiplier );

        emit SellLog( user, _tokenIDs.length, outputAmount );

    }

    /// @notice Buy NFTs with tokens
    /// @param _tokenIDs NFTs to buy
    /// @param _maxExpectedIn The maximum expected that the trade will cost
    /// @param _user Address to send the NFTs
    /// @return inputAmount Amount of tokens that input to the pool
    function swapTokenForNFT( uint[] memory _tokenIDs, uint _maxExpectedIn, address _user ) external payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on sell-type pool" );

        require( 
            IERC721( NFT ).balanceOf( address( this ) ) >= _tokenIDs.length,
            "Insufficient NFT balance" 
        );

        // in case the trade caller is not a router approved the user is the msg.sender

        address user = _getUser( _user );

        uint protocolFee;

        uint128 newStartPrice;

        uint128 newMultiplier;

        ( 
            inputAmount, 
            protocolFee,
            newStartPrice,
            newMultiplier
        ) = _getBuyNFTInfo( _tokenIDs.length, _maxExpectedIn );

        // receive tokens and send NFTs

        _receiveTokensAndPayFee( inputAmount, protocolFee );

        _sendOutputNFTs( user, _tokenIDs );

        // update Start Price and Multiplier if is needed

        _updatePoolPriceParams( newStartPrice, newMultiplier );

        // the tokens are returned to the user if more than necessary are sent

        _returnRemainingValue( inputAmount );

        emit BuyLog( user, inputAmount, _tokenIDs.length);
        
    }

    /// @notice Buy any NFTs with tokens ( It is used when the NFTs that you want to buy do not matter )
    /// @param _numNFTs Number NFTs to buy
    /// @param _maxExpectedIn The maximum expected that the trade will cost
    /// @param _user Address to send the NFTs
    /// @return inputAmount Amount of tokens that input to the pool
    function swapTokenForAnyNFT( uint _numNFTs, uint _maxExpectedIn, address _user ) external payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on sell-type pool" );

        require( 
            IERC721( NFT ).balanceOf( address( this ) ) >= _numNFTs,
            "Insufficient NFT balance" 
        );

        // in case the trade caller is not a router approved the user is the msg.sender

        address user = _getUser( _user );

        uint protocolFee;

        uint128 newStartPrice;

        uint128 newMultiplier;

        ( 
            inputAmount, 
            protocolFee,
            newStartPrice,
            newMultiplier
        ) = _getBuyNFTInfo( _numNFTs, _maxExpectedIn );

        // receive tokens and send NFTs

        _receiveTokensAndPayFee( inputAmount, protocolFee );

        _sendAnyOutputNFTs( user, _numNFTs );

        // update Start Price and Multiplier if is needed

        _updatePoolPriceParams( newStartPrice, newMultiplier );

        // the tokens are returned to the user if more than necessary are sent

        _returnRemainingValue( inputAmount );

        emit BuyLog( user, inputAmount, _numNFTs);
        
    }

    /*************************************************************************/
    /********************** WITHDRAW FUNCTIONS FUNCTIONS *********************/

    /// @notice Withdraw the balance tokens
    function withdrawTokens() external onlyOwner {

        uint balance = address( this ).balance;

        require( balance > 0, "Insufficient balance" );

        ( bool isSended, ) = owner().call{ value: balance }("");

        require(isSended, "Amount not sent" );

        emit TokenWithdrawal( owner(), balance );

    }

    /// @notice Withdraw the balance of NFTs
    /// @param _nft NFT collection to withdraw
    /// @param _nftIds NFTs to withdraw
    function withdrawNFTs( IERC721 _nft, uint[] calldata _nftIds ) external virtual;

    /*************************************************************************/
    /*************************** DEPOSIT FUNCTIONS ***************************/

    /// @notice Allows the pool to receive ETH
    receive() external payable {

        emit TokenDeposit( msg.value );

    }

}