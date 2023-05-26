// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RedBull is ERC721Enumerable, Pausable {
    using Strings for uint256;
    string private baseURI;
    address public admin;
    address public operator;

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Restricted to admin");
        _;
    }
    modifier onlyOperator() {
        require(_msgSender() == operator, "Restricted to operator");
        _;
    }

    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor(
        address admin_, 
        address operator_,
        string memory baseURI_, 
        string memory name_, 
        string memory symbol_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        admin = admin_;
        operator = operator_;

    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function changeBaseURI(string memory newBaseURI) external onlyAdmin {
        baseURI = newBaseURI;
    }

    function _setAdmin(address newAdmin) private {
        address oldAdmin = admin;
        admin = newAdmin;
        emit OwnershipTransferred(oldAdmin, newAdmin);
    }

    function _setOperator(address newOperator) private {
        address oldOperator = operator;
        operator = newOperator;
        emit OperatorTransferred(oldOperator, newOperator);
    }

    function transferOwnership(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "NFT: new admin is the zero address");
        require(newAdmin != admin, "NFT: same admin");
        _setAdmin(newAdmin);
    }

    function transferOperator(address newOperator) external onlyAdmin {
        require(newOperator != address(0), "NFT: new operator is the zero address");
        require(newOperator != operator, "NFT: same operator");
        _setOperator(newOperator);
    }

    function mintBatch(uint256[] memory tokenIds) external onlyOperator {
        require(tokenIds.length > 0);
        for (uint i = 0; i < tokenIds.length; i++) {
            require(!_exists(tokenIds[i]));
            _mintForOperator(operator, tokenIds[i]);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override whenNotPaused {
        _mintIfNotExist(tokenId);
        if (from != to) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "NFT: caller is not token owner or approved");
            _safeTransfer(from, to, tokenId, data);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        _mintIfNotExist(tokenId);
        
        if (from != to) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "NFT: caller is not token owner or approved");
            _transfer(from, to, tokenId);
        }
    }

    function _mintForOperator(address to, uint256 tokenId) private {
        _safeMint(to, tokenId);
    }

    /*
    * mint if msg.sender is operator && tokenId not mint.
    */
    function _mintIfNotExist(uint256 tokenId) private {
        if (_msgSender() == operator) {
            if (!_exists(tokenId)) {
                _mintForOperator(operator, tokenId);
            }
        }
    }

    /**
     * override tokenURI(uint256), remove restrict for tokenId exist.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory){
        _requireMinted(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}