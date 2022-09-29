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

    event CCSmartWalletAddressUpdated(address oldAddress, address newAddress);

    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public constant AUGUSTUS_SWAPPER = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    address public ccSmartWallet = 0xdb92C94a0e8295E54792F22dcE6620FB38a91980;

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
     * @param updateMode can be "admin" or "smartWallet". It helps to detect what type of action need to be done in this arbitrary tx
     * @param newAdminOrSmartWallet new address of smart wallet or new admin
     */
    function updateAdminOrSmartWallet(string calldata updateMode, address newAdminOrSmartWallet) public onlyAdmin {
        require(
            keccak256(bytes(updateMode)) == keccak256(bytes("admin")) ||
                keccak256(bytes(updateMode)) == keccak256(bytes("smartWallet")),
            "Update mode is not correct"
        );
        if (keccak256(bytes(updateMode)) == keccak256(bytes("admin"))) {
            address oldAdmin = currentAdmin;
            currentAdmin = newAdminOrSmartWallet;
            emit AdminUpdated(oldAdmin, newAdminOrSmartWallet);
        }
        if (keccak256(bytes(updateMode)) == keccak256(bytes("smartWallet"))) {
            address oldSmartWallet = ccSmartWallet;
            ccSmartWallet = newAdminOrSmartWallet;
            emit CCSmartWalletAddressUpdated(oldSmartWallet, newAdminOrSmartWallet);
        }
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
    ) public payable returns (bool txStatus, bytes memory data) {
        require(token != address(0), "token address is zero address");
        if (usdcByChainId[block.chainid] == token) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(token).safeTransfer(ccSmartWallet, amount);

            emit FirstPartOfSwapExecuted(destNetworkId, destTokenAddress, destAmount, destUserAddress, slippageInBP);
        } else {
            if (token != NATIVE_TOKEN) {
                IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
                IERC20(token).approve(TOKEN_TRANSFER_PROXY, amount);
            }

            (bool success, bytes memory txData) = AUGUSTUS_SWAPPER.call{value: msg.value}(callData);

            /** @dev assembly allows to get tx failure reason here*/
            if (success == false) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
            emit FirstPartOfSwapExecuted(destNetworkId, destTokenAddress, destAmount, destUserAddress, slippageInBP);
            return (success, txData);
        }
    }
}