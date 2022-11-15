// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/INft.sol";
import "./interfaces/IDynamic.sol";

contract NFTContract is ERC721A, AccessControl {
    uint256 internal _tokenIds = 1;
    uint256 internal _burnCounter = 0;
    address public coreContractAddress;
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    string private baseURI;
    string private _suffix = ".json";

    event BaseURIUpdated(string _baseURI);
    event UpdatedCoreContractAddress(address coreContractAddress);

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI
    ) ERC721A(name, symbol) {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, address(this));

        baseURI = _baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function currentIndex() public view returns (uint256) {
        return _nextTokenId();
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), _suffix));
    }

    function setBaseURI(string memory _baseURI) public onlyRole(ADMIN_ROLE) {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    function setCoreContractAdress(address _coreContractAddress) public onlyRole(ADMIN_ROLE) {
        require(_coreContractAddress != address(0), "ADDRESS ZERO");

        coreContractAddress = _coreContractAddress;
        _setupRole(EXECUTOR_ROLE, _coreContractAddress);
        emit UpdatedCoreContractAddress(_coreContractAddress);
    }

    function mint(address _to, uint256 amount) public onlyRole(EXECUTOR_ROLE) {
        _mint(_to, amount);
    }

    function burn(uint256 _tokenId) public onlyRole(EXECUTOR_ROLE) {
        require(_exists(_tokenId), "Non Existant Token");
        _burn(_tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(ERC721A) {
        IDynamic Dynamic = IDynamic(coreContractAddress);
        Dynamic.transferNft(_to, _tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }
}