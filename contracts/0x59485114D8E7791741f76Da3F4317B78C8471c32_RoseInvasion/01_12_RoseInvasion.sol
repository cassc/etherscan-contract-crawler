// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";


contract RoseInvasion is Ownable, AccessControl, ReentrancyGuard, ERC721A {

    event Mint(address indexed account, uint256 indexed num);

    enum PreSaleIdentity {
        NONE,
        DOUBLELIST,
        WHITELIST
    }

    uint256 public maxSupply;
    uint256 public immutable maxPreSaleSupply;

    uint256 public preSaleMinted;

    bytes32 public merkleRootForDoublelist;
    bytes32 public merkleRootForWhitelist;

    address public benefit;

    uint256 public maxOneAccountForDoublelistMint;
    uint256 public maxOneAccountForWhitelistMint;
    uint256 public maxOneAccountForPublicMint;

    mapping(address => uint256) public amountNFTsDoubleMinted;
    mapping(address => uint256) public amountNFTsWhiteMinted;
    mapping(address => uint256) public amountNFTsPublicMinted;

    uint256 public doublelistSalePrice;
    uint256 public whitelistSalePrice;
    uint256 public publicSalePrice;

    uint256 public preMintStartTime;
    uint256 public pubMintStartTime;
    uint256 public mintEndTime;

    string private _internalBaseURI;
    string private _revealingURI;

    constructor(string memory name_, string memory symbol_, string memory revealingURI_, address benefit_) ERC721A(name_, symbol_) {

        maxSupply = 2222;
        maxPreSaleSupply = 2000;

        maxOneAccountForDoublelistMint = 2;
        maxOneAccountForWhitelistMint = 1;
        maxOneAccountForPublicMint = 1;

        doublelistSalePrice = 0.1 ether;
        whitelistSalePrice = 0.1 ether;
        publicSalePrice = 0.1 ether;

        preMintStartTime = 1662177600;
        pubMintStartTime = 1662264000;
        mintEndTime = 1662350400;

        benefit = benefit_;
        _revealingURI = revealingURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function preSaleMint(PreSaleIdentity identify_, uint256 num_, bytes32[] calldata proof_) external payable notContract nonReentrant {
        require(block.timestamp >= preMintStartTime, "not time");
        require(block.timestamp <= pubMintStartTime, "pre sale end");
        require(identify_ == PreSaleIdentity.WHITELIST || identify_ == PreSaleIdentity.DOUBLELIST, "identity error");
        bytes32 merkleRoot = bytes32(0);
        uint256 numOfMinted = 0;
        uint256 numOfMaxMint = 0;
        uint256 mintPrice = 0;
        if (identify_ == PreSaleIdentity.DOUBLELIST) {
            require(num_ == maxOneAccountForDoublelistMint);
            merkleRoot = merkleRootForDoublelist;
            numOfMinted = amountNFTsDoubleMinted[_msgSender()];
            numOfMaxMint = maxOneAccountForDoublelistMint;
            mintPrice = doublelistSalePrice;
        } else if (identify_ == PreSaleIdentity.WHITELIST) {
            require(num_ == maxOneAccountForWhitelistMint);
            merkleRoot = merkleRootForWhitelist;
            numOfMinted = amountNFTsWhiteMinted[_msgSender()];
            numOfMaxMint = maxOneAccountForWhitelistMint;
            mintPrice = whitelistSalePrice;
        } else {
            revert();
        }
        require(numOfMinted + num_ <= numOfMaxMint, "over amount");
        require(totalSupply() + num_ <= maxSupply, "over supply");
        require(preSaleMinted + num_ <= maxPreSaleSupply, "over pre sale supply");
        require(isLegalListed(proof_, merkleRoot, _msgSender()), "not in list");
        require(msg.value >= mintPrice * num_, "insufficient funds");

        if (identify_ == PreSaleIdentity.DOUBLELIST) {
            amountNFTsDoubleMinted[_msgSender()] += num_;
        } else if (identify_ == PreSaleIdentity.WHITELIST) {
            amountNFTsWhiteMinted[_msgSender()] += num_;
        } else {
            revert();
        }

        preSaleMinted += num_;
        _internalMint(msg.sender, num_);
        refundIfOver(mintPrice * num_);
        payable(benefit).transfer(mintPrice * num_);
    }

    function publicMint(uint256 num_) external payable notContract nonReentrant {
        require(block.timestamp >= pubMintStartTime && block.timestamp <= mintEndTime, "not time");
        require(num_ != 0, "num cant be zero");
        require(totalSupply() + num_ <= maxSupply, "over amount");
        require(amountNFTsPublicMinted[_msgSender()] + num_ <= maxOneAccountForPublicMint, "over limit");
        require(msg.value >= publicSalePrice * num_, "insufficient funds");

        amountNFTsPublicMinted[_msgSender()] += num_;

        _internalMint(msg.sender, num_);
        refundIfOver(publicSalePrice * num_);
        payable(benefit).transfer(publicSalePrice * num_);
    }

    function claim(address to, uint256 num) external onlyOwner {
        require(totalSupply() + num <= maxSupply, "over amount");
        _internalMint(to, num);
    }

    function _internalMint(address to, uint256 num) internal {
        super._safeMint(to, num);
        emit Mint(to, num);
    }

    function setMerkleRoots(bytes32 merkleRootForDoublelist_, bytes32 merkleRootForWhitelist_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRootForDoublelist = merkleRootForDoublelist_;
        merkleRootForWhitelist = merkleRootForWhitelist_;
    }

    function setMintTimes(uint256 preMintStartTime_, uint256 pubMintStartTime_, uint256 mintEndTime_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(preMintStartTime_ < pubMintStartTime_ && pubMintStartTime_ < mintEndTime_);
        preMintStartTime = preMintStartTime_;
        pubMintStartTime = pubMintStartTime_;
        mintEndTime = mintEndTime_;
    }

    function setMintPrices(uint256 doublelistSalePrice_, uint256 whitelistSalePrice_, uint256 publicSalePrice_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        doublelistSalePrice = doublelistSalePrice_;
        whitelistSalePrice = whitelistSalePrice_;
        publicSalePrice = publicSalePrice_;
    }

    function setNumsToMint(uint256 maxOneAccountForDoublelistMint_, uint256 maxOneAccountForWhitelistMint_, uint256 maxOneAccountForpublicMint_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxOneAccountForDoublelistMint = maxOneAccountForDoublelistMint_;
        maxOneAccountForWhitelistMint = maxOneAccountForWhitelistMint_;
        maxOneAccountForPublicMint = maxOneAccountForpublicMint_;
    }

    function setRevealingURI(string memory revealingURI_) external onlyOwner {
        _revealingURI = revealingURI_;
    }

    function setBaseURI(string memory internalBaseURI_) external onlyOwner {
        _internalBaseURI = internalBaseURI_;
    }

    function burnLeft() external onlyOwner {
        maxSupply = totalSupply();
    }

    function grantAdminRole(address account) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function claimAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBenefit(address _benefit) external onlyOwner {
        benefit = _benefit;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _internalBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "query for nonexistent token");
        if (bytes(_baseURI()).length == 0) {
            return _revealingURI;
        }
        return super.tokenURI(tokenId);
    }

    function isLegalListed(
        bytes32[] calldata proof_,
        bytes32 merkleRoot_,
        address account_
    ) private pure returns (bool) {
        return MerkleProof.verify(proof_, merkleRoot_, leaf(account_));
    }

    function leaf(address account_) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account_));
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721A) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);

        TokenOwnership memory ownership;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
            ownership = _ownershipAt(i);

            if (ownership.burned) {
                continue;
            }

            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }

            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }
}