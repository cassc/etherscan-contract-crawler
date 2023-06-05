// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/AltBn128.sol";
import "./lib/LSAG.sol";
import "./interfaces/IOxODexFactory.sol";
import "./interfaces/IOxODexTokenPool.sol";
import { Types } from "./OxODexPool.sol";


contract OxODexTokenPool {

    // =============================================================
    //                           ERRORS
    // =============================================================
    
    error AlreadyInitialized();
    error NotInitialized();

    // =============================================================
    //                           EVENTS
    // =============================================================
    
    event Deposit(address, uint256 tokenAmount, uint256 ringIndex);
    event Withdraw(address, uint256 tokenAmount, uint256 ringIndex);
    event Swap(address indexed tokenOut, uint256 tokenAmountIn, uint256 tokenAmountOut);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice Maximum number of participants in a ring It can be changed to a higher value, 
    /// but it will increase the gas cost.
    uint256 constant MAX_RING_PARTICIPANT = 2;


    /// The participant value would use 16 bits
    uint256 constant _BITWIDTH_PARTICIPANTS = 16;

    /// The Block value would use 16 bits
    uint256 constant _BITWIDTH_BLOCK_NUM = 32;

    /// Bitmask for `numberOfParticipants`
    uint256 constant _BITMASK_PARTICIPANTS = (1 << _BITWIDTH_PARTICIPANTS) -1;

    /// Bitmask for `blockNumber`
    uint256 constant _BITMASK_BLOCK_NUM = (1 << _BITWIDTH_BLOCK_NUM) -1;


    // =============================================================
    //                           STORAGE
    // =============================================================

    struct Ring {
        /// The total amount deposited in the ring
        uint256 amountDeposited;

        /// Bits Layout:
        /// - [0..32]    `initiatedBlockNumber` 
        /// - [32..48]   `numberOfParticipants`
        /// - [48..64]   `numberOfWithdrawnParticipants`
        uint256 packedRingData; 

        /// The public keys of the participants
        mapping (uint256 => uint256[2]) publicKeys;

        /// The key images from successfully withdrawn participants
        /// NOTE: This is used to prevent double spending
        mapping (uint256 => uint256[2]) keyImages;
        bytes32 ringHash;
    }

    struct WithdrawalData {
        /// The amount to withdraw`
        uint256 amount;

        /// The index of the ring
        uint256 ringIndex;

        /// Signed message parameters
        uint256 c0;
        uint256[2] keyImage;
        uint256[] s;
        Types.WithdrawalType wType;
    }

    address public token;
    uint256 public tokenDecimals;
    address public factory;

    /// tokenAmount => ringIndex
    mapping(uint256 => uint256) public ringsNumber;

    /// tokenAmount => ringIndex => Ring
    mapping (uint256 => mapping(uint256 => Ring)) public rings;

    constructor() {}

    modifier whenNotPaused(){
        require(!IOxODexFactory(factory).paused(), "PAUSED");
        _;
    }

    /// @notice Initialize the vault to use and accept `token`
    /// @param _token The address of the token to use
    function initialize(address _token, address _factory) external {
        require(_token != address(0), "ZERO_ADDRESS");
        require(_factory != address(0), "ZERO_ADDRESS");

        if (token != address(0)) revert AlreadyInitialized();
        factory = _factory;
        token = _token;
        tokenDecimals = ERC20(_token).decimals();
    }

    /// @notice Deposit `amount` of `token` into the vault
    /// @param _amount The amount of `token` to deposit
    /// @param _publicKey The public key of the participant
    function deposit(uint _amount, uint256[4] memory _publicKey) external whenNotPaused {
        require(_amount > 0, "AMOUNT_MUST_BE_GREATER_THAN_ZERO");

        IOxODexFactory factoryContract = IOxODexFactory(factory);

        if(ERC20(factoryContract.token()).balanceOf(msg.sender) < factoryContract.getTokenFeeDiscountLimit()) {
            uint256 fee = getFeeForAmount(_amount);
            ERC20(token).transferFrom(msg.sender, address(this), _amount+fee);

            /// Transfer the fee to the treasurer
            ERC20(token).transfer(factoryContract.treasurerAddress(), fee);   
        }else{
            uint256 fee = getDiscountFeeForAmount(_amount);
            ERC20(token).transferFrom(msg.sender, address(this), _amount+fee);

            if(fee > 0) {
                /// Transfer the fee to the treasurer
                ERC20(token).transfer(factoryContract.treasurerAddress(), fee);  
            }
        }
        
        if (!AltBn128.onCurve(uint256(_publicKey[0]), uint256(_publicKey[1]))) {
            revert("PK_NOT_ON_CURVE");
        }

        /// Gets the current ring for the amounts
        uint256 ringIndex = ringsNumber[_amount];
        Ring storage ring = rings[_amount][ringIndex];

        (uint wParticipants,
        uint participants, uint blockNum) = getRingPackedData(ring.packedRingData);

        /// Making sure no duplicate public keys are added
        for (uint256 i = 0; i < participants;) {
            if (ring.publicKeys[i][0] == _publicKey[0] &&
                ring.publicKeys[i][1] == _publicKey[1]) {
                revert("PK_ALREADY_IN_RING");
            }

            if (ring.publicKeys[i][0] == _publicKey[2] &&
                ring.publicKeys[i][1] == _publicKey[3]) {
                revert("PK_ALREADY_IN_RING");
            }

            unchecked {
                i++;
            }
        }

        if (participants == 0) {
            blockNum = block.number - 1;
        }

        ring.publicKeys[participants] = [_publicKey[0], _publicKey[1]];
        ring.publicKeys[participants + 1] = [_publicKey[2], _publicKey[3]];
        ring.amountDeposited += _amount;
        unchecked {
            participants += 2;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        packedData = (packedData << _BITWIDTH_BLOCK_NUM) | blockNum;
        ring.packedRingData = packedData;

        /// If the ring is full, start a new ring
        if (participants >= MAX_RING_PARTICIPANT) {
            ring.ringHash = hashRing(_amount, ringIndex);
            
            /// Add new Ring pool
            ringsNumber[_amount] += 1;
        }

        emit Deposit(msg.sender, _amount, ringIndex);
    }

    modifier chargeForGas(uint256 relayerFee) {
        require(relayerFee <= IOxODexFactory(factory).maxRelayerGasCharge(address(this)) , "RELAYER_FEE_TOO_HIGH");
        _;
        if(relayerFee > 0) {
            ERC20(token).transfer(msg.sender, relayerFee);
        }
    }


    /// @notice Withdraw `amount` of `token` from the vault
    /// @param recipient The address to send the withdrawn tokens to
    /// @param withdrawalData The data for the withdrawal
    /// @param relayerFee The fee to pay the relayer
    function withdraw(
        address recipient, 
        WithdrawalData memory withdrawalData,
        uint256 relayerFee
    ) public whenNotPaused chargeForGas(relayerFee)
    {
        Ring storage ring = rings[withdrawalData.amount][withdrawalData.ringIndex];

        if(withdrawalData.amount > ring.amountDeposited) {
            revert("AMOUNT_EXCEEDS_DEPOSITED");
        }

        if(withdrawalData.amount < relayerFee) {
            revert("RELAYER_FEE_TOO_HIGH");
        }

        (uint wParticipants,
        uint participants,) = getRingPackedData(ring.packedRingData);

        if (recipient == address(0)) {
            revert("ZERO_ADDRESS");
        }
        
        if (wParticipants >= MAX_RING_PARTICIPANT) {
            revert("ALL_FUNDS_WITHDRAWN");
        }

        if (ring.ringHash == bytes32(0x00)) {
            revert("RING_NOT_CLOSED");
        }

        uint256[2][] memory publicKeys = new uint256[2][](MAX_RING_PARTICIPANT);

        for (uint256 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];
            unchecked {
                i++;
            }
        }
    
        /// Attempts to verify ring signature
        bool signatureVerified = LSAG.verify(
            abi.encodePacked(ring.ringHash, recipient), // Convert to bytes
            withdrawalData.c0,
            withdrawalData.keyImage,
            withdrawalData.s,
            publicKeys
        );

        if (!signatureVerified) {
            revert("INVALID_SIGNATURE");
        }

        /// Confirm key image is not already used (no double spends)
        for (uint i = 0; i < wParticipants;) {
            if (ring.keyImages[i][0] == withdrawalData.keyImage[0] &&
                ring.keyImages[i][1] == withdrawalData.keyImage[1]) {
                revert("USED_SIGNATURE");
            }

            unchecked {
                i++;
            }
        }    

        ring.keyImages[wParticipants] = withdrawalData.keyImage;
        unchecked {
            wParticipants++;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        ring.packedRingData = (packedData << _BITWIDTH_BLOCK_NUM) | 0; // blockNum set to zero;  

        // Transfer tokens to recipient
        // If recipient is the contract, don't transfer. Used in swap
        if(withdrawalData.wType == Types.WithdrawalType.Direct){
            // Transfer amount to recipient
            _sendFundsWithRelayerFee(withdrawalData.amount - relayerFee, token, recipient);
        }

        emit Withdraw(recipient, withdrawalData.amount, withdrawalData.ringIndex);
    }

    /// @notice Calculate the fee for a given amount
    /// @param amount The amount to calculate the fee for
    function getFeeForAmount(uint256 amount) public view returns(uint256){
        return (amount * IOxODexFactory(factory).fee()) / 10_000;
    }

    /// @notice Calculate and send the relayer fee for a given amount
    /// @param _amount The amount to calculate the fee for
    /// @param _token The token to send the fee in
    function _sendFundsWithRelayerFee(uint256 _amount, address _token, address _recipient) private returns(uint256 relayerFee){
        relayerFee = getRelayerFeeForAmount(_amount);
        IERC20(_token).transfer(msg.sender, relayerFee);
        IERC20(_token).transfer(_recipient, _amount - relayerFee);
    }

    /// @notice Calculate the relayer fee for a given amount
    /// @param _amount The amount to calculate the fee for
    function getRelayerFeeForAmount(uint256 _amount) public view returns(uint256 relayerFee){
        relayerFee = (_amount * IOxODexFactory(factory).relayerFee()) / 10_000;
    }
    
    /// @notice Get the fee for Discount holders
    /// @param amount The amount to calculate the fee for
    function getDiscountFeeForAmount(uint256 amount) public view returns(uint256){
        return (amount * IOxODexFactory(factory).tokenFee()) / 10_000;
    }

    /// @notice Withdraw `amount` of `token` from the vault
    /// @param recipient The address to send the withdrawn tokens to
    /// @param relayerFee The fee to send to the relayer
    /// @param withdrawalData The data for the withdrawal
    function swapOnWithdrawal(
        address tokenOut,
        address router,
        bytes memory params, 
        address payable recipient,
        uint256 relayerFee, 
        WithdrawalData memory withdrawalData
    ) external {
        require(recipient != address(0), "ZERO_ADDRESS");

        withdraw(
            recipient, 
            withdrawalData,
            relayerFee
        );
        IERC20(token).approve(router, withdrawalData.amount - relayerFee);

        (bool success, bytes memory data) = address(router).call(params);

        if (success == false) {
            assembly {
                // Copy the returned error string to memory
                // and revert with it.
                revert(add(data,32),mload(data))
            }
        }

        uint256 amountOut = IERC20(tokenOut).balanceOf(address(this));
        _sendFundsWithRelayerFee(amountOut, tokenOut, recipient);

        emit Swap(tokenOut, withdrawalData.amount, amountOut);
    }

    /// @notice Generates a hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function hashRing(uint256 _amountToken, uint256 _ringIndex) internal view
        returns (bytes32)
    {
        uint256[2][MAX_RING_PARTICIPANT] memory publicKeys;
        uint256 receivedToken = _amountToken;

        Ring storage ring = rings[receivedToken][_ringIndex];

        for (uint8 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];

            unchecked {
                i++;
            }
        }

        (uint participants,, uint blockNum) = getRingPackedData(ring.packedRingData);

        bytes memory b = abi.encodePacked(
            blockhash(block.number - 1),
            blockNum,
            ring.amountDeposited,
            participants,
            publicKeys
        );

        return keccak256(b);
    }

    /// @notice Gets the hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function getRingHash(uint256 _amountToken, uint256 _ringIndex) public view
        returns (bytes32)
    {
        uint256 receivedToken = _amountToken;
        return rings[receivedToken][_ringIndex].ringHash;
    }

    /// @notice Gets the total amount of `token` in the ring
    function getPoolBalance() external view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    // =============================================================
    //                           UTILITIES
    // =============================================================


    /// @notice Gets the public keys of the ring
    /// @param amountToken The amount of `token` in the ring
    /// @param ringIndex The index of the ring
    function getPublicKeys(uint256 amountToken, uint256 ringIndex) public view
        returns (bytes32[2][MAX_RING_PARTICIPANT] memory)
    {
        bytes32[2][MAX_RING_PARTICIPANT] memory publicKeys;

        for (uint i = 0; i < MAX_RING_PARTICIPANT; i++) {
            publicKeys[i][0] = bytes32(rings[amountToken][ringIndex].publicKeys[i][0]);
            publicKeys[i][1] = bytes32(rings[amountToken][ringIndex].publicKeys[i][1]);
        }

        return publicKeys;
    }

    /// @notice Gets the unpacked, packed ring data
    /// @param packedData The packed ring data
    function getRingPackedData(uint packedData) public pure returns (uint256, uint256, uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return (
            p >> _BITWIDTH_PARTICIPANTS,
            p & _BITMASK_PARTICIPANTS,
            packedData & _BITMASK_BLOCK_NUM
        );
    }

    /// @notice Gets the number of participants that have withdrawn from the ring
    /// @param packedData The packed ring data
    function getWParticipant(uint256 packedData) public pure returns (uint256){
        return (packedData >> _BITWIDTH_BLOCK_NUM) >> _BITWIDTH_PARTICIPANTS;
    }

    /// @notice Gets the number of participants in the ring
    /// @param packedData The packed ring data
    function getParticipant(uint256 packedData) public pure returns (uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return p & _BITMASK_PARTICIPANTS;
    }

    /// @notice Gets the maximum number of participants in any ring
    function getRingMaxParticipants() external pure
        returns (uint256)
    {
        return MAX_RING_PARTICIPANT;
    }

    /// @notice Gets the lates ring index for `amountToken`
    /// @param amountToken The amount of `token` in the ring
    function getCurrentRingIndex(uint256 amountToken) external view
        returns (uint256)
    {
        return ringsNumber[amountToken];
    }
}