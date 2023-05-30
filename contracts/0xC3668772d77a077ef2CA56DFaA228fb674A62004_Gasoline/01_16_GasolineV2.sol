// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {IAccessControl, AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721A} from "./ERC721A.sol";

contract Gasoline is ERC721A, ERC2981, DefaultOperatorFilterer, AccessControl {
    uint256 public MAX_TOKEN_SUPPLY = 3333;
    uint256 public MAX_STANDARD_TOKEN_SUPPLY = 3000;
    uint256 public MAX_SUPER_TOKEN_SUPPLY = 333;

    uint256 public MAX_ALLOWLIST_TOTAL_SUPPLY = 2500;
    uint256 public MAX_ALLOWLIST_SUPER_SUPPLY = 102;
    uint256 public MAX_ALLOWLIST_STANDARD_SUPPLY = 2000;

    bool public paused = true;
    bool public publicMintPhase = false;
    bytes32 public allowlistMerkleRoot = 0x0;
    bytes32 public freeClaimMerkleRoot = 0x0;
    uint256 public price = 0.22 ether;
    bool public staking = false;

    string private baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _uri;
    }

    constructor() ERC721A("Gasoline", "GAS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setDefaultRoyalty(0xC71Df678A0026861d1975EbD7478E73F3845A2ce, 500);

        _currentIndexStandard = _standardStartTokenId();
        _currentIndexSuper = _superStartTokenId();
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowlistMerkleRoot = _merkleRoot;
    }

    function setFreeClaimMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        freeClaimMerkleRoot = _merkleRoot;
    }

    function pause(bool _pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = _pause;
    }

    function setPublicMintPhase(bool _publicMintPhase)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        publicMintPhase = _publicMintPhase;
    }

    // =============================================================
    //   MINT OPERATIONS
    // =============================================================

    modifier supplyCheck() {
        require(_totalMinted() < MAX_TOKEN_SUPPLY, "Max token supply reached.");

        _;
    }

    modifier pauseCheck() {
        require(paused == false, "Minting is paused.");

        _;
    }

    function _generateRandomNumber(address to) public view returns (uint256) {
        bytes32 blockHash = blockhash(block.number - 1);
        bytes32 combined = keccak256(
            abi.encodePacked(blockHash, block.timestamp, to)
        );
        uint256 random = uint256(combined) % 1000; // [0..999]

        return random;
    }

    function _randomMint(address minter) private {
        uint256 roll = _generateRandomNumber(minter);

        if (minter == address(0)) {
            revert MintToZeroAddress();
        }

        if (roll >= 901) {
            // if roll is [901..999]
            // then superMint
            _superMint(minter, 1);
        } else {
            // standardMint
            _standardMint(minter, 1);
        }
    }

    /**
     * @notice Each allowlisted address can mint one token (randomly rolled).
     */
    function allowlistMint(bytes32[] calldata _merkleProof)
        public
        payable
        supplyCheck
        pauseCheck
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(_numberMinted(msg.sender) == 0, "Already minted.");
        require(
            MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf),
            "Invalid Merkle proof."
        );
        require(msg.value >= price, "Incorrect ether sent.");
        require(
            totalSupply() < MAX_ALLOWLIST_TOTAL_SUPPLY,
            "Allowlist supply reached."
        );

        if (totalMintedSuper() >= MAX_ALLOWLIST_SUPER_SUPPLY) {
            _standardMint(msg.sender, 1);
        } else if (totalMintedStandard() >= MAX_ALLOWLIST_STANDARD_SUPPLY) {
            _superMint(msg.sender, 1);
        } else {
            _randomMint(msg.sender);
        }
    }

    /**
     * @notice Public mint is still 1 mint per tx (still randomly rolled).
     */
    function publicMint() public payable supplyCheck pauseCheck {
        require(publicMintPhase == true, "Public mint is not open.");
        require(msg.value >= price, "Incorrect ether sent.");

        // If one supply is tapped out, then default to the other.
        if (totalMintedStandard() >= MAX_STANDARD_TOKEN_SUPPLY) {
            _superMint(msg.sender, 1);
        } else if (totalMintedSuper() >= MAX_SUPER_TOKEN_SUPPLY) {
            _standardMint(msg.sender, 1);
        } else {
            _randomMint(msg.sender);
        }
    }

    uint256 public constant STANDARD_MINT_COST = 5;
    uint256 public constant SUPER_MINT_COST = 10;

    function freeClaimMint(
        bytes32[] calldata _merkleProof,
        uint256 _numberOfStandardMints,
        uint256 _numberOfSuperMints
    ) public supplyCheck pauseCheck {
        require(_numberOfSuperMints <= 1, "Only 1 super allowed.");
        require(_numberMinted(msg.sender) == 0, "Already minted.");

        bytes32 leaf = keccak256(
            abi.encodePacked(
                msg.sender,
                _numberOfStandardMints *
                    STANDARD_MINT_COST +
                    _numberOfSuperMints *
                    SUPER_MINT_COST
            )
        );

        require(
            MerkleProof.verify(_merkleProof, freeClaimMerkleRoot, leaf),
            "Invalid Merkle proof."
        );

        if (_numberOfStandardMints > 0) {
            _standardMint(msg.sender, _numberOfStandardMints);
        }
        if (_numberOfSuperMints > 0) {
            _superMint(msg.sender, _numberOfSuperMints);
        }
    }

    function adminMint(
        uint256 _numberOfStandardMints,
        uint256 _numberOfSuperMints
    ) external supplyCheck onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_numberOfStandardMints > 0) {
            _standardMint(msg.sender, _numberOfStandardMints);
        }
        if (_numberOfSuperMints > 0) {
            _superMint(msg.sender, _numberOfSuperMints);
        }
    }

    function _standardMint(address _to, uint256 _mintAmount) private {
        // mint 1-3000
        require(
            totalMintedStandard() + _mintAmount <= MAX_STANDARD_TOKEN_SUPPLY,
            "Will exceed token supply."
        );

        _safeMint(_to, _mintAmount, _currentIndexStandard);
        _currentIndexStandard = _currentIndexStandard + _mintAmount;
    }

    function _superMint(address _to, uint256 _mintAmount) private {
        // mint 3001-3333
        require(
            totalMintedSuper() + _mintAmount <= MAX_SUPER_TOKEN_SUPPLY,
            "Will exceed token supply."
        );
        _safeMint(_to, _mintAmount, _currentIndexSuper);
        _currentIndexSuper = _currentIndexSuper + _mintAmount;
    }

    // =============================================================
    //   TOKEN COUNTING OPERATIONS
    // =============================================================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _standardStartTokenId() internal view virtual returns (uint256) {
        return _startTokenId();
    }

    function _superStartTokenId() internal view virtual returns (uint256) {
        return 3001;
    }

    function totalMintedStandard() public view virtual returns (uint256) {
        unchecked {
            return _currentIndexStandard - _standardStartTokenId();
        }
    }

    function totalMintedSuper() public view virtual returns (uint256) {
        unchecked {
            return _currentIndexSuper - _superStartTokenId();
        }
    }

    function _totalMinted() internal view virtual override returns (uint256) {
        unchecked {
            return totalMintedStandard() + totalMintedSuper();
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalMinted();
    }

    // =============================================================
    //   STAKING OPERATIONS
    // =============================================================

    mapping(uint256 => uint256) private tokenIdToStakingStartTime;
    event Staked(uint256 indexed _tokenId, uint256 _stakingStartTime);
    event Unstaked(uint256 indexed _tokenId, uint256 _stakingEndTime);

    function setStaking(bool _staking) external onlyRole(DEFAULT_ADMIN_ROLE) {
        staking = _staking;
    }

    function _stake(uint256 tokenId) private {
        require(ownerOf(tokenId) == msg.sender, "Not owner.");

        uint256 timestamp = block.timestamp;

        tokenIdToStakingStartTime[tokenId] = timestamp;
        emit Staked(tokenId, timestamp);
    }

    function stake(uint256[] calldata tokenIds) external {
        require(staking == true, "Staking is not enabled.");

        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _stake(tokenIds[i]);
        }
    }

    function _unstake(uint256 tokenId, bool _expel) private {
        if (!_expel) {
            require(ownerOf(tokenId) == msg.sender, "Not owner.");
        }
        tokenIdToStakingStartTime[tokenId] = 0;
        emit Unstaked(tokenId, block.timestamp);
    }

    function unstake(uint256[] calldata tokenIds) external {
        require(staking == true, "Staking is not enabled.");

        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _unstake(tokenIds[i], false);
        }
    }

    function expel(uint256[] calldata tokenIds)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _unstake(tokenIds[i], true);
        }
    }

    function timeStaked(uint256 tokenId) external view returns (uint256) {
        if (tokenIdToStakingStartTime[tokenId] == 0) {
            return 0;
        }

        return block.timestamp - tokenIdToStakingStartTime[tokenId];
    }

    function stakingStartTime(uint256 tokenId) external view returns (uint256) {
        return tokenIdToStakingStartTime[tokenId];
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;

        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                tokenIdToStakingStartTime[tokenId] == 0,
                "Token is staking."
            );
        }
    }

    // =============================================================
    //   ADMIN OPERATIONS
    // =============================================================

    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
    }

    function setPrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _price;
    }

    function setMaxTokenSupply(uint256 _max)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_max <= 3333, "Cannot exceed 3333.");
        require(_max >= totalSupply(), "Less than current supply.");

        MAX_TOKEN_SUPPLY = _max;
    }

    function setMaxStandardTokenSupply(uint256 _max)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_max <= 3333, "Cannot exceed 3333.");
        require(_max >= totalMintedStandard(), "Less than current supply.");

        MAX_STANDARD_TOKEN_SUPPLY = _max;
    }

    function setMaxSuperTokenSupply(uint256 _max)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_max <= 3333, "Cannot exceed 3333.");
        require(_max >= totalMintedSuper(), "Less than current supply.");

        MAX_SUPER_TOKEN_SUPPLY = _max;
    }

    function setMaxAllowlistSuperSupply(uint256 _max)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_ALLOWLIST_SUPER_SUPPLY = _max;
    }

    function setMaxAllowlistStandardSupply(uint256 _max)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_ALLOWLIST_STANDARD_SUPPLY = _max;
    }

    function setMaxAllowlistTotalSupply(uint256 _max)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_ALLOWLIST_TOTAL_SUPPLY = _max;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // IERC721Metadata
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    // =============================================================
    //   EIP 2981 ROYALTIES
    // =============================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    // =============================================================
    //   OPERATOR FILTERING
    // =============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}