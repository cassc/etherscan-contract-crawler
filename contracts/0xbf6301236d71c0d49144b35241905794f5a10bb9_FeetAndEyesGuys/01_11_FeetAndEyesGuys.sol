// SPDX-License-Identifier: MIT

/// @title Feet and Eyes Guys
/// @author Transient Labs

/*
 ____  ____  ____  ____     __   __ _  ____    ____  _  _  ____  ____     ___  _  _  _  _  ____ 
(  __)(  __)(  __)(_  _)   / _\ (  ( \(    \  (  __)( \/ )(  __)/ ___)   / __)/ )( \( \/ )/ ___)
 ) _)  ) _)  ) _)   )(    /    \/    / ) D (   ) _)  )  /  ) _) \___ \  ( (_ \) \/ ( )  / \___ \
(__)  (____)(____) (__)   \_/\_/\_)__)(____/  (____)(__/  (____)(____/   \___/\____/(__/  (____/

*/

pragma solidity ^0.8.9;

import "ERC721ATLCore.sol";

contract FeetAndEyesGuys is ERC721ATLCore {
    
    bytes32 public provenanceHash;

    constructor(address _royaltyAddress,
        uint256 _royaltyPerc, address _admin, address _payout,
        uint256 _price, uint256 _supply, bytes32 _merkleRoot, bytes32 _provenanceHash)
        ERC721ATLCore("Feet and Eyes Guys", "FEG", _royaltyAddress,
        _royaltyPerc, _price, _supply, _merkleRoot, _admin, _payout) 
    {
        provenanceHash = _provenanceHash;
    }

    /// @notice function to update the merkle root in order to implement a waitlist in addition to the regular allowlist
    /// @dev requires admin or owner
    /// @param _merkleRoot is the new merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external adminOrOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

}