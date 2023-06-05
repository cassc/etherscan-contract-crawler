// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./interfaces/ICollectibles.sol";

contract Collectibles is ERC1155, AccessControlEnumerable, ICollectibles {
    using Strings for uint256;

    error OnlyMinterError();
    error OnlyAdminError();
    error OnlyBurnerError();
    error NonExistentTokenError();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string public name;
    string public symbol;
    string internal baseTokenURI;

    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, msg.sender)) {
            revert OnlyMinterError();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert OnlyAdminError();
        }
        _;
    }

    modifier onlyBurner() {
        if (!hasRole(BURNER_ROLE, msg.sender)) {
            revert OnlyBurnerError();
        }
        _;
    }

    /// @notice Constructor
    /// @param _symbol symbol of token
    /// @param _name name of token
    /// @param _baseMetadataURI should be in https://token-cdn-domain/{id}.json format
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseMetadataURI
    ) ERC1155(_baseMetadataURI) {
        name = _name;
        symbol = _symbol;
        baseTokenURI = _baseMetadataURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Signals support for a given interface
    /// @param interfaceId 4bytes signature of the interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice batch mints nfts. length of _tokenTypes and _amounts should be equal.
    /// @param _tokenTypes array with the token types
    /// @param _amounts amounts to be received per token type
    /// @param _receiver Address receiving the NFT
    function mintBatch(
        uint256[] memory _tokenTypes,
        uint256[] memory _amounts,
        address _receiver
    ) external override onlyMinter {
        _mintBatch(_receiver, _tokenTypes, _amounts, "");
    }

    /// @notice mint single nft
    /// @param _account account owning the nft
    /// @param _id token type to mint
    /// @param _amount amount to mint
    function mint(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external onlyMinter {
        _mint(_account, _id, _amount, "");
    }

    /// @dev Will update the base URL of token's URI
    /// @param _newBaseMetadataURI New base URL of token's URI
    function setURI(string memory _newBaseMetadataURI) public onlyAdmin {
        baseTokenURI = _newBaseMetadataURI;
        _setURI(_newBaseMetadataURI);
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString(), ".json"));
    }

    /// @notice batch burns nfts. length of _tokenTypes and _amounts should be equal.
    /// @param _tokenTypes array with the token types
    /// @param _amounts amounts to be burned per token type
    /// @param _receiver Address receiving the NFT
    function burnBatch(
        uint256[] memory _tokenTypes,
        uint256[] memory _amounts,
        address _receiver
    ) external onlyBurner {
        _burnBatch(_receiver, _tokenTypes, _amounts);
    }

    /// @notice burn single nft
    /// @param _account account owning the nft
    /// @param _id token type to burn
    /// @param _amount amount to burn
    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external onlyBurner {
        _burn(_account, _id, _amount);
    }
}