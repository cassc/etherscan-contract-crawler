// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../base/BaseProxyContract.sol";
import "../../interfaces/IRangoVoyager.sol";
import "../../interfaces/IVoyager.sol";
import "../base/BaseInterchainContract.sol";

contract RangoVoyager is IRangoVoyager, BaseInterchainContract {

    address public routerAddress;
    address public nativeWrappedAddress;

    /// @notice Emits when the Voyager address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event RouterAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Emits when Voyager deposit process is done
    event VoyagerDepositETH(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes data,
        address feeTokenAddress
    );

    /// @notice update whitelisted router
    /// @param _address router
    function updateVoyagerRouters(address _address) public onlyOwner {
        updateRouterAddressInternal(_address);
    }

    /// @notice The constructor of this contract that receives WETH address and initiates the settings
    /// @param _weth The address of WETH, WBNB, etc of the current network
    function initialize(address _weth, address _address) public initializer {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        baseStorage.WETH = _weth;
        nativeWrappedAddress = _weth;

        updateRouterAddressInternal(_address);

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function voyagerBridge(
        address fromToken,
        uint256 amount,
        VoyagerBridgeRequest calldata request
    ) external override payable whenNotPaused nonReentrant {
        IVoyager voyager = IVoyager(routerAddress);
        /*
                         (
                uint256 isDestNative,
                uint256 lenRecipientAddress,
                uint256 lenSrcTokenAddress,
                uint256 lenDestTokenAddress,
                uint256 widgetID
                ) = abi.decode(request.data, (uint256, uint256, uint256, uint256, uint256));

                uint256 index = 160;
                bytes memory recipient = bytes(request.data[index:index + lenRecipientAddress]);

                index = index + lenRecipientAddress;
                bytes memory srcToken = bytes(request.data[index:index + lenSrcTokenAddress]);

                index = index + lenSrcTokenAddress;
                bytes memory destStableToken = bytes(request.data[index:index + lenDestTokenAddress]);

                index = index + lenDestTokenAddress;
                bytes memory destToken = bytes(request.data[index:index + lenDestTokenAddress]);
        */

        if (fromToken != ETH) {
            approve(fromToken, request.reserveContract, amount);
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(fromToken), msg.sender, address(this), amount);
        }
        approve(request.feeTokenAddress, request.reserveContract, msg.value);
        // IWETH(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83).deposit{value: msg.value}();

        bytes memory encodedParams = bytes.concat(
            abi.encode(
                amount,
                amount,
                request.dstTokenAmount,
                request.dstTokenAmount
            ), request.data
        );

        uint256[] memory flags;
        address[] memory path;
        bytes[] memory dataTx;

        voyager.depositETH{value: msg.value}(
            request.voyagerDestinationChainId,
            request.resourceID,
            encodedParams,
            flags, path, dataTx,
            request.feeTokenAddress
        );

        emit VoyagerDepositETH(
            request.voyagerDestinationChainId,
            request.resourceID,
            encodedParams,
            request.feeTokenAddress
        );

    }

    function updateRouterAddressInternal(address _address) private {
        address oldAddress = routerAddress;
        routerAddress = _address;

        emit RouterAddressUpdated(oldAddress, _address);
    }

}