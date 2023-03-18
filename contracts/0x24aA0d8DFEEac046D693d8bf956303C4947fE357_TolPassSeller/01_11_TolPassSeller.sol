// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ITolPass.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TolPassSeller is AccessControl, Ownable, Pausable {
    ITolPass public tolPass;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant PIE = "PIE";
    address public withdrawAddress;

    // SaleInfo
    uint256 public salesId;
    uint256 public maxSupply;
    uint256 public mintCost;
    bytes32 merkleRoot;
    mapping(uint256 => mapping(address => uint256)) public mintedAmountBySales;

    // Modifier
    modifier enoughEth(uint256 amount) {
        require(msg.value >= amount * mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxSupply(uint256 amount) {
        require(tolPass.getTotalSupply() + amount <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier withinMintableAmount(address minter, uint256 amount, uint256 allowedAmount) {
        require(mintedAmountBySales[salesId][minter] + amount <= allowedAmount, 'Over Max Amount Per Address');
        _;
    }
    modifier validProof(address minter, uint256 allowedAmount, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(minter, allowedAmount));
        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }

    // Constructor
    constructor(address _withdrawAddress) {
        _grantRole(ADMIN, msg.sender);
        withdrawAddress = _withdrawAddress;
    }

    // AirDrop
    function airdrop(address[] calldata _addresses, uint256[] calldata _amounts) payable external onlyRole(ADMIN) {
        require(_addresses.length == _amounts.length, 'Invalid Arguments');
        uint256 supply = tolPass.getTotalSupply();
        for (uint256 i = 0; i < _addresses.length; i++) {
            uint256 _amount = _amounts[i];
            if (supply + _amount <= maxSupply) {
                tolPass.mint(_addresses[i], _amount);
                supply = supply + _amount;
            }
        }
    }

    // Mint
    function allowlistMint(uint256 _amount, uint256 _allowedAmount, bytes32[] calldata _merkleProof) external payable
        whenNotPaused
        withinMaxSupply(_amount)
        enoughEth(_amount)
        withinMintableAmount(msg.sender, _amount, _allowedAmount)
        validProof(msg.sender, _allowedAmount, _merkleProof)
    {
        mintCommon(msg.sender, _amount);
    }

    function pieMint(address _minter, uint256 _amount, uint256 _allowedAmount, bytes32[] calldata _merkleProof) external payable onlyRole(PIE)
        whenNotPaused
        withinMaxSupply(_amount)
        enoughEth(_amount)
        withinMintableAmount(_minter, _amount, _allowedAmount)
        validProof(_minter, _allowedAmount, _merkleProof)
    {
        mintCommon(_minter, _amount);
    }

    function mintCommon(address _minter, uint _amount) private {
        mintedAmountBySales[salesId][_minter] += _amount;
        tolPass.mint(_minter, _amount);
    }

    // Getter
    function totalSupply() external view returns (uint256) {
        return tolPass.getTotalSupply();
    }

    // Setter
    function setTolPass(address _address) external onlyRole(ADMIN) {
        tolPass = ITolPass(_address);
    }
    function setWithdrawAddress(address _value) external onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setSalesInfo(uint256 _salesId, uint256 _maxSupply, uint256 _mintCost, bytes32 _merkleRoot) external onlyRole(ADMIN) {
        salesId = _salesId;
        maxSupply = _maxSupply;
        mintCost = _mintCost;
        merkleRoot = _merkleRoot;
    }
    function setSalesId(uint256 _value) external onlyRole(ADMIN) {
        salesId = _value;
    }
    function setMaxSupply(uint256 _value) external onlyRole(ADMIN) {
        maxSupply = _value;
    }
    function setMintCost(uint256 _value) external onlyRole(ADMIN) {
        mintCost = _value;
    }
    function setMerkleRoot(bytes32 _value) external onlyRole(ADMIN) {
        merkleRoot = _value;
    }

    // Metadata
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }
}