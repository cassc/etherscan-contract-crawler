// contracts/RedBandannaSneaker.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EndstatePreMintedNFT.sol";

/**
 * @title Shawn Thornton Foundation x Endstate
 * ShawnThorntonFoundation - a contract for the collaboration between The Shawn Thornton Foundation and Endstate.
 */
contract ShawnThorntonFoundation is EndstatePreMintedNFT
{
    address shawnThorntonWalletAddress;

    string internal _contractUri =
        "https://mint.endstate.io/ShawnThorntonFoundation/metadata.json";

   constructor(
        address wallet
   )
        EndstatePreMintedNFT(
            "Shawn Thornton Foundation x Endstate",
            shawnThorntonWalletAddress
        )
    {
        shawnThorntonWalletAddress = wallet;
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
        safeTransferFrom(shawnThorntonWalletAddress, _userWallet, _tokenId);
    }

    function updateTokenURI(uint256 tokenId, string memory newTokenURI) public {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "EndstateNFT: must have admin role to update"
        );

        _setTokenURI(tokenId, newTokenURI);
    }
}