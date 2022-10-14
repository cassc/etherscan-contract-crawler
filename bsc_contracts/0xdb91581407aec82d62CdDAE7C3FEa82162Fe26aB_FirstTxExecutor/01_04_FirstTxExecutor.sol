// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FirstTxExecutor {
    using SafeERC20 for IERC20;

    event FirstPartOfSwapExecuted(
        uint256 destNetworkId,
        address destTokenAddress,
        uint256 destAmount,
        address destUserAddress,
        uint256 slippage
    );

    event DirectUSDCTransfer(address userAddress, uint256 amount, address smartWallet);

    event CCSmartWalletAddressUpdated(address oldAddress, address newAddress);

    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public constant AUGUSTUS_SWAPPER = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    address public ccSmartWallet = 0xb4fDA86d41885ecE3672fD512446D75772EDb755;

    address public currentAdmin;

    mapping(uint256 => address) internal usdcByChainId;

    modifier onlyAdmin() {
        require(msg.sender == currentAdmin, "caller is not an admin");
        _;
    }

    /**
     * @notice init usdc addresses for all supported networks
     * @dev it's important to pass elements in arrays in the same order. Example ([usdcMainnetAddress, usdcBscAddress], [1, 56]).
     * Also, two arrays have to have the same length.
     *
     * @param usdcAddresses array of usdc in supported networks
     * @param chainIds array of networks ids
     * @param admin gnosis safe admin address
     */
    constructor(
        address[] memory usdcAddresses,
        uint256[] memory chainIds,
        address admin
    ) {
        require(usdcAddresses.length == chainIds.length, "arrays length is not the same");
        for (uint256 i = 0; i < chainIds.length; i++) {
            usdcByChainId[chainIds[i]] = usdcAddresses[i];
        }
        currentAdmin = admin;
    }

    /**
     * @notice it's type of arbitrary tx. Only transaction called by admin can be executed
     *
     * @param newAddress new address of new admin
     */
    function updateAdmin(address newAddress) public onlyAdmin {
        address oldAdmin = currentAdmin;
        currentAdmin = newAddress;
        emit AdminUpdated(oldAdmin, newAddress);
    }

    /**
     * @notice it's type of arbitrary tx. Only transaction called by admin can be executed
     *
     * @param newAddress new address of new smart wallet
     */
    function updateSmartWallet(address newAddress) public onlyAdmin {
        address oldSmartWallet = ccSmartWallet;
        ccSmartWallet = newAddress;
        emit CCSmartWalletAddressUpdated(oldSmartWallet, newAddress);
    }

    /**
     * @notice it calls in case when user wants to swap not USDC token. Works as with native as with ERC-20
     *
     * @param callData encoded calldata of the swap
     * @param token address of src token
     * @param amount amount of the src token to be swaped during cross chain swap
     * @param destNetworkId chain id of destinational network in cross chain swap
     * @param destTokenAddress address of the token that user wants to receive in result of the swap
     * @param destAmount predicted amount of the dest token
     * @param destUserAddress user address where user wants to send his dest token in dest network
     * @param slippageInBP allowed slippage during the cross chain swap
     */
    function executeFirstSwap(
        bytes calldata callData,
        address token,
        uint256 amount,
        uint256 destNetworkId,
        address destTokenAddress,
        uint256 destAmount,
        address destUserAddress,
        uint256 slippageInBP
    ) public payable {
        require(token != address(0), "token address is zero address");
        if (usdcByChainId[block.chainid] == token) {
            IERC20(token).safeTransferFrom(msg.sender, ccSmartWallet, amount);

            emit DirectUSDCTransfer(msg.sender, amount, ccSmartWallet);
        } else {
            if (token != NATIVE_TOKEN) {
                IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
                IERC20(token).approve(TOKEN_TRANSFER_PROXY, amount);
            }

            (bool success, ) = AUGUSTUS_SWAPPER.call{value: msg.value}(callData);

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
        emit FirstPartOfSwapExecuted(destNetworkId, destTokenAddress, destAmount, destUserAddress, slippageInBP);
    }
}