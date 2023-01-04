// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Batched Phased Escrow Beneficiary
/// @notice Interface expected from contracts receiving tokens from the
///         BatchedPhasedEscrow.
interface IBeneficiaryContract {
    function __escrowSentTokens(uint256 amount) external;
}

/// @title BatchedPhasedEscrow
/// @notice A token holder contract allowing contract owner to approve a set of
///         beneficiaries of tokens held by the contract, to appoint a separate
///         drawee role, and allowing that drawee to withdraw tokens to approved
///         beneficiaries in phases.
contract BatchedPhasedEscrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryApproved(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);
    event DraweeRoleTransferred(address oldDrawee, address newDrawee);

    IERC20 public token;
    address public drawee;
    mapping(address => bool) private approvedBeneficiaries;

    modifier onlyDrawee() {
        require(drawee == msg.sender, "Caller is not the drawee");
        _;
    }

    constructor(IERC20 _token) {
        token = _token;
        drawee = msg.sender;
    }

    /// @notice Approves the provided address as a beneficiary of tokens held by
    ///         the escrow. Can be called only by escrow owner.
    function approveBeneficiary(IBeneficiaryContract _beneficiary)
        external
        onlyOwner
    {
        address beneficiaryAddress = address(_beneficiary);
        require(
            beneficiaryAddress != address(0),
            "Beneficiary can not be zero address"
        );
        approvedBeneficiaries[beneficiaryAddress] = true;
        emit BeneficiaryApproved(beneficiaryAddress);
    }

    /// @notice Returns `true` if the given address has been approved as a
    ///         beneficiary of the escrow, `false` otherwise.
    function isBeneficiaryApproved(IBeneficiaryContract _beneficiary)
        public
        view
        returns (bool)
    {
        return approvedBeneficiaries[address(_beneficiary)];
    }

    /// @notice Transfers the role of drawee to another address. Can be called
    ///         only by the contract owner.
    function setDrawee(address newDrawee) external onlyOwner {
        require(newDrawee != address(0), "New drawee can not be zero address");
        emit DraweeRoleTransferred(drawee, newDrawee);
        drawee = newDrawee;
    }

    /// @notice Funds the escrow by transferring all of the approved tokens
    ///         to the escrow.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory
    ) external {
        require(IERC20(_token) == token, "Unsupported token");
        token.safeTransferFrom(_from, address(this), _value);
    }

    /// @notice Withdraws tokens from escrow to selected beneficiaries,
    ///         transferring to each beneficiary the amount of tokens specified
    ///         as a parameter. Only beneficiaries previously approved by escrow
    ///         owner can receive funds.
    function batchedWithdraw(
        IBeneficiaryContract[] memory beneficiaries,
        uint256[] memory amounts
    ) external onlyDrawee {
        require(
            beneficiaries.length == amounts.length,
            "Mismatched arrays length"
        );

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            IBeneficiaryContract beneficiary = beneficiaries[i];
            require(
                isBeneficiaryApproved(beneficiary),
                "Beneficiary was not approved"
            );
            withdraw(beneficiary, amounts[i]);
        }
    }

    function withdraw(IBeneficiaryContract beneficiary, uint256 amount)
        private
    {
        emit TokensWithdrawn(address(beneficiary), amount);
        token.safeTransfer(address(beneficiary), amount);
        // slither-disable-next-line calls-loop
        beneficiary.__escrowSentTokens(amount);
    }
}