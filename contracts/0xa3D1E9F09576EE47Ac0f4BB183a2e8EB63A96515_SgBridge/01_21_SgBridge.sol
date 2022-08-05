//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {Swapper} from "./interfaces/Swapper.sol";
import {IStargateReceiver, IStargateRouter} from "./interfaces/IStargate.sol";
import {WardedLiving} from "./interfaces/WardedLiving.sol";

import "hardhat/console.sol";
import "./interfaces/ISgBridge.sol";

contract SgBridge is Initializable, UUPSUpgradeable, OwnableUpgradeable, IStargateReceiver, WardedLiving, ISgBridge {

    using SafeERC20 for IERC20;

    Swapper public swapper;
    address public dex; //UNUSED
    address public factory; //UNUSED
    IStargateRouter public router;
    address public defaultBridgeToken;
    uint16 public currentChainId;

    struct Destination {
        address receiveContract;
        uint256 destinationPool;
    }

    mapping(uint16 => Destination) public supportedDestinations; //destination stargate_chainId => Destination struct
    mapping(address => uint256) public poolIds; // token address => Stargate poolIds for token

    address public quoter; //UNUSED

    function initialize(address swapperLib_,
        address stargateRouter_,
        uint16 currentChainId_
    ) public initializer {
        __Ownable_init();

        swapper = Swapper(swapperLib_);
        router = IStargateRouter(stargateRouter_);

        currentChainId = currentChainId_;
        relyOnSender();
        run();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Add stargate pool here. See this table: https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    function setStargatePoolId(address token, uint256 poolId) external override auth {
        poolIds[token] = poolId;
        IERC20(token).approve(address(router), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        defaultBridgeToken = token;
    }

    function setSwapper(address swapperLib_) external override auth {
        swapper = Swapper(swapperLib_);
    }

    // Set destination.
    // Chain id is here:https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    // Receiver is this contract deployed on the other chain
    // PoolId is picked from here https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    function setSupportedDestination(uint16 destChainId, address receiver, uint256 destPoolId) external override auth {
        supportedDestinations[destChainId] = Destination(receiver, destPoolId);
    }

    function isTokenSupported(address token) public override view returns (bool) {
        return swapper.isTokenSupported(defaultBridgeToken, token);
    }

    function isTokensSupported(address[] calldata tokens) public override view returns (bool[] memory) {
        return swapper.isTokensSupported(defaultBridgeToken, tokens);
    }

    function isPairsSupported(address[][] calldata tokens) public override view returns (bool[] memory) {
        return swapper.isPairsSupported(tokens);
    }

    function createPayload(address destAddress, address destToken) private returns (bytes memory) {
        bytes memory data;
        {
            data = abi.encode(destAddress, destToken);
        }
        return data;
    }

    function getLzParams(address destinationAddress) private pure returns (IStargateRouter.lzTxObj memory) {
        return IStargateRouter.lzTxObj({
        dstGasForCall : 500000, // extra gas, if calling smart contract,
        dstNativeAmount : 0, // amount of dust dropped in destination wallet
        //            dstNativeAddr: abi.encodePacked(destinationAddress) // destination wallet for dust
        dstNativeAddr : "0x8E0eeC5bCf1Ee6AB986321349ff4D08019e29918" // destination wallet for dust
        });
    }

    function estimateGasFee(address token,
        uint16 destChainId,
        address destinationAddress) public override view returns (uint256) {

        if (destChainId == currentChainId) {
            return 0;
        }

        Destination memory destSgBridge = supportedDestinations[destChainId];
        require(destSgBridge.receiveContract != address(0), "SgBridge/chain-not-supported");

        (uint256 fee,) = router.quoteLayerZeroFee(
            destChainId,
            1, //SWAP
            abi.encodePacked(destSgBridge.receiveContract, token),
            abi.encodePacked(destinationAddress),
            getLzParams(destinationAddress)
        );
        return fee;
    }

    function bridge(address token,
        uint256 amount,
        uint16 destChainId,
        address destinationAddress,
        address destinationToken) external override live payable {
        require(isTokenSupported(token), "SgBridge/token-not-supported");
        if (token != address(0x0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
        if (currentChainId == destChainId) {
            swap(token, destinationToken, amount, destinationAddress);
            return;
        }
        Destination memory destination = supportedDestinations[destChainId];
        require(destination.receiveContract != address(0), "SgBridge/chain-not-supported");

        uint256 usdtAmount = amount;
        uint256 srcPoolId = poolIds[token];
        if (srcPoolId == 0) {//There are no stargate pool for this token => swap on DEX
            usdtAmount = swap(token, defaultBridgeToken, amount, address(this));
            srcPoolId = poolIds[defaultBridgeToken];
        }

        bytes memory payload = createPayload(destinationAddress, destinationToken);
        router.swap{value: msg.value - amount }(
            destChainId,
            srcPoolId,
            destination.destinationPool,
            payable(msg.sender),
            usdtAmount,
            0, //usdtAmount - 10000000000000000000, FIXME!!!
            getLzParams(destinationAddress),
            abi.encodePacked(destination.receiveContract),
            payload
        );

        emit Bridge(msg.sender, destChainId, amount);
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

        (address _toAddr, address _tokenOut) = abi.decode(payload, (address, address));

        if (_tokenOut != _token) {
            (bool swapSuccess, uint256 amount) = _swap(_token, _tokenOut, amountLD, _toAddr);
            if (swapSuccess) {
                emit BridgeAndSwapSuccess(_toAddr, _chainId, _tokenOut, amount);
            } else {
                // send transfer _token/amountLD to msg.sender because the swap failed for some reason
                IERC20(_token).transfer(_toAddr, amountLD);
                emit BridgeSuccess(_toAddr, _chainId, _tokenOut, amountLD);
            }
        } else {
            IERC20(_token).transfer(_toAddr, amountLD);
            emit BridgeSuccess(_toAddr, _chainId, _tokenOut, amountLD);
        }
    }

    function _swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        address recipient
    ) internal returns (bool, uint256) {
        (bool success, bytes memory data) = address(swapper).call(
            abi.encodeWithSelector(swapper.swap.selector,
                tokenA, tokenB, amountA, recipient)
        );
        if (success) {
            return (success, abi.decode(data, (uint256)));
        } else {
            return (success, 0);
        }
    }

    function swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        address recipient
    ) public payable live returns (uint256) {
        if (tokenA != address(0x0)) {
            IERC20(tokenA).approve(address(swapper), amountA);
            return swapper.swap(tokenA, tokenB, amountA, recipient);
        } else {
            require(amountA <= msg.value, "SgBridge/not-enough-value");
            return swapper.swap{ value: amountA}(tokenA, tokenB, amountA, recipient);
        }
    }

    // do not used on-chain, gas inefficient!
    function quote(address tokenA, address tokenB, uint256 amountA) external override returns (uint256) {
        return swapper.quote(tokenA, tokenB, amountA);
    }
}