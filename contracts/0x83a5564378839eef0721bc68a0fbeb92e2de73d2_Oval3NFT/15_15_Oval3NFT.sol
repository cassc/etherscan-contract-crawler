// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./interfaces/INextContract.sol";

/// @title OVAL3 NFTs contract
/// @notice a mintable ERC721 with global editable URI
/// @dev tokens can be be minted with role `MINTER_ROLE`
contract Oval3NFT is ERC721, AccessControl {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    uint256 public totalSupply;

    INextContract public nextContract;

    string private _contractUri = "https://api.oval3.game/api/collection";
    string private _baseUri = "https://api.oval3.game/api/metadata/";
    string private _extension = "";

    constructor() ERC721("Oval3", "OVL3") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        uint8 FIRST_AUCTION_SUPPLY = 31;
        for (uint256 i; i < FIRST_AUCTION_SUPPLY; i++) {
            _mint(msg.sender, i);
        }

        totalSupply = FIRST_AUCTION_SUPPLY;
    }

    /**
     * @notice batch mint with auto-increment id
     * @dev /!\ IF THIS CONTRACT IS INextContract, MIGRATION SHOULD BE FINISHED FIRST
     * @param _receivers, list of receivers
     */
    function batchMint(
        address[] calldata _receivers
    ) external onlyRole(MINTER_ROLE) {
        uint256[] memory mintedIds = new uint256[](_receivers.length);

        uint256 tokenId = totalSupply;

        for (uint256 i; i < _receivers.length; i++) {
            _safeMint(_receivers[i], tokenId + i);
            mintedIds[i] = tokenId + i;
        }

        totalSupply += _receivers.length;
    }

    /**
     * @dev Set the potential next version contract
     * @param _nextContract, address of the new contract
     */
    function setNextContract(
        address _nextContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            ERC165Checker.supportsInterface(
                _nextContract,
                type(INextContract).interfaceId
            ),
            "does not implement INextContract"
        );

        nextContract = INextContract(_nextContract);
    }

    /**
     * @notice Migrates tokens to a potential new version of this contract
     * @dev this contract MUST have `MINTER_ROLE` on the next contract
     * @param _tokenIds, list of tokens to transfer
     */
    function migrateTokens(uint256[] calldata _tokenIds) external {
        require(address(nextContract) != address(0), "next contract not set");

        address[] memory owners = new address[](_tokenIds.length);

        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                ERC721.ownerOf(_tokenIds[i]) == msg.sender,
                "migration from incorrect owner"
            );
            _burn(_tokenIds[i]);
            owners[i] = msg.sender;
        }

        nextContract.receiveTokens(_tokenIds, owners);
    }

    /**
     * @notice Force token migration to a potential new version of this contract
     * @dev this contract MUST have `MINTER_ROLE` on the next contract
     * @param _tokenIds, list of token to migrate
     */
    function forceMigrateTokens(
        uint256[] calldata _tokenIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(nextContract) != address(0), "next contract not set");

        address[] memory owners = new address[](_tokenIds.length);

        for (uint256 i; i < _tokenIds.length; i++) {
            address owner = ownerOf(_tokenIds[i]);
            _burn(_tokenIds[i]);
            owners[i] = owner;
        }

        nextContract.receiveTokens(_tokenIds, owners);
    }

    /**
     * @dev Allow ADMIN to change URI & extension
     * @param _uri, the new uri
     * @param _ext, the new extension
     */
    function setURI(
        string memory _uri,
        string memory _ext
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUri = _uri;
        _extension = _ext;
    }

    /**
     * @dev Allow ADMIN to change contractURI
     * @param _uri, the new uri
     */
    function setContractURI(
        string memory _uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractUri = _uri;
    }

    /**
     * @dev gives contract URI
     * @return uri of the contract
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /**
     * @notice gives URI of the specified tokenId
     * @param _tokenId, id of token
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _requireMinted(_tokenId);

        return
            bytes(_baseUri).length > 0
                ? string(
                    abi.encodePacked(_baseUri, _tokenId.toString(), _extension)
                )
                : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}