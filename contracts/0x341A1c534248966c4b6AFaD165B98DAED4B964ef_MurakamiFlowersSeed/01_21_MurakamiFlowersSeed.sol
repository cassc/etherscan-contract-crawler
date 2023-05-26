// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title: Murakami.Flowers Seed
/// @author: niftykit.com

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BaseCollection.sol";

contract MurakamiFlowersSeed is
    BaseCollection,
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    AccessControl
{
    using MerkleProof for bytes32[];

    uint256 public constant SEED = 0;

    uint256 public maxSupply;

    mapping(address => uint256) private _count;

    string private _name;

    string private _symbol;

    address private _flowerAddress;

    bytes32 private _merkleRoot;

    uint256 private _price;

    bool private _active;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 price_,
        address royalty_,
        uint96 royaltyFee_,
        string memory uri_,
        address niftyKit_
    ) ERC1155(uri_) BaseCollection(_msgSender(), niftyKit_) {
        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _price = price_;
        _active = false;
        _setDefaultRoyalty(royalty_, royaltyFee_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function redeem(
        uint256 amount,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable {
        require(_active, "Not active");
        require(amount > 0, "Invalid amount");
        require(_price * amount <= msg.value, "Value incorrect");
        require(_count[_msgSender()] + amount <= allowed, "Exceeded max");
        require(totalSupply(SEED) + amount <= maxSupply, "Exceeded max supply");
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(_msgSender(), allowed))
            ),
            "Not part of list"
        );

        unchecked {
            _count[_msgSender()] = _count[_msgSender()] + amount;
        }

        _niftyKit.addFees(msg.value);
        _mint(_msgSender(), SEED, amount, "");
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(totalSupply(SEED) + amount <= maxSupply, "Exceeded max supply");

        _mint(account, SEED, amount, "");
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;
    }

    function setActive(bool newActive) external onlyOwner {
        _active = newActive;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setURI(string memory newURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setURI(newURI);
    }

    function setMerkleRoot(bytes32 newRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _merkleRoot = newRoot;
    }

    function setFlowerAddress(address newFlowerAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _flowerAddress = newFlowerAddress;
    }

    function burn(address account, uint256 amount) external {
        require(_msgSender() == _flowerAddress, "Invalid address");

        _burn(account, SEED, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function active() external view returns (bool) {
        return _active;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}