// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

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
 */
library MerkleProofUpgradeable {
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

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
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
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
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
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
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

contract ASNO is
    Initializable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    struct UserInfo {
        mapping(address => uint256[]) GoldId;
        mapping(address => uint256[]) DiamondId;
        mapping(address => uint256[]) SilverId;
        mapping(address => uint256[]) OrangeId;
    }

    mapping(address => UserInfo) users;

    uint256 saleStartTime;
    uint256 saleEndTime;
    bytes32 public merkleDiamond;
    bytes32 public merkleGold;
    mapping(address => uint256) public _goldCounter;
    mapping(address => uint256) public _diamondCounter;
    mapping(address => uint256) public _silverCounter;

    uint256 public diamondLimit;
    uint256 public goldLimit;
    uint256 public silverLimit;
    uint256 public totalLimt;

    uint256 public purchasedDiamond;
    uint256 public totalDiamondLimit;
    uint256 public purchasedGold;
    uint256 public totalGoldLimit;
    uint256 public purchasedSilver;
    uint256 public totalSilverLimit;
    uint256 public purchasedOrange;

    uint256 public goldRate;
    uint256 public silverRate;

    mapping(address => bool) public adminRole;

    string public baseDiamondURI;
    string public baseGoldURI;
    string public baseSilverURI;
    string public baseOrangeURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event UpdatedBaseURI(string baseURI);
    event Received(address _address, uint256 amount);

    function initialize() external initializer {
        __ERC721_init_unchained("a", "a");
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __AccessControl_init_unchained();
        diamondLimit = 1;
        goldLimit = 3;
        totalLimt = 10;
        totalDiamondLimit = 500;
        totalGoldLimit = 4000;
        totalSilverLimit = 3500;
        goldRate = 6;
        silverRate = 8;
        baseDiamondURI = "ipfs://QmSfYd5gsRBeHgMwKtzT2rY6Raz7sF6Krk1GeRLYgiYjXH/diamond.json";
        baseGoldURI = "ipfs://QmSfYd5gsRBeHgMwKtzT2rY6Raz7sF6Krk1GeRLYgiYjXH/gold.json";
        baseSilverURI = "ipfs://QmSfYd5gsRBeHgMwKtzT2rY6Raz7sF6Krk1GeRLYgiYjXH/silver.json";
        baseOrangeURI = "";

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
    }

    function zu(bytes32 _merkleDiamond, bytes32 _merkleGold) public {
        merkleDiamond = _merkleDiamond;
        merkleGold = _merkleGold;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev token uri of particular token id
     * @param tokenId.
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev update base uris
     */
    function updateBaseURI(
        string memory _baseDiamondURI,
        string memory _baseGoldURI,
        string memory _baseSilverUri
    ) external {
        require(adminRole[msg.sender] == true, "Only Admin");
        baseDiamondURI = _baseDiamondURI;
        baseGoldURI = _baseGoldURI;
        baseSilverURI = _baseSilverUri;
    }

    /**
     * @dev Mint single nft
     * @param to - account
     * @param uri - token uri
     */
    function safeMint(address to, string memory uri, uint256 tierId) internal {
        UserInfo storage user = users[to];
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        if (tierId == 0) {
            user.DiamondId[to].push(tokenId);
            purchasedDiamond += 1;
        } else if (tierId == 1) {
            user.GoldId[to].push(tokenId);
            purchasedGold += 1;
        } else if (tierId == 2) {
            user.SilverId[to].push(tokenId);
            purchasedSilver += 1;
        } else if (tierId == 3) {
            user.OrangeId[to].push(tokenId);
            purchasedOrange += 1;
        }
    }

    /**
     * @dev Pause the contract (stopped state)
     * by caller with PAUSER_ROLE.
     *
     * - The contract must not be paused.
     *
     * Emits a {Paused} event.
     */
    function pause() external {
        require(adminRole[msg.sender] == true, "Only Admin");
        _pause();
    }

    /**
     * @dev Unpause the contract (normal state)
     * by caller with PAUSER_ROLE.
     *
     * - The contract must be paused.
     *
     * Emits a {Unpaused} event.
     */
    function unpause() external {
        require(adminRole[msg.sender] == true, "Only Admin");
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function deviantNFTMint(
        uint diamond,
        uint gold,
        uint silver,
        bytes32[] calldata _tree
    ) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProofUpgradeable.verify(_tree, merkleDiamond, leaf)) {
            require(
                diamond + purchasedDiamond <= totalDiamondLimit,
                "Total Diamond Limit Reached"
            );
            require(
                _diamondCounter[msg.sender] + diamond <= diamondLimit,
                "Diamond Reached"
            );
            require(
                gold + purchasedGold <= totalGoldLimit,
                "Total gold limit reached"
            );
            require(
                _goldCounter[msg.sender] + gold <= goldLimit,
                "Gold already claimed"
            );
            require(
                _diamondCounter[msg.sender] + _goldCounter[msg.sender] + _silverCounter[msg.sender] <= totalLimt,'you limit exceed'
            );
            require(silver + purchasedSilver <= totalSilverLimit,'Total silver limit reached');
            diamondMint(diamond, msg.sender);
            goldMint(gold, msg.sender);
            uint256 goldPrice = gold * goldRate;
            silverMint(silver, msg.sender);
            uint256 silverPrice = silver * silverRate;
            uint256 totalPrice = (goldPrice + silverPrice) * 10 ** 15;
            require(msg.value >= totalPrice, "not enough eth");
            _diamondCounter[msg.sender] += diamond;
            _goldCounter[msg.sender] += gold;
            _silverCounter[msg.sender] += silver;
        } else if ((MerkleProofUpgradeable.verify(_tree, merkleGold, leaf))) {
            require(
                MerkleProofUpgradeable.verify(_tree, merkleGold, leaf),
                "You are not Gold Listed"
            );
            require(
                gold + purchasedGold <= totalGoldLimit,
                "Total gold limit reached"
            );
            require(
                _goldCounter[msg.sender] + gold <= goldLimit,
                "Gold already claimed"
            );
             require(
                _diamondCounter[msg.sender] + _goldCounter[msg.sender] + _silverCounter[msg.sender] <= totalLimt,'you limit exceed'
            );
            require(silver + purchasedSilver <= totalSilverLimit,'Total silver limit reached');
            goldMint(gold, msg.sender);
            uint256 goldPrice = gold * goldRate;
            silverMint(silver, msg.sender);
            uint256 silverPrice = silver * silverRate;
            uint256 totalPrice = (goldPrice + silverPrice) * 10 ** 15;
            require(msg.value >= totalPrice, "not enough eth");
            _goldCounter[msg.sender] += gold;
            _silverCounter[msg.sender] += silver;
        } else {
             require(
                _diamondCounter[msg.sender] + _goldCounter[msg.sender] + _silverCounter[msg.sender] <= totalLimt,'you limit exceed'
            );
            require(silver + purchasedSilver <= totalSilverLimit,'Total silver limit reached');
            silverMint(silver, msg.sender);
            uint256 silverPrice = (silver * silverRate) * 10 ** 15;
            require(msg.value >= silverPrice, "not enough eth");

            _silverCounter[msg.sender] += silver;
        }
    }

    function diamondMint(uint256 amount, address _address) internal {
        for (uint i = 0; i < amount; i++) {
            safeMint(_address, baseDiamondURI, 0);
        }
    }

    function goldMint(uint256 amount, address _address) internal {
        for (uint i = 0; i < amount; i++) {
            safeMint(_address, baseGoldURI, 1);
        }
    }

    function silverMint(uint256 amount, address _address) internal {
        for (uint i = 0; i < amount; i++) {
            safeMint(_address, baseSilverURI, 2);
        }
    }

    function calculateNative(uint256 gold, uint256 silver) internal {}

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
    @dev view token id's for perticular user
    @param account - perticular user account
     */
    function tokenIdOfUser(
        address account
    )
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        UserInfo storage user = users[account];
        return (
            user.DiamondId[account],
            user.GoldId[account],
            user.SilverId[account]
        );
    }

    function withdrawCurrency() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function EthBalanceInContract() public view returns (uint256) {
        return address(this).balance;
    }

    function setGoldRate(uint256 _goldRate) external {
        require(adminRole[msg.sender] == true, "Only Admin");
        goldRate = _goldRate;
    }

    function setSilverRate(uint256 _silverRate) external {
        require(adminRole[msg.sender] == true, "Only Admin");
        silverRate = _silverRate;
    }

    /**
     * Owner can update admin role
     */
    function updateAdminRole(address _address) external onlyOwner {
        adminRole[_address] = true;
    }

    

    /**
     * @dev Mint multiple nft and transfer
     * @param to - accounts
     
     */
    function mintAirdrop(
        address[] memory to   
    ) external {
        require(adminRole[msg.sender] == true, "Only Admin");
        for (uint256 i; i < to.length; i++) {
                safeMint(to[i], baseOrangeURI, 3);
        }
    }

   
    function setLimit(uint diamond, uint gold,uint silver) external {
    require(adminRole[msg.sender] == true, "Only Admin");
       totalDiamondLimit = diamond;
       totalGoldLimit = gold;
       totalSilverLimit=silver;
    }
}