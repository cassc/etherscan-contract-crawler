// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "./operator-filter-registry/DefaultOperatorFilterer.sol";

contract WeoGamePass is ERC721, Ownable, ERC2981, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) private minterRole;

    string public baseTokenURI = "";
    uint256 public constant maxSupply = 1000;

    event RoyaltySet(address _receiver, uint96 _feeNumerator);
    event BaseURISet(string _baseTokenURI);

    constructor() ERC721("WeoGamePass", "WEOGP") {
        _addMinter(msg.sender);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BaseURISet(_baseTokenURI);
    }

    //Minter Roles
    function isMinter(address account) public view returns (bool) {
        return minterRole[account];
    }

    function addMinter(address minter) public onlyOwner {
        require(minter != address(0), "Minter invalid");
        _addMinter(minter);
    }

    function removeMinter(address minter) public onlyOwner {
        require(minter != address(0), "Minter invalid");
        _removeMinter(minter);
    }

    function _addMinter(address account) internal {
        if (!isMinter(account)) {
            minterRole[account] = true;
        }
    }

    function _removeMinter(address account) internal {
        if (isMinter(account)) {
            minterRole[account] = false;
        }
    }

    function _checkMinterRole() internal view {
        require(isMinter(_msgSender()), "Minter role not granted");
    }

    modifier onlyMinter() {
        _checkMinterRole();
        _;
    }

    //Minting
    function safeMint(address to) public onlyMinter {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Reached Max Supply");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
        emit RoyaltySet(_receiver, _feeNumerator);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    //Transfer ownership
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        address oldOwner = owner();
        super.transferOwnership(newOwner);
        _addMinter(newOwner);
        _removeMinter(oldOwner);
    }

    //Operator Filtering
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}