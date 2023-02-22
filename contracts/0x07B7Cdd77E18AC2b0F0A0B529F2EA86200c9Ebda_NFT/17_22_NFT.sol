// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../common/Ownable.sol";
import "../staking/interfaces/IFeePool.sol";
import "../token/interfaces/IERC20.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract NFT is ReentrancyGuard, ERC721Enumerable, Ownable, DefaultOperatorFilterer, ERC2981 {
    using Strings for uint256;

    bool public allowMint;
    bool public allowAlloc;
    bool public allowEnergonOps;
    uint256 public cost;
    uint256 public mintCost = 0;
    uint256 public maxSupply = 10000;
    uint256 public treasuryEditionSupply = 1000;
    uint256 public totalAllocated;
    uint256 public mintedByOwner;
    uint256 public mintedByTreasury;
    uint256 public mintedBySig;
    uint256 public mintedByAllowlist;
    address public feePool;
    address public allocator;
    address public energon;
    address public token;
    string public _contractURI;
    string public baseURI;
    string public baseExtension = ".json";
    mapping(uint256 => uint256) public p2pBalances;
    mapping(uint256 => uint256) public engBalances;
    mapping(address => mapping(uint256 => uint256)) public burnAllowances;
    mapping(address => uint256) public allowlist;
    mapping(address => mapping(uint256 => uint8)) public usedNonce;

    event UpdatedBaseExtension(string _new);
    event UpdatedBaseURI(string _new);
    event UpdatedContractURI(string _new);
    event UpdatedMaxMintAmount(uint256 _new);
    event UpdatedCost(uint256 _new);
    event UpdatedMintCost(uint256 _new);
    event Withdrawal(uint256 amt);
    event Allocated(address indexed sender, uint256 indexed _tokenId, uint256 amount);
    event AllowMint(bool allow);
    event AllowAlloc(bool allow);
    event AllowBurn(bool allow);
    event AllocatorUpdated(address addr);
    event EnergonUpdated(address addr);
    event TokenUpdated(address addr);
    event AllowAddr(address indexed addr, uint256 slot, bool add);
    event BurnedEnergon(address indexed owner, uint256 indexed _tokenId, uint256 _amount, bytes _purpose);
    event DepositedEnergon(address indexed depositor, uint256 indexed _tokenId, uint256 _amount);
    event WithdrawnEnergon(address indexed withdrawer, uint256 indexed _tokenId, uint256 _amount);
    event BurnAllowance(address indexed _owner, uint256 indexed _tokenId, address indexed _burner, uint256 _amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _maxSupply,
        uint256 _treasuryEditionSupply,
        address _feePool,
        address _allocator,
        address _energon,
        address _token
    ) ERC721(_name, _symbol) {
        baseURI = _initBaseURI;
        feePool = _feePool;
        allocator = _allocator;
        maxSupply = _maxSupply;
        treasuryEditionSupply = _treasuryEditionSupply;
        energon = _energon;
        token = _token;
    }

    /// @notice Set the FeePool contract address
    /// @dev Only owner can call
    function setFeePool(address addr) public onlyOwner {
        feePool = addr;
    }

    /// @notice Set the allocator address.
    /// @dev The allocator is the entity who can sign an allocation signature.
    /// @dev Only owner can call
    function setAllocator(address _allocator) public onlyOwner {
        allocator = _allocator;
        emit AllocatorUpdated(_allocator);
    }

    /// @notice Set the energon contract address.
    /// @dev Only owner can call
    function setEnergon(address _energon) public onlyOwner {
        energon = _energon;
        emit EnergonUpdated(_energon);
    }

    /// @notice Set the native token contract address
    /// @dev Only owner can call
    function setToken(address _token) public onlyOwner {
        token = _token;
        emit TokenUpdated(_token);
    }

    /// @dev Toggle switch to allow minting
    /// @dev Only owner can call
    function toggleAllowMint() public onlyOwner {
        allowMint = !allowMint;
        emit AllowMint(allowMint);
    }

    /// @dev Toggle switch to allow allocation
    /// @dev Only owner can call
    function toggleAllowAlloc() public onlyOwner {
        allowAlloc = !allowAlloc;
        emit AllowAlloc(allowAlloc);
    }

    /// @dev Toggle switch to allow energon operations
    /// @dev Only owner can call
    function toggleAllowEnergonOps() public onlyOwner {
        allowEnergonOps = !allowEnergonOps;
        emit AllowBurn(allowEnergonOps);
    }

    /// @notice Set the base metadata URI
    /// @dev Only owner can call
    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit UpdatedBaseURI(_newBaseURI);
    }

    /// @notice Set the base metadata extension
    /// @dev Only owner can call
    function setBaseExtension(string calldata _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
        emit UpdatedBaseExtension(_newBaseExtension);
    }

    /// @notice Set default royalty
    /// @param receiver The recipient of royalties
    /// @param feeNumerator The basis point to use as fee
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Set the cost per allocated token
    /// @dev Only owner can call
    function setCost(uint256 value) public onlyOwner {
        cost = value;
        emit UpdatedCost(value);
    }

    /// @notice Set the amount of energon required to mint
    /// @dev Only owner can call
    function setMintCost(uint256 value) public onlyOwner {
        mintCost = value;
        emit UpdatedMintCost(value);
    }

    /// @notice Set the contract URI
    function setContractURI(string calldata uri) public onlyOwner {
        _contractURI = uri;
        emit UpdatedContractURI(uri);
    }

    /// @notice Get contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Allow an address to mint without a signature and energon
    /// @param addr The target address
    /// @param slot The amount of mint slot
    /// @param add Whether to add or remove the given number of slot
    function allowAddr(
        address addr,
        uint256 slot,
        bool add
    ) public onlyOwner {
        if (add) allowlist[addr] += slot;
        else allowlist[addr] -= slot;
        emit AllowAddr(addr, slot, add);
    }

    /// @dev Get the base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Mint an NFT
    /// @param _mintAmount The amount of tokens to mint
    /// @param _signature The mint authorization signature (optional). If not provided, energon balance is used to pay for mint.
    /// @param expireAt Expiry time of the signature and also serves as a nonce for replay protection
    function mint(
        uint256 _mintAmount,
        bool _noEnergon,
        bytes calldata _signature,
        uint256 expireAt
    ) public nonReentrant {
        require(allowMint, "NFT: MINT_DISABLED");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "NFT: AMOUNT_REQ");
        require((supply - mintedByTreasury) + _mintAmount <= maxSupply - treasuryEditionSupply, "NFT: SURPASSED_MAX_SUPPLY");

        if (msg.sender != owner()) {
            if (allowlist[msg.sender] > 0) {
                require(_mintAmount <= allowlist[msg.sender], "NFT: ABOVE_SLOT_LIMIT");
                allowlist[msg.sender] -= _mintAmount;
                mintedByAllowlist += _mintAmount;
            } else {
                require(_signature.length > 0, "NFT: SIG_REQUIRED");
                require(usedNonce[msg.sender][expireAt] == 0, "NFT: SIG_NONCE_USED");
                require(verifyMintSig(allocator, msg.sender, _mintAmount, _noEnergon, expireAt, _signature), "NFT: BAD_SIG");
                require(expireAt > block.timestamp, "NFT: EXPIRED_SIG");
                usedNonce[msg.sender][expireAt] = 1;
                mintedBySig += _mintAmount;
                if (!_noEnergon && mintCost > 0) IERC20(energon).transferFrom(msg.sender, address(this), mintCost);
            }
        } else {
            mintedByOwner += _mintAmount;
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, treasuryEditionSupply + (supply - mintedByTreasury) + i);
        }
    }

    /// @notice Mint a treasury edition token
    /// @param _fromId The token id to start minting from (must not exist)
    /// @param _mintAmount The amount of tokens to mint
    function mintTE(uint256 _fromId, uint256 _mintAmount) public onlyOwner {
        require(_fromId + _mintAmount <= treasuryEditionSupply, "NFT: ID_OUT_OF_RANGE");
        for (uint256 i = _fromId; i <= _fromId + _mintAmount; i++) {
            _safeMint(msg.sender, i);
            mintedByTreasury++;
        }
    }

    /// @notice Allocate tokens based on traits
    /// @param _tokenId The token ID
    /// @param _alloc The amount to allocate
    function allocate(
        uint256 _tokenId,
        uint256 _alloc,
        bytes calldata _signature
    ) public payable nonReentrant {
        require(allowAlloc, "NFT: ALLOC_DISABLED");
        require(ownerOf(_tokenId) == msg.sender, "NFT: NOT_OWNER");
        require(verifyAllocSig(allocator, msg.sender, _tokenId, _alloc, _signature), "NFT: BAD_SIG");
        require(p2pBalances[_tokenId] == 0, "NFT: ALREADY_ALLOCATED");
        require(msg.value >= cost * _alloc, "NFT: INSUFFICIENT_DEPOSIT");
        totalAllocated += _alloc;
        p2pBalances[_tokenId] = _alloc;
        engBalances[_tokenId] = _alloc;
        IERC20(energon).mint(address(this), _alloc);
        IERC20(token).mint(address(this), _alloc);
        IFeePool(feePool).stakeNFT(_tokenId, _alloc);
        emit Allocated(msg.sender, _tokenId, _alloc);
    }

    /// @notice Return P2P token allocation
    /// @param _tokenId The token ID
    function p2pBalanceOf(uint256 _tokenId) external view returns (uint256) {
        return p2pBalances[_tokenId];
    }

    /// @notice Return energon token allocation
    /// @param _tokenId The token ID
    function engBalanceOf(uint256 _tokenId) external view returns (uint256) {
        return engBalances[_tokenId];
    }

    /// @notice Deposit energon for the given token
    /// @param _tokenId The token ID
    /// @param _amount The amount of energon to deposit
    function depositEnergon(uint256 _tokenId, uint256 _amount) external {
        require(allowEnergonOps, "NFT: DEPOSIT_DISABLED");
        engBalances[_tokenId] += _amount;
        IERC20(energon).transferFrom(msg.sender, address(this), _amount);
        emit DepositedEnergon(msg.sender, _tokenId, _amount);
    }

    /// @notice Withdraw energon from a token
    function withdrawEnergon(uint256 _tokenId, uint256 _amount) external {
        require(allowEnergonOps, "NFT: WITHDRAW_DISABLED");
        require(ownerOf(_tokenId) == msg.sender, "NFT: NOT_OWNER");
        require(engBalances[_tokenId] >= _amount, "NFT: INSUFFICIENT_BAL");
        engBalances[_tokenId] -= _amount;
        IERC20(energon).transfer(msg.sender, _amount);
        emit WithdrawnEnergon(msg.sender, _tokenId, _amount);
    }

    /// @notice Burn energon for an arbitrary purpose
    /// @param _tokenId The token ID
    /// @param _amount The amount of energon to burn
    /// @param _purpose The purpose of the energon being burned
    function burnEnergon(
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _purpose
    ) external {
        require(allowEnergonOps, "NFT: BURN_DISABLED");
        require(ownerOf(_tokenId) == msg.sender, "NFT: NOT_OWNER");
        require(engBalances[_tokenId] >= _amount, "NFT: INSUFFICIENT_BAL");
        engBalances[_tokenId] -= _amount;
        IERC20(energon).burn(_amount);
        emit BurnedEnergon(msg.sender, _tokenId, _amount, _purpose);
    }

    /// @notice Approve an address to burn an token's energon
    /// @param _tokenId The token ID
    /// @param _burner The address to permit
    /// @param _amount The amount to permit
    function burnApprove(
        uint256 _tokenId,
        address _burner,
        uint256 _amount
    ) external {
        require(allowEnergonOps, "NFT: BURN_DISABLED");
        require(ownerOf(_tokenId) == msg.sender, "NFT: NOT_OWNER");
        burnAllowances[_burner][_tokenId] += _amount;
        emit BurnAllowance(msg.sender, _tokenId, _burner, _amount);
    }

    /// @notice Get the energon burn allowance
    /// @param _tokenId The token ID
    /// @param _burner The address of the burner
    function burnAllowance(uint256 _tokenId, address _burner) external view returns (uint256) {
        return burnAllowances[_burner][_tokenId];
    }

    /// @notice Burn energon for a given token.
    /// Sender must have sufficient approved amount to burn _amount.
    /// @param _tokenId The token ID
    /// @param _amount The amount to burn.
    function burnFrom(uint256 _tokenId, uint256 _amount) external {
        require(allowEnergonOps, "NFT: BURN_DISABLED");
        require(burnAllowances[msg.sender][_tokenId] >= _amount, "NFT: LOW_ALLOWANCE");
        require(engBalances[_tokenId] >= _amount, "NFT: INSUFFICIENT_BAL");
        engBalances[_tokenId] -= _amount;
        burnAllowances[msg.sender][_tokenId] -= _amount;
        IERC20(energon).burn(_amount);
        emit BurnedEnergon(msg.sender, _tokenId, _amount, bytes(""));
    }

    /// @notice Return index of tokens owned by the target account
    /// @param _owner The address of the target account
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /// @notice Returns the token metadata URI
    /// @param tokenId The token ID
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    /// @notice Withdraw the contract balance
    /// @dev Only owner can call
    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        emit Withdrawal(bal);
    }

    /// @dev Construct mint message hash
    function getMintMessageHash(
        address _addr,
        uint256 _mintAmount,
        bool _noEnergon,
        uint256 expireAt
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _mintAmount, _noEnergon, expireAt));
    }

    /// @dev Construct allocation message hash
    function getAllocMessageHash(
        address _addr,
        uint256 _tokenId,
        uint256 _alloc
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _tokenId, _alloc));
    }

    /// @dev Construct a signed message hash
    function getSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /// @dev Recover the signer
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /// @dev Verify mint signature
    function verifyMintSig(
        address _signer,
        address _addr,
        uint256 _mintAmount,
        bool _noEnergon,
        uint256 _expireAt,
        bytes memory signature
    ) internal pure returns (bool) {
        if (address(0) == _signer) return false;
        bytes32 messageHash = getMintMessageHash(_addr, _mintAmount, _noEnergon, _expireAt);
        bytes32 ethSignedMessageHash = getSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /// @dev Verify allocation signature
    function verifyAllocSig(
        address _signer,
        address _addr,
        uint256 _tokenId,
        uint256 _alloc,
        bytes calldata signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getAllocMessageHash(_addr, _tokenId, _alloc);
        bytes32 ethSignedMessageHash = getSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}