// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Interfaces.sol";

/// @title KumaTracker NFT contract
/// @author agonist (https://github.com/agonist)
contract KumaTracker is ERC1155Pausable, Ownable {

    uint256 public constant KUMA_TRACKER = 1;

    bool public saleActive;
    bool public presaleActive;
    uint256 public immutable maxSupply;
    uint256 _totalSupply;
    uint256 public price = 0.03 ether;

    mapping(address => bool) public claimed;
    bytes32 public whitelistMerkleRoot = 0x0;

    IPaw public pawContract;

    constructor(
        string memory baseTokenURI_,
        uint256 maxSupply_
    ) ERC1155(baseTokenURI_) {
        maxSupply = maxSupply_;
    }

    function mint() external payable {
        require(saleActive, "Sale inactive");
        require(_totalSupply + 1 <= maxSupply, "Mint exceed max supply");
        require(!claimed[msg.sender], "Max mint exceeded");
        require(price == msg.value, "Value sent is incorrect");

        _totalSupply += 1;
        claimed[msg.sender] = true;
        _mint(msg.sender, KUMA_TRACKER, 1, "");
        pawContract.updateReward(msg.sender);
    }

    function mintPresale(bytes32[] calldata _merkleProof) external payable {
        require(presaleActive, "Presale inactive");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Not whitelisted");
        require(_totalSupply + 1 <= maxSupply, "Mint exceed max supply");
        require(!claimed[msg.sender], "Max mint exceeded");
        require(price == msg.value, "Value sent is incorrect");

        _totalSupply += 1;
        claimed[msg.sender] = true;
        _mint(msg.sender, KUMA_TRACKER, 1, "");
        pawContract.updateReward(msg.sender);
    }

    /// @notice Check if someone is whitelisted
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    /// toggle the main sale on or off
    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    /// @notice toggle the presale on or off
    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    /// set the base URI of the NFT
    function setBaseURI(
        string calldata _baseTokenURI
    ) external onlyOwner {
        _setURI(_baseTokenURI);
    }

    /// Override to trigger the $PAW rewards updates
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        pawContract.updateReward(from);
        pawContract.updateReward(to);
        _safeTransferFrom(from, to, id, amount, data);
    }

    /// Override to trigger the $PAW rewards updates
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        pawContract.updateReward(from);
        pawContract.updateReward(to);
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @notice for marketing / team
    /// @param _quantity Amount to mint
    function reserve(uint256 _quantity) external onlyOwner {
        require(_totalSupply + _quantity <= maxSupply, "Mint exceed max supply");
        _mint(msg.sender, KUMA_TRACKER, _quantity, "");
        pawContract.updateReward(msg.sender);
    }

    /// @notice set the merkle hash root for whitelist check
    /// @param _merkleRoot The root hash
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    function setPaw(address _address) public onlyOwner {
        pawContract = IPaw(_address);
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}