// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./CNPRcore.sol";
import "./interface/ICNPRdescriptor.sol";

/**
 *  @title CNPRadmin abstract contract for CNPR.
 *  @dev A collection of functions that can only be operated by the owner or admin.
 */
abstract contract CNPRadmin is CNPRcore {
    /**
     *  @notice Check to see if you have admins' permissions.
     */
    modifier onlyAdmin() {
        require(
            owner() == _msgSender() || admin == _msgSender(),
            "caller is not the admin"
        );
        _;
    }

    /**
     *  @notice Move money to a designated address in an emergency.
     *  @dev Allow the owner to send funds directly to the recipient.
     *  This is for emergency purposes and use withdraw for regular withdraw.
     *  Only callable by the owner.
     *  @param _recipient The address of the recipient.
     */
    function emergencyWithdraw(address _recipient) external onlyOwner {
        require(_recipient != address(0), "recipient shouldn't be 0");
        (bool sent, ) = _recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    /**
     *  @notice Move all of the funds to the fund manager contract.
     *  @dev Only callable by the admin.
     */
    function withdraw() external onlyAdmin {
        require(
            WITHDRAW_ADDRESS != address(0),
            "WITHDRAW_ADDRESS shouldn't be 0"
        );
        (bool sent, ) = WITHDRAW_ADDRESS.call{value: address(this).balance}("");
        require(sent, "failed to move fund to WITHDRAW_ADDRESS contract");
    }

    /**
     *  @notice Set the admin.
     *  @dev Only callable by the owner.
     *  @param _admin The address of the admin.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "address shouldn't be 0");
        admin = _admin;
    }

    /**
     *  @notice Set the adminSigner.
     *  @dev Only callable by the or admin.
     *  @param _adminSigner The address of the adminSigner.
     */
    function setAdminSigner(address _adminSigner) external onlyAdmin {
        require(_adminSigner != address(0), "address shouldn't be 0");
        adminSigner = _adminSigner;
    }

    /**
     *  @notice Set the phase.
     *  @dev Only callable by the admin.
     *  @param _phase The phase number of the project.
     */
    function setPhase(SalePhase _phase) external onlyAdmin {
        phase = _phase;
    }

    /**
     *  @notice Set the burn mint cost.
     *  @dev Only callable by the admin.
     *  @param _cost The cost of the burn mint.
     */
    function setBurnMintCost(uint256 _cost) external onlyAdmin {
        burnMintCost = _cost;
    }

    /**
     *  @notice Set the max amount supply of burn mint.
     *  @dev Only callable by the admin.
     *  @param _amount The max amount supply of the burn mint.
     */
    function setMaxBurnMintSupply(uint256 _amount) external onlyAdmin {
        maxBurnMintSupply = _amount;
    }

    /**
     *  @notice Set the index of the presale coupon.
     *  @dev Only callable by the admin.
     *  @param _index The index of the presale mint.
     */
    function setPresaleMintIndex(uint256 _index) external onlyAdmin {
        presaleMintIndex = _index;
    }

    /**
     *  @notice Set the index to change the burn mint count each time and the coupon index.
     *  Makes the previous index used and unusable.
     *  @dev Only callable by the admin.
     *  @param _index The index of the burn mint.
     */
    function setBurnMintIndex(uint256 _index) external onlyAdmin {
        require(
            burnMintStructs[_index].isDone != true,
            "this index has already been used"
        );
        bool done = !burnMintStructs[burnMintIndex].isDone;
        burnMintStructs[burnMintIndex].isDone = done;
        burnMintIndex = _index;
    }

    /**
     *  @notice Set the token URI descriptor.
     *  @dev Only callable by the admin.
     *  @param _descriptor The address of the descriptor.
     */
    function setCnprDescriptor(ICNPRdescriptor _descriptor) external onlyAdmin {
        bool onChain = true;
        isOnchain = onChain;
        descriptor = _descriptor;
    }

    /**
     *  @notice Set the base URI for all token IDs.
     *  @dev Only callable by the admin.
     *  @param _baseURI The baseURI of the token.
     */
    function setBaseURI(string memory _baseURI) external onlyAdmin {
        baseURI = _baseURI;
    }

    /**
     *  @notice Set the base URI extension for all token IDs.
     *  @dev Only callable by the admin.
     *  @param _baseExtension The base extension of the token.
     */
    function setBaseExtension(string memory _baseExtension) external onlyAdmin {
        baseExtension = _baseExtension;
    }

    /**
     *  @notice Toggle a boolean value that determines if `tokenURI` returns an on-chain or off-chain.
     *  @dev Only callable by the admin.
     */
    function toggleOnchain() external onlyAdmin {
        bool onChain = !isOnchain;
        isOnchain = onChain;
    }

    /**
     *  @notice Get a boolean value whether the index was used for burn minting or not.
     *  @return True or false.
     */
    function getBurnMintIsdone() external view returns (bool) {
        return burnMintStructs[burnMintIndex].isDone;
    }

    /**
     *  @notice Get the number of burn mint set for an address.
     *  @param _address The address to be set in numberOfBurnMintByAddress.
     *  @return The number of burn mint set at the address.
     */
    function getBurnMintCount(address _address)
        external
        view
        returns (uint256)
    {
        return
            burnMintStructs[burnMintIndex].numberOfBurnMintByAddress[_address];
    }
}