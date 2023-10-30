// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solbase/utils/SafeTransferLib.sol";
import "solbase/utils/MerkleProofLib.sol";
import "solbase/utils/Clone.sol";

abstract contract ERC20 {
    function balanceOf(address) external view virtual returns (uint256);
}

contract Merkledrop is Clone {
    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;

    using MerkleProofLib for bytes32[];

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Claim(address account, uint256 amount);

    event Recovered(address to);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error InvalidProof();

    error CallerNotCreator();

    /// -----------------------------------------------------------------------
    /// Mutables
    /// -----------------------------------------------------------------------

    mapping(address => bool) public claimed;

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    function creator() public pure returns (address) {
        return _getArgAddress(12);
    }

    function asset() public pure returns (address) {
        return _getArgAddress(44);
    }

    function merkleRoot() public pure returns (bytes32) {
        return bytes32(_getArgBytes(64, 32));
    }

    /// -----------------------------------------------------------------------
    /// Transfer Helper
    /// -----------------------------------------------------------------------

    function universalTransfer(address token, address to, uint256 amount)
        internal
    {
        if (token != address(0)) {
            token.safeTransfer(to, amount);
        } else {
            to.safeTransferETH(amount);
        }
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function claim(bytes32[] calldata proof, uint256 value) external {
        bool valid = proof.verify(
            merkleRoot(), keccak256(abi.encodePacked(msg.sender, value))
        );

        if (valid && !claimed[msg.sender]) {
            claimed[msg.sender] = true;
            universalTransfer(asset(), msg.sender, value);
        } else {
            revert InvalidProof();
        }

        emit Claim(msg.sender, value);
    }

    /// @notice Allows creator to refund/remove all deposited funds.
    function recover(address token, address to) external {
        if (msg.sender != creator()) revert CallerNotCreator();

        uint256 balance = token != address(0)
            // If 'token' address is provided assume we're sending ERC20 tokens.
            ? ERC20(asset()).balanceOf(address(this))
            // Otherwise assume we're sending ether.
            : address(this).balance;

        universalTransfer(asset(), to, balance);

        emit Recovered(to);
    }
}