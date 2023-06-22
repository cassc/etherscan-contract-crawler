// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// Import types
import {ERC20} from "solmate/tokens/ERC20.sol";

// Define Data Structures
struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

// Define Vault Interface
interface IVault {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (address[] memory, uint256[] memory, uint256);
}

// Define Balancer Base Pool Interface
interface IBasePool {
    function getPoolId() external view returns (bytes32);

    function balanceOf(address user_) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address spender_, uint256 amount_) external returns (bool);
}

// Define Balancer Pool Factory Interface
interface IFactory {
    function create(
        string memory name,
        string memory symbol,
        ERC20[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

interface IBalancerHelper {
    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}