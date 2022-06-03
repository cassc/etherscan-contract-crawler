// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import { AkumuDragonz } from "./AkumuDragonz.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author frolic.eth
/// @title  Akumu Dragonz allowlist
/// @notice Patches the loop hole in the Akumu Dragonz contract, allowing folks
///         on the allowlist to claim from the remaining supply allocated to
///         this contract.
contract AkumuDragonzAllowlist is IERC721Receiver, Ownable, Pausable {

    AkumuDragonz public immutable akumuContract;
    address public claimSigner;

    mapping (address => bool) public claimers;
    uint256 public nextClaimableTokenId = 0;
    uint256 public claimableSupply = 0;

    event ClaimSignerUpdated(address previousSigner, address newSigner);


    // ****************** //
    // *** INITIALIZE *** //
    // ****************** //

    constructor(AkumuDragonz _akumuContract) {
        akumuContract = _akumuContract;
        _pause();
        emit Initialized();
    }


    // ****************** //
    // *** CONDITIONS *** //
    // ****************** //

    event Initialized();
    error InvalidSignature();
    error AlreadyClaimed(address claimer);
    error OutOfStock();
    error WrongPayment();
    error DoNotWant();


    // ******************** //
    // *** BEFORE CLAIM *** //
    // ******************** //

    /// @dev Assumes that this contract is the owner of akumuContract. This
    ///      populates the allowlist supply using the uncapped
    ///      vaultRemainingSupply method. We'll call this with a total quantity
    ///      remaining after existing mints + mint pass supply.
    function mintAllowlistSupply(uint256 quantity) external onlyOwner {
        uint256 startTokenId = akumuContract.totalMinted() + 1;
        akumuContract.vaultRemainingSupply(quantity);
        claimableSupply += quantity;
        if (nextClaimableTokenId == 0) {
            nextClaimableTokenId = startTokenId;
        }
    }

    /// @dev Transfers the akumuContract back to the owner after we've minted
    ///      the supply we need.
    function transferAkumuContract(address newOwner) external onlyOwner {
        akumuContract.transferOwnership(newOwner);
    }

    /// @dev When an AkumuDragonz is transferred to this contract, like via the
    ///      mintAllowlistSupply call above, we add the ID to the list of
    ///      tokens that can be claimed. This intentionally doesn't restrict
    ///      where these tokens come from in case someone wants to be nice.
    function onERC721Received(
        address operator,
        address from,
        uint256, // tokenId
        bytes calldata // data
    ) external view returns (bytes4) {
        // We only want AkumuDragonz tokens
        if (msg.sender != address(akumuContract)) {
            revert DoNotWant();
        }
        // And we only want them when this contract has minted them
        if (operator != address(this) && from != address(0)) {
            revert DoNotWant();
        }
        return AkumuDragonzAllowlist.onERC721Received.selector;
    }


    // ************* // 
    // *** CLAIM *** //
    // ************* //

    /// @dev This mimics the AkumuDragonz.allowlistMint function but with
    ///      stronger checks in place and pulling from the supply of tokens
    ///      held by this contract.
    function allowlistClaim(bytes memory signature)
        external
        payable
        whenNotPaused
    {
        uint256 totalMinted = akumuContract.totalMinted();
        if (claimableSupply == 0 || nextClaimableTokenId > totalMinted) {
            revert OutOfStock();
        }

        address claimer = _msgSender();
        if (akumuContract.hasMintedInGeneralSale(claimer)) {
            revert AlreadyClaimed(claimer);
        }
        if (claimers[claimer] == true) {
            revert AlreadyClaimed(claimer);
        }

        if (msg.value != 0.169 ether) {
            revert WrongPayment();
        }

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encode(_msgSender()));
        if (!SignatureChecker.isValidSignatureNow(claimSigner, messageHash, signature)) {
            revert InvalidSignature();
        }

        for (uint256 tokenId = nextClaimableTokenId; tokenId <= totalMinted; tokenId++) {
            if (akumuContract.ownerOf(tokenId) == address(this)) {
                claimers[claimer] = true;
                nextClaimableTokenId = tokenId + 1;
                claimableSupply--;
                akumuContract.safeTransferFrom(address(this), claimer, tokenId);
                return;
            }
        }

        revert OutOfStock();
    }


    // ************* //
    // *** ADMIN *** //
    // ************* //

    function setClaimSigner(address signer) external onlyOwner {
        emit ClaimSignerUpdated(claimSigner, signer);
        claimSigner = signer;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAll() external {
        require(address(this).balance > 0, "Zero balance");
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    function withdrawAllERC20(IERC20 token) external {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    /// @dev There's small possibility that, after the mint pass mint, there's
    ///      more than enough supply to fulfill the entirety of the allowlist,
    ///      so we need a way to return these back to the vault.
    function withdrawRemainingSupply(address to, uint256 quantity) external onlyOwner {
        uint256 totalMinted = akumuContract.totalMinted();
        if (claimableSupply == 0 || nextClaimableTokenId > totalMinted) {
            revert OutOfStock();
        }

        uint256 tokenId = nextClaimableTokenId;
        for (; tokenId <= totalMinted; tokenId++) {
            if (akumuContract.ownerOf(tokenId) == address(this)) {
                akumuContract.transferFrom(address(this), to, tokenId);
                claimableSupply--;
                if (--quantity == 0) {
                    nextClaimableTokenId = tokenId + 1;
                    return;
                }
            }
        }
        nextClaimableTokenId = tokenId;
        claimableSupply = 0;
    }

    /// @dev In case a token gets stuck for any reason, this lets us transfer
    ///      it back to the vault.
    function withdrawToken(address to, uint256 tokenId) external onlyOwner {
        claimableSupply--;
        if (tokenId == nextClaimableTokenId) {
            nextClaimableTokenId++;
        }
        akumuContract.transferFrom(address(this), to, tokenId);
    }
}