// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "src/FloorDrop.sol";
import "@thirdweb-dev/contracts/extension/BatchMintMetadata.sol";
import "@thirdweb-dev/contracts/lib/TWStrings.sol";

contract MrNiftySax is 
    BatchMintMetadata,
    FloorDrop
{
    using TWStrings for uint256;

    address private splitWallet = 0xbEb031488bDb570A4499cDfee08CBc70Bf8F950f;
    //address private super_admin = 0x6C0425869E7D549135D8C0E5eA5EcDEBb4a448F0;

    string private newBaseUri;

    constructor() FloorDrop("Mr. Nifty Sax by Genzo & NiftySax", "MRNS", splitWallet, 1000, splitWallet, 0 ether, 0 ether, 500) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // grantRole(DEFAULT_ADMIN_ROLE, super_admin);
        // grantRole(MINTER_ROLE, super_admin);
        // grantRole(ADMIN_ROLE, super_admin);
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