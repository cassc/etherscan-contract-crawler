// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";

contract NiftyNuggetsOfficial is ERC721, Ownable, ReentrancyGuard, ERC2981, OperatorFilterer {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    constructor () ERC721("NiftyNuggetsOfficial", "NIFTYNUGGETSOFFICIAL") { 
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    bool public operatorFilteringEnabled;
    uint256 public constant MIGRATION_END_ID = 750;
    uint256 public constant MAX_MINT_PER_TX = 1;
    uint256 public currentTokenId = 750;
    uint256 public totalSupply = 1000;
    uint256 public totalMigrated = 0;
    bool public supplyLocked = false;
    mapping(uint256 => bool) public migrated; 
    mapping(bytes32 => bool) private _usedHashes;

    address private signerAddress;
    bool public migrationIsOn = false;
    bool public mintIsOn = false;
    uint256 public mintPrice = 0 ether;
    string public baseTokenURI = "";
    
    function migrate(bytes calldata _sig, uint256[] calldata _tokenIds)
        external
        payable
        nonReentrant
    {
        require(migrationIsOn, "MIGRATION_NOT_STARTED");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _tokenIds));
        require(!_usedHashes[hash], "HASH_ALREADY_USED");
        require(_matchSigner(hash, _sig), "INVALID_SIGNER");

        _usedHashes[hash] = true;

        for(uint i = 0; i < _tokenIds.length; i++) {
            _safeMint(msg.sender, _tokenIds[i]);
            migrated[_tokenIds[i]] = true;
            totalMigrated++;
        }
    }

    function mint(bytes calldata _sig) 
        external
        payable
        nonReentrant
    {
        require(mintIsOn, "MINT_NOT_STARTED");
        require(totalSupply >= (currentTokenId + 1), "SUPPLY_REACHED");
        require(msg.value == mintPrice, "WRONG_AMOUNT_SENT");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        require(!_usedHashes[hash], "HASH_ALREADY_USED");
        require(_matchSigner(hash, _sig), "INVALID_SIGNER");

        _usedHashes[hash] = true;
        currentTokenId++;
        _safeMint(msg.sender, currentTokenId);
    }

    function _matchSigner(bytes32 _hash, bytes memory _signature) private view returns(bool) {
        return signerAddress == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function setMigrationIsOn(bool _migrationIsOn) external onlyOwner {
        migrationIsOn = _migrationIsOn;
    }

    function setMintIsOn(bool _mintIsOn) external onlyOwner {
        mintIsOn = _mintIsOn;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string.concat(_baseURI(), Strings.toString(_tokenId));
    }

    function setTotalSuppy(uint256 _totalSupply) public onlyOwner {
        require(supplyLocked == false, "SUPPLY_LOCKED");
        totalSupply = _totalSupply;
    }

    function lockSupply() public onlyOwner {
        supplyLocked = true;
    }

    function getSignerAddress() public view onlyOwner returns(address) {
        return signerAddress;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        require(_signer != address(0), "SIGNER_ADDRESS_ZERO");
        signerAddress = _signer;
    }

    function isMigrated(uint256 _id) external view returns(bool) {
        return migrated[_id];
    }

    function withdrawBalance(address payable wallet) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "EMPTY_BALANCE");

        payable(wallet).transfer(balance);
    }

    /**
     * @dev to withdraw accidentally sent tokens
     */
    function withdrawERC20(address _token, address _to) external onlyOwner {
        IERC20 targetToken = IERC20(_token);
        uint256 balance = targetToken.balanceOf(address(this));
        require(balance > 0, "EMPTY_BALANCE");

        targetToken.transferFrom(address(this), _to, balance);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}