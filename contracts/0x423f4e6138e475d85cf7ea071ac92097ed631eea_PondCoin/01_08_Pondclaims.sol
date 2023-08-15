// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPondCoin is IERC20 {
    function mint(address to, uint256 amount) external;
    function endMinting() external;
}

interface IPondCoinSpawner {
    function spawn(address invoker, uint256 amount) external returns (bool);
}

contract PondCoin is IERC20, ERC20, IPondCoin {
    address public minter;

    address public constant distilleryAddress = 0x17CC6042605381c158D2adab487434Bde79Aa61C;
    uint256 public constant initialLPAmount = 1000000000000000000000000000;
    uint256 public constant maxSupply = 420690000000000000000000000000000 - initialLPAmount;

    constructor(address initialLPAddress) ERC20("Pond Coin", "PNDC") {
        minter = msg.sender;
        _mint(initialLPAddress, initialLPAmount);
    }

    function _safeMint(address to, uint256 amount) internal {
        _mint(to, amount);
        require(totalSupply() <= maxSupply, "Too Much Supply");
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == minter, "Not Minter");
        _safeMint(to, amount);
    }

    function endMinting() public {
        require(msg.sender == minter, "Not Minter");
        minter = address(0);

        if (totalSupply() < maxSupply) {
            _safeMint(distilleryAddress, maxSupply - totalSupply());
        }
    }

    // Coming soon ;)
    function useSpawner(uint256 amount, IPondCoinSpawner spawner) external {
        require(transferFrom(msg.sender, distilleryAddress, amount), "Could Not Send");
        require(spawner.spawn(msg.sender, amount), "Could Not Spawn");
    }
}

pragma solidity ^0.8.0;

contract PondClaims is ReentrancyGuard, Ownable {
    /**
     * Declare immutable/Constant variables
     */
    // How long after contract cretion the end method can be called
    uint256 public constant canEndAfterTime = 48 hours + 30 minutes;
    uint256 public constant beforeStartBuffer = 30 minutes;

    // The root of the claims merkle tree
    bytes32 public immutable merkleRoot;
    // The address of $PNDC
    IPondCoin public immutable pondCoin;
    // The timestamp in which the contract was deployed
    uint256 public immutable openedAtTimestamp;
    // The block number in which the contract was deployed
    uint256 public immutable openedAtBlock;
    // The address that deployed this contract
    address public immutable opener;

    /**
     * Declare runtime/mutable variables
     */
    
    // Mapping of address -> claim offset -> claimed
    mapping(address => mapping(uint32 => bool)) public alreadyClaimedByAddress;

    // If the contract is "ended"
    bool public ended;

    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
        opener = msg.sender;
        pondCoin = new PondCoin(msg.sender);
        openedAtTimestamp = block.timestamp;
        openedAtBlock = block.number;
    }

    // Modifier that makes sure only the opener can call specific function
    modifier onlyOpener() {
        require(msg.sender == opener, "Not Opener");
        _;
    }

    // Modifier that ensures the contract is not ended, and the before start buffer is completed
    modifier notEnded() {
        require(ended == false && (openedAtTimestamp + beforeStartBuffer) <= block.timestamp, "Already Ended");
        _;
    }

    function close() external notEnded onlyOpener {
        require(block.timestamp >= (openedAtTimestamp + canEndAfterTime), "Too Early");
        ended = true;
        pondCoin.endMinting();
    }

    /**
     * Claim PNDC against merkle tree
     */
    function claim(
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint32[] calldata offsets,
        bytes32[][] calldata merkleProofs
    ) external notEnded nonReentrant {
        // Verify that all lengths match
        uint length = addresses.length;
        require(amounts.length == length && offsets.length == length && merkleProofs.length == length, "Invalid Lengths");

        for (uint256 i = 0; i < length; i++) {
            // Require that the user can claim with the information provided
            require(_canClaim(addresses[i], amounts[i], offsets[i], merkleProofs[i]), "Invalid");
            // Mark that the user has claimed
            alreadyClaimedByAddress[addresses[i]][offsets[i]] = true;
            // Mint to the user the specified amount
            pondCoin.mint(addresses[i], amounts[i]);
        }
    }

    function canClaim(
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint32[] calldata offsets,
        bytes32[][] calldata merkleProofs
    ) external view returns (bool[] memory) {
        // Verify that all lengths match
        uint length = addresses.length;
        require(amounts.length == length && offsets.length == length && merkleProofs.length == length, "Invalid Lengths");

        bool[] memory statuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            statuses[i] = _canClaim(addresses[i], amounts[i], offsets[i], merkleProofs[i]);
        }

        return (statuses);
    }

    function currentOffset() public view returns (uint256) {
        return block.number - openedAtBlock;
    }

    function _canClaim(
        address user,
        uint256 amount,
        uint32 offset,
        bytes32[] calldata merkleProof
    ) notEnded internal view returns (bool) {
        // If the user has already claimed, or the currentOffset has not yet reached the desired offset, the user cannot claim.
        if (alreadyClaimedByAddress[user][offset] == true || currentOffset() < offset) {
            return false;
        } else {
            // Verify that the inputs provided are valid against the merkle tree
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, amount, offset))));
            bool canUserClaim = MerkleProof.verify(merkleProof, merkleRoot, leaf);
            return canUserClaim;
        }
    }
}