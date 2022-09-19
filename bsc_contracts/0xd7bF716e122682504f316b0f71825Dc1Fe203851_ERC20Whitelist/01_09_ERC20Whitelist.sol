// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// import "hardhat/console.sol";
import "./interfaces/IERC20Permit.sol";
import "./abstract/Ownable.sol";
import "./abstract/ReentrancyGuard.sol";
import "./library/SafeERC20.sol";
import "./library/MerkleProof.sol";

/*
 * @title Whitelist contract to allow user to claim their old token share
 *
 * @author @Pedrojok01
 */

contract ERC20Whitelist is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Permit;

    /* Storage:
     ***********/

    IERC20Permit public immutable token;

    bytes32 private merkleRoot;

    uint256 public immutable claimablePeriod;
    uint256 public amountToClaim;
    uint256 public amountClaimed;
    uint256 public walletCount;
    uint256 public walletClaimed;

    mapping(address => bool) public isClaimAvailable;
    mapping(address => uint256) private amountClaimable;

    event TokenClaimed(address to, uint256 amount);

    /* Constructor:
     ***************/

    constructor(address _token) {
        token = IERC20Permit(_token);
        claimablePeriod = block.timestamp + (180 * 24 * 60 * 60);
    }

    function claim(bytes32[] calldata _merkleProof) external nonReentrant {
        require(this.isWhitelisted(msg.sender, _merkleProof), "Not whitelisted");
        require(isClaimAvailable[msg.sender], "Already claimed");

        uint256 amount = this.isAmountClaimable(msg.sender);
        require(amount != 0, "Amount is 0");
        require(amount <= token.balanceOf(address(this)), "Not enough fund");

        _resetWallet(msg.sender);
        amountClaimed += amount;
        token.safeTransfer(msg.sender, amount);

        emit TokenClaimed(msg.sender, amount);
    }

    /* View:
     ********/

    function isWhitelisted(address wallet, bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function isAmountClaimable(address wallet) external view returns (uint256) {
        return amountClaimable[wallet];
    }

    function areadyClaimed() external view returns (uint256, uint256) {
        return (amountClaimed, walletClaimed);
    }

    function leftToClaim() external view returns (uint256, uint256) {
        return (amountToClaim - amountClaimed, walletCount - walletClaimed);
    }

    function contractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /* Restricted:
     **************/

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function addWalletsToWhitelist(address[] memory wallets, uint256[] memory amounts) external onlyOwner {
        require(wallets.length == amounts.length, "Array don't match");
        uint256 numOfwallets = 0;
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < wallets.length; i++) {
            _addWalletToWhitelist(wallets[i], amounts[i]);
            numOfwallets++;
            totalAmount += amounts[i];
        }
        walletCount = numOfwallets;
        amountToClaim = totalAmount;
    }

    function withdraw(address to) external onlyOwner {
        require(block.timestamp >= claimablePeriod, "Claimable period still ongoing");
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(to, amount);
    }

    /* Private:
     ***********/

    function _addWalletToWhitelist(address wallet, uint256 _amount) private {
        require(!isClaimAvailable[wallet], "Address already added");

        isClaimAvailable[wallet] = true;
        amountClaimable[wallet] = _amount;
    }

    function _resetWallet(address wallet) private {
        isClaimAvailable[wallet] = false;
        amountClaimable[wallet] = 0;
        walletClaimed++;
    }
}