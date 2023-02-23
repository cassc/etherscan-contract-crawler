// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./pools/MSPoolBasic.sol";
import "./pools/MSPoolNFTEnumerable.sol";
import "./pools/MSPoolNFTBasic.sol";
import "./pools/PoolTypes.sol";


/// @title MetaFactory a contract factory for NFT / ETH liquidity Pools
/// @author JorgeLpzGnz & CarlosMario714
/// @notice Factory that creates minimal proxies based on the IEP-1167
/// @dev All the used in this protocol is on base 18 ( 1e18 )
contract MetaFactory is Ownable, IERC721Receiver {

    /// @notice Using Clones library from Openzeppelin
    using Clones for address;

    /// @notice ERC721 Enumerable interface ID
    bytes4 constant ERC721_ENUMERABLE_INTERFACE_ID =
        type(IERC721Enumerable).interfaceId;

    /// @notice ERC721 interface ID
    bytes4 constant ERC721_INTERFACE_ID =
        type(IERC721).interfaceId;

    /// @notice Maximum percentage allowed for fees
    uint128 public constant MAX_FEE_PERCENTAGE = 0.9e18;

    /// @notice The fee charged per swap in the protocol
    uint128 public PROTOCOL_FEE = 0.0025e18;

    /// @notice recipient that receives the fees
    address public PROTOCOL_FEE_RECIPIENT;

    /// @dev Templates used to create the clone pools

    /// @notice Pool Template using ERC-721 Enumerable 
    MSPoolNFTEnumerable public poolEnumTemplate;

    /// @notice Pool Template using ERC-721
    MSPoolNFTBasic public poolNotEnumTemplate;

    /// @notice Algorithms allowed to calculate pool prices
    mapping( address => bool ) public isMSAlgorithm;

    /// @notice Routers allowed
    mapping( address => bool ) public isMSRouter;

    /*************************************************************************/
    /******************************* EVENTS **********************************/

    /// @param pool New pool created
    /// @param owner Owner of the respective pool
    event NewPool( address pool, address indexed owner);

    /// @param router Router approval set it
    /// @param approval Approval set it
    event RouterApproval( address indexed router, bool approval);

    /// @param algorithm algorithm to establish approval 
    /// @param approval algorithm approval 
    event AlgorithmApproval( address indexed algorithm, bool approval );

    /// @param newFee New fee charged per swap 
    event NewProtocolFee( uint128 newFee );

    /// @param newRecipient Address that receives the protocol fees
    event NewFeeRecipient( address newRecipient );

    /// @param owner Protocol Owner
    /// @param withdrawAmount Amount to withdraw
    event TokenWithdrawal( address indexed owner, uint withdrawAmount );

    /// @param owner Protocol Owner
    /// @param AmountOfNFTs Amount of NFTs withdrawal
    event NFTWithdrawal( address indexed owner, uint AmountOfNFTs );

    /// @param amount Amount of ETH deposit
    event TokenDeposit( uint amount );

    /// @param collectionNFT NFT collection address
    /// @param tokenID ID of the deposited NFT
    event NFTDeposit( address indexed collectionNFT, uint tokenID );

    /*************************************************************************/
    /**************************** CONSTRUCTOR ********************************/

    /// @notice Params are the initial allowed price Algorithms
    constructor( address  _LinearAlgorithm, address _ExponentialAlgorithm, address _CPAlgorithm, address _feeRecipient ) {

        isMSAlgorithm[_LinearAlgorithm] = true;

        isMSAlgorithm[_ExponentialAlgorithm] = true;

        isMSAlgorithm[_CPAlgorithm] = true;

        PROTOCOL_FEE_RECIPIENT = _feeRecipient;

        /// deploy Clone Templates

        poolEnumTemplate = new MSPoolNFTEnumerable();

        poolNotEnumTemplate = new MSPoolNFTBasic();

    }

    /*************************************************************************/
    /*************************** CREATION UTILS ******************************/

    /// @notice function used to create the new pools
    /// @notice the NFT must be a ERC-721 or ERC-721 Enumerable
    /// @param _nft the NFT to init the pool ( this can not be changed after init )
    function _creteContract( address _nft ) private returns( MSPoolBasic _newPool ) {

        bool isEnumerable =
            IERC165( _nft )
            .supportsInterface(ERC721_ENUMERABLE_INTERFACE_ID);

        bool isBasic =
            IERC165( _nft )
            .supportsInterface(ERC721_INTERFACE_ID);

        require( isEnumerable || isBasic );

        address implementation = isEnumerable
            ? address( poolEnumTemplate )
            : address( poolNotEnumTemplate );

        _newPool = MSPoolBasic( payable( implementation.clone() ) );

    }

    /// @notice verifies that the initialization parameters are correct
    /// @param _poolType The pool type of the new Pool
    /// @param _fee The fees charged per swap on that pool ( available only on trade pools )
    /// @param _poolType The pool type of the new Pool
    /// @param _recipient The recipient of the swap assets ( not available on trade pools )
    /// @param _startPrice the start price of the Pool ( depending of the algorithm this will take at different ways )
    /// @param _multiplier The price multiplier ( depending of the algorithm this will take at different ways )
    /// @param _Algorithm algorithm that determines the prices
    function checkInitParams( 
        uint128 _multiplier, 
        uint128 _startPrice,
        address _recipient,  
        uint128 _fee,
        IMetaAlgorithm _Algorithm,
        PoolTypes.PoolType _poolType
        ) public pure 
    {

        if( _poolType == PoolTypes.PoolType.Sell || _poolType == PoolTypes.PoolType.Buy ) {

            require( _fee == 0, "Fee available only on trade pools" );

        } else {

            require( _recipient == address(0), "Recipient not available on trade pool" );

            require( _fee <= MAX_FEE_PERCENTAGE, "Pool Fee exceeds the maximum" );

        }

        require( 
            _Algorithm.validateStartPrice( _startPrice ) &&
            _Algorithm.validateMultiplier( _multiplier ),
            "Invalid multiplier or start price"
        );
        
    }

    /*************************************************************************/
    /***************************** SET FUNCTIONS *****************************/


    /// @notice Set a router approval
    /// @param _router A new protocol Fee
    function setRouterApproval( address _router, bool _approval ) external onlyOwner {

        require( isMSRouter[_router] != _approval, "Approval is the same than previous");

        isMSRouter[_router] = _approval;

        emit RouterApproval( _router, _approval);

    }

    /// @notice Set approval for a price Algorithm
    /// @param _algorithm Algorithm to set approval
    /// @param _approval Approval to set
    function setAlgorithmApproval( address _algorithm, bool _approval) external onlyOwner {

        require( isMSAlgorithm[ _algorithm ] != _approval, "Approval is the same than previous");

        isMSAlgorithm[ _algorithm ] = _approval;

        emit AlgorithmApproval( _algorithm, _approval);

    }

    /// @notice Set a new protocol Fee
    /// @param _newProtocolFee A new protocol Fee
    function setProtocolFee( uint128 _newProtocolFee ) external onlyOwner {

        require( _newProtocolFee < MAX_FEE_PERCENTAGE, "new Fee exceeds limit" );

        require( PROTOCOL_FEE != _newProtocolFee, "new fee cannot be the same as the previous one" );

        PROTOCOL_FEE = _newProtocolFee;

        emit NewProtocolFee( _newProtocolFee );

    }

    /// @notice Set a new protocol Recipient
    /// @param _newRecipient A new protocol Fee
    function setProtocolFeeRecipient( address _newRecipient ) external onlyOwner {

        require( PROTOCOL_FEE_RECIPIENT != _newRecipient, "new fee cannot be the same as the previous one" );

        PROTOCOL_FEE_RECIPIENT = _newRecipient;

        emit NewFeeRecipient( _newRecipient );

    }

    /*************************************************************************/
    /************************** GET FUNCTIONS ********************************/

    /// @notice Get current pool info
    /// @return MAX_FEE_PERCENTAGE The maximum percentage fee per swap
    /// @return PROTOCOL_FEE Current protocol fee charged per swap
    /// @return PROTOCOL_FEE_RECIPIENT The recipient of the fees
    function getFactoryInfo() public view returns( uint128, uint128, address ) {

        return ( MAX_FEE_PERCENTAGE, PROTOCOL_FEE, PROTOCOL_FEE_RECIPIENT );

    }

    /*************************************************************************/
    /*************************** CREATE FUNCTION *****************************/


    /// @notice verifies that the initialization parameters are correct
    /// @param _nft the NFT to init the pool ( this can not be changed after init )
    /// @param _nftIds The NFTs to pull in the pool ( in case of sell pool this must be empty )
    /// @param _multiplier The price multiplier ( depending of the algorithm this will take at different ways )
    /// @param _startPrice the start price of the Pool ( depending of the algorithm this will take at different ways )
    /// @param _recipient The recipient of the swap assets ( not available on trade pools )
    /// @param _fee The fees charged per swap on that pool ( available only on trade pools )
    /// @param _Algorithm algorithm that determines the prices
    /// @param _poolType The pool type of the new Pool
    /// @return pool pool created
    function createPool( 
        address _nft, 
        uint[] calldata _nftIds,
        uint128 _multiplier,
        uint128 _startPrice,
        address _recipient,
        uint128 _fee,
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType
        ) public payable  returns(
            MSPoolBasic pool
        )
    {

        require( isMSAlgorithm[ address(_Algorithm) ], "Algorithm is not Approved");

        checkInitParams( _multiplier, _startPrice, _recipient, _fee,  _Algorithm, _poolType );

        pool = _creteContract( _nft );

        pool.init(
            _multiplier, 
            _startPrice, 
            _recipient,
            msg.sender, 
            _nft, 
            _fee, 
            _Algorithm, 
            _poolType
        );

        // Transfer ETH To the pool 

        if( _poolType == PoolTypes.PoolType.Trade || _poolType == PoolTypes.PoolType.Sell ) {

            ( bool isSended, ) = payable( address( pool ) ).call{ value: msg.value }("");

            require( isSended );
            
        }

        // Transfer NFTs To the pool 

        if( _poolType == PoolTypes.PoolType.Trade || _poolType == PoolTypes.PoolType.Buy ) {

            for (uint256 i = 0; i < _nftIds.length; i++) {

                IERC721( _nft ).safeTransferFrom( msg.sender, address( pool ), _nftIds[i]);

            }
            
        }

        emit NewPool( address( pool ), msg.sender );

    }

    /*************************************************************************/
    /********************** WITHDRAW FUNCTIONS FUNCTIONS *********************/

    /// @notice withdraw the ETH balance of the contract
    function withdrawETH() external onlyOwner {

        uint balance = address( this ).balance;

        require( balance > 0, "insufficient balance" );

        ( bool isSended, ) = owner().call{ value: balance }("");

        require( isSended, "transaction not sended" );

        emit TokenWithdrawal( owner(), balance );

    }

    /// @notice withdraw deposited NFTs
    /// @param _nft address of the collection to withdraw
    /// @param _nftIds the NFTs to withdraw
    function withdrawNFTs( address _nft, uint[] memory _nftIds ) external onlyOwner {

        for (uint256 i = 0; i < _nftIds.length; i++) {
            
            IERC721(_nft).safeTransferFrom( address( this ), owner(), _nftIds[ i ] );

        }

        emit NFTWithdrawal( owner(), _nftIds.length );

    }

    /*************************************************************************/
    /*************************** DEPOSIT FUNCTIONS ***************************/

    /// @notice Allows the contract to receive ETH ( the swap fees )
    receive() external payable  {

        emit TokenDeposit( msg.value );

    }

    /// @notice ERC-721 Receiver implementation
    /// @notice Only the owner can withdraw this input NFTs
    function onERC721Received(address, address, uint256 id, bytes calldata) external override returns (bytes4) {

        emit NFTDeposit( msg.sender, id );

        return IERC721Receiver.onERC721Received.selector;

    }

}