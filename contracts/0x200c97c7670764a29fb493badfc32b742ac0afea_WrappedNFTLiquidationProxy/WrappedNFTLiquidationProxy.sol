/**
 *Submitted for verification at Etherscan.io on 2019-08-22
*/

pragma solidity ^0.5.8;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/// @title WrappedNFTLiquidationProxy accompanies WrappedNFT and WrappedNFTFactory. This contract
///  allows you to send a mixed bundle of NFT’s to a single address, wraps them appropriately, and
///  liquidates them with Uniswap, as well as allowing you to purchase random NFTs with ETH by
///  grabbing wrapped-NFTs from Uniswap and converting them back into the underlying NFT.

contract WrappedNFTLiquidationProxy {

    // OpenZeppelin's SafeMath library is used for all arithmetic operations to avoid overflows/underflows.
    using SafeMath for uint256;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /// @dev This event is fired when a user atomically wraps tokens from ERC721s
    ///  to ERC20s and then atomically sells the ERC20s to Uniswap in the same
    ///  transaction.
    /// @param numTokensMelted The number of NFTs that were liquified
    /// @param nftContractAddress The core contract address of the NFTs that were
    ///  liquified.
    /// @param ethReceived The amount of ETH (in wei) that was sent to the User in
    ///  exchange for their NFTs.
    event LiquidateNFTs(
        uint256 numTokensMelted,
        address nftContractAddress,
        uint256 ethReceived
    );

    /// @dev This event is fired when a user atomically buys WNFT ERC20 tokens
    ///  from Uniswap and subsequently converts them back into ERC721s in the
    ///  same transaction.
    /// @param numTokensBought The number of NFTs that were purchased
    /// @param nftContractAddress The core contract address of the NFTs that were
    ///  purchased.
    /// @param ethSpent The amount of ETH (in wei) that was sent from the User to
    ///  Uniswap in exchange for the NFTs that they received.
    event PurchaseNFTs(
        uint256 numTokensBought,
        address nftContractAddress,
        uint256 ethSpent
    );

    /// @dev This event is fired when a user wraps a bundle of NFTs from ERC721s
    ///  into ERC20s
    /// @param numTokensWrapped The number of NFTs that were wrapped
    /// @param nftContractAddress The core contract address of the NFTs that were
    ///  wrapped.
    event WrapNFTs(
        uint256 numTokensWrapped,
        address nftContractAddress
    );

    /// @dev This event is fired when a user unwraps a bundle of NFTs from ERC20s
    ///  into ERC721s
    /// @param numTokensUnwrapped The number of NFTs that were unwrapped
    /// @param nftContractAddress The core contract address of the NFTs that were
    ///  unwrapped.
    event UnwrapNFTs(
        uint256 numTokensUnwrapped,
        address nftContractAddress
    );

    /* ********* */
    /* CONSTANTS */
    /* ********* */

    /// @dev This contract's instance of the WrappedNFTFactory contract
    address public wrappedNFTFactoryAddress;
    WrappedNFTFactory private wrappedNFTFactory;

    /// @dev This contract's instance of the UniswapFactory contract
    address public uniswapFactoryAddress;
    UniswapFactory private uniswapFactory;

    /// @dev The address of the wrappedKitties contract, used in our internal functions
    ///  in order to specify the correct function call name for depositNftsAndMintTokens,
    ///  since the WrappedKitties contract uses slightly different wording in its function
    ///  calls.
    address private wrappedKittiesAddress = 0x09fE5f0236F0Ea5D930197DCE254d77B04128075;

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /// @dev This function allows aa user to atomically wrap tokens from ERC721s
    ///  to ERC20s and then atomically sell the ERC20s to Uniswap in the same
    ///  transaction.
    /// @param _nftIds The array of ids of the NFT tokens.
    /// @param _nftContractAddresses The nftCore addresses for each of the respective tokens.
    /// @param _isMixedBatchOfNFTs A flag indicating whether all of the NFTs originate from
    ///  the same NFTCore contract or not
    /// @param _uniswapSlippageAllowedInBasisPoints A percentage (measured in hundreths of a
    ///  percent), of how much slippage is tolerated when the wrapped NFTs are sold on Uniswap.
    ///  If Uniswap is would cause more slippage (or this call has been frontrun), then this
    ///  this call will revert.
    function liquidateNFTs(uint256[] memory _nftIds, address[] memory _nftContractAddresses, bool _isMixedBatchOfNFTs, uint256 _uniswapSlippageAllowedInBasisPoints) public {
        require(_nftIds.length == _nftContractAddresses.length, 'you did not provide an nftContractAddress for each of the groups of NFTs that you wish to liquidate');
        require(_nftIds.length > 0, 'you must submit an array with at least one element');

        for(uint i = 0; i < _nftIds.length; i++){
            // Transfer NFTs from User to Proxy, since only the owner of the token can call depositNftsAndMintTokens.
            NFTCore(_nftContractAddresses[i]).transferFrom(msg.sender, address(this), _nftIds[i]);

            // If we are melting an array of NFTs that come from different NFTCore contracts, then we
            //  call wrapAndLiquidate one by one, since each NFT has a different corresponding wrapper
            //  contract and uniswap contract
            if(_isMixedBatchOfNFTs){
                uint256[] memory nftIdArray = new uint256[](1);
                nftIdArray[0] = _nftIds[i];
                _wrapAndLiquidateArrayOfNfts(nftIdArray, _nftContractAddresses[i], msg.sender, _uniswapSlippageAllowedInBasisPoints);
            }
        }
        // If we are melting an array of NFTs that come from the same NFTCore contract, then we call
        //  wrapAndLiquidate together in a bundle to save gas, since they share the same wrapper contract
        //  and the same uniswap contract.
        if(!_isMixedBatchOfNFTs){
            _wrapAndLiquidateArrayOfNfts(_nftIds, _nftContractAddresses[0], msg.sender, _uniswapSlippageAllowedInBasisPoints);
        }
    }

    /// @dev This function allows a user atomically to buy WNFT ERC20 tokens
    ///  from Uniswap and subsequently convert them back into ERC721s in the
    ///  same transaction.
    /// @param _nftContractAddress The nftCore addresses for the tokens to be purchased
    /// @param _numTokensToPurchase The number of NFTs to be purchased.
    function purchaseNFTs(address _nftContractAddress, uint256 _numTokensToPurchase) payable external {
        require(_numTokensToPurchase > 0, 'you need to purchase at least one full NFT');

        address wrapperContractAddress = wrappedNFTFactory.getWrapperContractForNFTContractAddress(_nftContractAddress);
        address uniswapAddress = uniswapFactory.getExchange(wrapperContractAddress);

        // Buy tokens from Uniswap
        uint256 inputEth = msg.value;
        uint256 ethRequired = UniswapExchange(uniswapAddress).getEthToTokenOutputPrice(_numTokensToPurchase.mul(10**18));
        require(inputEth >= ethRequired, 'you did not submit enough ETH to purchase the number of NFTs that you requested');
        uint256 ethSpent = UniswapExchange(uniswapAddress).ethToTokenSwapOutput.value(msg.value)(_numTokensToPurchase.mul(10**18), ~uint256(0));

        // Unwrap ERC20s to ERC721s And Send ERC721s To User
        uint256[] memory tokenIds = new uint256[](_numTokensToPurchase);
        address[] memory destinationAddresses = new address[](_numTokensToPurchase);
        for(uint i = 0; i < _numTokensToPurchase; i++){
            tokenIds[i] = 0;
            destinationAddresses[i] = msg.sender;
        }
        _burnTokensAndWithdrawNfts(wrapperContractAddress, tokenIds, destinationAddresses);

        // Refund the user for any remaining ETH that wasn't spent on Uniswap
        msg.sender.transfer(inputEth.sub(ethSpent));

        emit PurchaseNFTs(_numTokensToPurchase, _nftContractAddress, ethSpent);
    }

        /// @dev This function allows a user to wrap a bundle of NFTs from ERC721s
    ///  into ERC20s, even if they come from different nftCore contracts
    /// @param _nftIds The array of ids of the NFT tokens.
    /// @param _nftContractAddresses The nftCore addresses for each of the respective tokens.
    /// @param _isMixedBatchOfNFTs A flag indicating whether all of the NFTs originate from the same NFTCore contract or not
    function wrapNFTs(uint256[] calldata _nftIds, address[] calldata _nftContractAddresses, bool _isMixedBatchOfNFTs) external {
        require(_nftIds.length == _nftContractAddresses.length, 'you did not provide an nftContractAddress for each of the groups of NFTs that you wish to wrap');
        require(_nftIds.length > 0, 'you must submit an array with at least one element');

        for(uint i = 0; i < _nftIds.length; i++){
            address wrapperContractAddress = wrappedNFTFactory.getWrapperContractForNFTContractAddress(_nftContractAddresses[i]);

            // Transfer NFTs from User to Proxy, since only the owner of the token can call depositNftsAndMintTokens.
            NFTCore(_nftContractAddresses[i]).transferFrom(msg.sender, address(this), _nftIds[i]);
            NFTCore(_nftContractAddresses[i]).approve(wrapperContractAddress, _nftIds[i]);

            // If we are wrapping an array of NFTs that come from different NFTCore contracts, then we
            //  call depositNftsAndMintTokens one by one, since each NFT has a different corresponding
            //  wrapper contract
            if(_isMixedBatchOfNFTs){
                // Convert NFTs from ERC721 to ERC20
                uint256[] memory nftIdArray = new uint256[](1);
                nftIdArray[0] = _nftIds[i];

                _depositNFTsAndMintTokens(wrapperContractAddress, nftIdArray);
                WrappedNFT(wrapperContractAddress).transfer(msg.sender, (10**18));
                emit WrapNFTs(1, _nftContractAddresses[i]);
            }
        }
        // If we are wrapping an array of NFTs that come from the same NFTCore contract, then we call
        //  depositNftsAndMintTokens together in a bundle to save gas, since they share the same wrapper
        //  contract.
        if(!_isMixedBatchOfNFTs){
            address wrapperContractAddress = wrappedNFTFactory.getWrapperContractForNFTContractAddress(_nftContractAddresses[0]);
            // Convert NFTs from ERC721 to ERC20
            _depositNFTsAndMintTokens(wrapperContractAddress, _nftIds);
            WrappedNFT(wrapperContractAddress).transfer(msg.sender, (_nftIds.length).mul(10**18));
            emit WrapNFTs(_nftIds.length, _nftContractAddresses[0]);
        }
    }

    /// @dev This function allows a user to unwraps a bundle of NFTs from ERC20s
    ///  into ERC721s, even if they come from different NFTCore contracts
    /// @param _nftIds The array of ids of the NFT tokens.
    /// @param _nftContractAddresses The nftCore addresses for each of the respective tokens.
    /// @param _destinationAddresses The destination addresses for where each of the unwrapped NFTs should be sent (this
    ///  is specified on a per-token basis the wrappedNFT contract to allow for the ability to "airdrop" tokens to many
    ///  addresses in a single transaction).
    /// @param _isMixedBatchOfNFTs A flag indicating whether all of the NFTs originate from the same NFTCore contract or not
    function unwrapNFTs(uint256[] calldata _nftIds, address[] calldata _nftContractAddresses, address[] calldata _destinationAddresses, bool _isMixedBatchOfNFTs) external {
        require(_nftIds.length == _nftContractAddresses.length, 'you did not provide an nftContractAddress for each of the groups of NFTs that you wish to unwrap');
        require(_nftIds.length > 0, 'you must submit an array with at least one element');

        if(_isMixedBatchOfNFTs){
             // If we are unwrapping a mixed batch of NFTs, then we need to unwrap them one at a time,
            //  since each comes from a different NFTCore contract with a different corresponding
            for(uint i = 0; i < _nftIds.length; i++){
                // Convert NFTs from ERC20 to ERC721
                address wrapperContractAddress = wrappedNFTFactory.getWrapperContractForNFTContractAddress(_nftContractAddresses[i]);
                WrappedNFT(wrapperContractAddress).transferFrom(msg.sender, address(this), (10**18));

                uint256[] memory nftIdArray = new uint256[](1);
                nftIdArray[0] = _nftIds[i];

                address[] memory destinationAddressesArray = new address[](1);
                destinationAddressesArray[0] = _destinationAddresses[i];

                _burnTokensAndWithdrawNfts(wrapperContractAddress, nftIdArray, destinationAddressesArray);
                emit UnwrapNFTs(1, _nftContractAddresses[i]);
            }
        } else if(!_isMixedBatchOfNFTs){
            // If we are unwrapping an array of NFTs that come from the same NFTCore contract, then we call
            //  burnTokensAndWithdrawNfts together in a bundle to save gas, since they share the same wrapper
            //  contract.

            // Convert NFTs from ERC20 to ERC721
            address wrapperContractAddress = wrappedNFTFactory.getWrapperContractForNFTContractAddress(_nftContractAddresses[0]);
            WrappedNFT(wrapperContractAddress).transferFrom(msg.sender, address(this), _nftIds.length.mul(10**18));
            _burnTokensAndWithdrawNfts(wrapperContractAddress, _nftIds, _destinationAddresses);
            emit UnwrapNFTs(_nftIds.length, _nftContractAddresses[0]);
        }
    }

    /// @dev If a user sends an NFT from nftCoreContract directly to this contract using a
    ///  transfer function that implements onERC721Received, then we will call liquidateNFTs().
    ///  The reason that we call liquidateNFTs() and not wrapNFTs() is that they can use
    ///  OnERC721Received to wrap kitties using the corresponding Wrapped NFT contract for this
    ///  NFT.
    /// @notice The contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` to indicate that
    ///  this contract is written in such a way to be prepared to receive ERC721 tokens.
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4) {
        address nftCoreAddress = msg.sender;

        uint256[] memory nftIdArray = new uint256[](1);
        nftIdArray[0] = _tokenId;

        _wrapAndLiquidateArrayOfNfts(nftIdArray, nftCoreAddress, _from, uint256(9999));
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /// @dev We set the address for the WrappedNFTFactory contract and the UniswapFactory
    ///  in the constructor, so that no special permissons are needed and no user can change
    ///  the factory logic from under our feet.
    /// @param _wrappedNFTFactoryAddress The mainnet address of the wrappedNFTFactory contract.
    ///  This contract serves as the directory for finding the corresponding WrappedNFT contract
    ///  for any NFTCore contract.
    /// @param _uniswapFactoryAddress The mainnet address of the uniswapFactoryAddress contract.
    ///  This contract serves as the directory for finding the corresponding UniswapExchange
    ///  contract for any NFTCore contract.
    constructor(address _wrappedNFTFactoryAddress, address _uniswapFactoryAddress) public {
        wrappedNFTFactoryAddress = _wrappedNFTFactoryAddress;
        wrappedNFTFactory = WrappedNFTFactory(_wrappedNFTFactoryAddress);
        uniswapFactoryAddress = _uniswapFactoryAddress;
        uniswapFactory = UniswapFactory(_uniswapFactoryAddress);
    }

    /// @notice We need to accept external payments since Uniswap will send refunds directly
    ///  to this contract.
    function() external payable {}

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    /// @dev This function transforms ERC721 tokens into their corresponding ERC20 WNFT tokens.
    /// @param _wrapperContractAddress The address of the corresponding WNFT contract for this
    ///  ERC721 token.
    /// @param _nftIds An array of the ids of the NFTs to be transformed into ERC20s.
    function _depositNFTsAndMintTokens(address _wrapperContractAddress, uint256[] memory _nftIds) internal {
        if(_wrapperContractAddress != wrappedKittiesAddress){
            WrappedNFT(_wrapperContractAddress).depositNftsAndMintTokens(_nftIds);
        } else {
            WrappedKitties(_wrapperContractAddress).depositKittiesAndMintTokens(_nftIds);
        }
    }

    /// @dev This function transforms WNFT ERC20 tokens into their corresponding ERC721 assets.
    /// @param _wrapperContractAddress The address of the corresponding WNFT contract for this
    ///  ERC721 token.
    /// @param _nftIds An array of the ids of the NFTs to be transformed into ERC20s.
    /// @param _destinationAddresses An array of the addresses that each nft should be sent to.
    ///  You can provide different addresses for each NFT in order to "airdrop" them in a single
    ///  transaction to many people.
    function _burnTokensAndWithdrawNfts(address _wrapperContractAddress, uint256[] memory _nftIds, address[] memory _destinationAddresses) internal {
        if(_wrapperContractAddress != wrappedKittiesAddress){
            WrappedNFT(_wrapperContractAddress).burnTokensAndWithdrawNfts(_nftIds, _destinationAddresses);
        } else {
            WrappedKitties(_wrapperContractAddress).burnTokensAndWithdrawKitties(_nftIds, _destinationAddresses);
        }
    }

    /// @dev This internal helper function wraps ERC721 tokens from the same nftCore contract
    ///  into ERC20 tokens and then subsequently liquidates them on Uniswap.
    /// @param _nftIds The array of ids of the NFT tokens.
    /// @param _nftContractAddress The nftCore address for the tokens
    /// @param _destinationAddress The address that will receive the payout from Uniswap.
    /// @param _uniswapSlippageAllowedInBasisPoints A percentage (measured in hundreths of a
    ///  percent), of how much slippage is tolerated when the wrapped NFTs are sold on Uniswap.
    ///  If Uniswap is would cause more slippage (or this call has been frontrun), then this
    ///  this call will revert.
    function _wrapAndLiquidateArrayOfNfts(uint256[] memory _nftIds, address _nftContractAddress, address _destinationAddress, uint256 _uniswapSlippageAllowedInBasisPoints) internal {
        require(_uniswapSlippageAllowedInBasisPoints <= uint256(9999), 'you provided an invalid value for uniswapSlippageAllowedInBasisPoints');
        address wrapperContractAddress = wrappedNFTFactory.getWrapperContractForNFTContractAddress(_nftContractAddress);
        address uniswapAddress = uniswapFactory.getExchange(wrapperContractAddress);

        // Approve each NFT to send them to WrappedNFT contract to be converted to ERC20s
        for(uint i = 0; i < _nftIds.length; i++){
            NFTCore(_nftContractAddress).approve(wrapperContractAddress, _nftIds[i]);
        }

        // Convert NFTs from ERC721 to ERC20
        _depositNFTsAndMintTokens(wrapperContractAddress, _nftIds);

        // Liquidate ERC20s for ETH and send ETH to User
        WrappedNFT(wrapperContractAddress).approve(uniswapAddress, ~uint256(0));
        uint256 theoreticalEthReceived = UniswapExchange(uniswapAddress).getTokenToEthInputPrice((_nftIds.length).mul(10**18));
        uint256 minEthReceived = (theoreticalEthReceived.mul(uint256(10000).sub(_uniswapSlippageAllowedInBasisPoints))).div(uint256(10000));
        uint256 ethReceived = UniswapExchange(uniswapAddress).tokenToEthTransferInput((_nftIds.length).mul(10**18), minEthReceived, ~uint256(0), _destinationAddress);

        emit LiquidateNFTs(_nftIds.length, _nftContractAddress, ethReceived);
    }
}

/// @title Interface for interacting with the NFTCore contract
contract NFTCore {
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;
}

/// @title Interface for interacting with the WrappedNFTFactory contract
contract WrappedNFTFactory {
    function getWrapperContractForNFTContractAddress(address _nftContractAddress) external returns (address);
}

/// @title Interface for interacting with the WrappedNFT contract
contract WrappedNFT {
    function depositNftsAndMintTokens(uint256[] calldata _nftIds) external;
    function burnTokensAndWithdrawNfts(uint256[] calldata _nftIds, address[] calldata _destinationAddresses) external;
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

/// @title Interface for interacting with the WrappedKitties contract
contract WrappedKitties {
    function depositKittiesAndMintTokens(uint256[] calldata _nftIds) external;
    function burnTokensAndWithdrawKitties(uint256[] calldata _nftIds, address[] calldata _destinationAddresses) external;
}

/// @title Interface for interacting with the UniswapFactory contract
contract UniswapFactory {
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
}

/// @title Interface for interacting with a UniswapExchange contract
contract UniswapExchange {
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256 eth_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
}