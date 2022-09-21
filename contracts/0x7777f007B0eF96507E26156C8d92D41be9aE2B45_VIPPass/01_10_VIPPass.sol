// SPDX-License-Identifier: MIT
 
// ██╗░░██╗██╗██╗░░██╗░█████╗░██╗░██████╗  ██╗░░░██╗██╗██████╗░
// ██║░██╔╝██║██║░██╔╝██╔══██╗╚█║██╔════╝  ██║░░░██║██║██╔══██╗
// █████═╝░██║█████═╝░██║░░██║░╚╝╚█████╗░  ╚██╗░██╔╝██║██████╔╝
// ██╔═██╗░██║██╔═██╗░██║░░██║░░░░╚═══██╗  ░╚████╔╝░██║██╔═══╝░
// ██║░╚██╗██║██║░╚██╗╚█████╔╝░░░██████╔╝  ░░╚██╔╝░░██║██║░░░░░
// ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝░╚════╝░░░░╚═════╝░  ░░░╚═╝░░░╚═╝╚═╝░░░░░

pragma solidity ^0.8.15;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract VIPPass is ERC721AUpgradeable, OwnableUpgradeable {
    // metadata
    string public baseURI;
    bool public metadataFrozen;

    // constants
    uint256 public constant MAX_SUPPLY = 1000;

    /**
     * @dev Initializes the contract
     */
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("Kiko VIP", "VIP");
        __Ownable_init();

        baseURI = "https://kikomints.s3.us-east-2.amazonaws.com/vip/";
    }

    // --------- config ------------

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(!metadataFrozen);
        baseURI = _uri;
    }

    /**
     * @dev Freezes metadata
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen);
        metadataFrozen = true;
    }

    // --------- minting ------------

    /**
     * @dev Owner minting
     */
    function airdropOwner(address[] calldata addr, uint256[] calldata count) external onlyOwner {
        for (uint256 i=0; i<addr.length; i++) {
            _mint(addr[i], count[i]);
        }
        require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
    }

    /**
     * @dev Owner minting
     */
    function airdropOwnerOnePerAddress(address[] calldata addr) external onlyOwner {
        for (uint256 i=0; i<addr.length; i++) {
            _mint(addr[i], 1);
        }
        require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
    }
}