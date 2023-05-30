// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Router01.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IWETH.sol";
import "./uniswapv2/libraries/UniswapV2Library.sol";
import "./MerkleProof.sol";

contract ETHAirdrop is Ownable, MerkleProof {
    using SafeERC20 for IERC20;

    address public immutable levx;
    address public immutable weth;
    address public immutable router;
    mapping(bytes32 => bool) public isValidMerkleRoot;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _hasClaimed;

    event Deposit(uint256 amount, address from);
    event Withdraw(uint256 amount, address to);
    event AddMerkleRoot(bytes32 indexed merkleRoot);
    event Claim(bytes32 indexed merkleRoot, address indexed account, uint256 amount, address to);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "LEVX: EXPIRED");
        _;
    }

    constructor(
        address _owner,
        address _levx,
        address _weth,
        address _router
    ) {
        levx = _levx;
        weth = _weth;
        router = _router;
        _transferOwnership(_owner);
    }

    receive() external payable {
        emit Deposit(msg.value, msg.sender);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);

        emit Withdraw(amount, msg.sender);
    }

    function addMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        require(!isValidMerkleRoot[merkleRoot], "SHOYU: DUPLICATE_ROOT");
        isValidMerkleRoot[merkleRoot] = true;

        emit AddMerkleRoot(merkleRoot);
    }

    function claim(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount,
        address to
    ) public {
        require(isValidMerkleRoot[merkleRoot], "SHOYU: INVALID_ROOT");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(!_hasClaimed[merkleRoot][leaf], "SHOYU: FORBIDDEN");
        require(verify(merkleRoot, leaf, merkleProof), "SHOYU: INVALID_PROOF");

        _hasClaimed[merkleRoot][leaf] = true;
        if (to != address(this)) {
            payable(to).transfer(amount);
        }

        emit Claim(merkleRoot, msg.sender, amount, to);
    }

    function batchClaim(
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata amounts,
        address to
    ) external {
        for (uint256 i; i < merkleRoots.length; i++) {
            claim(merkleRoots[i], merkleProofs[i], amounts[i], to);
        }
    }

    function claimAndSwapToLevx(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountOut) {
        claim(merkleRoot, merkleProof, amount, address(this));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = levx;
        uint256[] memory amounts = IUniswapV2Router01(router).swapExactETHForTokens{value: amount}(
            amountOutMin,
            path,
            to,
            deadline
        );
        amountOut = amounts[1];
    }

    function batchClaimAndSwapToLevx(
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata amounts,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountOut) {
        uint256 amountIn;
        for (uint256 i; i < merkleRoots.length; i++) {
            uint256 amount = amounts[i];
            claim(merkleRoots[i], merkleProofs[i], amount, address(this));
            amountIn += amount;
        }

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = levx;
        uint256[] memory _amounts = IUniswapV2Router01(router).swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            to,
            deadline
        );
        amountOut = _amounts[1];
    }
}