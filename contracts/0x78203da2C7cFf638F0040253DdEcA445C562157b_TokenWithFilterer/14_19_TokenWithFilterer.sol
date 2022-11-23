// contracts/Token.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
Ownable is used here only for implementing the interface required by some marketplaces
Use AccessControl for controlling access
*/

contract TokenWithFilterer is ERC721A, Pausable, AccessControl, DefaultOperatorFilterer, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI;
    uint64 public totalTokens;
    uint64 public tokenReserve;

    event Mint(address indexed _to, uint256 indexed _tokenId, uint256 _option);
    event ChangeTotalTokens(uint64 _totalTokens);
    event ChangeTokenReserve(uint64 _tokenReserve);
    event ChangeBaseURI(string _baseURI);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uri,
        uint64 _totalTokens,
        uint32 _tokenReserve
    ) ERC721A(_tokenName, _tokenSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());

        totalTokens = _totalTokens;
        tokenReserve = _tokenReserve;
        baseURI = _uri;
    }

    function setAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newAdmin != address(0), 'empty address');

        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _transferOwnership(_newAdmin);
    }

    function setTotalTokens(uint64 _totalTokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalTokens = _totalTokens;
        emit ChangeTotalTokens(_totalTokens);
    }

    function setTokenReserve(uint64 _tokenReserve) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenReserve = _tokenReserve;
        emit ChangeTokenReserve(_tokenReserve);
    }

    function setBaseURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
        emit ChangeBaseURI(_uri);
    }

    function addMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _minter);
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function mint(address _owner, uint256 _amount, uint256[] calldata _options) external onlyRole(MINTER_ROLE) {
        uint256 oldTotalSupply = totalSupply();

        require(oldTotalSupply + _amount <= totalTokens - tokenReserve, "no supply left");
        require(_amount == _options.length, "not enough options");

        _safeMint(_owner, _amount);
        _emitMintEvents(_owner, oldTotalSupply, _amount, _options);
    }

    function adminMint(address _owner, uint256 _amount, uint256[] calldata _options) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldTotalSupply = totalSupply();

        require(oldTotalSupply + _amount <= totalTokens, "no supply left");
        require(_amount == _options.length, "not enough options");

        _safeMint(_owner, _amount);
        _emitMintEvents(_owner, oldTotalSupply, _amount, _options);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function adminBurn(uint256 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(_tokenId);
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId, true);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _emitMintEvents(address _to, uint256 _startTokenId, uint256 _amount, uint256[] calldata _options) internal {
        for (uint256 i = 0; i < _amount; i++) {
            emit Mint(_to, i+_startTokenId, _options[i]);
        }
    }

    /*
        overridden methods to implement Opensea's Operator Filtering
    */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}