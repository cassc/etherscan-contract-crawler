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

    /// @notice used to calculate the swap price
    uint128 public multiplier;

    /// @notice used to calculate the swap price
    /// @notice start Price is just a name, depending of the algorithm it will take it at different ways
    uint128 public startPrice;

    /// @notice fee charged per swap ( only available in trade pools )
    uint128 public tradeFee;

    /// @notice fee charged per swap ( only available in trade pools )
    uint128 public constant MAX_TRADE_FEE = 0.9e18;

    /// @notice the address that will receive the tokens depending of the pool type
    address public recipient;

    /// @notice the collection that the pool trades
    address public NFT;

    /// @notice the address of the factory that creates this pool
    IMetaFactory public factory;

    /// @notice the type of the pool ( Sell, Buy, Trade )
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

    /// @param owner pool owner
    /// @param withdrawAmount amount of tokens withdrawn
    event TokenWithdrawal( address indexed owner, uint withdrawAmount );

    /// @param owner pool owner
    /// @param AmountOfNFTs amount of NFTs withdrawn
    event NFTWithdrawal( address indexed owner, uint AmountOfNFTs );

    /// @param amount amount of token deposited
    event TokenDeposit( uint amount );

    /// @param nft address of the NFT Collection
    /// @param tokenID NFT deposited
    event NFTDeposit( address nft, uint tokenID );

    /*************************************************************************/
    /*************************** PRIVATE FUNCTIONS ***************************/

    /// @notice Returns the info to sell NFTs and updates the params
    /// @param _numNFTs number of NFTs to sell at pool
    /// @param _minExpected the minimum number of tokens expected to be returned to the user
    /// @return outputValue Amount of Tokens to send to the user
    /// @return protocolFee Fee charged in a trade
    function _getSellNFTInfo( uint _numNFTs, uint _minExpected ) internal virtual returns ( 
            uint256 outputValue, 
            uint256 protocolFee 
        ) 
    {

        bool isValid;

        uint128 newStartPrice;

        uint128 newMultiplier;

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

        require( isValid, "Algorithm Error" );

        require( outputValue >= _minExpected, "output amount is les than min expected" );

        if( startPrice != newStartPrice ) {
            
            startPrice = newStartPrice;

            emit NewStartPrice( newStartPrice );
            
        }

        if( multiplier != newMultiplier ) { 
            
            multiplier = newMultiplier;

            emit NewMultiplier( newMultiplier );
            
        }

    }

    /// @notice Returns the info to buy NFTs and updates the params
    /// @param _numNFTs NFT number to buy at pool
    /// @param _maxExpectedIn the maximum expected cost to buy the NFTs
    /// @return inputValue Amount of tokens to pay the NFTs
    /// @return protocolFee Fee charged in a trade
    function _getBuyNFTInfo( uint _numNFTs, uint _maxExpectedIn ) internal virtual returns ( 
            uint256 inputValue, 
            uint256 protocolFee 
        ) 
    {

        bool isValid;

        uint128 newStartPrice;

        uint128 newMultiplier;

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

        require( isValid, "Algorithm Error" );

        require( inputValue <= _maxExpectedIn, "input amount is greater than max expected" );

        if( startPrice != newStartPrice ) {
            
            startPrice = newStartPrice;

            emit NewStartPrice( newStartPrice );
            
        }

        if( multiplier != newMultiplier ) {
            
            multiplier = newMultiplier;

            emit NewMultiplier( newMultiplier );
            
        }

    }

    /// @notice send tokens to the given address and pay protocol fee
    /// @param _protocolFee the trade cost
    /// @param _amount amount of tokens to send
    /// @param _to the address to send the tokens
    function _sendTokensAndPayFee( uint _protocolFee, uint _amount, address _to ) private {

        address feeRecipient = factory.PROTOCOL_FEE_RECIPIENT();

        ( bool isFeeSended, ) = payable( feeRecipient ).call{value: _protocolFee}("");

        ( bool isAmountSended, ) = payable( _to ).call{ value: _amount - _protocolFee }( "" );

        require( isAmountSended && isFeeSended, "tx error" );

    }

    /// @notice sends the tokens to the pool and pays the protocol fee
    /// @param _inputAmount Amount of tokens that input to the pool
    /// @param _protocolFee the trade cost
    function _receiveTokensAndPayFee( uint _inputAmount, uint _protocolFee ) private {

        require( msg.value >= _inputAmount, "insufficient amount of ETH" );

        address _recipient = getAssetsRecipient();

        if( _recipient != address( this ) ) {

            ( bool isAssetSended, ) = payable( _recipient ).call{ value: _inputAmount - _protocolFee }("");

            require( isAssetSended, "tx error" );

        }

        address feeRecipient = factory.PROTOCOL_FEE_RECIPIENT();

        ( bool isFeeSended, ) = payable( feeRecipient ).call{ value: _protocolFee }("");

        require( isFeeSended, "tx error");

    }

    /// @notice send NFTs to the given address
    /// @param _from NFTs owner address
    /// @param _to address to send the NFTs
    /// @param _tokenIDs NFTs to send
    function _sendNFTsTo( address _from, address _to, uint[] memory _tokenIDs ) internal virtual;

    /// @notice send NFTs from the pool to the given address
    /// @param _to address to send the NFTs
    /// @param _numNFTs the number of NFTs to send
    function _sendAnyOutNFTs( address _to, uint _numNFTs ) internal virtual;

    /*************************************************************************/
    /***************************** SET FUNCTIONS *****************************/

    /// @notice it sets a new recipient 
    /// @param _newRecipient the new recipient 
    function setAssetsRecipient( address _newRecipient ) external onlyOwner {

        require( currentPoolType != PoolTypes.PoolType.Trade, "Recipient not supported in trade pools");

        require( recipient != _newRecipient, "New recipient is equal than current" );

        recipient = _newRecipient;

        emit NewAssetsRecipient( _newRecipient );

    }

    /// @notice it sets a new trade fee 
    /// @param _newFee the new trade fee 
    function setTradeFee( uint128 _newFee ) external onlyOwner {

        require( currentPoolType == PoolTypes.PoolType.Trade, "fee available only on trade pools");

        require( tradeFee != _newFee, "New fee is equal than current" );

        tradeFee = _newFee;

        emit NewTradeFee( _newFee );

    }

    /// @notice it sets a new start Price 
    /// @param _newStartPrice the new start Price 
    function setStartPrice( uint128 _newStartPrice ) external onlyOwner {

        require( startPrice != _newStartPrice, "new price is equal than current");

        require( Algorithm.validateStartPrice( _newStartPrice ), "invalid Start Price" );

        startPrice = _newStartPrice;

        emit NewStartPrice( _newStartPrice );

    }

    /// @notice it sets a new multiplier
    /// @param _newMultiplier the new multiplier
    function setMultiplier( uint128 _newMultiplier ) external onlyOwner {

        require( multiplier != _newMultiplier, "multiplier is equal than current");

        require( Algorithm.validateMultiplier( _newMultiplier ), "invalid multiplier" );

        multiplier = _newMultiplier;

        emit NewMultiplier( _newMultiplier );
        
    }

    /*************************************************************************/
    /************************** GET FUNCTIONS ********************************/
 
    /// @notice it return the pool sell info
    /// @param _numNFTs number of NFTs to buy
    /// @return isValid indicate if will be an error calculating the price
    /// @return newStartPrice the pool new Star Price
    /// @return newMultiplier the pool new Multiplier
    /// @return inputValue the amount of tokens to send at pool to buy NFTs
    /// @return protocolFee the trade cost
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
 
    /// @notice it return the pool sell info
    /// @param _numNFTs number of NFTs to buy
    /// @return isValid indicate if will be an error calculating the price
    /// @return newStartPrice the pool new Star Price
    /// @return newMultiplier the pool new Multiplier
    /// @return outputValue the number of tokens to send to the user when selling NFTs
    /// @return protocolFee the trade cost
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

    /// @notice it returns the NFTs hold by the pool 
    function getNFTIds() public virtual view returns ( uint[] memory nftIds );

    /// @notice returns the recipient of the input assets
    function getAssetsRecipient() public view returns ( address _recipient ) {

        if ( recipient == address(0) ) _recipient = address( this );

        else _recipient = recipient;

    }

    /// @notice returns the name of the price algorithm used
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
    function getPoolInfo() public view returns( 
        uint128 poolMultiplier,
        uint128 poolStartPrice,
        uint128 poolTradeFee,
        address poolNft,
        uint[] memory poolNFTs,
        IMetaAlgorithm poolAlgorithm,
        string memory poolAlgorithmName,
        PoolTypes.PoolType poolPoolType
    ){
        poolMultiplier = multiplier;

        poolStartPrice = startPrice;

        poolTradeFee = tradeFee;

        poolNft = NFT;

        poolNFTs = getNFTIds();

        ( poolAlgorithm, poolAlgorithmName ) = getAlgorithmInfo();

        poolPoolType = currentPoolType;

    }
    
    /*************************************************************************/
    /***************************** INIT POOL *********************************/

    /// @notice it set the initial params of the pool
    /// @dev it is expected that the parameters have already been verified
    /// @param _multiplier multiplier to calculate price
    /// @param _startPrice the Star Price ( depending of the algorithm it will be take it by different ways )
    /// @param _recipient the recipient of the input assets
    /// @param _owner the owner of the pool
    /// @param _NFT the NFT collection that will be trade
    /// @param _fee pool fee charged per trade
    /// @param _Algorithm address of the algorithm to calculate the price
    /// @param _poolType the type of the pool
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

        if( recipient != _recipient ) recipient = _recipient;

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

    /// @notice sell NFTs for tokens
    /// @param _tokenIDs NFTs to sell
    /// @param _minExpected the minimum expected that the pool will return to the user
    /// @param _user address to send the tokens
    /// @return outputAmount the amount of tokens that output of the pool
    function swapNFTsForToken( uint[] memory _tokenIDs, uint _minExpected, address _user ) public nonReentrant returns( uint256 outputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Sell || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on buy-type pool" );

        require( address( this ).balance >= _minExpected, "insufficient token balance");

        uint256 protocolFee;

        ( outputAmount, protocolFee ) = _getSellNFTInfo( _tokenIDs.length, _minExpected );

        address _recipient = getAssetsRecipient();

        _sendNFTsTo( _user, _recipient, _tokenIDs );

        _sendTokensAndPayFee( protocolFee, outputAmount, _user );

        emit SellLog( _user, _tokenIDs.length, outputAmount );

    }

    /// @notice buy NFTs with tokens
    /// @param _tokenIDs NFTs to buy
    /// @param _maxExpectedIn the minimum expected that the trade will cost
    /// @param _user address to send the NFTs
    /// @return inputAmount amount of tokens that input of the pool
    function swapTokenForNFT( uint[] memory _tokenIDs, uint _maxExpectedIn, address _user ) public payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on sell-type pool" );

        require( 
            IERC721( NFT ).balanceOf( address( this ) ) >= _tokenIDs.length,
            "Insufficient NFT balance" 
        );

        uint protocolFee;

        ( inputAmount, protocolFee ) = _getBuyNFTInfo( _tokenIDs.length, _maxExpectedIn );

        _receiveTokensAndPayFee( inputAmount, protocolFee );

        _sendNFTsTo( address( this ), _user, _tokenIDs );

        if ( msg.value > inputAmount ) {

            ( bool isSended , ) = payable( _user ).call{ value: msg.value - inputAmount }("");
            
            require( isSended, "tx error" );
            
        }

        emit BuyLog( _user, inputAmount, _tokenIDs.length);
        
    }

    /// @notice buy any NFTs with tokens ( It is used when the NFTs that you want to buy do not matter )
    /// @param _numNFTs number NFTs to buy
    /// @param _maxExpectedIn the minimum expected that the trade will cost
    /// @param _user address to send the NFTs
    /// @return inputAmount amount of tokens that input of the pool
    function swapTokenForAnyNFT( uint _numNFTs, uint _maxExpectedIn, address _user ) public payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on sell-type pool" );

        require( 
            IERC721( NFT ).balanceOf( address( this ) ) >= _numNFTs,
            "Insufficient NFT balance" 
        );

        uint protocolFee;

        ( inputAmount, protocolFee ) = _getBuyNFTInfo( _numNFTs, _maxExpectedIn );

        _receiveTokensAndPayFee( inputAmount, protocolFee );

        _sendAnyOutNFTs( _user, _numNFTs );

        if ( msg.value > inputAmount ) {

            ( bool isSended , ) = payable( _user ).call{ value: msg.value - inputAmount }("");
            
            require( isSended, "tx error" );
            
        }

        emit BuyLog( _user, inputAmount, _numNFTs);
        
    }

    /*************************************************************************/
    /********************** WITHDRAW FUNCTIONS FUNCTIONS *********************/

    /// @notice withdraw the balance tokens
    function withdrawTokens() external onlyOwner {

        uint balance = address( this ).balance;

        require( balance > 0, "insufficient balance" );

        ( bool isSended, ) = owner().call{ value: balance }("");

        require(isSended, "amount not sended" );

        emit TokenWithdrawal( owner(), balance );

    }

    /// @notice withdraw the balance NFTs
    /// @param _nft NFT collection to withdraw
    /// @param _nftIds NFTs to withdraw
    function withdrawNFTs( IERC721 _nft, uint[] calldata _nftIds ) external virtual;

    /*************************************************************************/
    /*************************** DEPOSIT FUNCTIONS ***************************/

    /// @notice allows the pool to receive ETH
    receive() external payable {

        emit TokenDeposit( msg.value );

    }

}