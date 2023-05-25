// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "ERC20.sol";
import "IGenericVault.sol";
import "ICurveV2Pool.sol";
import "ICurveFactoryPool.sol";
import "ICurveTriCrypto.sol";
import "ICVXLocker.sol";
import "IUniV2Router.sol";
import "ITriPool.sol";
import "IBooster.sol";
import "IRewards.sol";
import "IUnionVault.sol";

contract stkCvxCrvZaps {
    using SafeERC20 for IERC20;

    address public immutable vault;

    address private constant CONVEX_LOCKER =
        0x72a19342e8F1838460eBFCCEf09F6585e32db86E;
    address private constant CVXCRV_STAKING_CONTRACT =
        0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    address private constant CURVE_CRV_ETH_POOL =
        0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address private constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address private constant CURVE_CVXCRV_CRV_POOL =
        0x971add32Ea87f10bD192671630be3BE8A11b8623;

    address private constant CRV_TOKEN =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant CVXCRV_TOKEN =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address private constant CVX_TOKEN =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private constant UNION_CRV =
        0x4eBaD8DbD4EdBd74DB0278714FbD67eBc76B89B7;
    address private constant WETH_TOKEN =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDT_TOKEN =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant TRICRYPTO =
        0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address private constant TRIPOOL =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant TRICRV =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant BOOSTER =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address private constant CONVEX_TRIPOOL_TOKEN =
        0x30D9410ED1D5DA1F6C8391af5338C93ab8d4035C;
    address private constant CONVEX_TRIPOOL_REWARDS =
        0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8;

    uint256 private constant CRVETH_ETH_INDEX = 0;
    uint256 private constant CRVETH_CRV_INDEX = 1;
    int128 private constant CVXCRV_CRV_INDEX = 0;
    int128 private constant CVXCRV_CVXCRV_INDEX = 1;
    uint256 private constant CVXETH_ETH_INDEX = 0;
    uint256 private constant CVXETH_CVX_INDEX = 1;

    ICurveV2Pool cvxEthSwap = ICurveV2Pool(CURVE_CVX_ETH_POOL);
    ICurveV2Pool crvEthSwap = ICurveV2Pool(CURVE_CRV_ETH_POOL);
    ITriPool triPool = ITriPool(TRIPOOL);
    IBooster booster = IBooster(BOOSTER);
    IRewards triPoolRewards = IRewards(CONVEX_TRIPOOL_REWARDS);
    ICurveFactoryPool crvCvxCrvSwap = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL);
    ICurveTriCrypto triCryptoSwap = ICurveTriCrypto(TRICRYPTO);
    ICVXLocker locker = ICVXLocker(CONVEX_LOCKER);

    constructor(address _vault) {
        vault = _vault;
    }

    /// @notice Set approvals for the contracts used when swapping & staking
    function setApprovals() external {
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, type(uint256).max);

        IERC20(CVXCRV_TOKEN).safeApprove(CVXCRV_STAKING_CONTRACT, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            CVXCRV_STAKING_CONTRACT,
            type(uint256).max
        );

        IERC20(CVXCRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            CURVE_CVXCRV_CRV_POOL,
            type(uint256).max
        );

        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, type(uint256).max);

        IERC20(TRICRV).safeApprove(BOOSTER, 0);
        IERC20(TRICRV).safeApprove(BOOSTER, type(uint256).max);

        IERC20(USDT_TOKEN).safeApprove(TRIPOOL, 0);
        IERC20(USDT_TOKEN).safeApprove(TRIPOOL, type(uint256).max);

        IERC20(CONVEX_TRIPOOL_TOKEN).safeApprove(CONVEX_TRIPOOL_REWARDS, 0);
        IERC20(CONVEX_TRIPOOL_TOKEN).safeApprove(
            CONVEX_TRIPOOL_REWARDS,
            type(uint256).max
        );

        IERC20(CVXCRV_TOKEN).safeApprove(vault, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(vault, type(uint256).max);

        IERC20(CVX_TOKEN).safeApprove(CONVEX_LOCKER, 0);
        IERC20(CVX_TOKEN).safeApprove(CONVEX_LOCKER, type(uint256).max);

        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, type(uint256).max);
    }

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _crvToCvxCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CRV_INDEX,
                CVXCRV_CVXCRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _cvxCrvToCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CVXCRV_INDEX,
                CVXCRV_CRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _crvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: 0}(
                CRVETH_CRV_INDEX,
                CRVETH_ETH_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: amount}(
                CRVETH_ETH_INDEX,
                CRVETH_CRV_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            cvxEthSwap.exchange_underlying{value: amount}(
                CVXETH_ETH_INDEX,
                CVXETH_CVX_INDEX,
                amount,
                minAmountOut
            );
    }

    /////////////////////////////////////////////////////////////

    /// @notice Deposit into the pounder from ETH
    /// @param minAmountOut - min amount of lp tokens expected
    /// @param to - address to stake on behalf of
    function depositFromEth(uint256 minAmountOut, address to)
        external
        payable
        notToZeroAddress(to)
    {
        require(msg.value > 0, "cheap");
        _depositFromEth(msg.value, minAmountOut, to);
    }

    /// @notice Internal function to deposit ETH to the pounder
    /// @param amount - amount of ETH
    /// @param minAmountOut - min amount of lp tokens expected
    /// @param to - address to stake on behalf of
    function _depositFromEth(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) internal {
        uint256 _crvAmount = _ethToCrv(amount, 0);
        _crvToCvxCrv(_crvAmount, address(this), minAmountOut);
        IGenericVault(vault).depositAll(to);
    }

    /// @notice Deposit into the pounder from CRV
    /// @param amount - amount of CRV
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param to - address to stake on behalf of
    function depositFromCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) {
        IERC20(CRV_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        _crvToCvxCrv(amount, address(this), minAmountOut);
        IGenericVault(vault).depositAll(to);
    }

    /// @notice Deposit into the pounder from legacy uCRV
    /// @param amount - amount of uCRV
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param to - address to stake on behalf of
    function depositFromUCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) {
        IERC20(UNION_CRV).safeTransferFrom(msg.sender, address(this), amount);
        IUnionVault(UNION_CRV).withdrawAll(address(this));
        IGenericVault(vault).depositAll(to);
    }

    /// @notice Deposit into the pounder from any token via Uni interface
    /// @notice Use at your own risk
    /// @dev Zap contract needs approval for spending of inputToken
    /// @param amount - min amount of input token
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param inputToken - address of the token to swap from, needs to have an ETH pair on router used
    /// @param to - address to stake on behalf of
    function depositViaUniV2EthPair(
        uint256 amount,
        uint256 minAmountOut,
        address router,
        address inputToken,
        address to
    ) external notToZeroAddress(to) {
        require(router != address(0));

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), amount);
        address[] memory _path = new address[](2);
        _path[0] = inputToken;
        _path[1] = WETH_TOKEN;

        IERC20(inputToken).safeApprove(router, 0);
        IERC20(inputToken).safeApprove(router, amount);

        IUniV2Router(router).swapExactTokensForETH(
            amount,
            1,
            _path,
            address(this),
            block.timestamp + 1
        );
        _depositFromEth(address(this).balance, minAmountOut, to);
    }

    /// @notice Retrieves a user's vault shares and withdraw all
    /// @param _amount - amount of shares to retrieve
    /// @return amount withdrawn
    function _claimAndWithdraw(uint256 _amount) internal returns (uint256) {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), _amount);
        return IGenericVault(vault).withdrawAll(address(this));
    }

    /// @notice Claim as native ETH
    /// @param amount - amount to withdraw
    /// @param minAmountOut - minimum amount of ETH expected
    /// @param to - address to send ETH to
    /// @return amount of ETH withdrawn
    function claimFromVaultAsEth(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) returns (uint256) {
        uint256 _ethAmount = _claimAsEth(amount, minAmountOut);
        (bool success, ) = to.call{value: _ethAmount}("");
        require(success, "ETH transfer failed");
        return _ethAmount;
    }

    /// @notice Withdraw as native CRV
    /// @param amount - amount to withdraw
    /// @param to - address that will receive the CRV
    /// @param minAmountOut - min amount of  CRV expected
    /// @return amount of CRV withdrawn
    function claimFromVaultAsCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public returns (uint256) {
        uint256 _cvxCrvAmount = _claimAndWithdraw(amount);
        return _cvxCrvToCrv(_cvxCrvAmount, to, minAmountOut);
    }

    /// @notice Withdraw as native ETH (internal)
    /// @param _amount - amount to withdraw
    /// @param _minAmountOut - min amount of ETH expected
    /// @return amount of ETH withdrawn
    function _claimAsEth(uint256 _amount, uint256 _minAmountOut)
        internal
        returns (uint256)
    {
        uint256 _crvAmount = claimFromVaultAsCrv(_amount, 0, address(this));
        return _crvToEth(_crvAmount, _minAmountOut);
    }

    /// @notice Claim to any token via a univ2 router
    /// @notice Use at your own risk
    /// @param amount - amount of uFXS to unstake
    /// @param minAmountOut - min amount of output token expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param outputToken - address of the token to swap to
    /// @param to - address of the final recipient of the swapped tokens
    function claimFromVaultViaUniV2EthPair(
        uint256 amount,
        uint256 minAmountOut,
        address router,
        address outputToken,
        address to
    ) public notToZeroAddress(to) {
        require(router != address(0));
        _claimAsEth(amount, 0);
        address[] memory _path = new address[](2);
        _path[0] = WETH_TOKEN;
        _path[1] = outputToken;
        IUniV2Router(router).swapExactETHForTokens{
            value: address(this).balance
        }(minAmountOut, _path, to, block.timestamp + 1);
    }

    /// @notice Claim as USDT via Tricrypto
    /// @param amount - the amount of uFXS to unstake
    /// @param minAmountOut - the min expected amount of USDT to receive
    /// @param to - the adress that will receive the USDT
    /// @return amount of USDT obtained
    function claimFromVaultAsUsdt(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) returns (uint256) {
        uint256 _ethAmount = claimFromVaultAsEth(amount, 0, address(this));
        _swapEthToUsdt(_ethAmount, minAmountOut);
        uint256 _usdtAmount = IERC20(USDT_TOKEN).balanceOf(address(this));
        IERC20(USDT_TOKEN).safeTransfer(to, _usdtAmount);
        return _usdtAmount;
    }

    /// @notice swap ETH to USDT via Curve's tricrypto
    /// @param amount - the amount of ETH to swap
    /// @param minAmountOut - the minimum amount expected
    function _swapEthToUsdt(uint256 amount, uint256 minAmountOut) internal {
        triCryptoSwap.exchange{value: amount}(
            2, // ETH
            0, // USDT
            amount,
            minAmountOut,
            true
        );
    }

    /// @notice Unstake from the Pounder to stables and stake on 3pool convex for yield
    /// @param amount - amount of uCRV to unstake
    /// @param minAmountOut - minimum amount of 3CRV (NOT USDT!)
    /// @param to - address on behalf of which to stake
    function claimFromVaultAndStakeIn3PoolConvex(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) {
        // claim as USDT
        uint256 _usdtAmount = claimFromVaultAsUsdt(amount, 0, address(this));
        // add USDT to Tripool
        triPool.add_liquidity([0, 0, _usdtAmount], minAmountOut);
        // deposit on Convex
        booster.depositAll(9, false);
        // stake on behalf of user
        triPoolRewards.stakeFor(
            to,
            IERC20(CONVEX_TRIPOOL_TOKEN).balanceOf(address(this))
        );
    }

    /// @notice Claim as CVX via CurveCVX
    /// @param amount - the amount of uFXS to unstake
    /// @param minAmountOut - the min expected amount of USDT to receive
    /// @param to - the adress that will receive the CVX
    /// @param lock - whether to lock the CVX or not
    /// @return amount of CVX obtained
    function claimFromVaultAsCvx(
        uint256 amount,
        uint256 minAmountOut,
        address to,
        bool lock
    ) public notToZeroAddress(to) returns (uint256) {
        uint256 _ethAmount = _claimAsEth(amount, 0);
        uint256 _cvxAmount = _ethToCvx(_ethAmount, minAmountOut);
        if (lock) {
            locker.lock(to, _cvxAmount, 0);
        } else {
            IERC20(CVX_TOKEN).safeTransfer(to, _cvxAmount);
        }
        return _cvxAmount;
    }

    modifier notToZeroAddress(address _to) {
        require(_to != address(0), "Invalid address!");
        _;
    }

    receive() external payable {}
}