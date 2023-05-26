// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "src/MintbossDrop.sol";
import "@thirdweb-dev/contracts/extension/BatchMintMetadata.sol";
import "@thirdweb-dev/contracts/lib/TWStrings.sol";

contract Artifacts is 
    BatchMintMetadata,
    MintbossDrop
{
    using TWStrings for uint256;

    address private splitWallet = 0x16FBb520F1774Dd702883867C5eF6cdE625fB64b;
    address private super_admin = 0xD06D855652A73E61Bfe26A3427Dfe51f3b827fe3;

    string private newBaseUri;

    constructor() MintbossDrop("Artifacts by Emma Miller", "ARTI", splitWallet, 1000, splitWallet, 0.005 ether, 0.005 ether, 1000) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, super_admin);
        grantRole(MINTER_ROLE, super_admin);
        grantRole(ADMIN_ROLE, super_admin);
    }

    function setBaseURI(string memory _baseURI) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Needs admin");
        newBaseUri = _baseURI;
    }

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(newBaseUri, _tokenId.toString()));
    }
}