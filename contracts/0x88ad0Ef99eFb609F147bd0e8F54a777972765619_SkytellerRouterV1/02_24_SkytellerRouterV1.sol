// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "./interfaces/ISkytellerSweepDelegate.sol";
import "./interfaces/IWETH9.sol";
import "./SkytellerErrors.sol";

/**
 * @title SkytellerRouterV1
 * @notice The router implementation for the Skyteller protocol.
 *         This contract is upgradeable via UUPS
 */
contract SkytellerRouterV1 is Initializable, Ownable2StepUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Sweep has occurred
    event SkytellerRouterSweep(
        ISkytellerSweepDelegate indexed sweeper, IERC20 indexed token, uint256 destinationAmount
    );

    /// @dev The destination address and transit token have been set
    event SkytellerRouterSetDestination(address indexed destination, IERC20 indexed transitToken);

    /// @dev The sweeper contract has been set
    event SkytellerRouterSetSweeperDelegate(ISkytellerSweepDelegate indexed sweeper);

    /// @dev Owner has withdrawn ERC1155
    event SkytellerRouterWithdrawERC1155(
        IERC1155 indexed token, uint256 indexed id, uint256 amount
    );

    /// @dev Owner has withdrawn ERC721
    event SkytellerRouterWithdrawERC721(IERC721 indexed token, uint256 indexed id);

    /// @dev Owner has withdrawn ERC20
    event SkytellerRouterWithdrawERC20(IERC20 indexed token, uint256 amount);

    /// @dev Owner has withdrawn ETH
    event SkytellerRouterWithdraw(uint256 amount);

    /// @dev Owner self-destructed the router
    event SkytellerRouterSelfDestruct();

    /// @dev Owner has set the restricted sweep flag
    event SkytellerRouterSetRestrictedSweep(bool restrictedSweep);

    /*//////////////////////////////////////////////////////////////
                         CONSTANTS + IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The version of the contract
    uint8 public constant VERSION = 1;

    /// @dev The WETH9 token contract
    IWETH9 private weth9;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev The destination address for the sweep
    address public destination;

    /// @dev The transit token that the sweep must swap to
    IERC20 public transitToken;

    /// @dev The ISkytellerSweeperDelegate contract
    ISkytellerSweepDelegate public sweeperDelegate;

    /// @dev Whether the router can publicly swept
    bool public restrictedSweep;

    /*//////////////////////////////////////////////////////////////
                        CREATION + INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @dev Construct the contract with the WETH9 address
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialization
     * @param _owner The owner of the contract
     * @param _destination The destination address for the sweep
     * @param _transitToken The transit token that the sweep must swap to
     * @param _sweeperDelegate The sweeper delegate contract
     */
    function initialize(
        address _weth9,
        address _owner,
        address _destination,
        address _transitToken,
        address _sweeperDelegate
    ) external reinitializer(VERSION) {
        __Ownable2Step_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _transferOwnership(_owner);
        weth9 = IWETH9(_weth9);
        destination = _destination;
        transitToken = IERC20(_transitToken);
        sweeperDelegate = ISkytellerSweepDelegate(_sweeperDelegate);
    }

    /*//////////////////////////////////////////////////////////////
                                  SWEEP
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sweep the ETH balance of the contract by wrapping it to WETH9
     *         If restrictedSweep is set, sender must be the owner
     * @return amountIn The amount of ETH that was swept
     * @return amountOut The amount of the transit token that was received
     */
    function sweep() external payable returns (uint256 amountIn, uint256 amountOut) {
        amountIn = address(this).balance;
        weth9.deposit{value: amountIn}();
        amountOut = sweep(weth9, amountIn);
    }

    /**
     * @notice Sweep the ETH balance of the contract by wrapping it to WETH9
     *         If restrictedSweep is set, sender must be the owner
     * @param amountIn The amount of ETH to sweep
     * @return amountOut The amount of the transit token that was received
     */
    function sweep(uint256 amountIn) external payable returns (uint256 amountOut) {
        weth9.deposit{value: amountIn}();
        amountOut = sweep(weth9, amountIn);
    }

    /**
     * @notice Sweep the token balance of the contract.
     *         If restrictedSweep is set, sender must be the owner
     * @param token The token to sweep
     * @return amountIn The router's balance of token that was swept
     * @return amountOut The amount of the transit token that was received
     */
    function sweep(IERC20 token) external returns (uint256 amountIn, uint256 amountOut) {
        amountIn = token.balanceOf(address(this));
        amountOut = sweep(token, amountIn);
    }

    /**
     * @notice Sweep the token balance of the contract.
     *         If restrictedSweep is set, sender must be the owner
     *         If the token is the transit token, it will be sent directly to the destination
     * @param token The token to sweep
     * @param amountIn The amount of tokens to sweep
     * @return amountOut The amount of the transit token that was received
     */
    function sweep(IERC20 token, uint256 amountIn) public returns (uint256 amountOut) {
        if (restrictedSweep) {
            if (owner() != msg.sender) {
                revert Skyteller_RouterOpenSweepDisabled();
            }
        }
        if (token == transitToken) {
            token.safeTransfer(destination, amountIn);
            amountOut = amountIn;
        } else {
            token.safeTransfer(address(sweeperDelegate), amountIn);
            amountOut = sweeperDelegate.sweep(token, transitToken, amountIn, destination);
        }
        emit SkytellerRouterSweep(sweeperDelegate, token, amountOut);
    }

    /*//////////////////////////////////////////////////////////////
                                OWNER-ONLY
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the restrictedSweep flag
     */
    function setRestrictedSweep(bool restricted) external onlyOwner {
        restrictedSweep = restricted;
        emit SkytellerRouterSetRestrictedSweep(restricted);
    }

    /**
     * @notice Set the destination address and transit token for the sweep
     * @param newDestination The new destination address
     * @param newTransitToken The new transit token
     */
    function setDestination(address newDestination, IERC20 newTransitToken) external onlyOwner {
        destination = newDestination;
        transitToken = newTransitToken;
        emit SkytellerRouterSetDestination(newDestination, newTransitToken);
    }

    /**
     * @notice Set the sweeper contract
     * @param _sweeperDelegate The new sweeper contract
     */
    function setSweeperDelegate(ISkytellerSweepDelegate _sweeperDelegate) external onlyOwner {
        sweeperDelegate = _sweeperDelegate;
        emit SkytellerRouterSetSweeperDelegate(_sweeperDelegate);
    }

    /**
     * @notice Withdraw ERC1155 token balance from the router
     * @param token The ERC1155 token contract
     * @param tokenId The token ID
     * @param amount The amount to withdraw
     */
    function withdrawERC1155(IERC1155 token, uint256 tokenId, uint256 amount) external onlyOwner {
        token.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        emit SkytellerRouterWithdrawERC1155(token, tokenId, amount);
    }

    /**
     * @notice Withdraw ERC721 token from the router
     * @param nft The ERC721 token contract
     * @param tokenId The token ID
     */
    function withdrawERC721(IERC721 nft, uint256 tokenId) external onlyOwner {
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit SkytellerRouterWithdrawERC721(nft, tokenId);
    }

    /**
     * @notice Withdraw ERC20 token balance from the router
     * @param token The ERC20 token contract
     * @param amount The amount to withdraw
     */
    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
        emit SkytellerRouterWithdrawERC20(token, amount);
    }

    /**
     * @notice Withdraw ETH balance from the router
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
        emit SkytellerRouterWithdraw(amount);
    }

    /**
     * @notice Call selfdestruct on the contract,
     * send the ETH balance to the owner
     */
    function selfDestruct() public onlyOwner {
        emit SkytellerRouterSelfDestruct();
        selfdestruct(payable(msg.sender));
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER-ONLY UPGRADES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice UUPS upgrade authorization by the owner
     */
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
        // Only the owner can upgrade the contract
    }
}