// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./V01dWalkERs.sol";

contract V01dWalkERsMinter is Ownable {
    // ---------
    // CONSTANTS
    // ---------
    uint256 public constant MAX_SUPPLY = 666;
    uint256 public constant RESERVED_VIAL_CLAIMS = 250;
    uint256 public constant MAX_MINTS_PER_WALLET = 2;

    IERC721A public constant VOID_VIALS = IERC721A(0xa1eF7407509F2f503ed2CAc239234301FD620291);
    IERC721A public constant ORIGINS = IERC721A(0xE185F44B1e212B396aee139C2c902d60e275c334);
    V01dWalkERs public constant V01D_WALKERS = V01dWalkERs(0x54B38073057772013FD77fb435A30c7Df70a725f);

    // -----------------
    // STORAGE VARIABLES
    // -----------------
    Phase public state;
    uint256 public price = 0.009 ether;

    mapping(address => bool) public originsHolderClaimed;
    mapping(address => uint256) public publicMints;
    mapping(address => uint256) public voidVialClaimsRemaining;
    mapping(uint256 => bool) public originsTokenIdClaimed;

    // --------------
    // MINT FUNCTIONS
    // --------------
    /// @notice Claims for snapshotted void vial holders
    function voidVialClaim() external {
        // 1. Check that the claim has started
        require(state != Phase.PAUSED, "Claim has not yet started");
        uint256 claimAmount = voidVialClaimsRemaining[msg.sender];
        // 2. Check that the user has claims remaining
        require(claimAmount > 0, "No claims remaining");
        // 3. Mark the account as having claimed a void vials mint
        delete voidVialClaimsRemaining[msg.sender];
        // 4. Check that supply would not be exceeded
        require(V01D_WALKERS.totalSupply() + claimAmount <= MAX_SUPPLY, "Max supply exceeded");
        // 5. Claim a single mint
        V01D_WALKERS.ownerMint(msg.sender, claimAmount);
    }

    /// @notice Claims a free mint during the holder claim phase using an origin token
    /// @notice Each tokenId from the Origins collection can only be claimed once
    /// @param tokenId The token id of the origin token to claim with
    function originClaim(uint256 tokenId) external {
        // 1. Check that the claim has started
        require(state != Phase.PAUSED, "Claim has not yet started");
        // 2. Check that claimer owns the origin token
        require(ORIGINS.ownerOf(tokenId) == msg.sender, "Not owner of origin token");
        // 3. Check that the user will has not claimed yet
        require(!originsHolderClaimed[msg.sender], "Account already claimed origin mint");
        // 4. Mark the account as having claimed an origin mint
        originsHolderClaimed[msg.sender] = true;
        // 5. Check that the origin token has not already been claimed
        require(!originsTokenIdClaimed[tokenId], "Origin token already claimed");
        // 6. Mark the origin token as claimed
        originsTokenIdClaimed[tokenId] = true;
        // 7. Check that supply would not be exceeded (250 reserved for void vial claims)
        require(V01D_WALKERS.totalSupply() + 1 <= MAX_SUPPLY - RESERVED_VIAL_CLAIMS, "No origin claims remaining");
        // 8. Claim a single mint
        V01D_WALKERS.ownerMint(msg.sender, 1);
    }

    /// @notice Mints a number of tokens during the public mint phase
    /// @param amount The number of tokens to mint (up to 2 per wallet, including any claims)
    function publicMint(uint256 amount) external payable {
        // 1. Check that the public mint has started
        require(state == Phase.PUBLIC, "Public mint has not yet started");
        // 2. Check that the user will not exceed more than 2 mints
        require(publicMints[msg.sender] + amount <= MAX_MINTS_PER_WALLET, "Max 2 per wallet");
        // 3. Mark the account as having claimed amount number of public mints
        publicMints[msg.sender] += amount;
        // 4. Check that supply would not be exceeded (250 reserved for void vial claims)
        require(V01D_WALKERS.totalSupply() + amount <= MAX_SUPPLY - RESERVED_VIAL_CLAIMS, "No public mints remaining");
        // 5. Check that the user has sent enough funds
        require(msg.value >= price * amount, "Insufficient funds");
        // 6. Claim the mints
        V01D_WALKERS.ownerMint(msg.sender, amount);
    }

    // --------------------
    // OWNER ONLY FUNCTIONS
    // --------------------
    /// @notice Mints a number of tokens to a recipient, only callable by the owner
    /// @param recipient The recipient of the tokens
    /// @param amount The number of tokens to mint
    function ownerMint(address recipient, uint256 amount) external onlyOwner {
        V01D_WALKERS.ownerMint(recipient, amount);
    }

    /// @notice Updates the mint phase
    /// @param newState The new phase
    function setPhase(Phase newState) external onlyOwner {
        state = newState;
    }

    /// @notice Sets the public mint price
    /// @param newPrice The new price
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /// @notice Sets the base URI for all tokens (include trailing slash if needed)
    /// @param uri The new base URI
    function setBaseURI(string memory uri) external onlyOwner {
        V01D_WALKERS.setBaseURI(uri);
    }

    /// @notice Withdraws all Ether from the contract to the owner
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Failed to withdraw Ether");
    }

    /// @notice reclaim ownership of the V01D_WALKERS contract
    function reclaimOwnership() external onlyOwner {
        V01D_WALKERS.transferOwnership(owner());
    }

    struct VoidVialClaim {
        address holder;
        uint256 claimAmount;
    }

    /// @notice update snapshot of void vial claims
    /// @param claimAmounts The number of claims remaining for each holder
    function updateSnapshot(VoidVialClaim[] calldata claimAmounts) external onlyOwner {
        for (uint256 i; i < claimAmounts.length; ) {
            voidVialClaimsRemaining[claimAmounts[i].holder] = claimAmounts[i].claimAmount;
            unchecked {
                i++;
            }
        }
    }
}