//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//         .-""-.
//        / .--. \
//       / /    \ \
//       | |    | |
//       | |.-""-.|
//      ///`.::::.`\
//     ||| ::/  \:: ;
//     ||; ::\__/:: ;
//      \\\ '::::' /
//       `=':-..-'`
//    https://duo.cash

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./interfaces/IERC721MetadataUri.sol";
import "./interfaces/IERC721Royalty.sol";

contract NFT is ERC721Enumerable, Ownable, IERC2981{

    // These implementations are the only upgradable parts
    IERC721Royalty public royaltyImplementation;
    IERC721MetadataUri public metadataImplementation;

    // Events
    event MetadataUpgraded(address indexed previousImplementation, address indexed newImplementation, address indexed upgradedBy);
    event RoyaltyUpgraded(address indexed previousImplementation, address indexed newImplementation, address indexed upgradedBy);

    // Errors
    error NonexistentToken();

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyImplementation,
        address _metadataImplementation,
        address _upgradeManager
    ) ERC721(_name, _symbol){
        royaltyImplementation = IERC721Royalty(_royaltyImplementation);
        metadataImplementation = IERC721MetadataUri(_metadataImplementation);

        // The 'owner' of this contract has no special permissions except being able
        // to change the royaltyImplementation and metadataImplementation (both are non-essential). 
        // Having the contract being 'Ownable' is also very usefull for getting
        // NFT marketplaces to list/verify us.
        _transferOwnership(_upgradeManager);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        returns (address, uint256)
    {
        return royaltyImplementation.royaltyInfo(_tokenId, _salePrice);
    }


    /// @inheritdoc ERC721
     function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if(!_exists(_tokenId)) revert NonexistentToken();
        return metadataImplementation.tokenURI(_tokenId);
    }

    /// @notice The manager of the contract can upgrade the implementation of the 'royaltyInfo' method
    /// @param _royaltyImplementation the address of the new implementation
     function upgradeRoyaltyImplementation(address _royaltyImplementation) external onlyOwner {
        emit RoyaltyUpgraded(address(royaltyImplementation), _royaltyImplementation, msg.sender);
        royaltyImplementation = IERC721Royalty(_royaltyImplementation);
    }

    /// @notice The manager of the contract can upgrade the implementation of the 'tokenURI' method
    /// @param _metadataImplementation the address of the new implementation
    function upgradeMetadataImplementation(address _metadataImplementation) external onlyOwner {
        emit MetadataUpgraded(address(metadataImplementation), _metadataImplementation, msg.sender);
        metadataImplementation = IERC721MetadataUri(_metadataImplementation);
    }

    
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}