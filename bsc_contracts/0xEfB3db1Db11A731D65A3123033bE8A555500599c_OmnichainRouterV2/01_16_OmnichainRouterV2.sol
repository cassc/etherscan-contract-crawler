// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NonblockingLzApp.sol";
import "../interfaces/IOmniApp.sol";
import {IAxelarExecutable} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarExecutable.sol';
import {IAxelarGateway} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol';
import {IAxelarGasService} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol';
import {AddressToString, StringToAddress} from '../libs/StringAddressUtils.sol';
import "../interfaces/IOmnichainRouterV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OmnichainRouter
 * @author Omnisea
 * @custom:version 1.0
 * @notice Omnichain Router contract serves as an abstract layer and common interface for omnichain/cross-chain
 *         messaging protocols. Currently supports LayerZero and Axelar.
 */
contract OmnichainRouterV2 is IOmnichainRouterV2, NonblockingLzApp, IAxelarExecutable, ReentrancyGuard {
    using StringToAddress for string;
    using AddressToString for address;

    event LzReceived(uint16 srcId);
    event AxReceived(string srcChain, string srcOA);
    event Redirect(string fromChain, string toChain);
    event Redirected(string sourceChain, string toChain);

    enum PacketType {
        SEND_TO_APTOS,
        RECEIVE_FROM_APTOS
    }

    /**
     * @notice Single route containing omnichain protocol (provider) identifier and its chain mapping
     *
     * @dev provider: 'lz': LayerZero | 'ax': Axelar
     * @dev chainId: LayerZero .send() param
     * @dev dstChain: Axelar gateway.callContract() param
    */
    struct Route {
        string provider;
        uint16 chainId;
        string dstChain;
    }

    /**
     * @notice Updatable values for LayerZero params configuration
     *
     * @dev payInZRO: if false, user app pays the protocol fee in native token;
     * @dev zroPaymentAddress: the address of the ZRO token holder who would pay for the transaction
    */
    struct LZConfig {
        bool payInZRO;
        address zroPaymentAddress;
    }

    /**
     * @notice Data structure for router's call execution
     *
     * @dev dstChainName: Name of the destination chain
     * @dev payload: Data passed to the omReceive() function of the destination OA
     * @dev gas: Gas limit of the function execution on the destination chain
     * @dev user: Address of the user sending cross-chain message
     * @dev srcOA: Address of the OA on the source chain
     * @dev redirectFee: redirectFee Fee required to cover transaction fee on the redirectChain, if involved.
     *      Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
    */
    struct RouteCall {
        string dstChainName;
        bytes payload;
        uint gas;
        address user;
        address srcOA;
        uint256 redirectFee;
        bytes adapterParams;
    }

    error AxInitialized();

    mapping(string => Route) public chainNameToRoute;
    string public chainName;
    string public redirectChain;
    mapping(string => mapping(address => uint256)) public oaRedirectBudget;
    mapping(address => uint256) public srcOARedirectBudget;
    IAxelarGasService public axGasReceiver;
    mapping(string => address) internal axRemotes;
    LZConfig public lzConfig;

    /**
     * @notice Sets the cross-chain protocols contracts - LayerZero Endpoint, Axelar Gateway & GasReceiver, etc.
     * Also sets source chain name and name of the chain delegated for multi-protocol cross-chain messaging.
     * @notice Using LayerZero in the Non-blocking mode.
     *
     * @param _lzEndpoint Address of the LayerZero Endpoint contract.
     * @param _axGateway Address of the Axelar Gateway contract.
     * @param _axGasReceiver Address of the Axelar GasReceiver contract.
     */
    constructor(address _lzEndpoint, address _axGateway, address _axGasReceiver) NonblockingLzApp(_lzEndpoint) IAxelarExecutable(address(0))  {
        if (address(gateway) != address(0) || address(axGasReceiver) != address(0)) revert AxInitialized();
        chainName = "BSC";
        redirectChain = "Avalanche";
        axGasReceiver = IAxelarGasService(_axGasReceiver);
        gateway = IAxelarGateway(_axGateway);
    }

    /**
     * @notice Sets a route.
     *
     * @param provider Symbol of the cross-chain messaging protocol.
     * @param chainId Chain identifier used internally by LayerZero.
     * @param dstChain Chain identifier (name) used internally by Axelar.
     */
    function setRoute(string memory provider, uint16 chainId, string memory dstChain) external onlyOwner {
        Route memory route = Route(provider, chainId, dstChain);
        chainNameToRoute[dstChain] = route;
    }

    /**
     * @notice Creates the mapping between supported by Axelar chain's name and corresponding remote Router address.
     *
     * @param _chainName Name of the chain supported by Axelar.
     * @param _remote Address of the corresponding remote OmnichainRouter contract.
     */
    function setAxRemote(string memory _chainName, address _remote) external onlyOwner {
        axRemotes[_chainName] = _remote;
    }

    /**
     * @notice Checks the Axelar remote binding.
     *
     * @param _chainName Name of the chain supported by Axelar.
     * @param _remote Address of the corresponding remote OmnichainRouter contract.
     */
    function isAxRemote(string memory _chainName, address _remote) public view returns (bool) {
        return axRemotes[_chainName] == _remote;
    }

    function setLzConfig(LZConfig calldata _lzConfig) external onlyOwner {
        lzConfig = _lzConfig;
    }

    /**
     * @notice Checks if the direct route is present or redirection is required. If true, redirectChain won't be used.
     *
     * @param dstChainName Name of the destination chain.
     */
    function isDirectRoute(string memory dstChainName) public view returns (bool) {
        return bytes(chainNameToRoute[dstChainName].provider).length > 0;
    }

    /**
     * @notice Function used by third applications to delegate a cross-chain task to Router. Maps and sends the message using
     *         the underlying protocol matching the route.
     *
     * @param dstChainName Name of the remote chain.
     * @param dstOA Address of the remote Omnichain Application ("OA").
     * @param fnData Encoded payload with data passed to a remote omReceive() function.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param user Address of the user initiating the cross-chain task (for gas refund)
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     * @param adapterParams LayerZero Adapter Params
     */
    function send(string memory dstChainName, address dstOA, bytes memory fnData, uint gas, address user, uint256 redirectFee, bytes memory adapterParams) external override payable {
        bytes memory _payload = abi.encode(uint8(PacketType.SEND_TO_APTOS)); // abi.encode(uint8(PacketType.SEND_TO_APTOS), dstChainName, addressToBytes32(dstOA), fnData, gas, addressToBytes32(msg.sender), chainName, addressToBytes32(user), redirectFee);
        RouteCall memory params = RouteCall(dstChainName, _payload, gas, user, msg.sender, redirectFee, adapterParams);
        _route(params, false);
    }

    /**
     * @notice OmnichainRouter on the redirect chain is charged with redirection transaction fee. Omnichain Application
     *         needs to fund its budget to support redirections (multi-protocol messaging).
     *
     * @param srcChain Name of the source chain.
     * @param remoteOA Address of the remote Omnichain Application ("OA") that calls the redirect chain Router.
     */
    function fundOA(string memory srcChain, address remoteOA) external payable {
        require(keccak256(bytes(chainName)) == keccak256(bytes(redirectChain)));
        oaRedirectBudget[srcChain][remoteOA] += msg.value;
    }

    /**
     * @notice Router on source chain receives redirect fee on payable send() function call. This fee is accounted to srcOARedirectBudget.
     *         here, msg.sender is that srcOA. srcOA contract should implement this function and point the address below which manages redirection budget.
     *
     * @param redirectionBudgetManager Address pointed by the srcOA (msg.sender) executing this function. Responsible for funding srcOA redirection budget.
     */
    function withdrawOARedirectFees(address redirectionBudgetManager) external {
        require(srcOARedirectBudget[msg.sender] > 0);
        srcOARedirectBudget[msg.sender] = 0;
        (bool sent,) = payable(redirectionBudgetManager).call{value: srcOARedirectBudget[msg.sender]}("");
        require(sent, "NO_WITHDRAW");
    }

    /**
     * @notice Maps the route by received params containing source and destination chain names, and delegates
     *         the sending of the message to the matching protocol.
     *
     * @param params See {RouteCall} struct.
     */
    function _route(RouteCall memory params, bool isRedirected) internal {
        bool isRedirect = isDirectRoute(params.dstChainName) == false;
        if (isRedirect) {
            _validateAndAssignRedirectFee(params.srcOA, params.redirectFee);
            emit Redirect(chainName, params.dstChainName);
        }
        Route storage route = isRedirect ? chainNameToRoute[redirectChain] : chainNameToRoute[params.dstChainName];

        if (keccak256(bytes(route.provider)) == keccak256(bytes('lz'))) {
            _lzProcess(route.chainId, params, isRedirect, isRedirected);
            return;
        }
        _axProcess(route.dstChain, params, isRedirect, isRedirected);
    }

    /**
     * @notice Handles the cross-chain message sending by LayerZero.
     *
     * @param chainId Destination chain identifier used internally by LayerZero Endpoint.
     * @param params See {RouteCall} struct.
     * @param isRedirect Used to set the gas limit (default if true for delegating message to redirect chain).
     * @param isRedirected Sets if transaction is "redirection" from redirectChain to dstChain.
     */
    function _lzProcess(uint16 chainId, RouteCall memory params, bool isRedirect, bool isRedirected) internal {
        require(trustedRemoteLookup[chainId].length != 0, "LzSend: destination chain is not a trusted source.");

        if (isRedirected) {
            (uint messageFee,) = lzEndpoint.estimateFees(chainId, address(this), params.payload, false, params.adapterParams);
            lzEndpoint.send{value : messageFee}(chainId, this.getTrustedRemote(chainId), params.payload, payable(params.user), lzConfig.zroPaymentAddress, params.adapterParams);
            return;
        }
        lzEndpoint.send{value : (msg.value - params.redirectFee)}(chainId, this.getTrustedRemote(chainId), params.payload, payable(params.user), lzConfig.zroPaymentAddress, params.adapterParams);
    }

    /**
     * @notice Handles the cross-chain message sending by Axelar.
     *
     * @param dstChain Destination chain identifier (name) used internally by Axelar contracts.
     * @param params See {RouteCall} struct.
     * @param isRedirect Used to set the destination OA considering possible redirection.
     * @param isRedirected Sets if transaction is "redirection" from redirectChain to dstChain. Applies redirectFee.
     */
    function _axProcess(string memory dstChain, RouteCall memory params, bool isRedirect, bool isRedirected) internal {
        string memory dstStringAddress = isRedirect ? axRemotes[redirectChain].toString() : axRemotes[params.dstChainName].toString();

        if (isRedirected) {
            axGasReceiver.payNativeGasForContractCall{value : params.redirectFee}(address(this), dstChain, dstStringAddress, params.payload, params.user);
        } else {
            axGasReceiver.payNativeGasForContractCall{value : (msg.value - params.redirectFee)}(address(this), dstChain, dstStringAddress, params.payload, params.user);
        }
        gateway.callContract(dstChain, dstStringAddress, params.payload);
    }

    /**
     * @notice Handles the cross-chain message receive by LayerZero.
     *
     * @param srcChainId Source chain identifier used by LayerZero.
     * @param payload Encoded message data
     */
    function _nonblockingLzReceive(uint16 srcChainId, bytes memory, uint64, bytes memory payload) internal override {
        emit LzReceived(srcChainId);
        _processMessage(payload);
    }

    /**
     * @notice Handles the cross-chain message receive by Axelar.
     *
     * @param srcChain Source chain identifier (name) used by Axelar.
     * @param srcAddressString Address of the Router sending the message.
     * @param payload Encoded message data
     */
    function _execute(
        string memory srcChain,
        string memory srcAddressString,
        bytes calldata payload
    ) internal override {
        emit AxReceived(srcChain, srcAddressString);
        require(isAxRemote(srcChain, srcAddressString.toAddress()), 'NOT_AX_REMOTE');
        _processMessage(payload);
    }

    /**
     * @notice Processes a received message.
     *
     * @param payload Encoded message data
     */
    function _processMessage(bytes memory payload) internal nonReentrant {
        // TODO: (Must) Aptos has different decoding at: https://etherscan.io/address/0x50002cdfe7ccb0c41f519c6eb0653158d11cd907#code
        (string memory dstChainName, bytes memory dstOABytes, bytes memory fnData, uint gas, bytes memory srcOABytes, string memory srcChain, bytes memory userBytes, uint256 redirectFee)
        = abi.decode(payload, (string, bytes, bytes, uint, bytes, string, bytes, uint256));

        address dstOA = bytesToAddress(dstOABytes);
        address srcOA = bytesToAddress(srcOABytes);
        address user = bytesToAddress(userBytes);

        if (keccak256(bytes(dstChainName)) != keccak256(bytes(chainName))) {
            emit Redirected(srcChain, dstChainName);
            RouteCall memory params = RouteCall(dstChainName, payload, gas, user, srcOA, redirectFee, (new bytes(0)));
            require(isDirectRoute(dstChainName), "NO_REDIRECTED_ROUTE");
            _validateAndChargeOA(srcChain, params.srcOA, params.redirectFee);
            _route(params, true);

            return;
        }
        IOmniApp receiver = IOmniApp(dstOA);
        receiver.omReceive(fnData, srcOA, srcChain);
    }

    /**
     * @notice Validates the budget of the Omnichain Application ("OA"), Router's balance, and charges OA with redirection fee.
     *
     * @param srcChain Name of the source chain
     * @param remoteOA Address of the source OA
     * @param redirectFee Fee to be paid for the redirection by the OmnichainRouter contract. OA will be charged.
     */
    function _validateAndChargeOA(string memory srcChain, address remoteOA, uint256 redirectFee) internal {
        require(address(this).balance >= redirectFee, "ROUTER_NOT_FUNDED");
        require(oaRedirectBudget[srcChain][remoteOA] >= redirectFee, "OA_NOT_FUNDED");
        oaRedirectBudget[srcChain][remoteOA] -= redirectFee;
    }

    /**
     * @notice Validates the user's balance, and assigns redirection fee for OA redirections budget
     * @notice To be automated using native gas airdrop function in the future iteration
     *
     * @param srcOA Address of the Omnichain Application on the source chain
     * @param redirectFee Fee to be paid for the redirection by the OmnichainRouter contract. OA will be charged on destination.
     */
    function _validateAndAssignRedirectFee(address srcOA, uint256 redirectFee) internal {
        require(redirectFee > 0, "NO_REDIRECT_FEE");
        srcOARedirectBudget[srcOA] += redirectFee;
    }

    /**
     * @notice Returns cross-chain transaction fee calculated by LayerZero Endpoint contract.
     *
     * @param _chainId Destination chain identifier used internally by LayerZero.
     * @param _payload Encoded message data
     * @param _adapterParams LayerZero Adapter Params
     */
    function estimateFees(uint16 _chainId, bytes memory _payload, bytes memory _adapterParams) external view returns (uint) {
        (uint fee,) = lzEndpoint.estimateFees(_chainId, address(this), _payload, lzConfig.payInZRO, _adapterParams);
        return fee;
    }

    function addressToBytes32(address _address) internal pure returns (bytes32 _bytes32Address) {
        return bytes32(uint(uint160(_address)));
    }

    // TODO: (Must) Aptos has different decoding at: https://etherscan.io/address/0x50002cdfe7ccb0c41f519c6eb0653158d11cd907#code
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    receive() external payable {}
}