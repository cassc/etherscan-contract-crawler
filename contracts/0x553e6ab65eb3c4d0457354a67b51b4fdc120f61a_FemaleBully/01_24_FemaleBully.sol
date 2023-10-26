//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

// claim errors
error InvalidInput();
error MaxSupplyReached();

// staking errors
error StakeNotEnabled();
error InvalidToken();
error AlreadyStaking();
error NotStaking();

contract FemaleBully is
    ERC721Upgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    UUPSUpgradeable
{
    string internal baseURI;

    uint256 public MAX_SUPPLY;
    uint256 public numberAirdropped;

    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    event Stake(uint256 indexed tokenId);
    event Unstake(uint256 indexed tokenId, uint256 stakedAtTimestamp, uint256 removedFromStakeAtTimestamp);

    address public maleBully;

    mapping (address => bool) public admins;

    event AdminSet(address indexed admin, bool status);

    modifier onlyOperator() {
        require(msg.sender == maleBully || msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address royaltyReceiver, uint96 royaltyFeeNumerator, address _maleBully) public initializer {
        __ERC721_init("Bullyverse Females", "BVF");
        __ERC2981_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();

        _transferOwnership(_owner);

        MAX_SUPPLY = 2500;
        baseURI = "https://cdn.bullyverse.io/nft/metadata/female/";
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);

        maleBully = _maleBully;
    }

    // =========================================================================
    //                              Token Logic
    // =========================================================================

    function airdrop(
        address[] calldata owners,
        uint256[] calldata femaleTokenIds
    ) external onlyOwner {
        uint256 size = owners.length;
        if (femaleTokenIds.length != size) {
            revert InvalidInput();
        }
        if (numberAirdropped + size > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        uint256 ts = block.timestamp;
        for (uint256 i = 0; i < size;) {
            address owner = owners[i];
            uint256 tokenId = femaleTokenIds[i];
            _mint(owner, tokenId);

            // stake
            tokensLastStakedAt[tokenId] = ts;
            emit Stake(tokenId);

            unchecked {
                ++i;
            }
        }

        unchecked {
            numberAirdropped += size;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // staking
    function _stake(uint256 tokenId) internal {
        if (tokensLastStakedAt[tokenId] > 0) {
            revert AlreadyStaking();
        }
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId);
    }

    function _unstake(uint256 tokenId) internal {
        if (tokensLastStakedAt[tokenId] == 0) {
            revert NotStaking();
        }
        uint256 stakedAtTimestamp = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, stakedAtTimestamp, block.timestamp);
    }

    function batchStake(uint256[] calldata tokenIds) external {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            stake(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function batchStakeFor(address owner, uint256[] calldata tokenIds) external onlyOperator {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != owner) {
                revert InvalidToken();
            }
            _stake(tokenId);
            unchecked { ++i; }
        }
    }

    function batchUnstake(uint256[] calldata tokenIds) external {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            unstake(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function batchUnstakeFor(address owner, uint256[] calldata tokenIds) external onlyOperator {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != owner) {
                revert InvalidToken();
            }
            _unstake(tokenId);
            unchecked { ++i; }
        }
    }

    function adminUnstake(uint256[] calldata tokenIds) external onlyOperator {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            _unstake(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function stake(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidToken();
        }
        _stake(tokenId);
    }

    function unstake(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidToken();
        }
        _unstake(tokenId);
    }

    function setMaleBully(address _maleBully) external onlyOwner {
        maleBully = _maleBully;
    }

    function setAdmin(address admin, bool status) external onlyOwner {
        admins[admin] = status;

        emit AdminSet(admin, status);
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================
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
        require(tokensLastStakedAt[tokenId] == 0, "Cannot transfer staked token");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        require(tokensLastStakedAt[tokenId] == 0, "Cannot transfer staked token");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        require(tokensLastStakedAt[tokenId] == 0, "Cannot transfer staked token");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId)
            || ERC2981Upgradeable.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}