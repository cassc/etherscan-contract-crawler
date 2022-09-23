// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC721Honoraries is ERC721A, Pausable, AccessControl {
    using Strings for uint;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public startMintId;
    address public ownerAddress;
    string public contractURI;
    string public baseTokenURI;
    address public feeCollectorAddress;
    mapping(uint => string) public uris;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
        _;
    }
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
        _;
    }

    /// @notice Constructor for the ONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _contractURI the contract URI
    /// @param _feeCollectorAddress the address fee collector
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _feeCollectorAddress) ERC721A(_name, _symbol) {
        contractURI = _contractURI;
        startMintId = 0;
        feeCollectorAddress = _feeCollectorAddress;
        ownerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint quantity) external onlyMinter {
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        return uris[tokenId];
    }

    function owner() external view returns (address) {
        return ownerAddress;
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setOwner(address _newOwner) public onlyOwner {
        ownerAddress = _newOwner;
    }

    function setURI(uint _tokenId, string memory _baseTokenURI) public onlyOwner {
        uris[_tokenId] = _baseTokenURI;
    }

    function setURIBatch(uint[] memory _tokenIds, string[] memory _baseTokenURIs) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            uris[_tokenIds[i]] = _baseTokenURIs[i];
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }
}