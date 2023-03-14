//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IWstETH {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface ICompoundMarket {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function borrowBalanceOf(address account) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external view returns (UserCollateral memory);
}

interface IEulerTokens {
    function balanceOfUnderlying(
        address account
    ) external view returns (uint256); //To be used for E-Tokens

    function balanceOf(address) external view returns (uint256); //To be used for D-Tokens
}

interface ILiteVaultV1 {
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IAavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface IAavePool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256); // Returns underlying amount withdrawn.
}

interface IMorphoAaveV2 {
    struct PoolIndexes {
        uint32 lastUpdateTimestamp; // The last time the local pool and peer-to-peer indexes were updated.
        uint112 poolSupplyIndex; // Last pool supply index. Note that for the stEth market, the pool supply index is tweaked to take into account the staking rewards.
        uint112 poolBorrowIndex; // Last pool borrow index. Note that for the stEth market, the pool borrow index is tweaked to take into account the staking rewards.
    }

    function poolIndexes(address) external view returns (PoolIndexes memory);

    // Current index from supply peer-to-peer unit to underlying (in ray).
    function p2pSupplyIndex(address) external view returns (uint256);

    // Current index from borrow peer-to-peer unit to underlying (in ray).
    function p2pBorrowIndex(address) external view returns (uint256);

    struct SupplyBalance {
        uint256 inP2P; // In peer-to-peer supply scaled unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In pool supply scaled unit. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In peer-to-peer borrow scaled unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In pool borrow scaled unit, a unit that grows in value, to keep track of the debt increase when borrowers are on Aave. Multiply by the pool borrow index to get the underlying amount.
    }

    // For a given market, the supply balance of a user. aToken -> user -> balances.
    function supplyBalanceInOf(
        address,
        address
    ) external view returns (SupplyBalance memory);

    // For a given market, the borrow balance of a user. aToken -> user -> balances.
    function borrowBalanceInOf(
        address,
        address
    ) external view returns (BorrowBalance memory);
}