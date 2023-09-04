/**
 *Submitted for verification at Etherscan.io on 2023-08-06
*/

/**

                                                                                                    
        ((((((((   .(((("/(((       (((((,                 .((((/        /(((((((   *((((((((       
     ,/(((((((((   .(((("//(((/*    (((((((,             (((((((/     ./(((((((((   /((((((((((*    
    ((((((                 ((((**       ((((((.       *((((((       .(((((                  /((((   
    (((/((                 (((((*          .#####   ,##((           ,(/(((                 ./"/"/   
    ((((((                 (((((/             *#####((              .((((/                 .////(   
    ((((((                 (((((*             ,((####(              .(((((                 ./((/(   
    ((((((                 (((((*             ,((((###/             ./((((                 .((((/   
    ((((((                 (((/(*           "//(((((/(#(/           .(###(                 .((((/   
    *(((((                 (((((/          *####...*"/###           .(####                 ./((((   
    (((((/                 ###((/       (####.          (###(       ,((#((                  (((#(   
     "/((######(    ((#######/*,    (((##( .             . *#((((     .,(((((((#(   ,((##((((((*    
        (######(    (#######(       (#(#(*                 .(((((        ((((((##   *(#((##((*      


    0x0 Dashboard contract allows you to claim ETH and compound it back to 0x0 tokens at your discretion, 
    with any amount in ETH. It utilizes Merkle Proofs, and your ETH amount remains fixed to your address 
    until you claim it. You can track your claimed and unclaimed rewards, as well as the total distributed rewards.
    
    Additionally, you can monitor the volume of ETH added to the contract. The contract also provides calculations 
    for APY, APR, and your rewards.

*/


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library MerkleProof {
    /**
     *@dev The multiproof provided is not valid.
     */
    error MerkleProofInvalidMultiproof();

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function symbol() external view returns (uint256);
}

contract OxODashboardClaim {
    IUniswapV2Router02 public router;

    address public token;

    address public owner;

    bool public claimingEnabled;

    bytes32 public merkleRoot;

    mapping(address => uint256) public amountClaimed;

    uint256 public totalEthForRewards;
    uint256 public lastEthForRewards;
    uint256 public totalClaimedEth;
    uint256 public totalRounds;
    uint256 public lastRewardTime;

    uint256 year = 365;
    uint256 public rewardReplenishFrequency = 7;

    uint256 constant PRECISION = 10**18;

    // Ineligible holders
    address[] private ineligibleHolders;

    error ExceedsClaim();
    error NotInMerkle();
    error ClaimingDisabled();

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        token = 0x5a3e6A77ba2f983eC0d371ea3B475F8Bc0811AD5;
        owner = msg.sender;
        addIneligibleHolder(0x000000000000000000000000000000000000dEaD);
        addIneligibleHolder(0x9Ec9367b8c4Dd45ec8E7b800b1F719251053AD60);
        addIneligibleHolder(0x5a3e6A77ba2f983eC0d371ea3B475F8Bc0811AD5);
        addIneligibleHolder(0x0E7619cCcfa3E181898E3b885A2527968953cf4B);
        addIneligibleHolder(0x120051a72966950B8ce12eB5496B5D1eEEC1541B);
        addIneligibleHolder(0x5bdf85216ec1e38D6458C870992A69e38e03F7Ef);
    }
   

    event Claim(
        address indexed to,
        uint256 amount,
        uint256 amountClaimed
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function processClaim(
        address to,
        uint256 amount,
        bytes32[] calldata proof,
        uint256 claimAmount
    ) internal {
        // Throw if address tries to claim too many tokens
        if (amountClaimed[to] + claimAmount > amount)
            revert ExceedsClaim();
        if(!claimingEnabled)
            revert ClaimingDisabled();

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        // Track ETH claimed
        amountClaimed[to] += claimAmount;
        totalClaimedEth += claimAmount;
    }

    function claimTokens(
        uint256 amount,
        bytes32[] calldata proof,
        uint256 claimAmount,
        uint256 minAmount
    ) external {

        address to = msg.sender;

        // Check if the claimer is not an ineligible holder
        require(!isIneligibleHolder(to), "Claimer is ineligible.");

        processClaim(to, amount, proof, claimAmount);

        swapEthForTokens(claimAmount, to, minAmount);

        // Emit claim event
        emit Claim(to, amount, claimAmount);
    }

    function claimEth(
        uint256 amount,
        bytes32[] calldata proof,
        uint256 claimAmount
    ) external returns (bool success) {

        address to = msg.sender;

        // Check if the claimer is not an ineligible holder
        require(!isIneligibleHolder(to), "Claimer is ineligible.");

        processClaim(to, amount, proof, claimAmount);

        // Send ETH to address
        (success, ) = to.call{value: claimAmount}("");

        // Emit claim event
        emit Claim(to, amount, claimAmount);
    }

    function swapEthForTokens(uint256 ethAmount, address to, uint256 minAmount) internal {

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            minAmount,
            path,
            to,
            block.timestamp
        );
    }

    function getAmountOut(uint256 ethIn) external view returns(uint256){
        (uint256 reserveA, uint256 reserveB,) = IUniswapV2Pair(IUniswapV2Factory(router.factory()).getPair(token, router.WETH())).getReserves();

        return router.getAmountOut(ethIn, reserveB, reserveA);
    }

    function toggleClaiming() external onlyOwner {
        claimingEnabled = !claimingEnabled;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function newRoot(bytes32 root) public payable onlyOwner {
        require(msg.value > 0, "Must send some ETH with the newRoot function.");

        totalEthForRewards += msg.value;
        lastEthForRewards = msg.value;
        rewardReplenishFrequency = (block.timestamp - lastRewardTime) / (60 * 60 * 24);

        // Check if rewardReplenishFrequency is 0, set it to 1
        if (rewardReplenishFrequency == 0) {
            rewardReplenishFrequency = 1;
        }

        merkleRoot = root;
        lastRewardTime = block.timestamp;
        totalRounds++; // Increment the totalRounds counter
    }

    function withdrawETH(uint256 _amount, address payable _to) external onlyOwner {
        require(_to != address(0), "Zero address is invalid.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(address(this).balance >= _amount, "Not enough ETH!");
        
        // totalEthForRewards -= _amount;

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed!");
    }

    function withdrawToken(uint256 _amount, address _to, address _token) external onlyOwner {
        require(_to != address(0), "Zero address is invalid.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(_amount <= IERC20(_token).balanceOf(address(this)), "Not enough tokens!");

        bool success = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Transfer failed!");
    }

    // Calculate the adjusted token supply without decimals
    function calculateAdjustedTokenSupply() public view returns (uint256 adjustedSupplyWithNoDecimals) {
        adjustedSupplyWithNoDecimals = IERC20(token).totalSupply();

        // Subtract the token balance of each ineligible holder from the total supply
        for (uint256 i = 0; i < ineligibleHolders.length; i++) {
            uint256 removeFromSupply = IERC20(token).balanceOf(ineligibleHolders[i]);
            adjustedSupplyWithNoDecimals -= removeFromSupply;
        }

        // Adjust for decimals
        adjustedSupplyWithNoDecimals = adjustedSupplyWithNoDecimals / (10**IERC20(token).decimals());

        return adjustedSupplyWithNoDecimals;
    }

    // Calculate the price of 1 token in terms of WETH (output in Wei)
    function calculateTokenPriceInWETH() public view returns (uint256 tokenPriceInWei) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();

        // Get the amounts out for 1 unit of the token in terms of WETH
        uint256[] memory amountsOut = router.getAmountsOut(1e9, path);

        // Ensure that the token is the output token in the path
        require(amountsOut.length > 0 && amountsOut[amountsOut.length - 1] > 0, "Invalid output token");

        tokenPriceInWei = amountsOut[amountsOut.length - 1];
        return (tokenPriceInWei);
    }

    // Calculate the reward of 1 token (without decimals) in terms of WETH (output in Wei)
    function calculateRewardPerTokenInWETH() public view returns (uint256 rewardPerTokenInWei) {

        uint256 adjustedSupply = calculateAdjustedTokenSupply();

        // Get reward of 1 token
        rewardPerTokenInWei = totalEthForRewards / totalRounds / adjustedSupply;

        return (rewardPerTokenInWei);
    }

    // Calculate the rewards in terms of WETH
    // How much ETH will I receive if I hold `tokenAmount` number of tokens?
    function calculateRewardsInWETH(uint256 tokenAmount) public view returns (uint256 rewardsInWei) {
        uint256 rewardPerTokenInWETH = calculateRewardPerTokenInWETH();

        // Calculate the rewards in WETH (output in Wei) 
        rewardsInWei = rewardPerTokenInWETH * tokenAmount; // tokenAmount with no decimals
    }

    // Calculate the holder rewards in terms of WETH
    function calculateHolderRewardsInWETH(address holderAddress) public view returns (uint256 holderRewardsInWei) {
        uint256 rewardPerTokenInWETH = calculateRewardPerTokenInWETH();

        // Calculate holder rewards in WETH (output in Wei)
        holderRewardsInWei = rewardPerTokenInWETH * IERC20(token).balanceOf(holderAddress) / (10**IERC20(token).decimals()); // tokenAmount with no decimals
    }

    // Calculate APR and APY
    /* 
        Formula:
            uint256 rewardPerTokenInWETH = calculateRewardPerTokenInWETH();
            uint256 tokenPriceInWETH = calculateTokenPriceInWETH();
        
            uint256 r = rewardPerTokenInWETH / tokenPriceInWETH;
            uint256 n = year / rewardReplenishFrequency;

            // Calculate APR
            APR = r * n;

            // Calculate APY
            APY = ((1 + (r / n))**n) - 1;
    */
    function calculateRAndN() public view returns (uint256 r, uint256 n) {
        uint256 rewardPerTokenInWETH = calculateRewardPerTokenInWETH();
        uint256 tokenPriceInWETH = calculateTokenPriceInWETH();

        r = (rewardPerTokenInWETH * PRECISION) / tokenPriceInWETH;
        n = year / rewardReplenishFrequency;

        return (r, n);
    }

    function calculateAPYAndAPR() public view returns (uint256 APR, uint256 APY) {
        uint256 r;
        uint256 n;
        (r, n) = calculateRAndN();

        // Calculate APR (precision in Wei, i.e., 18 decimals)
        APR = r * n;

        // Calculate APY iteratively (precision in Wei, i.e., 18 decimals)
        uint256 tempAPY = PRECISION;
        for (uint256 i = 0; i < n; i++) {
            tempAPY = (tempAPY * (r + PRECISION)) / PRECISION;
        }
        APY = tempAPY - PRECISION;
    }

    // Calculate custom volume
    // How much ETH will I receive if I hold `tokenAmount` number of tokens 
    // if `ethReplenishedForRewardsInWei` amount of ETH is added 
    // every `ethReplenishedFrequencyInDays` and what's the APY and APR?
    function calculateCustomVolume(
        uint256 tokenAmount, 
        uint256 ethReplenishedForRewardsInWei, 
        uint256 ethReplenishedFrequencyInDays
        ) public view returns (
        uint256 yourEthRewardsInWei,
        uint256 r,
        uint256 n,
        uint256 APR, 
        uint256 APY
        ) {
        
        uint256 adjustedSupply = calculateAdjustedTokenSupply();
        uint256 tokenPriceInWETH = calculateTokenPriceInWETH();
        uint256 rewardPerTokenInWETH = ethReplenishedForRewardsInWei / adjustedSupply;

        r = (rewardPerTokenInWETH * PRECISION) / tokenPriceInWETH;
        n = year / ethReplenishedFrequencyInDays;

        // Calculate the rewards in terms of WETH (output in Wei)
        yourEthRewardsInWei = rewardPerTokenInWETH * tokenAmount; // tokenAmount with no decimals

        // Calculate APR (precision in Wei, i.e., 18 decimals)
        APR = r * n;

        // Calculate APY iteratively (precision in Wei, i.e., 18 decimals)
        uint256 tempAPY = PRECISION;
        for (uint256 i = 0; i < n; i++) {
            tempAPY = (tempAPY * (r + PRECISION)) / PRECISION;
        }
        APY = tempAPY - PRECISION;
    }

    function updateRewardReplenishFrequency(uint256 _rewardReplenishFrequency) public onlyOwner {
        rewardReplenishFrequency =  _rewardReplenishFrequency;
    }

    function updateTotalRounds(uint256 _totalRounds) public onlyOwner {
        totalRounds =  _totalRounds;
    }

    function updateTotalEthForRewards(uint256 _totalEthForRewards) public onlyOwner {
        totalEthForRewards =  _totalEthForRewards;
    }

    function updateToken(address _token) public onlyOwner {
        token = _token;
    }

    function updateRouter(address _router) public onlyOwner {
        router = IUniswapV2Router02(_router);
    }

    function addIneligibleHolder(address user) public onlyOwner {
      ineligibleHolders.push(user);
    }
    
    function removeIneligibleHolder(address user) public onlyOwner {
      uint256 len = ineligibleHolders.length;
      for(uint i; i < len; i++) {
        if(ineligibleHolders[i] == user) {
          ineligibleHolders[i] = ineligibleHolders[len - 1];
          ineligibleHolders.pop();
          break;
        }
      }
    }

    // Function to check if an address is an ineligible holder
    function isIneligibleHolder(address user) public view returns (bool) {
        for (uint256 i = 0; i < ineligibleHolders.length; i++) {
            if (ineligibleHolders[i] == user) {
                return true;
            }
        }
        return false;
    }

    // Function to allow setting the claimed amount for addresses
    function setAmountClaimed(address _address, uint256 _amount) public onlyOwner {
        require(!isIneligibleHolder(_address), "Address is ineligible");
        amountClaimed[_address] = _amount;
    }

    function setAmountClaimedBatch(address[] calldata addresses, uint256[] calldata amounts) public onlyOwner {
        require(addresses.length == amounts.length, "Arrays must have the same length");

        for (uint256 i = 0; i < addresses.length; i++) {
            address _address = addresses[i];
            uint256 _amount = amounts[i];

            require(!isIneligibleHolder(_address), "Address is ineligible");
            amountClaimed[_address] = _amount;
        }
    }

}