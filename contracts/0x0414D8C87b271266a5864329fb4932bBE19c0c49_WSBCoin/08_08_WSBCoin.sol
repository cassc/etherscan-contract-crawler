// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WSBCoin is ERC20, ERC20Burnable, Ownable {
    uint256 public immutable maxSupply;

    uint256 public immutable airdropOpens;
    uint256 public immutable airdropCloses;
    uint256 public immutable globalAirdropCap;
    uint256 public immutable airdropIndividualAllocation;
    bytes32 public immutable airdropMerkleRoot;

    address public immutable wsbModeratorsWallet;
    address public immutable wsbCommunityWallet;

    bool public moderatorClaimed;
    uint256 public airdropTokensClaimed;
    bool public airdropEnabled;
    bool public airdropRemainderClaimed;

    mapping(address => bool) public airdropClaimed;

    error NotAllowed();
    error TradingNotStarted();
    error ExceedsAllocation();
    error NotEligibleForAirdrop();
    error AirdropClosed();
    error AirdropOpen();
    error AirdropTimeNotExpired();

    constructor(
        bytes32 airdropMerkleRoot_,
        address cexWallet_,
        address dexWallet_,
        address wsbModeratorsWallet_,
        address wsbCommunityWallet_,
        uint256 maxSupply_,
        uint256 airdropIndividualAllocation_
    ) ERC20("WSB Coin", "WSB") {
        maxSupply = maxSupply_;

        _mint(cexWallet_, (maxSupply * 5) / 100);
        _mint(dexWallet_, (maxSupply * 60) / 100);
        _mint(wsbCommunityWallet_, (maxSupply * 10) / 100);

        wsbModeratorsWallet = wsbModeratorsWallet_;
        wsbCommunityWallet = wsbCommunityWallet_;

        globalAirdropCap = (maxSupply * 20) / 100;

        airdropOpens = block.timestamp;
        airdropCloses = block.timestamp + 90 days;
        airdropIndividualAllocation = airdropIndividualAllocation_;
        airdropMerkleRoot = airdropMerkleRoot_;
    }

    // The moderator wallet can claim their token allocation directly.
    function claimWSBModeratorsAllocation() external {
        if (msg.sender != wsbModeratorsWallet) {
            revert NotAllowed();
        }
        if (moderatorClaimed) {
            revert ExceedsAllocation();
        }
        moderatorClaimed = true;
        _mint(wsbModeratorsWallet, (maxSupply * 5) / 100);
    }

    // After the airdrop period, if there are any unclaimed tokens, they can be minted to the wsb community wallet.
    // Anyone can call this after the airdrop closes.
    function mintRemainderOfAirdropSupply() external {
        // Require the airdrop time period to have expired.
        if (block.timestamp < airdropCloses) {
            revert AirdropTimeNotExpired();
        }

        // Can only be done once.
        if (airdropRemainderClaimed) {
            revert ExceedsAllocation();
        }
        airdropRemainderClaimed = true;

        // Check if there are any tokens left to claim.
        if (airdropTokensClaimed >= globalAirdropCap) {
            revert ExceedsAllocation();
        }

        uint256 remainingAirdropTokens = globalAirdropCap -
            airdropTokensClaimed;
        // Update the total claimed count so we know there should be no airdrop tokens left after this.
        airdropTokensClaimed += remainingAirdropTokens;

        _mint(wsbCommunityWallet, remainingAirdropTokens);
    }

    function isAirdropOpen() public view returns (bool) {
        // Require the airdrop to be enabled.
        if (!airdropEnabled) {
            return false;
        }

        // Require the airdrop period to be active.
        if (block.timestamp < airdropOpens || block.timestamp > airdropCloses) {
            return false;
        }

        // Require the airdrop to not be maxed out.
        // Must be >, not >=, because the airdropTokensClaimed is incremented before this check.
        if (airdropTokensClaimed > globalAirdropCap) {
            return false;
        }
        return true;
    }

    function setAirdropEnabled(bool enabled_) external onlyOwner {
        airdropEnabled = enabled_;
    }

    function airdropMint(bytes32[] memory proof_) external {
        // Update the total claimed count.
        airdropTokensClaimed += airdropIndividualAllocation;

        // Require the airdrop to be open.
        if (!isAirdropOpen()) {
            revert AirdropClosed();
        }

        // Require the address to be on the whitelist.
        if (!verifyProof(proof_, msg.sender)) {
            revert NotEligibleForAirdrop();
        }

        // Check if address has already claimed it.
        if (airdropClaimed[msg.sender]) {
            revert ExceedsAllocation();
        }

        // Mark as claimed.
        airdropClaimed[msg.sender] = true;

        // Mint tokens.
        _mint(msg.sender, airdropIndividualAllocation);
    }

    function verifyProof(
        bytes32[] memory proof_,
        address minterAddress_
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(minterAddress_)))
        );
        if (MerkleProof.verify(proof_, airdropMerkleRoot, leaf)) {
            return true;
        }
        return false;
    }

    // Receive function.
    receive() external payable {
        revert();
    }

    // Fallback function.
    fallback() external {
        revert();
    }
}