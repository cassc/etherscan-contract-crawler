// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../base/BaseProxyContract.sol";
import "../../interfaces/IRangoAcross.sol";
import "../../interfaces/Interchain.sol";
import "../../interfaces/IRangoHop.sol";
import "../../interfaces/IRangoHyphen.sol";
import "../../interfaces/IRangoThorchain.sol";
import "../../interfaces/IRangoMultichain.sol";
import "../../interfaces/IRangoSynapse.sol";
import "../../interfaces/IRangoStargate.sol";
import "../../interfaces/IRangoCBridge.sol";
import "../../interfaces/IRangoSymbiosis.sol";
import "../../interfaces/IRangoSatellite.sol";
import "../../interfaces/IRangoVoyager.sol";

/// TODO:
// Arbitrum Bridge
// Avalanche Bridge
// Optimism Bridge
// Polygon Bridge
// Rainbow Bridge
// Satellite
// Sifchain
// Wormhole
// allbridge
// symbiosis
// router protocol
// Poly network

/// @title The main contract that users interact with in the source chain
/// @author Uchiha Sasuke
/// @notice It contains all the required functions to swap on-chain or swap + bridge or swap + bridge + swap initiation in a single step
/// @dev To support a new bridge, it inherits from a proxy with the name of that bridge which adds extra function for that specific bridge
/// @dev There are some extra refund functions for admin to get the money back in case of any unwanted problem
/// @dev This contract is being seen via a transparent proxy from openzeppelin
contract RangoV1 is BaseProxyContract {

    /// @notice Initializes the state of all sub bridges contracts that RangoV1 inherited from
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    /// @param _feeContractAddress Address of wallet that receives Rango fees
    /// @dev It is the initializer function of proxy pattern, and is equivalent to constructor for normal contracts
    function initialize(
        address _weth,
        address payable _feeContractAddress
    ) public initializer {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        
        baseProxyStorage.WETH = _weth;
        baseProxyStorage.feeContractAddress = _feeContractAddress;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Enables the contract to receive native ETH token from other contracts including WETH contract
    receive() external payable { }

    struct BridgesProxyStorage {
        address across;
        address cBridge;
        address hop;
        address hyphen;
        address multichain;
        address stargate;
        address synapse;
        address thorchain;
        address symbiosis;
        address satellite;
        address voyager;

    }

    enum BridgeType { Across, CBridge, Hop, Hyphen, Multichain, Stargate, Synapse, Thorchain, Symbiosis, Satellite, Voyager }

    /// @notice Notifies that a bridge contract address is updated
    /// @param _oldAddress The previous deployed address
    /// @param _newAddress The new deployed address
    /// @param _bridgeType The type of updated bridge
    event BridgeAddressUpdated(address _oldAddress, address _newAddress, BridgeType _bridgeType);

    /// @notice Updates the address of deployed bridge contract
    /// @param _address The address
    function updateBridgeProxyAddress(address _address, BridgeType _bridgeType) external onlyOwner {
        address oldAddress = getProxyAddress(_bridgeType);
        setProxyAddress(_bridgeType, _address);

        emit BridgeAddressUpdated(oldAddress, _address, _bridgeType);
    }

    /// @notice Returns the list of valid Rango contracts that can call other contracts for the security purpose
    /// @dev This contains the contracts that can call others via messaging protocols, and excludes DEX-only contracts such as Thorchain
    /// @return List of addresses of Rango contracts that can call other contracts
    function getValidRangoContracts() external view returns (address[] memory) {
        BridgesProxyStorage memory s = getBridgesStorage();

        address[] memory whitelist = new address[](12);
        whitelist[0] = address(this);
        whitelist[1] = s.across;
        whitelist[2] = s.cBridge;
        whitelist[3] = s.hop;
        whitelist[4] = s.hyphen;
        whitelist[5] = s.multichain;
        whitelist[6] = s.stargate;
        whitelist[7] = s.synapse;
        whitelist[8] = s.thorchain;
        whitelist[9] = s.symbiosis;
        whitelist[10] = s.satellite;
        whitelist[11] = s.voyager;

        return whitelist;
    }

    function getProxyAddress(BridgeType bridgeType) public pure returns(address) {
        BridgesProxyStorage memory s = getBridgesStorage();
        if (bridgeType == BridgeType.Across) return s.across;
        if (bridgeType == BridgeType.CBridge) return s.cBridge;
        if (bridgeType == BridgeType.Hop) return s.hop;
        if (bridgeType == BridgeType.Hyphen) return s.hyphen;
        if (bridgeType == BridgeType.Multichain) return s.multichain;
        if (bridgeType == BridgeType.Stargate) return s.stargate;
        if (bridgeType == BridgeType.Synapse) return s.synapse;
        if (bridgeType == BridgeType.Thorchain) return s.thorchain;
        if (bridgeType == BridgeType.Symbiosis) return s.symbiosis;
        if (bridgeType == BridgeType.Satellite) return s.satellite;
        if (bridgeType == BridgeType.Voyager) return s.voyager;

        revert("Unsupported bridge type");
    }

    function setProxyAddress(BridgeType bridgeType, address _newAddress) internal {
        BridgesProxyStorage storage s = getBridgesStorage();
        if (bridgeType == BridgeType.Across) s.across = _newAddress;
        if (bridgeType == BridgeType.CBridge) s.cBridge = _newAddress;
        if (bridgeType == BridgeType.Hop) s.hop = _newAddress;
        if (bridgeType == BridgeType.Hyphen) s.hyphen = _newAddress;
        if (bridgeType == BridgeType.Multichain) s.multichain = _newAddress;
        if (bridgeType == BridgeType.Stargate) s.stargate = _newAddress;
        if (bridgeType == BridgeType.Synapse) s.synapse = _newAddress;
        if (bridgeType == BridgeType.Thorchain) s.thorchain = _newAddress;
        if (bridgeType == BridgeType.Symbiosis) s.symbiosis =_newAddress;
        if (bridgeType == BridgeType.Satellite) s.satellite = _newAddress;
        if (bridgeType == BridgeType.Voyager) s.voyager = _newAddress;
    }

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    /// @dev hex is keccak256("exchange.rango.bridges.proxy")
    function getBridgesStorage() internal pure returns (BridgesProxyStorage storage s) {
        bytes32 namespace = hex"1ed014b447bfe01bc8cf4e9aa355dee866801d51ab06e08144ccd58f6177a3ad";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice Does a simple on-chain swap
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param nativeOut indicates that the output of swaps must be a native token
    /// @return The byte array result of all DEX calls
    function onChainSwaps(
        SwapRequest memory request,
        Call[] calldata calls,
        bool nativeOut
    ) external payable whenNotPaused nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = onChainSwapsInternal(request, calls);

        _sendToken(request.toToken, outputAmount, msg.sender, nativeOut, false);
        return result;
    }

    /// @notice Does a simple on-chain swap
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param nativeOut indicates that the output of swaps must be a native token
    /// @return The byte array result of all DEX calls
    function onChainSwapsWithReceiver(
        SwapRequest memory request,
        Call[] calldata calls,
        bool nativeOut,
        address receiver
    ) external payable whenNotPaused nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = onChainSwapsInternal(request, calls);

        _sendToken(request.toToken, outputAmount, receiver, nativeOut, false);
        return result;
    }

    /// @notice Executes a DEX (arbitrary) call + a Across bridge call
    /// @dev The bridge part is handled in the RangoAcross.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function acrossBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoAcross.AcrossBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Across);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoAcross(a).acrossBridge{value: value}(request.toToken, out, bridgeRequest);
    }

    /// @notice Executes a DEX (arbitrary) call + a cBridge send function
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param _receiver The receiver address in the destination chain
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @dev The cbridge part is handled in the RangoCBridge.sol contract
    /// @dev If this function is success, user will automatically receive the fund in the destination in his/her wallet (_receiver)
    /// @dev If bridge is out of liquidity somehow after submiting this transaction and success, user must sign a refund transaction which is not currently present here, will be supported soon
    function cBridgeSend(
        SwapRequest memory request,
        Call[] calldata calls,

        // cbridge params
        address _receiver,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.CBridge);
        (uint out, ) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoCBridge(a).send(_receiver, request.toToken, out, _dstChainId, _nonce, _maxSlippage);
    }

    /// @notice Executes a DEX (arbitrary) call + a cBridge IM function
    /// @dev The cbridge part is handled in the RangoCBridge.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param _receiverContract Our RangoCbridge.sol contract in the destination chain that will handle the destination logic
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @param _sgnFee The fee amount (in native token) that cBridge IM charges for delivering the message
    /// @param imMessage Our custom interchain message that contains all the required info for the RangoCBridge.sol on the destination
    /// @dev The msg.value should at least be _sgnFee + (input + fee + affiliate) if input is native token
    /**
     * @dev Here is the overall flow for a cross-chain dApp that integrates Rango + cBridgeIM:
     * Example case: RangoSea is an imaginary cross-chain OpenSea that users can lock their NFT on BSC to get 100 BNB
     * and convert it to FTM to buy another NFT there, all in one TX.
     * RangoSea contract = RS
     * Rango contract = R
     *
     * 1. RangoSea server asks Rango for a quote of 100 BSC.BNB to Fantom.FTM and embeds the message (imMessage.dAppMessage) that should be received by RS on destination
     * 2. User signs sellNFTandBuyCrosschain on RS
     * 3. RS executes their own logic and locks the NFT, gets 100 BNB and calls R with the hex from step 1 (which is cBridgeIM function call)
     * 4. R on source chain does the required swap/bridge
     * 5. R on destination receives the message via Celer network (by calling RangoCBridge.executeMessageWithTransfer on dest) and does other Rango internal stuff on destination to have the final FTM
     * 6. R on dest sends fund to RS on dest and calls their handler function for message handling and passes imMessage.dAppMessage to it
     * 7. RS on destination has the money and the message it needs to buy the NFT on destination and if it is still available it will be purchased
     *
     * Failure scenarios:
     * If cBridge does not have enough liquidity later:
     * 1. Celer network will call (RangoCBridge on source chain).executeMessageWithTransferRefund function
     * 2. RangoCbridge will refund money to the RS contract on source and ask it to handle refund to their own users
     *
     * If something on the destination fails:
     * 1. Celer network will call (RangoCBridge on dest chain).executeMessageWithTransferFallback function
     * 2. R on dest sends fund to RS on dest with refund reason, again RS should send it to your user if you like
     *
     * Hint: The dAppMessage part is arbitrary, if it's not set. The scenario is the same as above but without RS being in. In this case Rango will refund to the end-user.
     * Here is the celer IM docs: https://im-docs.celer.network/
     */
    function cBridgeIM(
        SwapRequest memory request,
        Call[] calldata calls,

        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        Interchain.RangoInterChainMessage memory imMessage
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.CBridge);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, _sgnFee);

        IRangoCBridge(a).cBridgeIM{value: value}(
            request.toToken,
            out,
            _receiverContract,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _sgnFee,
            imMessage
        );
    }


    /// @notice Executes a DEX (arbitrary) call + a Hop bridge call
    /// @dev The bridge part is handled in the RangoHop.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function hopBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoHop.HopRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Hop);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);

        IRangoHop(a).hopBridge{value: value}(bridgeRequest, request.toToken, out);
    }

    /// @notice Executes a DEX (arbitrary) call + a hyphen bridge function
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest data related to hyphen bridge
    /// @dev The hyphen bridge part is handled in the RangoHyphen.sol contract
    /// @dev If this function is a success, user will automatically receive the fund in the destination in their wallet (_receiver)
    function hyphenBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoHyphen.HyphenBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Hyphen);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);

        IRangoHyphen(a).hyphenBridge{value: value}(bridgeRequest, request.toToken, out);
    }

    /// @notice Executes a DEX (arbitrary) call + a MultichainOrg bridge call
    /// @dev The cbridge part is handled in the RangoMultichain.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function multichainBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoMultichain.MultichainBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Multichain);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoMultichain(a).multichainBridge{value: value}(request.toToken, out, bridgeRequest);
    }

    function stargateSwap(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoStargate.StargateRequest memory stargateRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Stargate);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, stargateRequest._stgFee);
        IRangoStargate(a).stargateSwap{value: value}(request.toToken, out, stargateRequest);
    }

    /// @notice Executes a DEX (arbitrary) call + a Synapse bridge call
    /// @dev The Synapse part is handled in the RangoSynapse.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function synapseBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoSynapse.SynapseBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Synapse);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoSynapse(a).synapseBridge{value : value}(request.toToken, out, bridgeRequest);
    }

    /// @notice Swap tokens if necessary, then pass it to RangoThorchain
    /// @dev Swap tokens if necessary, then pass it to RangoThorchain. If no swap is required (calls.length==0) the provided token is passed to RangoThorchain without change.
    /// @param request The swap information used to check input and output token addresses and balances, as well as the fees if any. Together with calls param, determines the swap logic before passing to Thorchain.
    /// @param calls The contract call data that is used to swap (can be empty if no swap is needed). Together with request param, determines the swap logic before passing to Thorchain.
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function swapInToThorchain(
        SwapRequest memory request,
        Call[] calldata calls,

        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Thorchain);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);

        IRangoThorchain(a).swapInToThorchain{value : value}(
            request.toToken,
            out,
            tcRouter,
            tcVault,
            thorchainMemo,
            expiration
        );
    }

    /// @notice Executes a DEX call + a Symbiosis bridge call + a Dex call
    /// @dev The Symbiosis part is handled in the RangoSymbiosis.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function symbiosisBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoSymbiosis.SymbiosisBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Symbiosis);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoSymbiosis(a).symbiosisBridge{value : value}(
            request.toToken, out, bridgeRequest
        );
    }

    /// @notice Executes a DEX (arbitrary) call + a Satellite bridge call
    /// @dev The Satellite part is handled in the RangoSatellite.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function satelliteBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoSatellite.SatelliteBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Satellite);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoSatellite(a).satelliteBridge{value : msg.value }(request.toToken, out, bridgeRequest);
    } 
    
    function voyagerBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoVoyager.VoyagerBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {

        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        require(bridgeRequest.feeTokenAddress == baseProxyStorage.WETH,
            "Fee is only acceptable in native token"
        );

        address a = getProxyAddress(BridgeType.Voyager);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, bridgeRequest.feeAmount);

        IRangoVoyager(a).voyagerBridge{value : value}(request.toToken, out, bridgeRequest);
    }

}