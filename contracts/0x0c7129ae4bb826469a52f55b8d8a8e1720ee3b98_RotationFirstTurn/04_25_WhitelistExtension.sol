// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IWhitelistExtension {
    // function setMerkleRoot(bytes32 _merkleRoot) external;
}

abstract contract WhitelistExtension is IWhitelistExtension {
    uint256 public maxWhitelistMintAmountPerTrx = 1;
    uint256 public maxWhitelistMintAmountPerAddress = 1;

    bool public whitelistMintEnabled = false;
    bytes32 public merkleRoot;

    mapping(address => uint256) public totalWhitelistMintedByAddress;

    /**
     *  @dev Checks if caller can mint
     */
    modifier canWhitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");

        require(
            _mintAmount <= maxWhitelistMintAmountPerTrx,
            "Exceeded maximum total amount per trx!"
        );
        require(
            totalWhitelistMintedByAddress[msg.sender] + _mintAmount <=
                maxWhitelistMintAmountPerAddress,
            "Exceeded maximum total amount per address!"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        _;
    }

    function _setWhitelistMintEnabled(bool _state) internal {
        whitelistMintEnabled = _state;
    }

    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
    }

    /**
     *  @notice Allows owner to set the max number of mintable items in a single transaction
     *  @param _maxAmount Max amount
     */
    function _setWhitelistMaxMintAmountPerTrx(uint256 _maxAmount) internal {
        maxWhitelistMintAmountPerTrx = _maxAmount;
    }

    /**
     *  @notice Allows owner to set the max number of mintable items per account
     *  @param _maxAmount Max amount
     */
    function _setWhitelistMaxMintAmountPerAddress(uint256 _maxAmount) internal {
        maxWhitelistMintAmountPerAddress = _maxAmount;
    }

    function _consumeWhitelist(address _account, uint256 _mintAmount) internal {
        totalWhitelistMintedByAddress[_account] += _mintAmount;
    }
}