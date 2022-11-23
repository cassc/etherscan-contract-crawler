// contracts/BoredApeYachtClub.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EndstatePreMintedNFT.sol";

/**
 * @title Bored Ape Yacht Club
 * BoredApeYachtClub - a contract for my non-fungible Bored Ape Yacht Club sneakers.
 */
contract BoredApeYachtClub is EndstatePreMintedNFT
{
    address boredApeYachtClubWalletAddress;

    string internal _contractUri =
        "https://www.endstate.io/drops/bayc/metadata.json";

    constructor(
        address wallet
    )
        EndstatePreMintedNFT(
            "Bored Ape Yacht Club",
            boredApeYachtClubWalletAddress
        )
    {
        boredApeYachtClubWalletAddress = wallet;
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
        safeTransferFrom(boredApeYachtClubWalletAddress, _userWallet, _tokenId);
    }
}