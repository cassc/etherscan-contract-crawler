/**
 *Submitted for verification at Etherscan.io on 2023-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//        |-----------------------------------------------------------------------------------------------------------|
//        |                                                                        %################.                 |
//        |                                                                       #####################@              |
//        |                                                         |           ######    @#####    &####             |
//        |                                                         |           ###%        ,         ###%            |
//        |                                                         |          &###,  /&@@     @(@@   ####            |
//        |                                                         |           ###@       &..%      *####            |
//        |  $$$$$$$\  $$$$$$$$\ $$\   $$\  $$$$$$\ $$\     $$\     |           @####     .,,,,@    #####             |
//        |  $$  __$$\ $$  _____|$$$\  $$ |$$  __$$\\$$\   $$  |    |            %##(       ,*      @##(@             |
//        |  $$ |  $$ |$$ |      $$$$\ $$ |$$ /  \__|\$$\ $$  /     |        /#&##@                    ##&#&          |
//        |  $$$$$$$  |$$$$$\    $$ $$\$$ |$$ |$$$$\  \$$$$  /      |       ######                        #(###       |
//        |  $$  ____/ $$  __|   $$ \$$$$ |$$ |\_$$ |  \$$  /       |    #######                          ######.     |
//        |  $$ |      $$ |      $$ |\$$$ |$$ |  $$ |   $$ |        |  &#######@                          ##(#####    |
//        |  $$ |      $$$$$$$$\ $$ | \$$ |\$$$$$$  |   $$ |        |        ###                           &##        |
//        |  \__|      \________|\__|  \__| \______/    \__|        |        &##%                          ###        |
//        |                                                         |         %###                        @##@        |
//        |                                                         |           %###@                  &###&          |
//        |                                                                    &,,,,,&################@,,,,,%         |
//        |                                                                  ,.,,,.*%@               /(.,,,,/@        |
//        |-----------------------------------------------------------------------------------------------------------|
//                                -----> Ken and the community makes penguins fly! 🚀  <-----     */

// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 *
 *
 * PENGY-NOTE: We have stripped this contract of non-essential functions to our use case to optimize gas usage.
 */
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     */
    function processProof(
        bytes32[] memory proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(
        bytes32 a,
        bytes32 b
    ) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

error SenderNotContractOwner();
error NoTierActive();
error NotEnoughETHSent();
error NotWhitelisted();
error IDONotStarted();
error IDOEnded();
error CannotBurnTokensWithActiveIDO();
error WithdrawFailed();
error PoolsAlreadyFunded();
error TierHasSoldOut();
error ContributionExceedsMaximumAllowed();
error HardcapReached();
error CannotChangeDatesIfIDOStarted();
error CannotWithdrawETHWithActiveIDO();
error CannotAirdropWithActiveIDO();

contract PengyPresaleMainnet {
    address public immutable tokenAddress;
    address public immutable owner;

    address public constant ethWithdrawDestination =
        0xe7bE0E9c3a5650dB004E306FC9D9cCE97eEe7166;

    uint256 private constant tiersCooldown = 10 minutes;

    uint256 private tierOneStartTimestamp;
    uint256 private tierOneEndTimestamp;

    uint256 private tierTwoStartTimestamp;
    uint256 private tierTwoEndTimestamp;

    uint256 private tierThreeStartTimestamp;
    uint256 private tierThreeEndTimestamp;

    // Variables visibility is private, we are fetching them with the getters to optimise gas usage
    uint256 private tierOneEthAllocated = 10 ether;
    uint256 private tierTwoEthAllocated = 10 ether;
    uint256 private tierThreeEthAllocated = 10 ether;

    uint256 private hardcap =
        tierOneEthAllocated + tierTwoEthAllocated + tierThreeEthAllocated;

    uint256 private maximumContribution = 0.2 ether;

    uint256 private tierOneTokensAllocated = 0;
    uint256 private tierTwoTokensAllocated = 0;
    uint256 private tierThreeTokensAllocated = 0;

    // We are using ether because the token has 18 decimals
    uint256 private constant totalTokensForSale = 1_920_000_000 ether;

    bytes32 private merkleRootTierOne;
    bytes32 private merkleRootTierTwo;
    bytes32 private merkleRootTierThree;

    mapping(address => uint256) public boughtTokens;
    mapping(address => uint256) public contribution;

    // We're using those in frontend to show the contributions per tier
    uint256 contributionsTierOne;
    uint256 contributionsTierTwo;
    uint256 contributionsTierThree;

    uint256 public totalContributions = 0;

    address[] public buyers;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool private poolsFunded = false;

    event TokensBought(address indexed buyer, uint256 amount);
    event EtherWithdrawn(address indexed withdrawer, uint256 amount);
    event PoolsFunded(
        uint256 amountInTierOne,
        uint256 amountInTierTwo,
        uint256 amountInTierThree
    );

    event TokensBurned(uint256 amount);
    event TokensAirdropped(address indexed recipient, uint256 amount);
    event TimestampsChanged(
        uint256[2] tierOne,
        uint256[2] tierTwo,
        uint256[2] tierThree
    );

    event MerkleRootsChanged(
        bytes32 merkleRootTierOne,
        bytes32 merkleRootTierTwo,
        bytes32 merkleRootTierThree
    );

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert SenderNotContractOwner();
        }
        _;
    }

    constructor(
        bytes32 _merkleRootTierOne,
        bytes32 _merkleRootTierTwo,
        bytes32 _merkleRootTierThree,
        address _tokenAddress,
        uint256 _startTimestamp
    ) payable {
        owner = msg.sender;
        tokenAddress = _tokenAddress;

        merkleRootTierOne = _merkleRootTierOne;
        merkleRootTierTwo = _merkleRootTierTwo;
        merkleRootTierThree = _merkleRootTierThree;

        tierOneStartTimestamp = _startTimestamp;
        tierOneEndTimestamp = tierOneStartTimestamp + tiersCooldown;

        tierTwoStartTimestamp = tierOneEndTimestamp;
        tierTwoEndTimestamp = tierTwoStartTimestamp + tiersCooldown;

        tierThreeStartTimestamp = tierTwoEndTimestamp;
        tierThreeEndTimestamp = tierThreeStartTimestamp + tiersCooldown;
    }

    function getTiersContributions()
        public
        view
        returns (uint256, uint256, uint256)
    {
        return (
            contributionsTierOne,
            contributionsTierTwo,
            contributionsTierThree
        );
    }

    function getMerkleRoots() public view returns (bytes32, bytes32, bytes32) {
        return (merkleRootTierOne, merkleRootTierTwo, merkleRootTierThree);
    }

    function getTierEtherAllocated()
        public
        view
        returns (uint256, uint256, uint256)
    {
        return (
            tierOneEthAllocated,
            tierTwoEthAllocated,
            tierThreeEthAllocated
        );
    }

    function getTierTokenAllocated()
        public
        view
        returns (uint256, uint256, uint256)
    {
        return (
            tierOneTokensAllocated,
            tierTwoTokensAllocated,
            tierThreeTokensAllocated
        );
    }

    function getTimestamps()
        public
        view
        returns (uint256[2] memory, uint256[2] memory, uint256[2] memory)
    {
        return (
            [tierOneStartTimestamp, tierOneEndTimestamp],
            [tierTwoStartTimestamp, tierTwoEndTimestamp],
            [tierThreeStartTimestamp, tierThreeEndTimestamp]
        );
    }

    function getMerkleRootForCurrentTier() internal view returns (bytes32) {
        if (
            block.timestamp >= tierOneStartTimestamp &&
            block.timestamp < tierOneEndTimestamp
        ) {
            return merkleRootTierOne;
        } else if (
            block.timestamp >= tierTwoStartTimestamp &&
            block.timestamp < tierTwoEndTimestamp
        ) {
            return merkleRootTierTwo;
        } else if (
            block.timestamp >= tierThreeStartTimestamp &&
            block.timestamp <= tierThreeEndTimestamp
        ) {
            return merkleRootTierThree;
        } else {
            revert NoTierActive();
        }
    }

    function getAvailableTokensAndEthForCurrentTier()
        public
        view
        returns (uint256 availableEth, uint256 availableTokens)
    {
        if (
            block.timestamp >= tierOneStartTimestamp &&
            block.timestamp < tierOneEndTimestamp
        ) {
            return (tierOneEthAllocated, tierOneTokensAllocated);
        } else if (
            block.timestamp >= tierTwoStartTimestamp &&
            block.timestamp < tierTwoEndTimestamp
        ) {
            return (
                tierOneEthAllocated + tierTwoEthAllocated,
                tierOneTokensAllocated + tierTwoTokensAllocated
            );
        } else if (
            block.timestamp >= tierThreeStartTimestamp &&
            block.timestamp <= tierThreeEndTimestamp
        ) {
            return (
                tierOneEthAllocated +
                    tierTwoEthAllocated +
                    tierThreeEthAllocated,
                tierOneTokensAllocated +
                    tierTwoTokensAllocated +
                    tierThreeTokensAllocated
            );
        } else {
            revert NoTierActive();
        }
    }

    function fundTokenPools() external onlyOwner {
        // Only allow pool funding once
        if (poolsFunded == true) {
            revert PoolsAlreadyFunded();
        }

        // Transfer the tokens from the sender to the contract
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            totalTokensForSale
        );

        uint256 tokensPerOnePool = totalTokensForSale / 3;

        // Allocate the tokens into the pools
        tierOneTokensAllocated = tokensPerOnePool;
        tierTwoTokensAllocated = tokensPerOnePool;
        tierThreeTokensAllocated = tokensPerOnePool;

        poolsFunded = true;

        emit PoolsFunded(
            tierOneTokensAllocated,
            tierTwoTokensAllocated,
            tierThreeTokensAllocated
        );
    }

    /*
     * We're using this so we don't try to substract from a pool which has already ended more than the pool has remaining (underselling )
     */
    function adjustPoolsInCaseOfUndersale() internal {
        if (
            block.timestamp >= tierOneStartTimestamp &&
            block.timestamp < tierOneEndTimestamp &&
            tierOneEthAllocated != 0 &&
            tierOneTokensAllocated != 0
        ) {
            // No adjustment needed
        } else if (
            block.timestamp >= tierTwoStartTimestamp &&
            block.timestamp < tierTwoEndTimestamp &&
            tierTwoEthAllocated != 0 &&
            tierTwoTokensAllocated != 0
        ) {
            tierTwoEthAllocated += tierOneEthAllocated;
            tierTwoTokensAllocated += tierOneTokensAllocated;

            tierOneEthAllocated = 0;
            tierOneTokensAllocated = 0;
        } else if (
            block.timestamp >= tierThreeStartTimestamp &&
            block.timestamp <= tierThreeEndTimestamp &&
            tierThreeEthAllocated != 0 &&
            tierThreeTokensAllocated != 0
        ) {
            tierThreeEthAllocated += tierOneEthAllocated;
            tierThreeEthAllocated += tierTwoEthAllocated;
            tierThreeTokensAllocated += tierOneTokensAllocated;
            tierThreeTokensAllocated += tierTwoTokensAllocated;

            tierOneEthAllocated = 0;
            tierOneTokensAllocated = 0;
            tierTwoEthAllocated = 0;
            tierTwoTokensAllocated = 0;
        }
    }

    function buy(bytes32[] memory proof) external payable {
        // Adjust the pools in case of undersale to make sure the substraction works as intended [449:476]
        adjustPoolsInCaseOfUndersale();
        // We're using a 0 as the second argument due to how the merkle root is built
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, 0)))
        );

        //  Prevent the user from buying more  than the maximum contribution, taking into account the previous contributions
        if (contribution[msg.sender] + msg.value > maximumContribution) {
            revert ContributionExceedsMaximumAllowed();
        }

        if (!MerkleProof.verify(proof, getMerkleRootForCurrentTier(), leaf)) {
            revert NotWhitelisted();
        }
        // Check if the IDO has started
        if (block.timestamp < tierOneStartTimestamp) {
            revert IDONotStarted();
        }
        // Check if the IDO has NOT ended
        if (block.timestamp > tierThreeEndTimestamp) {
            revert IDOEnded();
        }
        // Check if the buyer is already in the buyers array, add them if not
        if (boughtTokens[msg.sender] == 0) {
            buyers.push(msg.sender);
        }
        (
            uint256 availableEth,
            uint256 availableTokens
        ) = getAvailableTokensAndEthForCurrentTier();

        if (availableEth == 0 || availableTokens == 0) {
            revert TierHasSoldOut();
        }

        // Available tokens will always be higher than the available eth, so no need to scale up the numbers here or do the multiplication first
        uint256 tokensBoughtThisTx = ((availableTokens * msg.value) /
            availableEth);
        boughtTokens[msg.sender] += tokensBoughtThisTx;
        contribution[msg.sender] += msg.value;
        totalContributions += msg.value;

        // Check if the totalContributions is not higher than the initial hardcap
        if (totalContributions > hardcap) {
            revert HardcapReached();
        }

        // Subtract the bought tokens from the pool and the eth from the pool
        if (
            block.timestamp >= tierOneStartTimestamp &&
            block.timestamp < tierOneEndTimestamp
        ) {
            tierOneEthAllocated -= msg.value;
            tierOneTokensAllocated -= tokensBoughtThisTx;

            // Add the contribution to the tier one contributions
            contributionsTierOne += msg.value;
        } else if (
            block.timestamp >= tierTwoStartTimestamp &&
            block.timestamp < tierTwoEndTimestamp
        ) {
            tierTwoEthAllocated -= msg.value;
            tierTwoTokensAllocated -= tokensBoughtThisTx;

            // Add the contribution to the tier two contributions
            contributionsTierTwo += msg.value;
        } else if (
            block.timestamp >= tierThreeStartTimestamp &&
            block.timestamp < tierThreeEndTimestamp
        ) {
            tierThreeEthAllocated -= msg.value;
            tierThreeTokensAllocated -= tokensBoughtThisTx;

            // Add the contribution to the tier three contributions
            contributionsTierThree += msg.value;
        }
        emit TokensBought(msg.sender, tokensBoughtThisTx);
    }

    function withdrawEth() external {
        // Check if the IDO has ended
        if (block.timestamp < tierThreeEndTimestamp) {
            revert CannotWithdrawETHWithActiveIDO();
        }

        uint256 etherToWithdraw = address(this).balance;

        (bool success, ) = address(ethWithdrawDestination).call{
            value: etherToWithdraw
        }("");

        if (!success) {
            revert WithdrawFailed();
        }

        emit EtherWithdrawn(ethWithdrawDestination, etherToWithdraw);
    }

    function changeStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        // Only allow to change if the IDO has not started yet

        if (block.timestamp > tierOneStartTimestamp) {
            revert CannotChangeDatesIfIDOStarted();
        }

        tierOneStartTimestamp = _startTimestamp;
        tierOneEndTimestamp = tierOneStartTimestamp + tiersCooldown;

        tierTwoStartTimestamp = tierOneEndTimestamp;
        tierTwoEndTimestamp = tierTwoStartTimestamp + tiersCooldown;

        tierThreeStartTimestamp = tierTwoEndTimestamp;
        tierThreeEndTimestamp = tierThreeStartTimestamp + tiersCooldown;

        emit TimestampsChanged(
            [tierOneStartTimestamp, tierOneEndTimestamp],
            [tierTwoStartTimestamp, tierTwoEndTimestamp],
            [tierThreeStartTimestamp, tierThreeEndTimestamp]
        );
    }

    function airdropContributors(
        uint256 buyerCountToAirdrop
    ) external onlyOwner {
        // Only allow airdropping after the IDO has ended
        if (block.timestamp < tierThreeEndTimestamp) {
            revert CannotAirdropWithActiveIDO();
        }

        uint256 amountToAirdrop;

        if (buyerCountToAirdrop > buyers.length) {
            amountToAirdrop = buyers.length;
        } else {
            amountToAirdrop = buyerCountToAirdrop;
        }

        for (uint256 i = 0; i < amountToAirdrop; i++) {
            // Always transfer to the last buyer in the array
            address buyer = buyers[buyers.length - 1];

            // Save the bought tokens locally before popping the buyer
            uint256 tokens = boughtTokens[buyer];

            // Pop the buyer from the array without preserving order (we don't care about that)
            buyers.pop();

            IERC20(tokenAddress).transfer(buyer, tokens);

            emit TokensAirdropped(buyer, tokens);
        }
    }

    function changeMerkleRoots(
        bytes32 _merkleRootTierOne,
        bytes32 _merkleRootTierTwo,
        bytes32 _merkleRootTierThree
    ) external onlyOwner {
        merkleRootTierOne = _merkleRootTierOne;
        merkleRootTierTwo = _merkleRootTierTwo;
        merkleRootTierThree = _merkleRootTierThree;

        emit MerkleRootsChanged(
            merkleRootTierOne,
            merkleRootTierTwo,
            merkleRootTierThree
        );
    }

    function burnUnsoldTokens() external onlyOwner {
        // Check if the presale has ended
        if (block.timestamp < tierThreeEndTimestamp) {
            revert CannotBurnTokensWithActiveIDO();
        }

        // Make sure burn is only possible when all contributors have been airdropped
        if (buyers.length > 0) {
            revert CannotBurnTokensWithActiveIDO();
        }

        // Burn the unsold tokens
        IERC20(tokenAddress).transfer(
            DEAD,
            IERC20(tokenAddress).balanceOf(address(this))
        );

        emit TokensBurned(IERC20(tokenAddress).balanceOf(address(this)));
    }
}

/*

The topics and opinions discussed by Ken the Crypto and the PENGY community are intended to convey general information only. All opinions expressed by Ken or the community should be treated as such.

This contract does not provide legal, investment, financial, tax, or any other type of similar advice.

As with all alternative currencies, Do Your Own Research (DYOR) before purchasing. Ken and the rest of the PENGY community are working to increase coin adoption, but no individual or community shall be held responsible for any financial losses or gains that may be incurred as a result of trading PENGY.

If you’re with us — Hop In, We’re Going Places 🚀

*/