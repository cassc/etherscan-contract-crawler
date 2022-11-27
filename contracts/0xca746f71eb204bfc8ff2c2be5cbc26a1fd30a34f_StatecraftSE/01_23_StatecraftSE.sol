// contracts/StatecraftSE.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EndstatePreMintedNFT.sol";

/**
 * @title Statecraft SE
 * StatecraftSE - a contract for my non-fungible Statecraft SE sneakers.
 */
contract StatecraftSE is EndstatePreMintedNFT
{
    address statecraftSEWalletAddress;

    string internal _contractUri =
        "https://www.endstate.io/drops/statecraftse/metadata.json";

    constructor(
        address wallet
    )
        EndstatePreMintedNFT(
            "Statecraft SE",
            statecraftSEWalletAddress
        )
    {
        statecraftSEWalletAddress = wallet;
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
        safeTransferFrom(statecraftSEWalletAddress, _userWallet, _tokenId);
    }
}