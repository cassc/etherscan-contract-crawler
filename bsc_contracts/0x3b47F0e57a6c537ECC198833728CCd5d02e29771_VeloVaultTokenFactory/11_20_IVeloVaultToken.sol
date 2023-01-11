pragma solidity >=0.5.0;

interface IVeloVaultToken {
    /*** Tarot ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*** Pool Token ***/

    event Mint(address indexed sender, address indexed minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address indexed sender, address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external view returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;

    /*** VaultToken ***/

    event Reinvest(address indexed caller, uint256 reward, uint256 bounty, uint256 fee);

    function isVaultToken() external pure returns (bool);

    function stable() external pure returns (bool);

    function optiSwap() external view returns (address);

    function router() external view returns (address);

    function voter() external view returns (address);

    function pairFactory() external view returns (address);

    function rewardsToken() external view returns (address);

    function WETH() external view returns (address);

    function reinvestFeeTo() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function REINVEST_BOUNTY() external view returns (uint256);

    function REINVEST_FEE() external view returns (uint256);

    function reinvestorListLength() external view returns (uint256);

    function reinvestorListItem(uint256 index) external view returns (address);

    function isReinvestorEnabled(address reinvestor) external view returns (bool);

    function addReinvestor(address reinvestor) external;

    function removeReinvestor(address reinvestor) external;

    function updateReinvestBounty(uint256 _newReinvestBounty) external;

    function updateReinvestFee(uint256 _newReinvestFee) external;

    function updateReinvestFeeTo(address _newReinvestFeeTo) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function observationLength() external view returns (uint);

    function observations(uint index)
        external
        view
        returns (
            uint timestamp,
            uint reserve0Cumulative,
            uint reserve1Cumulative
        );

    function currentCumulativePrices()
        external
        view
        returns (
            uint reserve0Cumulative,
            uint reserve1Cumulative,
            uint timestamp
        );

    function _initialize(
        address _underlying,
        address _optiSwap,
        address _router,
        address _voter,
        address _pairFactory,
        address _rewardsToken,
        address _reinvestFeeTo
    ) external;

    function reinvest() external;

    function getReward() external returns (uint256);

    function getBlockTimestamp() external view returns (uint32);

    function adminClaimRewards(address[] calldata _tokens) external;

    function adminRescueTokens(address _to, address[] calldata _tokens) external;
}