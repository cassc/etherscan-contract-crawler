// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MiniAnisu is ERC721AntiScam, AccessControl, Pausable {
    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant PIEMENT = "PIEMENT";
    address public withdrawAddress;

    // Metadata
    string public baseURI;
    string public baseExtension;

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
        require(totalSupply() + amount <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier withinMaxAmountPerAddress(address _to, uint256 amount, uint256 allowedAmount) {
        require(mintedAmountBySales[salesId][_to] + amount <= allowedAmount, 'Over Max Amount Per Address');
        _;
    }
    modifier validProof(address _to, uint256 allowedAmount, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(_to, allowedAmount));
        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }

    // Constructor
    constructor() ERC721A("miniANISU", "MANISU") {
        grantRole(ADMIN, msg.sender);
        setWithdrawAddress(msg.sender);
    }

    // AirDrop
    function airdrop(address[] calldata _addresses, uint256[] calldata _amounts) external onlyRole(ADMIN) {
        require(_addresses.length == _amounts.length, 'Invalid Arguments');
        uint256 _supply = totalSupply();
        for (uint256 i = 0; i < _addresses.length; i++) {
            uint256 _amount = _amounts[i];
            if (_supply + _amount > maxSupply) continue;
            _mint(_addresses[i], _amount);
            _supply = _supply + _amount;
        }
    }

    // Mint
    function claim(uint256 _amount, uint256 _allowedAmount, bytes32[] calldata _merkleProof) external payable
        whenNotPaused
        enoughEth(_amount)
        withinMaxSupply(_amount)
        withinMaxAmountPerAddress(msg.sender, _amount, _allowedAmount)
        validProof(msg.sender, _allowedAmount, _merkleProof)
    {
        mintedAmountBySales[salesId][msg.sender] += _amount;
        _mint(msg.sender, _amount);
    }

    function piementClaim(address _to, uint256 _amount, uint256 _allowedAmount, bytes32[] calldata _merkleProof) external payable onlyRole(PIEMENT)
        whenNotPaused
        enoughEth(_amount)
        withinMaxSupply(_amount)
        withinMaxAmountPerAddress(_to, _amount, _allowedAmount)
        validProof(_to, _allowedAmount, _merkleProof)
    {
        mintedAmountBySales[salesId][_to] += _amount;
        _mint(_to, _amount);
    }


    // Getter
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }
    function isTokenOwner(address _owner, uint256 _tokenId) view external returns(bool) {
        return ownerOf(_tokenId) == _owner;
    }

    // Setter
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setBaseURI(string memory _value) public onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) public onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() public onlyRole(ADMIN) {
        baseExtension = "";
    }
    function setSalesInfo(uint256 _salesId, uint256 _maxSupply, uint256 _mintCost, bytes32 _merkleRoot) public onlyRole(ADMIN) {
        salesId = _salesId;
        maxSupply = _maxSupply;
        mintCost = _mintCost;
        merkleRoot = _merkleRoot;
    }
    function setSalesId(uint256 _value) public onlyRole(ADMIN) {
        salesId = _value;
    }
    function setMaxSupply(uint256 _value) public onlyRole(ADMIN) {
        maxSupply = _value;
    }
    function setMintCost(uint256 _value) public onlyRole(ADMIN) {
        mintCost = _value;
    }
    function setMerkleRoot(bytes32 _value) public onlyRole(ADMIN) {
        merkleRoot = _value;
    }

    // Metadata
    function withdraw() public onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Pausable
    function pause() public onlyRole(ADMIN) {
        _pause();
    }
    function unpause() public onlyRole(ADMIN) {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721AntiScam) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}