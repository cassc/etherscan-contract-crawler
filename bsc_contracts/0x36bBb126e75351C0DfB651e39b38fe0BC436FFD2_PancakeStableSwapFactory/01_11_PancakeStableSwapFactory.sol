// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "@openzeppelin-4.5.0/contracts/security/ReentrancyGuard.sol";
import "./PancakeStableSwap.sol";

contract PancakeStableSwapFactory is Ownable {
    struct StableSwapPairInfo {
        address swapContract;
        address token0;
        address token1;
        address LPContract;
    }
    mapping(address => mapping(address => StableSwapPairInfo)) stableSwapPairInfo;
    mapping(uint256 => address) public swapPairContract;

    uint256 public constant N_COINS = 2;
    uint256 public pairLength;

    event NewStableSwapPair(address indexed swapContract, address indexed tokenA, address indexed tokenB);

    constructor() {}

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice createSwapPair
     * @param _tokenA: Addresses of ERC20 conracts .
     * @param _tokenB: Addresses of ERC20 conracts .
     * @param _A: Amplification coefficient multiplied by n * (n - 1)
     * @param _fee: Fee to charge for exchanges
     * @param _admin_fee: Admin fee
     */
    function createSwapPair(
        address _tokenA,
        address _tokenB,
        uint256 _A,
        uint256 _fee,
        uint256 _admin_fee
    ) external onlyOwner {
        require(_tokenA != address(0) && _tokenB != address(0) && _tokenA != _tokenB, "Illegal token");
        (address t0, address t1) = sortTokens(_tokenA, _tokenB);
        StableSwapPairInfo storage info = stableSwapPairInfo[t0][t1];
        require(info.swapContract == address(0), "Pair already exists");
        address[N_COINS] memory coins = [t0, t1];
        // create swap contract
        bytes memory bytecode = type(PancakeStableSwap).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_tokenA, _tokenB, msg.sender, block.timestamp, block.chainid));
        address swapContract;
        assembly {
            swapContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        PancakeStableSwap(swapContract).initialize(coins, _A, _fee, _admin_fee, msg.sender);

        swapPairContract[pairLength] = swapContract;

        info.swapContract = swapContract;
        info.token0 = t0;
        info.token1 = t1;
        info.LPContract = address(PancakeStableSwap(swapContract).token());
        pairLength += 1;

        emit NewStableSwapPair(swapContract, t0, t1);
    }

    function getPairInfo(address _tokenA, address _tokenB) external view returns (StableSwapPairInfo memory info) {
        (address t0, address t1) = sortTokens(_tokenA, _tokenB);
        info = stableSwapPairInfo[t0][t1];
    }
}