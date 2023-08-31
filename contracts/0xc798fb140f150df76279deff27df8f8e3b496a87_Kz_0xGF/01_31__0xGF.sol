// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IERC721xHelper.sol";
import "./interfaces/IConverterMintableERC721.sol";
import "./interfaces/IStakable.sol";

import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IERC6551Account.sol";

contract Kz_0xGF is
    ERC721x,
    IERC721xHelper,
    DefaultOperatorFiltererUpgradeable,
    IConverterMintableERC721,
    ReentrancyGuardUpgradeable,
    IStakable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using ERC165Checker for address;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;
    uint256 public MAX_SUPPLY;
    address public converter;
    bool public canStake;
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    mapping(address => bool) public whitelistedMarketplaces;

    // v2 config
    IERC6551Registry public erc6551Registry;
    address public erc6551AccountImplementation;
    IERC721 public kzgContract;
    // EnumerableSet.UintSet claimedKzgIds;
    // EnumerableSet.UintSet gfIdsFromKzg;
    address public signer;
    uint256 public MINT_PRICE;
    uint256 public MAX_MINT_PER_WL;
    mapping(address => uint256) public wlMintCount;

    // events
    event Stake(uint256 indexed tokenId);
    event Unstake(
        uint256 indexed tokenId,
        uint256 stakedAtTimestamp,
        uint256 removedFromStakeAtTimestamp
    );

    event TokenRelationship(
        uint256 indexed avycTokenId,
        uint256 indexed gfTokenId,
        address indexed minter
    );

    // event KzgClaim(
    //     uint256 indexed kzgTokenId,
    //     uint256 indexed gfTokenId,
    //     address indexed minter
    // );

    event WLMint(uint256 indexed gfTokenId, address indexed minter);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        ERC721x.__ERC721x_init("0xGF", "0xGF");
        baseTokenURI = baseURI;
        MAX_SUPPLY = 10000;
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    function setConverterAddress(address addr) external onlyOwner {
        converter = addr;
    }

    // new config
    function setupMinting(
        uint256 maxSupply,
        uint256 price,
        uint256 maxMintPerWL,
        address _kzgContract,
        address _signer,
        address _erc6551AccountImplementation,
        address _erc6551Registry
    ) external onlyOwner {
        MAX_SUPPLY = maxSupply;
        MINT_PRICE = price;
        MAX_MINT_PER_WL = maxMintPerWL;
        kzgContract = IERC721(_kzgContract);
        signer = _signer;
        erc6551AccountImplementation = _erc6551AccountImplementation;
        erc6551Registry = IERC6551Registry(_erc6551Registry);
    }

    // =============== Airdrop ===============

    function airdrop(address[] memory receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            safeMint(receiver, 1);
        }
    }

    function airdropWithAmounts(
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            safeMint(receiver, amounts[i]);
        }
    }

    // =============== Minting ===============

    // function kzgClaim(uint256 kzgId) external {
    //     require(
    //         kzgContract.ownerOf(kzgId) == msg.sender,
    //         "Must be owner of KzG"
    //     );
    //     require(!claimedKzgIds.contains(kzgId), "This KzG already claimed");
    //     address tba = erc6551Registry.account(
    //         erc6551AccountImplementation,
    //         block.chainid,
    //         address(kzgContract),
    //         kzgId,
    //         0
    //     );
    //     uint256 nextTid = _nextTokenId();
    //     claimedKzgIds.add(kzgId);
    //     // gfIdsFromKzg.add(nextTid);
    //     safeMint(tba, 1);
    //     emit KzgClaim(kzgId, nextTid, msg.sender);
    // }

    function converterMint(
        address receiver,
        uint256[] calldata avycTokenIds
    ) external nonReentrant {
        require(msg.sender == converter, "converter not set");
        require(avycTokenIds.length >= 1);
        uint256 nextTid = _nextTokenId();
        safeMint(receiver, avycTokenIds.length);
        for (uint256 i = 0; i < avycTokenIds.length; i++) {
            uint256 avycTokenId = avycTokenIds[i];
            uint256 gfTokenId = nextTid + i;
            emit TokenRelationship(avycTokenId, gfTokenId, receiver);
        }
    }

    function wlMint(bytes calldata signature, uint256 amount) external payable {
        require(amount > 0, "amount must be > 0");
        require(MAX_MINT_PER_WL > 0, "wl mint is not open");
        require(
            MINT_PRICE * amount == msg.value,
            "msg.value does not match MINT_PRICE * amount"
        );

        checkValidity(signature, "gf:wlMint");
        uint256 newAmt = wlMintCount[msg.sender] + amount;
        require(newAmt <= MAX_MINT_PER_WL, "newAmt exceeds MAX_MINT_PER_WL");
        wlMintCount[msg.sender] = newAmt;

        uint256 nextTid = _nextTokenId();
        safeMint(msg.sender, amount);
        for (uint256 i = 0; i < amount; i++) {
            uint256 gfTokenId = nextTid + i;
            emit WLMint(gfTokenId, msg.sender);
        }
    }

    function checkValidity(
        bytes calldata signature,
        string memory action
    ) public view returns (bool) {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function withdrawSales() public onlyOwner {
        uint256 balance = address(this).balance;
        _withdraw(owner(), balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    // =============== URI ===============

    // function compareStrings(
    //     string memory a,
    //     string memory b
    // ) public pure returns (bool) {
    //     return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // function tokenURI(
    //     uint256 _tokenId
    // )
    //     public
    //     view
    //     override(ERC721AUpgradeable, IERC721AUpgradeable)
    //     returns (string memory)
    // {
    //     if (bytes(tokenURIOverride).length > 0) {
    //         return tokenURIOverride;
    //     }
    //     return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    // }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // function setTokenURISuffix(
    //     string calldata _tokenURISuffix
    // ) external onlyOwner {
    //     if (compareStrings(_tokenURISuffix, "!empty!")) {
    //         tokenURISuffix = "";
    //     } else {
    //         tokenURISuffix = _tokenURISuffix;
    //     }
    // }

    // function setTokenURIOverride(
    //     string calldata _tokenURIOverride
    // ) external onlyOwner {
    //     if (compareStrings(_tokenURIOverride, "!empty!")) {
    //         tokenURIOverride = "";
    //     } else {
    //         tokenURIOverride = _tokenURIOverride;
    //     }
    // }

    // =============== STAKING ===============
    function transferCheck(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        // IERC6551Account: the ERC-165 identifier for this interface is `0x400a0398`
        if (owner.supportsInterface(0x400a0398)) {
            (
                uint256 chainId,
                address tokenContract,
                uint256 tokenId
            ) = IERC6551Account(owner).token();
            require(
                tokenContract != address(kzgContract),
                "Cannot transfer token owned by KzG TBA"
            );
        }

        if (approvedContract[msg.sender]) {
            // always allow staked emergency transfer
        } else if (whitelistedMarketplaces[msg.sender]) {
            // also allow but force unstake if wled marketplace tx
            if (tokensLastStakedAt[_tokenId] > 0) {
                uint256 lsa = tokensLastStakedAt[_tokenId];
                tokensLastStakedAt[_tokenId] = 0;
                // emit Unstake(_tokenId, msg.sender, lsa, block.timestamp);
                emit Unstake(_tokenId, lsa, block.timestamp);
            }
        } else {
            // disallow transfer
            require(
                tokensLastStakedAt[_tokenId] == 0,
                "Cannot transfer staked token"
            );
        }
    }

    function whitelistMarketplaces(
        address[] calldata markets,
        bool whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            whitelistedMarketplaces[market] = whitelisted;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721x) onlyAllowedOperator(from) {
        transferCheck(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721x) onlyAllowedOperator(from) {
        transferCheck(tokenId);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function stake(uint256 tokenId) public {
        require(canStake, "staking not open");
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId);
    }

    function unstake(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "not staking");
        uint256 lsa = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, lsa, block.timestamp);
        _emitTokenStatus(tokenId);
    }

    function setTokensStakeStatus(
        uint256[] memory tokenIds,
        bool setStake
    ) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (setStake) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    function setCanStake(bool b) external onlyOwner {
        canStake = b;
    }

    // =============== IERC721xHelper ===============
    function tokensLastStakedAtMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokensLastStakedAt[tokenIds[i]];
        }
        return part;
    }

    function isUnlockedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(
        uint256[] calldata tokenIds
    ) external view returns (address[] memory) {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function tokenNameByIndexMultiple(
        uint256[] calldata tokenIds
    ) external view returns (string[] memory) {
        string[] memory part = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokenNameByIndex(tokenIds[i]);
        }
        return part;
    }

    // =============== ??? ===============

    // function getClaimedKzgIds() external view returns (uint256[] memory) {
    //     return claimedKzgIds.values();
    // }

    // function getGfIdsFromKzg() external view returns (uint256[] memory) {
    //     return gfIdsFromKzg.values();
    // }

    function _emitTokenStatus(uint256 tokenId) internal {
        if (lockCount[tokenId] > 0) {
            emit TokenLocked(tokenId, msg.sender);
        }
        if (tokensLastStakedAt[tokenId] > 0) {
            emit Stake(tokenId);
        }
    }

    function unlockId(uint256 _id) external virtual override {
        require(_exists(_id), "Token !exist");
        _unlockId(_id);
        _emitTokenStatus(_id);
    }

    function freeId(uint256 _id, address _contract) external virtual override {
        require(_exists(_id), "Token !exist");
        _freeId(_id, _contract);
        _emitTokenStatus(_id);
    }
}