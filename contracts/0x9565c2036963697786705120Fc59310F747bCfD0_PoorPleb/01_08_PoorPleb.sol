// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PoorPleb is ERC20, ERC20Burnable, Ownable {
    bytes32 public immutable merkleRoot;
    uint256 public immutable claimAmount;
    uint256 public immutable allowClaimAllDate;
    uint256 public immutable PAAmountPerClaim;
    uint256 public totalClaimedAmount;
    uint256 public claimCounter;
    address public PA;
    bool internal PAclaimed;

    mapping(address => bool) public claimed;

    event Claim(address indexed claimer, uint256 amount);

    // CONSTRUCTOR ------------------------------------------------------------------------------------------
    constructor(bytes32 _merkleRoot) ERC20("PoorPleb", "PP") {
        _mint(msg.sender, 1666725026387720000000000000000);
        merkleRoot = _merkleRoot;

        claimAmount = 1420369000000000000000000;
        PAAmountPerClaim = 420369000000000000000000;
        totalClaimedAmount = 0;

        allowClaimAllDate = block.timestamp + 69 days; // 69 days of claim phase
        PAclaimed = false;
    }

    // CONTRACT FUNCTIONS ------------------------------------------------------------------------------------
    function claim(bytes32[] calldata merkleProof) external {
        require(block.timestamp <= allowClaimAllDate, "claim period is over");
        require(
            canClaim(msg.sender, merkleProof),
            "MerkleAirdrop: Address is not a candidate for claim"
        );

        claimed[msg.sender] = true;

        _mint(msg.sender, claimAmount);

        totalClaimedAmount += claimAmount;
        claimCounter++;

        emit Claim(msg.sender, claimAmount);
    }

    function getPAClaimableAmount() external view returns (uint256) {
        return PAAmountPerClaim * claimCounter;
    }

    function setPA(address account) external onlyOwner {
        require(account != address(0), "PA address cannot be 0");
        PA = account;
    }

    function claimPA() external {
        require(block.timestamp >= allowClaimAllDate, "cant claim yet");
        require(PA != address(0), "set PA first");
        require(!PAclaimed, "already claimed");
        PAclaimed = true;
        _mint(PA, PAAmountPerClaim * claimCounter);
        emit Claim(PA, PAAmountPerClaim * claimCounter);
    }

    function canClaim(address claimer, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        return
            !claimed[claimer] &&
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(claimer))
            );
    }
}