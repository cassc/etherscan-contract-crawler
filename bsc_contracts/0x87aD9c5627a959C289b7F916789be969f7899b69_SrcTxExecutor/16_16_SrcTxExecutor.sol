// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract SrcTxExecutor is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event SrcCrossSwap(
        address srcToken,
        uint256 srcAmount,
        uint256 destChainId,
        address destToken,
        uint256 minDestAmount,
        address destUser,
        uint256 usdcIncome
    );

    event SrcMultichainSwap(
        address srcToken,
        uint256 srcAmount,
        uint256 destChainId,
        address destToken,
        uint256 minDestAmount,
        address destUser
    );

    event CCSmartWalletAddressUpdated(address oldAddress, address newAddress);

    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AUGUSTUS_SWAPPER = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;
    address public ccSmartWallet;

    mapping(uint256 => address) public usdcByChainId;
    mapping(uint256 => address) public routerByChainId;
    mapping(address => address) public anyUsdcByRealUsdc;

    /**
     * @notice init usdc addresses for all supported chains
     * @dev it's important to pass elements in arrays in the same order. Example ([usdcMainnetAddress, usdcBscAddress], [1, 56]).
     * Also, two arrays have to have the same length.
     *
     * @param usdcAddresses array of usdc in supported chains
     * @param anyUsdcAddresses array of multichain any usdc
     * @param routerAddresses array of multichain router V6 addreses in supported chains
     * @param chainIds array of chain ids
     * @param _owner gnosis safe admin address
     */
    function initialize(
        address[] memory usdcAddresses,
        address[] memory anyUsdcAddresses,
        address[] memory routerAddresses,
        uint256[] memory chainIds,
        address _owner
    ) public initializer {
        __Ownable_init();
        _transferOwnership(_owner);

        require(usdcAddresses.length == chainIds.length, "Construstor params(usdc) length is not the same");
        require(routerAddresses.length == chainIds.length, "Construstor params(router) length is not the same");
        for (uint256 i = 0; i < chainIds.length; i++) {
            anyUsdcByRealUsdc[usdcAddresses[i]] = anyUsdcAddresses[i];
            usdcByChainId[chainIds[i]] = usdcAddresses[i];
            routerByChainId[chainIds[i]] = routerAddresses[i];
        }
    }

    /**
     * @dev required by the OZ UUPS module
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice it's type of arbitrary tx. Only transaction called by admin can be executed
     *
     * @param newAddress new address of new smart wallet
     */
    function updateSmartWallet(address newAddress) public onlyOwner {
        emit CCSmartWalletAddressUpdated(ccSmartWallet, newAddress);
        ccSmartWallet = newAddress;
    }

    /**
     * @notice initCrossSwap
     *
     * @param callData encoded calldata of the src swap
     * @param srcToken address of src token
     * @param srcAmount amount of the src token to be swaped during cross chain swap
     * @param destChainId chainId of destinational chain in cross chain swap
     * @param destToken address of the token that user wants to receive in result of the swap
     * @param minDestAmount min amount of the dest token
     * @param destUser user address where user wants to send his dest token in dest chain
     */
    function initCrossSwap(
        bytes calldata callData,
        address srcToken,
        uint256 srcAmount,
        uint256 destChainId,
        address destToken,
        uint256 minDestAmount,
        address destUser
    ) public payable {
        uint256 usdcBalanceBeforeSwap = IERC20(usdcByChainId[block.chainid]).balanceOf(ccSmartWallet);

        executeSrcSwap(callData, srcToken, srcAmount, ccSmartWallet);

        uint256 usdcBalanceAfterSwap = IERC20(usdcByChainId[block.chainid]).balanceOf(ccSmartWallet);
        uint256 usdcIncome = usdcBalanceAfterSwap - usdcBalanceBeforeSwap;
        require(usdcIncome > 0, "USDC income should be positive");

        emit SrcCrossSwap(srcToken, srcAmount, destChainId, destToken, minDestAmount, destUser, usdcIncome);
    }

    /**
     * @notice initCrossSwap
     *
     * @param swapCalldata encoded calldata of the src swap
     * @param srcToken address of src token
     * @param srcAmount amount of the src token to be swaped during cross chain swap
     * @param destChainId chainId of destinational chain in cross chain swap
     * @param destToken address of the token that user wants to receive in result of the swap
     * @param minDestAmount min amount of the dest token
     * @param destUser user address where user wants to send his dest token in dest chain
     */
    function initMultichainSwap(
        bytes calldata swapCalldata,
        address srcToken,
        uint256 srcAmount,
        uint256 destChainId,
        address destToken,
        uint256 minDestAmount,
        address destUser
    ) public payable {
        uint256 usdcBalanceBeforeSwap = IERC20Upgradeable(usdcByChainId[block.chainid]).balanceOf(address(this));

        executeSrcSwap(swapCalldata, srcToken, srcAmount, address(this));

        uint256 usdcBalanceAfterSwap = IERC20Upgradeable(usdcByChainId[block.chainid]).balanceOf(address(this));
        uint256 usdcIncome = usdcBalanceAfterSwap - usdcBalanceBeforeSwap;

        executeViaMultichain(anyUsdcByRealUsdc[usdcByChainId[block.chainid]], ccSmartWallet, usdcIncome, destChainId);

        emit SrcMultichainSwap(srcToken, srcAmount, destChainId, destToken, minDestAmount, destUser);
    }

    function executeViaMultichain(
        address srcToken,
        address to,
        uint256 srcAmount,
        uint256 destChainId
    ) internal {
        IERC20Upgradeable(usdcByChainId[block.chainid]).approve(routerByChainId[block.chainid], srcAmount);
        Router(routerByChainId[block.chainid]).anySwapOutUnderlying(srcToken, to, srcAmount, destChainId);
    }

    /**
     * @notice executeSrcSwap
     *
     * @param callData encoded calldata of the swap
     * @param srcToken address of src token
     * @param srcAmount amount of the src token to be swaped during cross chain swap
     */
    function executeSrcSwap(
        bytes calldata callData,
        address srcToken,
        uint256 srcAmount,
        address to
    ) internal {
        if (usdcByChainId[block.chainid] == srcToken) {
            IERC20Upgradeable(srcToken).safeTransferFrom(msg.sender, to, srcAmount);
        } else {
            if (srcToken != NATIVE_TOKEN) {
                IERC20Upgradeable(srcToken).safeTransferFrom(msg.sender, address(this), srcAmount);
                IERC20Upgradeable(srcToken).approve(TOKEN_TRANSFER_PROXY, srcAmount);
            }

            (bool success, ) = AUGUSTUS_SWAPPER.call{ value: msg.value }(callData);

            /** @dev assembly allows to get tx failure reason here*/
            if (success == false) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        }
    }
}