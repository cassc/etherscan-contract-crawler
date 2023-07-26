// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC4907A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../utils/LockRegistry.sol";
import "../utils/SignatureCheck.sol";

contract OliveXOniPetz is
    ERC2981,
    ERC4907A,
    SignatureCheck,
    DefaultOperatorFilterer,
    LockRegistry
{
    bytes4 private constant _INTERFACE_ID_ERC721x = 0x706e8489;
    bytes4 private constant _INTERFACE_ID_IERC4906 = 0x49064906;

    bytes32 private constant BURN_TYPEHASH =
        keccak256(
            "Burn(address operator,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );
    bytes32 private constant CLAIM_TYPEHASH =
        keccak256(
            "Claim(address to,uint256 quantity,uint256 nonce,uint256 deadline)"
        );

    uint256 public immutable MAX_SUPPLY;

    mapping(uint256 => uint256) public tokensLastStakedAt;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public claimedUsers;

    bool public operatorFilteringEnabled = true;
    address public admin;
    bool public canStake;
    bool public canClaim;
    bool public allowSetUser;
    bool public allowBurn;
    string public baseTokenURI;

    event Stake(uint256 tokenId, address by, uint256 stakedAt);
    event Unstake(
        uint256 tokenId,
        address by,
        uint256 stakedAt,
        uint256 unstakedAt
    );
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_,
        uint256 maxSupply,
        string memory baseTokenURI_,
        address receiver,
        uint96 feeNumerator
    ) ERC721A(name_, symbol_) SignatureCheck(name_, version_) {
        MAX_SUPPLY = maxSupply;
        baseTokenURI = baseTokenURI_;

        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function airdrop(address[] memory receivers, uint256[] memory quantities)
        external
        onlyOwner
    {
        uint256 count = receivers.length;
        require(
            count > 0 && count == quantities.length,
            "Invalid receivers and quantities length"
        );

        uint256 total = 0;
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            uint256 quantity = quantities[i];
            _mint(receiver, quantity);
            total += quantity;
        }
        require(_totalMinted() <= MAX_SUPPLY, "Excess MAX_SUPPLY");
    }

    function claim(
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(canClaim, "Not yet open for claim");
        require(block.timestamp <= deadline, "Signature is expired");

        address sender = _msgSender();
        require(!claimedUsers[sender], "Already claimed");
        claimedUsers[sender] = true;

        uint256 nonce = nonces[sender]++;
        bytes32 hashStruct = keccak256(
            abi.encode(CLAIM_TYPEHASH, sender, 1, nonce, deadline)
        );

        require(
            verifySignature(admin, hashStruct, v, r, s),
            "Invalid signature"
        );
        safeMint(sender, 1);
    }

    function safeMint(address to, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Excess MAX_SUPPLY");
        _mint(to, quantity);
    }

    // =============== Staking ===============
    function toggleStakeStatus() external onlyOwner {
        canStake = !canStake;
    }

    function stake(uint256 tokenId) public {
        require(canStake, "Staking not yet open");
        address sender = _msgSender();
        require(
            sender == ERC721A.ownerOf(tokenId) || sender == owner(),
            "Caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "Already staked");
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
    }

    function unstake(uint256 tokenId) public {
        address sender = _msgSender();
        require(
            sender == ERC721A.ownerOf(tokenId) || sender == owner(),
            "Caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "Not yet stake");
        uint256 stakeAt = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, sender, stakeAt, block.timestamp);
    }

    function setTokensStakeStatus(uint256[] memory tokenIds, bool setStake)
        external
    {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (setStake) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    function tokensLastStakedAtMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokensLastStakedAt[tokenIds[i]];
        }
        return part;
    }

    // =============== ERC721x ===============
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC4907A)
        returns (bool)
    {
        return
            _interfaceId == _INTERFACE_ID_ERC721x ||
            _interfaceId == _INTERFACE_ID_IERC4906 ||
            ERC4907A.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }

    function lockId(uint256 _id) external virtual override {
        require(_exists(_id), "Token not exist");
        _lockId(_id);
    }

    function unlockId(uint256 _id) external virtual override {
        require(_exists(_id), "Token not exist");
        _unlockId(_id);
    }

    function freeId(uint256 _id, address _contract) external virtual override {
        require(_exists(_id), "Token not exist");
        _freeId(_id, _contract);
    }

    // ERC721A calls transferFrom internally in its two safeTransferFrom functions
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        require(isUnlocked(tokenId), "Token is locked");
        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.transferFrom(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    // =============== OperatorFilterer ===============
    function toggleOperatorFiltering() public onlyOwner {
        operatorFilteringEnabled = !operatorFilteringEnabled;
    }

    function _checkFilterOperator(address operator) internal view override {
        if (operatorFilteringEnabled) {
            super._checkFilterOperator(operator);
        }
    }

    // =============== ERC2981 ===============
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    // =============== ERC4907 ===============
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual override {
        require(allowSetUser, "Cannot set user");
        super.setUser(tokenId, user, expires);
    }

    function toggleAllowSetUser() external onlyOwner {
        allowSetUser = !allowSetUser;
    }

    // =============== Burn ===============
    function burn(
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(allowBurn, "Cannot burn token");
        require(isUnlocked(tokenId), "Token is locked");
        require(tokensLastStakedAt[tokenId] == 0, "Cannot burn staked token");
        require(block.timestamp <= deadline, "Signature is expired");

        address operator = _msgSender();
        uint256 nonce = nonces[operator]++;
        bytes32 hashStruct = keccak256(
            abi.encode(BURN_TYPEHASH, operator, tokenId, nonce, deadline)
        );

        require(
            verifySignature(admin, hashStruct, v, r, s),
            "Invalid signature"
        );

        _burn(tokenId, true);
    }

    function toggleAllowBurn() external onlyOwner {
        allowBurn = !allowBurn;
    }

    // =============== Admin/General ===============
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function toggleClaimStatus() external onlyOwner {
        canClaim = !canClaim;
    }

    function setBaseURI(string calldata baseTokenURI_, bool updateMetadata)
        external
        onlyOwner
    {
        baseTokenURI = baseTokenURI_;
        if (updateMetadata) {
            emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
        }
    }

    function updateMetaData(uint256 tokenId) external onlyOwner {
        emit MetadataUpdate(tokenId);
    }

    function batchUpdateMetaData(uint256 fromTokenId, uint256 toTokenId)
        external
        onlyOwner
    {
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // =============== Helper ===============
    function isUnlockedMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (address[] memory)
    {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    // Handle accidently transferred ETH to contract
    function withdrawEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Fail to withdraw");
    }
}