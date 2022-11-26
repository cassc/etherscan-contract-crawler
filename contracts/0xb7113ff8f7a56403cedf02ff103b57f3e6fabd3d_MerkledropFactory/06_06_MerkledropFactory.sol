// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solbase/utils/SafeMulticallable.sol";
import "solbase/utils/SelfPermit.sol";
import "solbase/utils/SafeTransferLib.sol";
import "solbase/utils/LibClone.sol";

contract MerkledropFactory is SelfPermit, SafeMulticallable {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using LibClone for address;

    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event NewMerkledrop(
        address instance,
        address asset,
        bytes32 merkleRoot,
        uint256 totalAirdrop
    );

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /// -----------------------------------------------------------------------
    /// Transfer Helper
    /// -----------------------------------------------------------------------

    function universalTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (token != address(0)) {
            token.safeTransferFrom(from, to, amount);
        } else {
            to.safeTransferETH(amount);
        }
    }

    /// -----------------------------------------------------------------------
    /// Merkledrop Creation
    /// -----------------------------------------------------------------------

    function create(address asset, bytes32 merkleRoot, uint256 totalAirdrop)
        external
        payable
        returns (address merkledrop)
    {
        bytes memory immutables = abi.encode(msg.sender, asset, merkleRoot);

        if (msg.value > 0) totalAirdrop = msg.value;

        merkledrop = implementation.clone(immutables);

        universalTransferFrom(asset, msg.sender, merkledrop, totalAirdrop);

        emit NewMerkledrop(merkledrop, asset, merkleRoot, totalAirdrop);
    }

    function create(
        address asset,
        bytes32 merkleRoot,
        uint256 totalAirdrop,
        bytes32 salt
    ) external payable returns (address merkledrop) {
        bytes memory immutables = abi.encode(msg.sender, asset, merkleRoot);

        if (msg.value > 0) totalAirdrop = msg.value;

        merkledrop = implementation.cloneDeterministic(immutables, salt);

        universalTransferFrom(asset, msg.sender, merkledrop, totalAirdrop);

        emit NewMerkledrop(merkledrop, asset, merkleRoot, totalAirdrop);
    }

    /// -----------------------------------------------------------------------
    /// Viewables
    /// -----------------------------------------------------------------------

    function predictDeterministicAddress(
        address creator,
        address asset,
        bytes32 merkleRoot,
        bytes32 salt
    ) external view returns (address) {
        bytes memory immutables = abi.encode(creator, asset, merkleRoot);

        return implementation.predictDeterministicAddress(
            immutables, salt, address(this)
        );
    }
}