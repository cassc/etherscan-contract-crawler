// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicValue.sol";

/// @custom:salt Foundation
/// @custom:deploy-type deployUpgradeable
contract Foundation is
    Initializable,
    MagicValue,
    EthSafeTransfer,
    ERC20SafeTransfer,
    ImmutableFactory,
    ImmutableALCA
{
    using Address for address;

    constructor() ImmutableFactory(msg.sender) ImmutableALCA() {}

    function initialize() public initializer onlyFactory {}

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION AS ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY. depositToken distributes ALCAs
    /// to all stakers evenly should only be called during a slashing event. Any
    /// ALCA sent to this method in error will be lost. This function will
    /// fail if the circuit breaker is tripped. The magic_ parameter is intended
    /// to stop some one from successfully interacting with this method without
    /// first reading the source code and hopefully this comment
    /// @notice deposits alcas that will be distributed to the foundation
    /// @param magic_ The required control number to allow operation
    /// @param amount_ The amount of ALCA to be deposited
    function depositToken(uint8 magic_, uint256 amount_) public checkMagic(magic_) {
        // collect tokens
        _safeTransferFromERC20(IERC20Transferable(_alcaAddress()), msg.sender, amount_);
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY depositEth distributes Eth to all
    /// stakers evenly should only be called by ALCB contract any Eth sent to
    /// this method in error will be lost this function will fail if the circuit
    /// breaker is tripped the magic_ parameter is intended to stop some one from
    /// successfully interacting with this method without first reading the
    /// source code and hopefully this comment
    /// @notice deposits eths that will be distributed to the foundation
    /// @param magic_ The required control number to allow operation
    function depositEth(uint8 magic_) public payable checkMagic(magic_) {}

    /// Delegates a call to the specified contract with any set of parameters encoded
    /// @param target_ The address of the contract to be delagated to
    /// @param cdata_ The encoded parameters of the delegate call encoded
    function delegateCallAny(
        address target_,
        bytes memory cdata_
    ) public payable onlyFactory returns (bytes memory) {
        return target_.functionDelegateCall(cdata_);
    }
}