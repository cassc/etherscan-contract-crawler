// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claimFor(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        address recipient
    ) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        uint256 index,
        address account,
        uint256 tokenId,
        uint256 amount
    );
}

interface IVe {
    function split(uint256 tokenId, uint256 sendAmount)
        external
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract MerkleDistributorVeSolid is IMerkleDistributor {
    address public immutable override token;
    bytes32 public override merkleRoot;
    uint256 public rootTokenId;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    address governance;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 rootTokenId_
    ) public {
        token = token_;
        merkleRoot = merkleRoot_;
        governance = msg.sender;
        rootTokenId = rootTokenId_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);

        // Split NFT
        uint256 tokenId = IVe(token).split(rootTokenId, amount);

        // Transfer NFT (intentionally use transferFrom instead of safeTransferFrom)
        IVe(token).transferFrom(address(this), account, tokenId);

        emit Claimed(index, account, tokenId, amount);
    }

    function claimFor(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        address recipient
    ) external override {
        require(msg.sender == governance, "!governance");
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);

        // Split NFT
        uint256 tokenId = IVe(token).split(rootTokenId, amount);

        // Transfer NFT (intentionally use transferFrom instead of safeTransferFrom)
        IVe(token).transferFrom(address(this), recipient, tokenId);

        emit Claimed(index, account, tokenId, amount);
    }

    function transferGovernance(address governance_) external {
        require(msg.sender == governance, "!governance");
        governance = governance_;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external {
        require(msg.sender == governance, "!governance");
        merkleRoot = _merkleRoot;
    }

    function setRootTokenId(uint256 _rootTokenId) external {
        require(msg.sender == governance, "!governance");
        rootTokenId = _rootTokenId;
    }

    function collectDust(address _token, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        require(_token != token, "!token");
        if (_token == address(0)) {
            // token address(0) = ETH
            payable(governance).transfer(_amount);
        } else {
            IERC20(_token).transfer(governance, _amount);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}