// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

enum Phase {
    PAUSED,
    HOLDERS,
    PUBLIC
}

contract V01dWalkERs is ERC721A("V01dWalkERs", "V01D"), ERC721AQueryable, Ownable {
    // ---------
    // CONSTANTS
    // ---------
    uint256 public constant MAX_SUPPLY = 666;
    uint256 public constant RESERVED_VIAL_CLAIMS = 250;
    uint256 public constant MAX_MINTS_PER_WALLET = 2;

    IERC721A public constant VOID_VIALS = IERC721A(0xa1eF7407509F2f503ed2CAc239234301FD620291);
    IERC721A public constant ORIGINS = IERC721A(0xE185F44B1e212B396aee139C2c902d60e275c334);

    // -----------------
    // STORAGE VARIABLES
    // -----------------
    Phase public state;

    uint256 public price = 0.009 ether;

    string public baseTokenURI = "ipfs://";

    mapping(uint256 => bool) voidVialsClaimed;
    mapping(uint256 => bool) originsClaimed;

    // --------------
    // MINT FUNCTIONS
    // --------------
    /// @notice Claims a free mint during the holder claim phase using a void vial
    /// @notice Each tokenId from the Void Vials collection can only be claimed once
    /// @param tokenId The token id of the void vial token to claim with
    function voidVialClaim(uint256 tokenId) external {
        // 1. Check that the claim is being made by a user and not a smart contract
        require(msg.sender == tx.origin, "No smart contracts");
        // 2. Check that the claim has started
        require(state != Phase.PAUSED, "Claim has not yet started");
        // 3. Check that the user will not exceed more than 2 mints
        require(_numberMinted(msg.sender) + 1 <= MAX_MINTS_PER_WALLET, "Max 2 per wallet");
        // 4. Check that supply would not be exceeded
        require(totalSupply() + 1 <= MAX_SUPPLY, "Max supply exceeded");
        // 5. Check that the user has not already claimed a void vials mint (auxiliary data == 1)
        require(_getAux(msg.sender) != 1, "Account already claimed void vials mint");
        // 6. Mark the account as having claimed a void vials mint (auxiliary data == 1)
        _setAux(msg.sender, 1);
        // 7. Check that claimer owns the void vials token
        require(VOID_VIALS.ownerOf(tokenId) == msg.sender, "Not owner of void vials token");
        // 8. Check that the void vials token has not already been claimed
        require(!voidVialsClaimed[tokenId], "Void vial token already claimed");
        // 9. Mark the void vials token as claimed
        voidVialsClaimed[tokenId] = true;
        // 10. Claim a single mint
        _mint(msg.sender, 1);
    }

    /// @notice Claims a free mint during the holder claim phase using an origin token
    /// @notice Each tokenId from the Origins collection can only be claimed once
    /// @param tokenId The token id of the origin token to claim with
    function originClaim(uint256 tokenId) external {
        // 1. Check that the claim is being made by a user and not a smart contract
        require(msg.sender == tx.origin, "No smart contracts");
        // 2. Check that the claim has started
        require(state != Phase.PAUSED, "Claim has not yet started");
        // 3. Check that the user will not exceed more than 2 mints
        require(_numberMinted(msg.sender) + 1 <= MAX_MINTS_PER_WALLET, "Max 2 per wallet");
        // 4. Check that supply would not be exceeded (250 reserved for void vial claims)
        require(totalSupply() + 1 <= MAX_SUPPLY - RESERVED_VIAL_CLAIMS, "No origin claims remaining");
        // 5. Check that the user has not already claimed an origin mint (auxiliary data == 2)
        require(_getAux(msg.sender) != 2, "Account already claimed origin mint");
        // 6. Mark the account as having claimed an origin mint (auxiliary data == 2)
        _setAux(msg.sender, 2);
        // 7. Check that claimer owns the origin token
        require(ORIGINS.ownerOf(tokenId) == msg.sender, "Not owner of origin token");
        // 8. Check that the origin token has not already been claimed
        require(!originsClaimed[tokenId], "Origin token already claimed");
        // 9. Mark the origin token as claimed
        originsClaimed[tokenId] = true;
        // 10. Claim a single mint
        _mint(msg.sender, 1);
    }

    /// @notice Mints a number of tokens during the public mint phase
    /// @param amount The number of tokens to mint (up to 2 per wallet, including any claims)
    function publicMint(uint256 amount) external payable {
        // 1. Check that the claim is being made by a user and not a smart contract
        require(msg.sender == tx.origin, "No smart contracts");
        // 2. Check that the public mint has started
        require(state == Phase.PUBLIC, "Public mint has not yet started");
        // 3. Check that the user will not exceed more than 2 mints
        require(_numberMinted(msg.sender) + amount <= MAX_MINTS_PER_WALLET, "Max 2 per wallet");
        // 4. Check that supply would not be exceeded (250 reserved for void vial claims)
        require(totalSupply() + amount <= MAX_SUPPLY - RESERVED_VIAL_CLAIMS, "No public mints remaining");
        // 5. Check that the user has sent enough funds
        require(msg.value >= price * amount, "Insufficient funds");
        // 6. Claim the mints
        _mint(msg.sender, amount);
    }

    // --------------------
    // OWNER ONLY FUNCTIONS
    // --------------------
    /// @notice Mints a number of tokens to a recipient, only callable by the owner
    /// @param recipient The recipient of the tokens
    /// @param amount The number of tokens to mint
    function ownerMint(address recipient, uint256 amount) external onlyOwner {
        // 1. Check that supply would not be exceeded
        require(totalSupply() + amount <= MAX_SUPPLY, "No mints remaining");
        _mint(recipient, amount);
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
        baseTokenURI = uri;
    }

    /// @notice Withdraws all Ether from the contract to the owner
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Failed to withdraw Ether");
    }

    // ------------------
    // INTERNAL OVERRIDES
    // ------------------
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}