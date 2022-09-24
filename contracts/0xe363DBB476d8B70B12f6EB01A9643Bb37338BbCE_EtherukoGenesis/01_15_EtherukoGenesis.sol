//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "hardhat/console.sol";
import "./erc721A/extensions/ERC721AQueryable.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/access/AccessControl.sol";
import "./openzeppelin/security/Pausable.sol";
import "./interface/IEtherukoGenesis.sol";

contract EtherukoGenesis is
    AccessControl,
    IEtherukoGenesis,
    Ownable,
    Pausable,
    ERC721AQueryable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _name = "EtherukoGenesis";
    string private _symbol = "ETHERUGEN";
    string public __baseURI = "https://etheruko.com/";

    uint256 public maxSupply = 10000;

    constructor() ERC721A("EtherukoGenesis", "ETHERUGEN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setName(string memory newName) external onlyOwner {
        _name = newName;
        emit SetName(newName);
    }

    function setSymbol(string memory newSymbol) external onlyOwner {
        _symbol = newSymbol;
        emit SetSymbol(newSymbol);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit SetMaxSupply(newMaxSupply);
    }

    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function grantMinter(address account) external onlyRole(MINTER_ROLE) {
        _grantRole(MINTER_ROLE, account);
        emit GrantMinter(account);
    }

    function revokeMinter(address account) external onlyRole(MINTER_ROLE) {
        _revokeRole(MINTER_ROLE, account);
        emit RevokeMinter(account);
    }

    function isPauser(address account) external view returns (bool) {
        return hasRole(PAUSER_ROLE, account);
    }

    function grantPauser(address account) external onlyRole(PAUSER_ROLE) {
        _grantRole(PAUSER_ROLE, account);
        emit GrantPauser(account);
    }

    function revokePauser(address account) external onlyRole(PAUSER_ROLE) {
        _revokeRole(PAUSER_ROLE, account);
        emit RevokePauser(account);
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
        emit SetBaseURI(newBaseURI);
    }

    function safeMint(address to, uint256 quantity)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _safeMint(to, quantity);
        emit SafeMint(to, quantity);
    }

    function safeMintBatch(
        address[] calldata toList,
        uint256[] calldata quantityList
    ) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(toList.length == quantityList.length);
        for (uint256 i = 0; i < toList.length; i++) {
            safeMint(toList[i], quantityList[i]);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
        emit Burn(tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}