// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SignedAllowance} from "@0xdievardump/signed-allowances/contracts/SignedAllowance.sol";
import {OriginValidator} from "./utils/OriginValidator.sol";

/// @title 8liensSpawner
/// @author 8liens (https://twitter.com/8liensNFT)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract $8liensSpawner is Ownable, OriginValidator, SignedAllowance {
    error AlreadyMinted();
    error TooEarly();
    error AlreadyMintedAllowance();

    string public constant name = "8liens Spawner";

    address public $8liensContract;

    uint256 public currentTier;

    /// @notice if an account has already minted during public mint
    mapping(address => bool) public hasPublicMinted;

    constructor(address signer_) {
        _setAllowancesSigner(signer_);
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    /// @notice easy getter for number minted
    /// @param account the account to check for
    /// @return the amount the account minted
    function numberMinted(address account) public view returns (uint256) {
        return I8liens($8liensContract).numberMinted(account);
    }

    /////////////////////////////////////////////////////////
    // Public                                              //
    /////////////////////////////////////////////////////////

    /// @notice Mint with allowance
    /// @param nonce the nonce to be signed (it's also the allocation for this address)
    /// @param signature of the validator
    function mint(uint256 nonce, bytes calldata signature) external {
        mintTo(msg.sender, nonce, nonce, signature);
    }

    /// @notice Mint `amount` to `to` with allowance check
    /// @param to address to mint to
    /// @param amount the amount to mint
    /// @param nonce the nonce to be signed
    /// @param signature of the validator
    function mintTo(
        address to,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public {
        if (currentTier < 1) {
            revert TooEarly();
        }

        validateSignature(to, nonce, signature);

        uint256 alreadyMinted = numberMinted(to);
        if ((alreadyMinted + amount) > nonce) {
            revert AlreadyMintedAllowance();
        }

        I8liens($8liensContract).mintTo(to, amount);
    }

    /// @notice Public Mint
    function publicMint() external validateOrigin {
        if (currentTier < 2) {
            revert TooEarly();
        }

        if (hasPublicMinted[msg.sender]) {
            revert AlreadyMinted();
        }

        hasPublicMinted[msg.sender] = true;
        return I8liens($8liensContract).mintTo(msg.sender, 1);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice allows owner to mint `amount` items to `to`
    /// @param to the address to mint to
    /// @param amount the amount to mint
    function teamMint(address to, uint256 amount) external onlyOwner {
        return I8liens($8liensContract).mintTo(to, amount);
    }

    /// @notice allows owner to set the 8lien contract
    /// @param new8liensContract the new 8liens contract address
    function set8liens(address new8liensContract) external onlyOwner {
        $8liensContract = new8liensContract;
    }

    /// @notice allows owner to set the signer for allowances
    /// @param newSigner the new signer address
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    /// @notice allows owner to set the current tier for mints (0 = no mint; 1 = allow list; 2 = public)
    /// @param newTier the new tier
    function setCurrentTier(uint256 newTier) external onlyOwner {
        currentTier = newTier;
    }
}

interface I8liens {
    function mintTo(address to, uint256 amount) external;

    function numberMinted(address account) external view returns (uint256);
}