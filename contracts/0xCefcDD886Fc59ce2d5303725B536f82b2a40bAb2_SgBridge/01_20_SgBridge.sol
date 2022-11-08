//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {IStargateReceiver, IStargateRouter} from "./interfaces/IStargate.sol";
import {WardedLiving} from "./interfaces/WardedLiving.sol";

import "hardhat/console.sol";
import "./interfaces/ISgBridge.sol";

contract SgBridge is Initializable, UUPSUpgradeable, OwnableUpgradeable, IStargateReceiver, WardedLiving, ISgBridge {

    using SafeERC20 for IERC20;

    IStargateRouter public router;
    address public defaultBridgeToken;
    uint16 public currentChainId;

    struct Destination {
        address receiveContract;
        uint256 destinationPool;
    }

    mapping(uint16 => Destination) public supportedDestinations; //destination stargate_chainId => Destination struct
    mapping(address => uint256) public poolIds; // token address => Stargate poolIds for token

    function initialize(
        address stargateRouter_,
        uint16 currentChainId_
    ) public initializer {
        __Ownable_init();

        router = IStargateRouter(stargateRouter_);

        currentChainId = currentChainId_;
        relyOnSender();
        run();
    }

    function setCurrentChainId(uint16 newChainId) external auth {
        currentChainId = newChainId;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Add stargate pool here. See this table: https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    function setStargatePoolId(address token, uint256 poolId) external override auth {
        poolIds[token] = poolId;
        IERC20(token).approve(address(router), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        defaultBridgeToken = token;
    }

    // Set destination.
    // Chain id is here:https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    // Receiver is this contract deployed on the other chain
    // PoolId is picked from here https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    function setSupportedDestination(uint16 destChainId, address receiver, uint256 destPoolId) external override auth {
        supportedDestinations[destChainId] = Destination(receiver, destPoolId);
    }

    function isTokenSupported(address token) public override view returns (bool) {
        return true;
    }

    function isTokensSupported(address[] calldata tokens) public override view returns (bool[] memory) {
        bool[] memory response = new bool[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            response[i] = true;
        }
        return response;
    }

    function isPairsSupported(address[][] calldata tokens) public override view returns (bool[] memory) {
        bool[] memory response = new bool[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            response[i] = true;
        }
        return response;
    }

    function createPayload(
        address destAddress,
        address destToken,
        bytes calldata receiverPayload
    ) private pure returns (bytes memory) {
        return abi.encode(destAddress, destToken, receiverPayload);
    }

    function getLzParams() private pure returns (IStargateRouter.lzTxObj memory) {
        return IStargateRouter.lzTxObj({
        dstGasForCall : 500000, // extra gas, if calling smart contract,
        dstNativeAmount : 0, // amount of dust dropped in destination wallet
        //            dstNativeAddr: abi.encodePacked(destinationAddress) // destination wallet for dust
        dstNativeAddr : "0x8E0eeC5bCf1Ee6AB986321349ff4D08019e29918" // destination wallet for dust
        });
    }

    function estimateGasFee(address token,
        uint16 destChainId,
        bytes calldata destinationPayload
    ) public override view returns (uint256) {

        if (destChainId == currentChainId) {
            return 0;
        }

        Destination memory destSgBridge = supportedDestinations[destChainId];
        require(destSgBridge.receiveContract != address(0), "SgBridge/chain-not-supported");

        (uint256 fee,) = router.quoteLayerZeroFee(
            destChainId,
            1, //SWAP
            abi.encodePacked(destSgBridge.receiveContract, token),
            createPayload(token, token, destinationPayload),
            getLzParams()
        );
        return fee;
    }

    // To avoid stsck too deep errors.
    struct BridgeParams {
        address token;
        uint256 fee;
        uint256 amount;
        uint256 srcPoolId;
        uint16 destChainId;
        uint256 destinationPoolId;
        address destinationAddress;
        address destinationToken;
        address destinationContract;
    }

    function bridgeInternal(
        BridgeParams memory params,
        bytes calldata destinationPayload
    ) internal {

        bytes memory payload = createPayload(
            params.destinationAddress, params.destinationToken, destinationPayload
        );

        router.swap{value: params.fee }(
            params.destChainId,
            params.srcPoolId,
            params.destinationPoolId,
            payable(msg.sender),
            params.amount,
            0, //FIXME!!!
            getLzParams(),
            abi.encodePacked(params.destinationContract),
            payload
        );

        emit Bridge(msg.sender, params.destChainId, params.amount);
    }

    function bridge(address token,
        uint256 amount,
        uint16 destChainId,
        address destinationAddress,
        address destinationToken,
        address routerSrcChain,
        bytes memory srcRoutingCallData,
        bytes calldata dstChainCallData) external override live payable {

        //        require(isTokenSupported(token), "SgBridge/token-not-supported");

        uint256 fee = msg.value;

        if (srcRoutingCallData.length > 0) {
            swapRouter(token, amount, routerSrcChain, srcRoutingCallData);
        } else {
            if (token != address(0x0)) {
                IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            } else {
                fee = msg.value - amount;
            }
        }

        if (currentChainId == destChainId) {
            return;
        }
        Destination memory destination = supportedDestinations[destChainId];
        require(destination.receiveContract != address(0), "SgBridge/chain-not-supported");
        uint256 usdtAmount = IERC20(defaultBridgeToken).balanceOf(address(this));
        uint256 srcPoolId = poolIds[token];
        if (srcPoolId == 0) {//There are no stargate pool for this token => swap on DEX
//            usdtAmount = swap(token, defaultBridgeToken, amount, address(this));
            srcPoolId = poolIds[defaultBridgeToken];
        }

        bridgeInternal(
            BridgeParams(
                token,
                fee,
                usdtAmount,
                srcPoolId,
                destChainId,
                destination.destinationPool,
                destinationAddress,
                destinationToken,
                destination.receiveContract
            ),
            dstChainCallData
        );
    }

    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint _nonce,
        address _token,
        uint amountLD,
        bytes memory payload) override external {
        //only-stargate-router can call sgReceive!
        require(msg.sender == address(router), "SgBridge/Forbidden");

        (address _toAddr, address _tokenOut, bytes memory destPayload) = abi.decode(payload, (address, address, bytes));
        if (destPayload.length > 0) {
            IERC20(_token).approve(_toAddr, amountLD);
            externalCall(_token, _toAddr, amountLD, _chainId, destPayload);
            return;
        }

        IERC20(_token).transfer(_toAddr, amountLD);
        emit BridgeSuccess(_toAddr, _chainId, _tokenOut, amountLD);
    }

    function externalCall(
        address token,
        address receiver,
        uint256 amount,
        uint16 chainId,
        bytes memory destPayload) private {
//        IERC20(token).transfer(receiver, amount);
        (bool success, bytes memory response) = receiver.call(destPayload);
        if (!success) {
            revert(_getRevertMsg(response));
        }
        emit ExternalCallSuccess(receiver, chainId, token, amount);
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function swapRouter(
        address tokenA,
        uint256 amountA,
        address router,
        bytes memory callData
    ) public payable live override {
        if (tokenA != address(0x0) && IERC20(tokenA).allowance(address(this), router) < amountA) {
            IERC20(tokenA).approve(router, type(uint256).max);
        }
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Bridge/stf");
        (bool success, bytes memory returnValues) = router.call(callData);
        require(success, "Bridge/routing-failed!");
    }

    fallback() external payable {
        //do nothing
    }
}