// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoseonKicks is ERC721, ERC721Pausable, AccessControl {
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private supply;
    uint256 public maxSupply = 1205;
    mapping(uint256 => string) private tokenURIMapping;
    mapping(uint256 => bool) public lockTokens;

    constructor() ERC721("RoseonKicks", "RKICKS") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function addMinter(address minterAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(minterAddress != address(0), "Target address must not be zero");
        _grantRole(MINTER_ROLE, minterAddress);
    }

    function removeMinter(address minterAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(minterAddress != address(0), "Target address must not be zero");
        _revokeRole(MINTER_ROLE, minterAddress);
    }

    /**
     * @dev not allow to direct use this method, should use it on declared function
    */
    function grantRole(bytes32 role, address account) public override pure {
        //Ignored.
    }

    /**
     * @dev not allow to direct use this method, should use it on declared function
    */
    function revokeRole(bytes32 role, address account) public override pure {
        //Ignored.
    }

    /**
     * @dev not allow to direct use this method, should use it on declared function
    */
    function renounceRole(bytes32 role, address account) public override pure {
        //Ignored.
    }

    function transferOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0), "Target address must not be zero");
        require(newOwner != _msgSender(), "Can not transfer ownership for self");
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to, string memory _tokenURI) external onlyRole(MINTER_ROLE) {
        _mint(to, _tokenURI);
    }

    function batchMint(address[] memory to, string[] memory _tokenURIs) external onlyRole(MINTER_ROLE) {
        require(_tokenURIs.length == to.length, "Array length does not equal");
        require(to.length > 0, "Array can not be empty");

        for (uint256 i = 0; i < to.length; i++) {
           _mint(to[i], _tokenURIs[i]);
        }
    }

    function _mint(address to, string memory _tokenURI) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(supply.current() < maxSupply, "ERC721: max supply reached");
        supply.increment();
        uint256 _tokenId = supply.current();
        require(!_exists(_tokenId), "ERC721: token already minted");
        super._mint(to, _tokenId);

        if (bytes(_tokenURI).length > 0)
            _setTokenURI(_tokenId, _tokenURI);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIMapping[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setTokenURIs(uint256[] memory tokenIds, string[] memory _tokenURIs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenIds.length == _tokenURIs.length, "Array length does not equal");
        require(tokenIds.length > 0, "Array can not be empty");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], _tokenURIs[i]);
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        tokenURIMapping[tokenId] = _tokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual whenNotPaused override(ERC721, ERC721Pausable) {
        ERC721Pausable._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        if (_isTokenLocked(tokenId)) {
            revert("This token id is temporarily locked");
        }
    }

    function totalSupply() external view returns (uint256) {
        return supply.current();
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
       _pause();
    }


    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
       _unpause();
    }

    function setLockToken(uint256 tokenId, bool lockState) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockTokens[tokenId] = lockState;
    }

    function setLockTokens(uint256[] calldata tokenIds, bool[] calldata lockState) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenIds.length > 0, "Token ids length must not be zero");
        require(lockState.length == 1 || lockState.length == tokenIds.length, "Both lengths does not equals");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            lockTokens[tokenIds[i]] = lockState.length == 1 ? lockState[0] : lockState[i];
        }
    }

    function isTokenLocked(uint256 tokenId) external view returns(bool) {
        return _isTokenLocked(tokenId);
    }

    function _isTokenLocked(uint256 tokenId) internal view returns(bool) {
        return lockTokens[tokenId];
    }

    function rescueERC20(address erc20Contract, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0) && !Address.isContract(recipient), "Target address must not be zero or contract address");
        IERC20 erc20 = IERC20(erc20Contract);
        require(erc20.balanceOf(address(this)) > 0, "Insufficient");
        erc20.transfer(recipient, erc20.balanceOf(address(this)));
    }

    function rescueERC721(address erc721Contract, uint256 tokenId, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0) && !Address.isContract(recipient), "Target address must not be zero or contract address");
        IERC721 erc721 = IERC721(erc721Contract);
        require(erc721.ownerOf(tokenId) == address(this), "Not the owner");
        erc721.safeTransferFrom(address(this), recipient, tokenId);
    }
}