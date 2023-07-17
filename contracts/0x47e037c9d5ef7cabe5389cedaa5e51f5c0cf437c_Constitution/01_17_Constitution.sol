// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Constitution is ERC1155, AccessControlEnumerable {
    using Strings for uint256;

    error OnlyAdminError();
    error OnlyUpdaterError();
    error OnlyEOAError();
    error AlreadyMintedError();
    error NonExistentTokenError();

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    string public name;
    string public symbol;
    string internal baseTokenURI;

    mapping(address => uint256) public mintedCount;
    uint256 public mintedCountTotal;

    event Mint(address indexed to, uint256 indexed tokenId, uint256 amount);

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert OnlyAdminError();
        }
        _;
    }

    modifier onlyUpdater() {
        if (!hasRole(UPDATER_ROLE, msg.sender)) {
            revert OnlyUpdaterError();
        }
        _;
    }

    modifier onlyEOA() {
        if (!isEOA()) {
            revert OnlyEOAError();
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
        string memory _baseMetadataURI,
        address _firstMint
    ) ERC1155(_baseMetadataURI) {
        name = _name;
        symbol = _symbol;
        baseTokenURI = _baseMetadataURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        mintedCount[_firstMint] ++;
        mintedCountTotal ++;
        _mint(_firstMint, 0, 1, "");
    }

    function isEOA() public view returns (bool) {
        return tx.origin == msg.sender;
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

    function mint() public onlyEOA {
        if (mintedCount[msg.sender] > 0) {
            revert AlreadyMintedError();
        }

        uint256 tokenId = 0;
        uint256 amount = 1;

        mintedCount[msg.sender] += amount;
        mintedCountTotal += amount;

        emit Mint(msg.sender, tokenId, amount);

        _mint(msg.sender, tokenId, amount, "");
    }

    /// @dev Will update the base URL of token's URI
    /// @param _newBaseMetadataURI New base URL of token's URI
    function setURI(string memory _newBaseMetadataURI) public onlyUpdater {
        baseTokenURI = _newBaseMetadataURI;
        _setURI(_newBaseMetadataURI);
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return baseTokenURI;
    }
}