// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./Errors.sol";
import "./ReentrancyGuard.sol";
import "../Helpers.sol";

contract BlackOnBlackNanoX is ERC721, ReentrancyGuard, AccessControl {
    // We have role for multiple accounts in case a transaction of one minter will stack (because of gas price)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // We have role for multiple accounts in case a transaction of one burner will stack (because of gas price)
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Constants
    // Maximum number of NFTs can be allocated
    uint256 public immutable maxSupply;

    // Base token and contract URI
    string private baseTokenURI;
    string private baseContractURI;

    // Current supply
    uint256 private _currentSupply;

    // Modifier that gives the ability to DEFAULT_ADMIN_ROLE to call function
    modifier onlyOwner() virtual {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Errors.NotOwner();
        _;
    }

    constructor(
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _baseContractURI,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        baseContractURI = _baseContractURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Accounts with MINTER_ROLE can call this function to mint `tokens` into `addresses`
    function airdropTokens(address[] memory addresses, uint256[] memory tokens) external onlyRole(MINTER_ROLE) lock {
        uint256 length = addresses.length;
        if (length != tokens.length)
            revert Errors.WrongInputSize();

        for (uint i; i < length; i++) {
            uint256 tokenId = tokens[i];
            if (tokenId > maxSupply || tokenId == 0)
                revert Errors.IdBeyondSupplyLimit();

            address mintAddress = addresses[i];
            _mint(mintAddress, tokenId);
        }

        unchecked {
            _currentSupply += length;
        }
    }

    function burn(uint256 id, address tokenOwner) external onlyRole(BURNER_ROLE) {
        _burnLogic(id, tokenOwner);
    }

    function setContractURI(string calldata baseContractURI_)
        external
        onlyOwner
    {
        if (bytes(baseContractURI_).length == 0)
            revert Errors.InvalidBaseContractURL();

        baseContractURI = baseContractURI_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        if (bytes(baseURI_).length == 0) revert Errors.InvalidBaseURI();

        baseTokenURI = baseURI_;
    }

    function totalSupply() external view returns (uint256) {
        return _currentSupply;
    }

    function contractURI() external view returns (string memory) {
        return baseContractURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) revert Errors.TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Helpers.uint2string(tokenId))
                )
                : "";
    }

    function _burnLogic(uint256 id, address tokenOwner) private {
        address owner_ = ownerOf(id);

        if (tokenOwner != owner_)
            revert Errors.InvalidOwner();

        _burn(id);
    }
}