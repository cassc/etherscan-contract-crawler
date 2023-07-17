// contracts/DavidOrtizChildrensFund.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EndstatePreMintedNFT.sol";

/**
 * @title David Ortiz Children's Fund
 * DavidOrtizChildrensFund - a contract for my non-fungible David Ortiz Children's Fund sneakers.
 */
contract DavidOrtizChildrensFund is EndstatePreMintedNFT
{
    address davidOrtizChildrensFundWalletAddress;

    string internal _contractUri =
        "https://www.endstate.io/davidortiz/metadata.json";

   constructor(
        address wallet
   )
        EndstatePreMintedNFT(
            "David Ortiz Children's Fund",
            davidOrtizChildrensFundWalletAddress
        )
    {
        davidOrtizChildrensFundWalletAddress = wallet;
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
        safeTransferFrom(davidOrtizChildrensFundWalletAddress, _userWallet, _tokenId);
    }
}