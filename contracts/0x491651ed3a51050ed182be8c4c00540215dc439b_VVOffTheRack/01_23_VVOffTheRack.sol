//SPDX-License-Identifier: MIT License (MIT)
pragma solidity ^0.8.15;

import "./access/AdminControl.sol";
import "./token/ERC721Optimized/ERC721.sol";
import "./token/ERC721Optimized/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ============ Errors ============

error InsufficientFunds();
error ExceedsMaxSupply();
error AllowlistTierTooLow();
error ExceedsWalletLimit();

contract VVOffTheRack is ERC721, ERC721Enumerable, ERC2981, AdminControl, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 2500;
    string baseURI = "";
    uint256 public MINT_PRICE = 0.25 ether;

    bytes32 public allowlistMerkleTreeRoot;
    uint256 public allowlistSaleStartTime;
    uint256 public allowlistMinimumTier;
    uint256 public publicSaleStartTime;

    mapping(address => uint256) numMintsPerAddress;
    uint16 public walletLimit;

    address payable private _paymentAddress;

    // Proxies
    mapping(address => bool) public projectProxy;

    constructor(
        uint256 _allowlistSaleStartTime,
        uint256 _publicSaleStartTime,
        address payable _splitterAddress
    ) ERC721("Vegas Vickie Off The Rack", "VVOFFTHERACK") {

        allowlistSaleStartTime = _allowlistSaleStartTime;
        allowlistMinimumTier = 4;
        publicSaleStartTime = _publicSaleStartTime;
        walletLimit = 10;

        // For Secondary Royalties
        _paymentAddress = _splitterAddress;
        // Percentage is in basis points
        _setDefaultRoyalty(_splitterAddress, 1000);

        _pause();
    }

    function ownerMint(address _to, uint256 _quantity) public onlyAdmin {
        _mintBatch(_to, _quantity);
    }

    function _mintBatch(address _to, uint256 _quantity) internal {
        if(_totalMinted() + _quantity > MAX_SUPPLY) revert ExceedsMaxSupply();

        for (uint256 i = 1; i <= _quantity; i++) {
            _mint(_to, _totalMinted() + i);
        }
    }

    // ============ Public Functions ============

    // @dev public mint function
    function mint(uint256 _quantity) whenNotPaused payable public {
        require(isPublicStage(), "Allowlist is required for this mint window");
        if(msg.value < MINT_PRICE * _quantity) revert InsufficientFunds();
        if(numMintsPerAddress[msg.sender] + _quantity > walletLimit) revert ExceedsWalletLimit();

        _mintBatch(msg.sender, _quantity);

        numMintsPerAddress[msg.sender] += _quantity;
    }

    /**
    * @notice Mints a token for the given address, if the address is on a allowlist.
    */
    function mintAllowlist(uint256 _quantity, uint priorityTier, bytes32[] calldata proof) public payable nonReentrant whenNotPaused {
        require(_quantity > 0, "Quantity must be greater than 0");
        require(isAllowlistStage(), "Allowlist is not required for this mint window");

        if(priorityTier > allowlistMinimumTier) revert AllowlistTierTooLow();

        require(_verify(_leaf(priorityTier, _msgSender()), proof), "Invalid Merkle Tree proof supplied.");

        if(msg.value < MINT_PRICE * _quantity) revert InsufficientFunds();

        _mintBatch(msg.sender, _quantity);

        numMintsPerAddress[msg.sender] += _quantity;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    // ============ Admin Functions ============

    function setBaseURI(string calldata _baseURI) public onlyAdmin {
        baseURI = _baseURI;
    }

    function setMintPrice(uint256 _price) public onlyAdmin {
        MINT_PRICE = _price;
    }

    function setAllowlistMerkleTreeRoot(bytes32 _root) public onlyAdmin {
        allowlistMerkleTreeRoot = _root;
    }

    function setPublicSaleStartTime(uint256 _time) public onlyAdmin {
        publicSaleStartTime = _time;
    }

    function setAllowlistSaleStartTime(uint256 _time) public onlyAdmin {
        allowlistSaleStartTime = _time;
    }

    function setWalletLimit(uint16 _limit) public onlyAdmin {
        walletLimit = _limit;
    }

    function setPaymentAddress(address _address) public onlyAdmin {
        _paymentAddress = payable(_address);
    }

    // @dev Any stage before the public stage is an allowlist stage
    function isAllowlistStage() internal view returns (bool) {
        return block.timestamp > allowlistSaleStartTime && block.timestamp < publicSaleStartTime;
    }

    function isPublicStage() internal view returns (bool) {
        return block.timestamp > publicSaleStartTime;
    }

    // ============ ERC2981 Royality Methods ============

    function setDefaultRoyalty(address _royaltyAddress, uint96 _feeNumerator) external onlyAdmin {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function setTokenRoyality(uint256 _tokenId, address _royaltyAddress, uint96 _feeNumerator) external onlyAdmin {
        _setTokenRoyalty(_tokenId, _royaltyAddress, _feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyAdmin {
        _resetTokenRoyalty(tokenId);
    }

    // ============ Withdrawal Methods ============

    function withdraw() external onlyAdmin {
        uint256 balance = address(this).balance;

        Address.sendValue(_paymentAddress, balance);
    }

    // ========== MerkleTree Helpers ==========

    function _leaf(uint priorityTier, address account) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked(account, priorityTier));
  }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, allowlistMerkleTreeRoot, leaf);
    }

    // ============ Proxy Functions ============

    function flipProxyState(address proxyAddress) public onlyAdmin {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    // ============ Overrides ========

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AdminControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, id);
    }

    function _mint(address account, uint256 id) internal override(ERC721) {
        super._mint(account, id);
    }

    function _burn(uint256 id) internal override(ERC721) {
        super._burn(id);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _tokenId > 0 && _tokenId <= MAX_SUPPLY,
            "URI requested for invalid token"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenId.toString()))
                : baseURI;
    }

    function isApprovedForAll(address _owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        if(projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    // Pausable

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }
}