// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract IcareumThe100 is ERC721Enumerable, AccessControl {

    bytes32 public constant WHITELISTED = keccak256('WHITELISTED');

    uint public constant price = .55 ether;

    uint public constant maxSupply = 100;
    uint public constant maxPerMint = 10;

    string private baseURI;
    string private contractMetadataURI;

    constructor (string memory base, string memory contractMetadata) ERC721('ICAREUM The 100', 'THE100') {
        baseURI = base;
        contractMetadataURI = contractMetadata;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint () external payable onlyRole(WHITELISTED) {
        require(msg.value >= price, 'Not enough ether sent');
        require(totalSupply() < maxSupply, 'All tokens have been minted');
        require(balanceOf(msg.sender) < maxPerMint, 'You have reached your minting limit');
        
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function contractURI () public view returns (string memory) {
        return contractMetadataURI;
    }

    // Admin

    function setBaseURI (string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function setContractURI (string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractMetadataURI = uri;
    }

    function whitelist (address[] memory addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < addresses.length; i++) {
            _setupRole(WHITELISTED, addresses[i]);
        }
    }

    function withdraw () external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

     // Overrides

    function supportsInterface (bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI (uint id) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(id), '.json'));
    }

    function _baseURI () internal view override returns (string memory) {
        return baseURI;
    }
}