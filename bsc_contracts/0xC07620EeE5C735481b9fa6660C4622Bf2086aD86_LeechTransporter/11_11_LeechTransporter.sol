// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import "./interfaces/IAnyswapRouter.sol";
import "./interfaces/IMultichainV7Router.sol";
import "./interfaces/ILeechTransporter.sol";
import "./interfaces/ILeechSwapper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LeechTransporter is Ownable, ILeechTransporter {
    using SafeERC20 for IERC20;

    /**
    @notice Current EVM Chain Id
    */
    uint256 public immutable chainID;

    /**
    @notice Mapping for storing base tokens on different chains
    */
    mapping(uint256 => address) public chainToBaseToken;

    /**
    @notice Anyswap has a multiple versions of router live. So we need to define it for each token
    */
    mapping(address => uint256) public destinationTokenToRouterId;

    mapping(address => address) public destinationTokenToAnyToken;

    /**
    @notice Multichain router instances
    */
    IAnyswapRouter public anyswapV4Router = IAnyswapRouter(address(0));
    IAnyswapRouter public anyswapV6Router = IAnyswapRouter(address(0));
    IMultichainV7Router public multichainV7Router =
        IMultichainV7Router(address(0));

    /**
    @notice LeechSwapper contract instance
    */
    ILeechSwapper public swapper;

    /**
     * The constructor sets the `chainID` variable to the current chain ID
     *
     * @dev The `chainid()` opcode is used to get the chain ID of the current network
     * The resulting value is stored in the `chainID` variable for later use in the contract
     */
    constructor() {
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainID = _chainId;
    }

    /**
     * @notice This function requires that `swapper` is properly initialized
     * The function first converts `amount` to base token on the target chain
     * The `amount` is then bridged to destAddress on chain with id `destinationChainId`
     * The `AssetBridged` event is emitted after the bridging is successful
     *
     * @param destinationChainId The ID of the destination chain to send to
     * @param destAddress The address of the router on the destination chain
     * @param amount The amount of asset to send
     */
    function sendTo(
        uint256 destinationChainId,
        address destAddress,
        uint256 amount
    ) external override {
        if (address(swapper) == address(0)) revert("Init swapper");
        if (destAddress == address(0)) revert("Wrong argument");
        if (amount == 0) revert("Wrong argument");

        address[] memory path = new address[](2);

        path[0] = chainToBaseToken[chainID];
        path[1] = chainToBaseToken[destinationChainId];

        if (path[0] != path[1]) {
            _approveTokenIfNeeded(path[0], address(swapper));

            uint256[] memory swapedAmounts = swapper.swap(amount, path);
            uint256 amount = swapedAmounts[swapedAmounts.length - 1];
        }

        bridgeOut(path[1], amount, destinationChainId, destAddress);

        emit AssetBridged(destinationChainId, destAddress, amount);
    }

    /**
     * @notice Initializes the instance with the router addresses and the leech swapper contract address
     * @dev We don't apply zero address validation because not all versions could be active on the current chain
     * @param _anyswapV4Router Address of the AnySwap V4 router contract
     * @param _anyswapV6Router Address of the AnySwap V6 router contract
     * @param _multichainV7Router Address of the Multi-chain V7 router contract
     * @param _swapper Address of the leech swapper contract
     */
    function initTransporter(
        address _anyswapV4Router,
        address _anyswapV6Router,
        address _multichainV7Router,
        address _swapper
    ) external onlyOwner {
        anyswapV4Router = IAnyswapRouter(_anyswapV4Router);
        anyswapV6Router = IAnyswapRouter(_anyswapV6Router);
        multichainV7Router = IMultichainV7Router(_multichainV7Router);
        swapper = ILeechSwapper(_swapper);

        emit Initialized(
            _anyswapV4Router,
            _anyswapV6Router,
            _multichainV7Router,
            _swapper
        );
    }

    /**
     * Sets the base token for a given chain ID
     *
     * @notice This function is restricted to the contract owner only and can be executed using the `onlyOwner` modifier
     * The function maps the given `chainId` to its corresponding base token `tokenAddress`
     * and stores it in the `chainToBaseToken` mapping
     * @param chainId destination EVM chain Id
     * @param tokenAddress base token address on the destination chain
     */
    function setBaseToken(
        uint256 chainId,
        address tokenAddress
    ) external onlyOwner {
        if (chainId == 0 || tokenAddress == address(0))
            revert("Wrong argument");
        chainToBaseToken[chainId] = tokenAddress;
    }

    /**
     * Sets the router ID for a given token address
     *
     * @notice This function is restricted to the contract owner only and can be executed using the `onlyOwner` modifier
     * The function maps the given `tokenAddress` to its corresponding router ID `routerId`
     * and stores it in the `destinationTokenToRouterId` mapping
     * @param tokenAddress base token address on the destination chain
     * @param routerId id of the multichain router that should be used
     */
    function setRouterIdForToken(
        address tokenAddress,
        uint256 routerId
    ) external onlyOwner {
        if (routerId == 0 || tokenAddress == address(0))
            revert("Wrong argument");
        destinationTokenToRouterId[tokenAddress] = routerId;
    }

    function setAnyToken(
        address tokenAddress,
        address anyTokenAddress
    ) external onlyOwner {
        destinationTokenToAnyToken[tokenAddress] = anyTokenAddress;
    }

    /**
     * @dev Transfers the specified amount of a token to the specified destination token on another chain
     * @param _destinationToken Address of the destination token on the other chain
     * @param _bridgedAmount Amount of the source token to transfer
     * @param _destinationChainId ID of the destination chain
     * @param _destAddress Address of the router contract responsible for handling the transfer
     */
    function bridgeOut(
        address _destinationToken,
        uint256 _bridgedAmount,
        uint256 _destinationChainId,
        address _destAddress
    ) public {
        uint256 routerId = destinationTokenToRouterId[_destinationToken];

        if (routerId == 1) {
            if (address(anyswapV4Router) == address(0)) revert("Init router");

            _approveTokenIfNeeded(_destinationToken, address(anyswapV4Router));
            anyswapV4Router.anySwapOutUnderlying(
                destinationTokenToAnyToken[_destinationToken],
                _destAddress,
                _bridgedAmount,
                _destinationChainId
            );

            return;
        }

        if (routerId == 2) {
            if (address(anyswapV6Router) == address(0)) revert("Init router");

            _approveTokenIfNeeded(_destinationToken, address(anyswapV6Router));
            anyswapV6Router.anySwapOutUnderlying(
                destinationTokenToAnyToken[_destinationToken],
                _destAddress,
                _bridgedAmount,
                _destinationChainId
            );

            return;
        }

        if (routerId == 3) {
            if (address(multichainV7Router) == address(0))
                revert("Init router");

            _approveTokenIfNeeded(_destinationToken, address(multichainV7Router));
            string memory routerAddressStringify = _toAsciiString(_destAddress);
            multichainV7Router.anySwapOutUnderlying(
                destinationTokenToAnyToken[_destinationToken],
                routerAddressStringify,
                _bridgedAmount,
                _destinationChainId
            );

            return;
        }

        revert("No router inited");
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }


    /**
     * @dev Converts an Ethereum address to its corresponding ASCII string representation
     * @param x Ethereum address
     * @return ASCII string representation of the address
     */
    function _toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    /**
     * @dev Converts a hexadecimal character represented as a byte to its corresponding ASCII character
     * @param b Hexadecimal character represented as a byte
     * @return c ASCII character represented as a byte
     */
    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}