// contracts/BoredApeYatchClub.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EndstatePreMintedNFT.sol";

/**
 * @title Bored Ape Yacht Club
 * BoredApeYatchClub - a contract for my non-fungible Bored Ape Yacht Club sneakers.
 */
contract BoredApeYatchClub is EndstatePreMintedNFT
{
    address boredApeYatchClubWalletAddress;

    string internal _contractUri =
        "https://www.endstate.io/drops/bayc/metadata.json";

    constructor(
        address wallet
    )
        EndstatePreMintedNFT(
            "Bored Ape Yacht Club",
            boredApeYatchClubWalletAddress
        )
    {
        boredApeYatchClubWalletAddress = wallet;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setContractURI(string memory contractUri_) public {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "EndstatePreMintedNFT: must have admin role to update contract URI"
        );

        _contractUri = contractUri_;
    }

    function claimTo(
        address _userWallet,
        uint256 _tokenId
    ) public {
        safeTransferFrom(boredApeYatchClubWalletAddress, _userWallet, _tokenId);
    }
}