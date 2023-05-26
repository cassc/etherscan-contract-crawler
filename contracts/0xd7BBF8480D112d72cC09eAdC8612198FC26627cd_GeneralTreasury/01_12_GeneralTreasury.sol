//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IToken.sol";
import "./interfaces/IRouter.sol";
import "./pancake-swap/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GeneralTreasury is AccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    uint8 public constant DENOMINATOR = 100;

    address public immutable USDC;
    IRouter public immutable ROUTER;
    
    address public multicall;

    EnumerableSet.AddressSet private _activeTokens;
    EnumerableSet.AddressSet private _allPurchasedTokens;

    mapping(address => Purchase[]) public purchases; // altcoin => array of purchases for this altcoin

    struct Purchase {
        uint256 purchasedAmount; // in altcoin
        uint256 spendedAmount; // in USDC
        uint256 alreadySold; // in altcoin
        uint256 pricePerOneToken; // in USDC
    }

    event PurchaseNewAltcoin(
        address altcoin,
        uint256 purchasedAmount,
        uint256 spendedAmount,
        uint256 id
    );
    event SellAltcoin(
        address altcoin,
        uint256 id,
        uint256 sold,
        uint256 received,
        uint256 profit
    );

    // addresses: [0] - owner, [1] - backend, [2] - usdc, [3] - router, [4] - multicall
    constructor(address[5] memory _addresses) {
        require(
            _addresses[0] != address(0) &&
                _addresses[1] != address(0) &&
                _addresses[2] != address(0) &&
                _addresses[3] != address(0) &&
                _addresses[4] != address(0),
            "GeneralTreasury: address 0x0..."
        );

        USDC = _addresses[2];
        ROUTER = IRouter(_addresses[3]);
        multicall = _addresses[4];

        _setupRole(DEFAULT_ADMIN_ROLE, _addresses[0]);
        _setupRole(BACKEND_ROLE, _addresses[1]);
    }

    /** @dev View function to get an array of all altcoin purchases
     * @param altcoin token address
     * @return an array of purchases
     */
    function getAllAltcoinPurchases(address altcoin)
        external
        view
        returns (Purchase[] memory)
    {
        return purchases[altcoin];
    }

    /** @dev View function to get available USDC balance in treasury
     * @return available USDC balance
     */
    function gelAllAvailableFunds() external view returns (uint256) {
        return IToken(USDC).balanceOf(address(this));
    }

    /** @dev View function to get the list of unsold tokens
     * @return an array of unsold token addresses
     */
    function getListOfActiveTokens() external view returns (address[] memory) {
        return _activeTokens.values();
    }

    /** @dev View function to get the list of all purchased (sold+unsold) tokens
     * @return an array of all purchased (sold+unsold) token addresses
     */
    function getListOfAllTokens() external view returns (address[] memory) {
        return _allPurchasedTokens.values();
    }

    /** @dev Function to create purchase of current altcoin in UniswapV2
     * @notice available for backend only
     * @param amount of USDC you're ready to spend
     * @param amountOutMin minimum amount of altcoins you're ready to purchase
     * @param path to swap ([USDC, altcoin], for example)
     * @return received amount of altcoins
     */
    function purchaseNewAltcoin(
        uint256 amount,
        uint256 amountOutMin,
        address[] memory path
    ) external onlyRole(BACKEND_ROLE) nonReentrant returns (uint256) {
        require(
            path.length > 1 && path[0] == USDC,
            "GeneralTreasury: wrong path"
        );
        require(
            amount > 0 && IToken(USDC).balanceOf(address(this)) >= amount,
            "GeneralTreasury: wrong amount"
        );

        TransferHelper.safeApprove(USDC, address(ROUTER), amount);
        address altcoin = path[path.length - 1];
        uint256 beforeTokenBalance = IToken(altcoin).balanceOf(address(this));
        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
            amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        amounts[amounts.length - 1] =
            IToken(altcoin).balanceOf(address(this)) -
            beforeTokenBalance;

        purchases[altcoin].push(
            Purchase(
                amounts[amounts.length - 1],
                amount,
                0,
                (amount * (10**IToken(altcoin).decimals())) /
                    amounts[amounts.length - 1]
            )
        );

        // accounting for the list of tokens
        if (!_activeTokens.contains(altcoin)) {
            _activeTokens.add(altcoin);
            if (!_allPurchasedTokens.contains(altcoin))
                _allPurchasedTokens.add(altcoin);
        }

        emit PurchaseNewAltcoin(
            altcoin,
            amounts[amounts.length - 1],
            amount,
            purchases[altcoin].length - 1
        );

        return amounts[amounts.length - 1];
    }

    /** @dev Function to sell purchased altcoin and distribute profit
     * @notice available for backend only
     * @param path to swap ([altcoin, USDC], for example)
     * @param id an index of current purchase from an array of all existed purchases
     * @param sellPercent percent which is necessary to spend
     * ( spended amount will be equal to (purchase.purchasedAmount - purchase.alreadySold) * sellPercent / 100) )
     * @param amountOutMin minimal amount of USDC you are ready to get (depends on slippage)
     * @return received amount of USDC
     */
    function sellAltcoin(
        address[] memory path,
        uint256 id,
        uint8 sellPercent,
        uint256 amountOutMin
    ) external onlyRole(BACKEND_ROLE) nonReentrant returns (uint256) {
        require(
            path.length > 1 && path[path.length - 1] == USDC,
            "GeneralTreasury: wrong path"
        );
        address altcoin = path[0];
        require(purchases[altcoin].length > id, "GeneralTreasury: wrong id");
        Purchase storage purch = purchases[altcoin][id];
        uint256 amountToSell = (sellPercent >= DENOMINATOR)
            ? purch.purchasedAmount - purch.alreadySold
            : ((purch.purchasedAmount - purch.alreadySold) * sellPercent) /
                DENOMINATOR;
        require(
            amountToSell > 0 &&
                IToken(altcoin).balanceOf(address(this)) >= amountToSell,
            "GeneralTreasury: wrong amount"
        );

        TransferHelper.safeApprove(altcoin, address(ROUTER), amountToSell);
        uint256[] memory amounts;
        amounts = new uint256[](2);
        amounts[0] = amountToSell;
        uint256 usdcBalanceBefore = IToken(USDC).balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSell,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        amounts[1] = IToken(USDC).balanceOf(address(this)) - usdcBalanceBefore;
        purch.alreadySold += amounts[0];
        // calculate profit (or inflation)
        uint256 oldValue = (purch.pricePerOneToken * amountToSell) /
            (10**IToken(altcoin).decimals());
        uint256 profit = (amounts[1] > oldValue) ? amounts[1] - oldValue : 0;

        // accounting for the list of tokens
        if (IToken(altcoin).balanceOf(address(this)) == 0)
            _activeTokens.remove(altcoin);

        emit SellAltcoin(altcoin, id, amountToSell, amounts[1], profit);

        return amounts[1];
    }

    /** @dev Function to emergency withdraw tokens. Removes all of the existed purchases with this token
     * @notice available for owner only
     * @param _token token is necessary to withdraw
     */
    function emergencyWithdrawTokens(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_token != address(0), "GeneralTreasury: wrong input");
        uint256 balance = IToken(_token).balanceOf(address(this));
        if (balance > 0) {
            if (_token != USDC) {
                delete purchases[_token];
                _activeTokens.remove(_token);
            }
            TransferHelper.safeTransfer(_token, _msgSender(), balance);
        }
    }

    /** @dev Function to set multicall contract address.
     * @notice available for owner only
     * @param _multicall contract address
     */
    function setMulticall(address _multicall)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_multicall != address(0), "GeneralTreasury: wrong input");
        multicall = _multicall;
    }

    function _msgSender() internal view override returns (address sender) {
        if (multicall == msg.sender) {
            // The assembly code is more direct than the Solidity version using abi.decode.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }
}