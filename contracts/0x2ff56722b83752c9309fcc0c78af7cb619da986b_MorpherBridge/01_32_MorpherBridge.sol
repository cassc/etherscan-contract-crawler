// ------------------------------------------------------------------------
// MorpherBridge
// Handles deposit to and withdraws from the side chain, writing of the merkle
// root to the main chain by the side chain operator, and enforces a rolling 24 hours
// token withdraw limit from side chain to main chain.
// If side chain operator doesn't write a merkle root hash to main chain for more than
// 72 hours positions and balaces from side chain can be transferred to main chain.
// ------------------------------------------------------------------------
//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "./MorpherState.sol";
import "./MorpherUserBlocking.sol";
import "./MorpherAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./MorpherTradeEngine.sol";

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';

contract MorpherBridge is Initializable, ContextUpgradeable {

    using ECDSAUpgradeable for bytes32;


    MorpherState state;
    MorpherBridge previousBridge;

    uint256 public withdrawalLimitPerUserDaily; //200k MPH per day
    uint256 public withdrawalLimitPerUserMonthly; //1M MPH per month
    uint256 public withdrawalLimitPerUserYearly; //5M MPH per year

    uint256 public withdrawalLimitGlobalDaily; 
    uint256 public withdrawalLimitGlobalMonthly;
    uint256 public withdrawalLimitGlobalYearly;
    
    mapping(address => mapping(uint256 => uint256)) public withdrawalPerUserPerDay; //[address][day] = withdrawalAmount
    mapping(address => mapping(uint256 => uint256)) public withdrawalPerUserPerMonth; //[address][month] = withdrawalAmount
    mapping(address => mapping(uint256 => uint256)) public withdrawalPerUserPerYear; //[address][year] = withdrawalAmount

    mapping(uint256 => uint256) public withdrawalsGlobalDaily;
    mapping(uint256 => uint256) public withdrawalsGlobalMonthly;
    mapping(uint256 => uint256) public withdrawalsGlobalYearly;

    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant SIDECHAINOPERATOR_ROLE = keccak256("SIDECHAINOPERATOR_ROLE");

    struct WithdrawalDataStruct {
        bytes32 merkleRoot;
        uint256 lastUpdatedAt;
    }

    WithdrawalDataStruct public withdrawalData;

    uint256 public inactivityPeriod;
    bool public recoveryEnabled;
    mapping(bytes32 => bool) public claimFromInactivity;

    ISwapRouter public swapRouter;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;


    struct TokensTransferredStruct {
        uint256 amount;
        uint256 lastTransferAt;
    }
    mapping(address => mapping(uint => TokensTransferredStruct)) public tokenSentToLinkedChain;
    mapping(address => TokensTransferredStruct) public tokenClaimedOnThisChain;

    uint256 public bridgeNonce;

    event TransferToLinkedChain(
        address indexed from,
        uint256 tokens,
        uint256 totalTokenSent,
        uint256 timeStamp,
        uint256 transferNonce,
        uint256 targetChainId,
        bytes32 indexed transferHash
    );
    event TransferToLinkedChainAndWithdrawTo(
        address indexed from,
        uint256 tokens,
        uint256 totalTokenSent,
        uint256 timeStamp,
        uint256 transferNonce,
        uint256 targetChainId,
        address destinationAddress,
        bytes userSigature,
        bytes32 indexed transferHash
    );
    event TrustlessWithdrawFromSideChain(address indexed from, uint256 tokens);
    event OperatorChainTransfer(address indexed from, uint256 tokens, bytes32 sidechainTransactionHash);
    event ClaimFailedTransferToSidechain(address indexed from, uint256 tokens);
    event PositionRecoveryFromSideChain(address indexed from, bytes32 positionHash);
    event TokenRecoveryFromSideChain(address indexed from, bytes32 positionHash);
    event SideChainMerkleRootUpdated(bytes32 _rootHash);
    event WithdrawLimitReset();
    event WithdrawLimitChanged(uint256 _withdrawLimit);
    event WithdrawLimitDailyPerUserChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitMonthlyPerUserChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitYearlyPerUserChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitDailyGlobalChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitMonthlyGlobalChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitYearlyGlobalChanged(uint256 _oldLimit, uint256 _newLimit);
    event LinkState(address _address);


    /**
     * emitted when the withdrawal was a success.
     * @param _destination: the address that received the amount
     * @param _amount: the amount of tokens
     * @param _convertedToGasToken: if it was converted to ETH/MATIC native (=true) or sent as ERC20 token (=false)
     */
    event WithdrawalSuccess(address _destination, uint _amount, bool _convertedToGasToken);

    function initialize(address _stateAddress, bool _recoveryEnabled, ISwapRouter _swapRouter) public initializer {
        //as of June 14, Martin :
        //User: daily 200k / monthly 1m / yearly 5m
        //Global: daily 3m / monthly 10m / yearly 50m

        state = MorpherState(_stateAddress);
        recoveryEnabled = _recoveryEnabled;

        withdrawalLimitPerUserDaily = 200000 ether; //200k MPH per day
        withdrawalLimitPerUserMonthly = 1000000 ether; //1M MPH per month
        withdrawalLimitPerUserYearly = 5000000 ether; //5M MPH per year

        withdrawalLimitGlobalDaily = 3000000 ether; //3M MPH per day
        withdrawalLimitGlobalMonthly = 10000000 ether; //10M MPH per month
        withdrawalLimitGlobalYearly = 50000000 ether; //50M MPH per year

        inactivityPeriod = 3 days;

        swapRouter = _swapRouter;

    }

    modifier sideChainInactive {
        require(block.timestamp - inactivityPeriod > withdrawalData.lastUpdatedAt, "MorpherBridge: Function can only be called if sidechain is inactive.");
        _;
    }

    modifier onlyRecoveryEnabled() {
        require(recoveryEnabled, "MorpherBridge: Recovery functions are not enabled");
        _;
    }

    modifier userNotBlocked {
        require(!MorpherUserBlocking(state.morpherUserBlockingAddress()).userIsBlocked(_msgSender()), "MorpherBridge: User is blocked");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(role, _msgSender()), "MorpherBridge: Permission denied.");
        _;
    }
    
    // ------------------------------------------------------------------------
    // Links Token Contract with State
    // ------------------------------------------------------------------------
    function setMorpherState(address _stateAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        state = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    function updateSwapRouter(ISwapRouter _swapRouter) public onlyRole(ADMINISTRATOR_ROLE) {
        swapRouter = _swapRouter;
    }


    function setInactivityPeriod(uint256 _periodInSeconds) public onlyRole(ADMINISTRATOR_ROLE) {
        inactivityPeriod = _periodInSeconds;
    }

    function updateSideChainMerkleRoot(bytes32 _rootHash) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        withdrawalData.merkleRoot = _rootHash;
        withdrawalData.lastUpdatedAt = block.timestamp;
        emit SideChainMerkleRootUpdated(_rootHash);
    }

    function updateWithdrawLimitPerUserDaily(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitDailyPerUserChanged(withdrawalLimitPerUserDaily, _withdrawLimit);
        withdrawalLimitPerUserDaily = _withdrawLimit;
    }

    function updateWithdrawLimitPerUserMonthly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitMonthlyPerUserChanged(withdrawalLimitPerUserMonthly, _withdrawLimit);
        withdrawalLimitPerUserMonthly = _withdrawLimit;
    }
    function updateWithdrawLimitPerUserYearly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitYearlyPerUserChanged(withdrawalLimitPerUserYearly, _withdrawLimit);
        withdrawalLimitPerUserYearly = _withdrawLimit;
    }

    function updateWithdrawLimitGlobalDaily(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitDailyGlobalChanged(withdrawalLimitGlobalDaily, _withdrawLimit);
        withdrawalLimitGlobalDaily = _withdrawLimit;
    }

    function updateWithdrawLimitGlobalMonthly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitMonthlyGlobalChanged(withdrawalLimitGlobalMonthly, _withdrawLimit);
        withdrawalLimitGlobalMonthly = _withdrawLimit;
    }
    function updateWithdrawLimitGlobalYearly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitYearlyGlobalChanged(withdrawalLimitGlobalYearly, _withdrawLimit);
        withdrawalLimitGlobalYearly = _withdrawLimit;
    }


    function isNotDailyLimitExceeding(address _usr, uint256 _amount) public view returns(bool) {
        return (
            (withdrawalPerUserPerDay[_usr][block.timestamp / 1 days] + _amount <= withdrawalLimitPerUserDaily) && 
            (withdrawalsGlobalDaily[block.timestamp / 1 days] + _amount <= withdrawalLimitGlobalDaily)
        );
    }
    function isNotMonthlyLimitExceeding(address _usr, uint256 _amount) public view returns(bool) {
        return (
            (withdrawalPerUserPerMonth[_usr][block.timestamp / 30 days] + _amount <= withdrawalLimitPerUserMonthly) &&
            (withdrawalsGlobalMonthly[block.timestamp / 30 days] + _amount <= withdrawalLimitGlobalMonthly)
        );
    }
    function isNotYearlyLimitExceeding(address _usr, uint256 _amount) public view returns(bool) {
        return (
            (withdrawalPerUserPerYear[_usr][block.timestamp / 365 days] + _amount <= withdrawalLimitPerUserYearly) &&
            (withdrawalsGlobalYearly[block.timestamp / 365 days] + _amount <= withdrawalLimitGlobalYearly)
        );
    }

    function verifyUpdateDailyLimit(address _usr, uint256 _amount) public {
        require(isNotDailyLimitExceeding(_usr, _amount), "MorpherBridge: Withdrawal Amount exceeds daily limit");
        withdrawalPerUserPerDay[_usr][block.timestamp / 1 days] += _amount;
        withdrawalsGlobalDaily[block.timestamp / 1 days] += _amount;
    }

    function verifyUpdateMonthlyLimit(address _usr, uint256 _amount) public {
        require(isNotMonthlyLimitExceeding(_usr, _amount), "MorpherBridge: Withdrawal Amount exceeds monthly limit");
        withdrawalPerUserPerMonth[_usr][block.timestamp / 30 days] += _amount;
        withdrawalsGlobalMonthly[block.timestamp / 30 days] += _amount;
    }

    function verifyUpdateYearlyLimit(address _usr, uint256 _amount) public {
        require(isNotYearlyLimitExceeding(_usr, _amount), "MorpherBridge: Withdrawal Amount exceeds yearly limit");
        withdrawalPerUserPerYear[_usr][block.timestamp / 365 days] += _amount;
        withdrawalsGlobalYearly[block.timestamp / 365 days] += _amount;
    }

    
    /**
    * stageTokensForTransfer [chain A] => claimTokens [chain B]
    *     former: transferToSideChain(uint256 _tokens)
    * 
    * Tokens are burned on chain A and then, after the merkle root is written, 
    * can be credited on chain B through claimStagedTokens(...) below
    *
    */
    function stageTokensForTransfer(uint256 _tokens, uint _targetChainId) public userNotBlocked {
        
        verifyUpdateDailyLimit(_msgSender(), _tokens);
        verifyUpdateMonthlyLimit(_msgSender(), _tokens);
        verifyUpdateYearlyLimit(_msgSender(), _tokens);
        uint withdrawalCost = 100 ether;
        
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), withdrawalCost); //BURN 100 MPH as a Withdrawal Fee

        uint tokensToWithdraw = _tokens - withdrawalCost;
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), tokensToWithdraw);


        uint256 _newTokenSentToLinkedChain = tokenSentToLinkedChain[_msgSender()][_targetChainId].amount + tokensToWithdraw;
        uint256 _transferNonce = getAndIncreaseBridgeNonce();
        uint256 _timeStamp = block.timestamp;
        bytes32 _transferHash = keccak256(
            abi.encodePacked(
                _msgSender(),
                tokensToWithdraw,
                _newTokenSentToLinkedChain,
                _timeStamp,
                _targetChainId,
                _transferNonce
            )
        );
        tokenSentToLinkedChain[_msgSender()][_targetChainId].amount =  _newTokenSentToLinkedChain;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt = block.timestamp;
        emit TransferToLinkedChain(_msgSender(), tokensToWithdraw, _newTokenSentToLinkedChain, _timeStamp, _transferNonce, _targetChainId, _transferHash);
    }
    
    /**
    * stageTokensForTransfer [chain A] => claimTokens [chain B]
    *     former: transferToSideChain(uint256 _tokens)
    * 
    * Tokens are burned on chain A and then, after the merkle root is written, 
    * can be credited on chain B through claimStagedTokens(...) below
    *
    */
    function stageTokensForTransfer(uint256 _tokens, uint _targetChainId, address _autoWithdrawalAddressTo, bytes memory _signature) public userNotBlocked {
        verifyUpdateDailyLimit(_msgSender(), _tokens);
        verifyUpdateMonthlyLimit(_msgSender(), _tokens);
        verifyUpdateYearlyLimit(_msgSender(), _tokens);
        
        uint withdrawalCost = 100 ether;
        
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), withdrawalCost); //BURN 100 MPH as a Withdrawal Fee

        uint tokensToWithdraw = _tokens - withdrawalCost;
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), tokensToWithdraw);
        uint256 _newTokenSentToLinkedChain = tokenSentToLinkedChain[_msgSender()][_targetChainId].amount + tokensToWithdraw;
        uint256 _transferNonce = getAndIncreaseBridgeNonce();
        uint256 _timeStamp = block.timestamp;
        bytes32 _transferHash = keccak256(
            abi.encodePacked(
                _msgSender(),
                tokensToWithdraw,
                _newTokenSentToLinkedChain,
                _timeStamp,
                _targetChainId,
                _transferNonce
            )
        );
        tokenSentToLinkedChain[_msgSender()][_targetChainId].amount =  _newTokenSentToLinkedChain;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt = block.timestamp;
        emit TransferToLinkedChainAndWithdrawTo(_msgSender(), tokensToWithdraw, _newTokenSentToLinkedChain, _timeStamp, _transferNonce, _targetChainId, _autoWithdrawalAddressTo, _signature, _transferHash);
    }
    
    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokens(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof) public userNotBlocked {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_msgSender()].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_msgSender(), _numOfToken);
        verifyUpdateMonthlyLimit(_msgSender(), _numOfToken);
        verifyUpdateYearlyLimit(_msgSender(), _numOfToken);        

        _chainTransfer(_msgSender(), _tokenClaimed, _numOfToken);   
        emit TrustlessWithdrawFromSideChain(_msgSender(), _numOfToken);
    }
    
    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokensConvertAndSend(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof, address payable _finalOutput) public userNotBlocked {
        // msg.sender must approve this contract
        
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_msgSender()].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_msgSender(), _numOfToken);
        verifyUpdateMonthlyLimit(_msgSender(), _numOfToken);
        verifyUpdateYearlyLimit(_msgSender(), _numOfToken);        

        _chainTransfer(address(this), _tokenClaimed, _numOfToken); //instead of transferring it to the user, transfer it to the bridge itself
        emit TrustlessWithdrawFromSideChain(_msgSender(), _numOfToken);
        // Transfer the specified amount of DAI to this contract.
        // Approve the router to spend DAI.
        TransferHelper.safeApprove(state.morpherTokenAddress(), address(swapRouter), _numOfToken);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: state.morpherTokenAddress(),
                tokenOut: IPeripheryImmutableState(address(swapRouter)).WETH9(),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _numOfToken,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint amountOut = swapRouter.exactInputSingle(params);
        //weth -> eth conversion
        IWETH9(IPeripheryImmutableState(address(swapRouter)).WETH9()).withdraw(amountOut);
        _finalOutput.transfer(amountOut);
    }

    function getWethWmaticAddress() public view returns (address) {
        return IPeripheryImmutableState(address(swapRouter)).WETH9();
    }

    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokensConvertAndSendForUser(address _usrAddr, uint256 _numOfToken, uint256 fee, address feeRecipient, uint256 _claimLimit, bytes32[] memory _proof, address payable _finalOutput, bytes32 _rootHash, bytes memory _userConfirmationSignature) public onlyRole(SIDECHAINOPERATOR_ROLE) returns(uint) {
        // msg.sender must approve this contract
        require(keccak256(abi.encodePacked(_numOfToken,_finalOutput,block.chainid)).toEthSignedMessageHash().recover(_userConfirmationSignature) == _usrAddr, "MorpherBridge: Users signature does not validate");
        updateSideChainMerkleRoot(_rootHash);
        bytes32 leaf = keccak256(abi.encodePacked(_usrAddr, _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_usrAddr].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_usrAddr, _numOfToken); //for usrAddr
        verifyUpdateMonthlyLimit(_usrAddr, _numOfToken);
        verifyUpdateYearlyLimit(_usrAddr, _numOfToken);        

        //mint the tokens
        tokenClaimedOnThisChain[_usrAddr].amount = _tokenClaimed + _numOfToken;
        tokenClaimedOnThisChain[_usrAddr].lastTransferAt = block.timestamp;
        MorpherToken(state.morpherTokenAddress()).mint(address(this), _numOfToken);
        emit TrustlessWithdrawFromSideChain(_usrAddr, _numOfToken);

        /**
         * Transfer the Fee away
         */
        MorpherToken(state.morpherTokenAddress()).transfer(feeRecipient, fee);
        
        
        uint convertTokens = _numOfToken - fee;


        // Transfer the specified amount of DAI to this contract.
        // Approve the router to spend DAI.
        TransferHelper.safeApprove(state.morpherTokenAddress(), address(swapRouter), convertTokens);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: state.morpherTokenAddress(),
                tokenOut: IPeripheryImmutableState(address(swapRouter)).WETH9(),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: convertTokens,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint amountOut = swapRouter.exactInputSingle(params);

        //weth -> eth conversion
        IWETH9(IPeripheryImmutableState(address(swapRouter)).WETH9()).withdraw(amountOut);
        _finalOutput.transfer(amountOut);
        emit WithdrawalSuccess(_finalOutput, amountOut, true);
        return amountOut;
    }

    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokensAndSendForUser(address _usrAddr, uint256 _numOfToken, uint256 fee, address feeRecipient, uint256 _claimLimit, bytes32[] memory _proof, address payable _finalOutput, bytes32 _rootHash, bytes memory _userConfirmationSignature) public onlyRole(SIDECHAINOPERATOR_ROLE) returns(uint) {
        // msg.sender must approve this contract
        require(keccak256(abi.encodePacked(_numOfToken,_finalOutput,block.chainid)).toEthSignedMessageHash().recover(_userConfirmationSignature) == _usrAddr, "MorpherBridge: Users signature does not validate");
        updateSideChainMerkleRoot(_rootHash);
        bytes32 leaf = keccak256(abi.encodePacked(_usrAddr, _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_usrAddr].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_usrAddr, _numOfToken); //for usrAddr
        verifyUpdateMonthlyLimit(_usrAddr, _numOfToken);
        verifyUpdateYearlyLimit(_usrAddr, _numOfToken);        

        //mint the tokens
        tokenClaimedOnThisChain[_usrAddr].amount = _tokenClaimed + _numOfToken;
        tokenClaimedOnThisChain[_usrAddr].lastTransferAt = block.timestamp;
        MorpherToken(state.morpherTokenAddress()).mint(address(this), _numOfToken);
        emit TrustlessWithdrawFromSideChain(_usrAddr, _numOfToken);

        /**
         * Transfer the Fee away
         */
        MorpherToken(state.morpherTokenAddress()).transfer(feeRecipient, fee);
        
        
        uint convertTokens = _numOfToken - fee;


        // Transfer the specified amount
        MorpherToken(state.morpherTokenAddress()).transfer( _finalOutput, convertTokens);
        
        emit WithdrawalSuccess(_finalOutput, convertTokens, false);
        return convertTokens;
    }
    
    // ------------------------------------------------------------------------
    // _chainTransfer(address _address, uint256 _tokenClaimed, uint256 _numOfToken)
    // Creates token on the chain for the user after proving their distruction on the 
    // linked chain has been proven before 
    // ------------------------------------------------------------------------
    function _chainTransfer(address _address, uint256 _tokenClaimed, uint256 _numOfToken) private {
        tokenClaimedOnThisChain[_address].amount = _tokenClaimed + _numOfToken;
        tokenClaimedOnThisChain[_address].lastTransferAt = block.timestamp;
        MorpherToken(state.morpherTokenAddress()).mint(_address, _numOfToken);
    }
        
    // ------------------------------------------------------------------------
    // claimFailedTransferToSidechain(uint256 _wrongSideChainBalance, bytes32[] memory _proof)
    // If token sent to side chain were not credited to the user on the side chain within inactivityPeriod
    // they can reclaim the token on the main chain by submitting the proof that their
    // side chain balance is less than the number of token sent from main chain.
    // ------------------------------------------------------------------------
    function claimFailedTransferToSidechain(uint256 _wrongSideChainBalance, bytes32[] memory _proof, uint256 _targetChainId) public userNotBlocked {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _wrongSideChainBalance));
        require(block.timestamp > tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt + inactivityPeriod, "MorpherBridge: Failed deposits can only be claimed after inactivity period.");
        require(_wrongSideChainBalance < tokenSentToLinkedChain[_msgSender()][_targetChainId].amount, "MorpherBridge: Other chain credit is greater equal to wrongSideChainBalance.");
       
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Enter total amount of deposits on side chain.");
 
        uint256 _claimAmount = tokenSentToLinkedChain[_msgSender()][_targetChainId].amount - _wrongSideChainBalance;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].amount -=  _claimAmount;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt = block.timestamp;
        verifyUpdateDailyLimit(_msgSender(), _claimAmount);
        verifyUpdateMonthlyLimit(_msgSender(), _claimAmount);
        verifyUpdateYearlyLimit(_msgSender(), _claimAmount);         
        MorpherToken(state.morpherTokenAddress()).mint(_msgSender(), _claimAmount);
        emit ClaimFailedTransferToSidechain(_msgSender(), _claimAmount);
    }

    // ------------------------------------------------------------------------
    // recoverPositionFromInactivity former recoverPositionFromSideChain(bytes32[] memory _proof, bytes32 _leaf, bytes32 _marketId, uint256 _timeStamp, uint256 _longShares, uint256 _shortShares, uint256 _meanEntryPrice, uint256 _meanEntrySpread, uint256 _meanEntryLeverage)
    // Failsafe against side chain operator becoming inactive or withholding Times (Time withhold attack).
    // After 72 hours of no update of the side chain merkle root users can withdraw their last recorded
    // positions from side chain to main chain. Overwrites eventually existing position on main chain.
    // ------------------------------------------------------------------------
    function recoverPositionFromInactivity(
        bytes32[] memory _proof,
        bytes32 _leaf,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
        ) public sideChainInactive userNotBlocked onlyRecoveryEnabled {
        require(_leaf == MorpherTradeEngine(state.morpherTradeEngineAddress()).getPositionHash(_msgSender(), _marketId, _timeStamp, _longShares, _shortShares, _meanEntryPrice, _meanEntrySpread, _meanEntryLeverage, _liquidationPrice), "MorpherBridge: leaf does not equal position hash.");
        require(claimFromInactivity[_leaf] == false, "MorpherBridge: Position already transferred.");
        require(mProof(_proof,_leaf) == true, "MorpherBridge: Merkle proof failed.");
        claimFromInactivity[_leaf] = true;
        //todo: double positions clashing? 
        MorpherTradeEngine(state.morpherTradeEngineAddress()).setPosition(_msgSender(), _marketId, _timeStamp, _longShares, _shortShares, _meanEntryPrice, _meanEntrySpread, _meanEntryLeverage, _liquidationPrice);
        emit PositionRecoveryFromSideChain(_msgSender(), _leaf);
        // Remark: After resuming operations side chain operator has 72 hours to sync and eliminate transferred positions on side chain to avoid double spend
    }

    // ------------------------------------------------------------------------
    // recoverTokenFromInactivity - former recoverTokenFromSideChain(bytes32[] memory _proof, bytes32 _leaf, uint256 _balance)
    // Failsafe against side chain operator becoming inactive or withholding times (time withhold attack).
    // After 72 hours of no update of the side chain merkle root users can withdraw their last recorded
    // token balance from side chain to main chain.
    // ------------------------------------------------------------------------
    function recoverTokenFromInactivity(bytes32[] memory _proof, bytes32 _leaf, uint256 _balance) public sideChainInactive userNotBlocked onlyRecoveryEnabled {
        // Require side chain root hash not set on Mainchain for more than 72 hours (=3 days)
        require(_leaf == getBalanceHash(_msgSender(), _balance), "MorpherBridge: Wrong balance.");
        require(claimFromInactivity[_leaf] == false, "MorpherBridge: Token already transferred.");
        require(mProof(_proof,_leaf) == true, "MorpherBridge: Merkle proof failed.");
        claimFromInactivity[_leaf] = true;

        verifyUpdateDailyLimit(_msgSender(), _balance);
        verifyUpdateMonthlyLimit(_msgSender(), _balance);
        verifyUpdateYearlyLimit(_msgSender(), _balance); 
        
        _chainTransfer(_msgSender(), tokenClaimedOnThisChain[_msgSender()].amount, _balance);
        emit TokenRecoveryFromSideChain(_msgSender(), _leaf);
        // Remark: Side chain operator must adjust side chain balances for token recoveries before restarting operations to avoid double spend
    }

    // ------------------------------------------------------------------------
    // mProof(bytes32[] memory _proof, bytes32 _leaf)
    // Computes merkle proof against the root hash of the sidechain stored in Morpher state
    // ------------------------------------------------------------------------
    function mProof(bytes32[] memory _proof, bytes32 _leaf) public view returns(bool _isTrue) {
        return MerkleProofUpgradeable.verify(_proof, withdrawalData.merkleRoot, _leaf);
    }

    function getBalanceHash(address _address, uint256 _balance) public pure returns (bytes32 _hash) {
        return keccak256(abi.encodePacked(_address, _balance));
    }

    function getAndIncreaseBridgeNonce() internal returns (uint256) {
        bridgeNonce++;
        return bridgeNonce;
    }

    receive() external payable {
        //needed to convert the weth to eth and send to user
    }
}