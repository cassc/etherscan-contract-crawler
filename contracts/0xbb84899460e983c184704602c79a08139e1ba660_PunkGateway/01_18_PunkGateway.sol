// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IPunkGateway.sol";
import "./interfaces/IWrappedPunks.sol";
import "./interfaces/IPunks.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IKyokoPool.sol";
import "./interfaces/IKyokoPoolAddressesProvider.sol";

contract PunkGateway is
    IPunkGateway,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IKyokoPoolAddressesProvider internal _addressesProvider;

    IPunks public punks;
    IWETH public WETH;
    IWrappedPunks public wrappedPunks;
    address public proxy;

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;
    uint256 private _status;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function initialize(
        address addressesProvider_,
        address weth_,
        address punks_,
        address wrappedPunks_
    ) public initializer {
        __Ownable_init();
        _addressesProvider = IKyokoPoolAddressesProvider(addressesProvider_);
        WETH = IWETH(weth_);

        punks = IPunks(punks_);
        wrappedPunks = IWrappedPunks(wrappedPunks_);
        wrappedPunks.registerProxy();
        proxy = wrappedPunks.proxyInfo(address(this));

        IERC721Upgradeable(address(wrappedPunks)).setApprovalForAll(
            address(_getKyokoPool()),
            true
        );
    }

    function _depositPunk(uint256 punkIndex) internal {
        address ownerAddress = punks.punkIndexToAddress(punkIndex);
        require(
            ownerAddress == _msgSender(),
            "PunkGateway: not owner of punkIndex"
        );

        punks.buyPunk(punkIndex);
        punks.transferPunk(proxy, punkIndex);

        wrappedPunks.mint(punkIndex);
    }

    function borrow(
        uint256 reserveId,
        uint256 punkIndex,
        uint256 interestRateMode
    ) external override nonReentrant {
        IKyokoPool cachePool = _getKyokoPool();
        _depositPunk(punkIndex);
        cachePool.borrow(
            reserveId,
            address(wrappedPunks),
            punkIndex,
            interestRateMode,
            _msgSender()
        );
    }

    function _withdrawPunk(uint256 punkIndex, address onBehalfOf) internal {
        address ownerAddress = wrappedPunks.ownerOf(punkIndex);
        require(
            ownerAddress == _msgSender(),
            "PunkGateway: caller is not owner"
        );
        require(
            ownerAddress == onBehalfOf,
            "PunkGateway: onBehalfOf is not owner"
        );

        wrappedPunks.safeTransferFrom(onBehalfOf, address(this), punkIndex);
        wrappedPunks.burn(punkIndex);
        punks.transferPunk(onBehalfOf, punkIndex);
    }

    function repay(
        uint256 borrowId
    ) external payable override nonReentrant returns (uint256 paybackAmount) {
        IKyokoPool cachePool = _getKyokoPool();
        paybackAmount = cachePool.repay{value: msg.value}(
            borrowId,
            _msgSender()
        );
        uint256 punkIndex = cachePool.getBorrowInfo(borrowId).nftId;
        _withdrawPunk(punkIndex, _msgSender());
    }

    function claimCall(uint256 borrowId) external override {
        IKyokoPool cachePool = _getKyokoPool();
        cachePool.claimCall(borrowId, _msgSender());
        uint256 punkIndex = cachePool.getBorrowInfo(borrowId).nftId;
        _withdrawPunk(punkIndex, _msgSender());
    }

    function _getKyokoPool() internal view returns (IKyokoPool) {
        return IKyokoPool(_addressesProvider.getKyokoPool()[0]);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(
        address to,
        uint256 value
    ) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(WETH).deposit{value: amount}();
            require(
                IERC20Upgradeable(address(WETH)).transfer(to, amount),
                "LP_WETH_TRANSFER_FAILED"
            );
        }
    }

    /**
     * @dev
     */
    receive() external payable {}

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }

    event EmergencyERC721TokenTransfer(
        address token,
        uint256 tokenId,
        address to
    );

    event EmergencyPunkTransfer(address to, uint256 punkIndex);

    /**
     * @dev transfer ERC721 from the utility contract, for ERC721 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token ERC721 token to transfer
     * @param tokenId tokenId to send
     * @param to recipient of the transfer
     */
    function emergencyERC721TokenTransfer(
        address token,
        uint256 tokenId,
        address to
    ) external onlyOwner {
        IERC721Upgradeable(token).safeTransferFrom(address(this), to, tokenId);
        emit EmergencyERC721TokenTransfer(token, tokenId, to);
    }

    /**
     * @dev transfer native Punk from the utility contract, for native Punk recovery in case of stuck Punk
     * due selfdestructs or transfer punk to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param punkIndex punk to send
     */
    function emergencyPunkTransfer(
        address to,
        uint256 punkIndex
    ) external onlyOwner {
        punks.transferPunk(to, punkIndex);
        emit EmergencyPunkTransfer(to, punkIndex);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}