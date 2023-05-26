// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IERC721TotalSupply {
    function totalSupply() external view returns (uint256);
}

interface IERC721Mint {
    function mint(address[] calldata to_, uint256[] calldata tokenId_) external;

    function mint(address to, uint256 tokenId) external;
}

contract Ayor is ERC721, Ownable, IERC721TotalSupply, IERC721Mint {
    event NewBaseUri(string uri);
    event GrantRole(bytes32 role, address user);
    event RevokeRole(bytes32 role, address user);

    bytes32 public constant MINT_ROLE = keccak256('MINT_ROLE');

    string public baseURI;
    uint256 internal _totalSupply;

    mapping(bytes32 => mapping(address => bool)) public roles;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_
    ) ERC721(name_, symbol_) {
        baseURI = baseUri_;
    }

    function grantRole(bytes32 role, address user) external onlyOwner {
        emit GrantRole(role, user);
        roles[role][user] = true;
    }

    function revokeRole(bytes32 role, address user) external onlyOwner {
        emit RevokeRole(role, user);
        delete roles[role][user];
    }

    modifier onlyRole(bytes32 role) {
        require(roles[role][msg.sender], 'RBAC: Caller missing role');
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
        emit NewBaseUri(uri);
    }

    function mint(address[] calldata to_, uint256[] calldata tokenId_)
        external
        override
        onlyRole(MINT_ROLE)
    {
        require(to_.length == tokenId_.length, 'Mint: invalid arguments');

        for (uint256 i = 0; i < to_.length; i++) {
            address to = to_[i];
            uint256 tokenId = tokenId_[i];

            require(!_exists(tokenId), 'Mint: token already exists');
            _mint(to, tokenId);
            _totalSupply += 1;
        }
    }

    function mint(address to, uint256 tokenId) external override onlyRole(MINT_ROLE) {
        require(!_exists(tokenId), 'Mint: token already exists');
        _mint(to, tokenId);
        _totalSupply += 1;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}