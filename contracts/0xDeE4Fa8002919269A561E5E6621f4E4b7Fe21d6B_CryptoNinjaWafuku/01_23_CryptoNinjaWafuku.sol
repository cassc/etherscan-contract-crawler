// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CryptoNinjaWafuku is DefaultOperatorFilterer, EIP2981RoyaltyOverrideCore, ERC721AntiScam, AccessControl, Pausable {
    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    address public withdrawAddress;

    // Metadata
    string public baseURI;
    string public baseExtension;

    // SaleInfo
    uint256 public salesId;
    uint256 public maxSupply;
    uint256 public mintCost;
    bool public isBurnMint;
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
    modifier withinMaxAmountPerAddress(uint256 amount, uint256 allowedAmount) {
        require(mintedAmountBySales[salesId][msg.sender] + amount <= allowedAmount, 'Over Max Amount Per Address');
        _;
    }
    modifier matchesIsBurnMintStatus(bool value) {
        require(isBurnMint == value, "Invalid IsBurnMint Status");
        _;
    }
    modifier validProof(uint256 allowedAmount, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, allowedAmount));
        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }

    // Constructor
    constructor(address _withdrawAddress) ERC721A("CryptoNinja Holiday in WAFUKU", "CNWAFUKU") {
        grantRole(ADMIN, msg.sender);
        setWithdrawAddress(_withdrawAddress);
        _pause();
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
    function mint(uint256 _amount, uint256 _allowedAmount, bytes32[] calldata _merkleProof) external payable
        whenNotPaused
        enoughEth(_amount)
        withinMaxSupply(_amount)
        withinMaxAmountPerAddress(_amount, _allowedAmount)
        matchesIsBurnMintStatus(false)
        validProof(_allowedAmount, _merkleProof)
    {
        mintedAmountBySales[salesId][msg.sender] += _amount;
        _mint(msg.sender, _amount);
    }

    function burnMint(uint256[] memory _burnTokenIds, uint256 _allowedAmount, bytes32[] calldata _merkleProof) external payable
        whenNotPaused
        enoughEth(_burnTokenIds.length)
        withinMaxSupply(_burnTokenIds.length)
        withinMaxAmountPerAddress(_burnTokenIds.length, _allowedAmount)
        matchesIsBurnMintStatus(true)
        validProof(_allowedAmount, _merkleProof)
    {
        uint256 _amount = _burnTokenIds.length;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = _burnTokenIds[i];
            require(_msgSender() == ownerOf(_tokenId));
            _burn(_tokenId);
        }
        mintedAmountBySales[salesId][msg.sender] += _amount;
        _mint(msg.sender, _amount);
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
    function getTotalBurned() view public returns (uint256) {
        return _totalBurned();
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
    function setSalesInfo(uint256 _salesId, uint256 _maxSupply, uint256 _mintCost, bool _isBurnMint, bytes32 _merkleRoot) public onlyRole(ADMIN) {
        salesId = _salesId;
        maxSupply = _maxSupply;
        mintCost = _mintCost;
        isBurnMint = _isBurnMint;
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
    function setIsBurnMint(bool _value) public onlyRole(ADMIN) {
        isBurnMint = _value;
    }
    function setMerkleRoot(bytes32 _value) public onlyRole(ADMIN) {
        merkleRoot = _value;
    }

    // Metadata
    function withdraw() public payable onlyRole(ADMIN) {
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

    // OperatorFilterer
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) payable {
        super.approve(operator, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Royalty
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyRole(ADMIN) {
        _setTokenRoyalties(royaltyConfigs);
    }
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyRole(ADMIN) {
        _setDefaultRoyalty(royalty);
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721AntiScam, EIP2981RoyaltyOverrideCore) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}