// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "./ERC5058Upgradeable/ERC5058Upgradeable.sol";
import "./ERC721VATUpgradeable/ERC721VATUpgradeable.sol";
import "./extensions/ERC721MultiURIUpgradeable.sol";
import "./extensions/TokenWithdrawUpgradeable.sol";
import "./ERC721AUpgradeable/ERC721AUpgradeable.sol";

contract MeowMeowUpgradeable is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    IERC721ReceiverUpgradeable,
    ERC5058Upgradeable,
    ERC721VATUpgradeable,
    ERC721MultiURIUpgradeable,
    TokenWithdrawUpgradeable,
    ERC721AUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MARKET_ROLE = keccak256("MARKET_ROLE");
    bytes32 public constant VAT_ADMIN_ROLE = keccak256("VAT_ADMIN_ROLE");

    uint256 public constant MaxAvailable = 10000;

    bool public constant ChromeExtension = true;

    CountersUpgradeable.Counter private _tokenIdTracker;

    address payable private _devWallet;
    bytes32 private _wlHash;
    bool public openMint;

    IERC20Upgradeable public rewardToken;
    address public tradeRewardWallet;
    uint256 public tradeRewardPerETH;

    uint256 public freeMintMaxNum;
    uint256 public currentFreeMintNum;

    uint256 public freeMintStartAfter;
    uint256 public freeMintNumPerAddress;
    uint256 public freeMintReward;

    uint256 public publicSaleStartAfter;
    uint256 public publicSaleNumPerAddress;
    uint256 public publicSalePrice;
    uint256 public publicSaleReward;

    uint256 public wlMintStartAfter;
    uint256 public wlMintNumPerAddress;
    uint256 public wlMintPrice;
    uint256 public wlMintReward;

    mapping(address => uint256) public wlMinted;
    mapping(address => uint256) public freeMinted;

    uint256 public startTokenId;

    /* function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ERC721PausableUpgradeable.__ERC721Pausable_init();
        ERC721Upgradeable.__ERC721_init("MeowMeow", "MeowMeow");
        ERC721MultiURIUpgradeable.__ERC721MultiURI_init(
            "",
            "https://ipfs.io/ipfs/QmNsvbhQHCWYpPxJxeG7qkmFEpS8d9gmPFrdRLXE7reKaP"
        );
        __MeowMeow_init_unchained();
    }

    function __MeowMeow_init_unchained() internal onlyInitializing {
        rewardToken = IERC20Upgradeable(0x84a32718E09fD6C0045070Fe7921153A290D45C2);
        tradeRewardWallet = 0x99999ca5293f20Bf666bDf317316eB83a4863A81;
        tradeRewardPerETH = 2000000;

        _devWallet = payable(0x00000078114eA16C13D81b6b1e96c607B3831829);
        openMint = true;
        freeMintMaxNum = 1;

        freeMintStartAfter = 1659952800;
        freeMintNumPerAddress = 1;
        freeMintReward = 5000 ether;

        publicSaleStartAfter = 1660305600;
        publicSaleNumPerAddress = 5;
        publicSalePrice = 0.0069 ether;
        publicSaleReward = 15000 ether;

        wlMintStartAfter = 1660305600;
        wlMintNumPerAddress = 1;
        wlMintReward = 10000 ether;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // seaport market
        _grantRole(MARKET_ROLE, 0x00000000006c3852cbEf3e08E8dF289169EdE581);
    } */

    function setRewardToken(address token) external onlyOwner {
        rewardToken = IERC20Upgradeable(token);
    }

    function setTradeRewardPerETH(uint256 reward) external onlyOwner {
        tradeRewardPerETH = reward;
    }

    function setDevWallet(address payable newWallet) external onlyOwner {
        _devWallet = newWallet;
    }

    function setWLHash(bytes32 hash) external onlyOwner {
        _wlHash = hash;
    }

    function setFreeMintMaxNum(uint256 num) external onlyOwner {
        freeMintMaxNum = num;
    }

    function setFreeMint(
        uint256 start,
        uint256 num,
        uint256 reward
    ) external onlyOwner {
        freeMintStartAfter = start;
        freeMintNumPerAddress = num;
        freeMintReward = reward;
    }

    function setPublicSale(
        uint256 start,
        uint256 num,
        uint256 price,
        uint256 reward
    ) external onlyOwner {
        publicSaleStartAfter = start;
        publicSaleNumPerAddress = num;
        publicSalePrice = price;
        publicSaleReward = reward;
    }

    function setWLMint(
        uint256 start,
        uint256 num,
        uint256 price,
        uint256 reward
    ) external onlyOwner {
        wlMintStartAfter = start;
        wlMintNumPerAddress = num;
        wlMintPrice = price;
        wlMintReward = reward;
    }

    function setOpenMint(bool open) external onlyOwner {
        openMint = open;
    }

    function freeMint(uint256 num) external whenNotPaused {
        require(openMint, "mint ended");
        require(tx.origin == msg.sender, "only EOA");
        require(currentFreeMintNum + num <= freeMintMaxNum, "insufficient free remaining");
        require(totalSupply() + num <= MaxAvailable, "mint ended");
        require(
            freeMintNumPerAddress == 0 || freeMinted[msg.sender] + num <= freeMintNumPerAddress,
            "already free minted"
        );
        require(block.timestamp >= freeMintStartAfter && freeMintStartAfter > 0, "not start yet");

        freeMinted[msg.sender] += num;
        currentFreeMintNum += num;

        _rewardToken(num, freeMintReward * num);
    }

    function publicSale(uint256 num) external payable whenNotPaused nonReentrant {
        require(openMint, "mint ended");
        require(tx.origin == msg.sender, "only EOA");
        require(totalSupply() + num <= MaxAvailable, "mint ended");
        require(block.timestamp >= publicSaleStartAfter && publicSaleStartAfter > 0, "not start yet");
        require(publicSaleNumPerAddress == 0 || num <= publicSaleNumPerAddress, "invalid mint num");
        require(msg.value == num * publicSalePrice, "insufficient funds");

        if (publicSalePrice > 0) {
            AddressUpgradeable.sendValue(_devWallet, msg.value);
        }

        _rewardToken(num, publicSaleReward * num);
    }

    function whitelistMint(uint256 num, bytes32[] calldata proof) external payable whenNotPaused nonReentrant {
        require(openMint, "mint ended");
        require(tx.origin == msg.sender, "only EOA");
        require(totalSupply() + num <= MaxAvailable, "insufficient remaining");
        require(
            MerkleProofUpgradeable.verify(proof, _wlHash, keccak256(abi.encodePacked(msg.sender))),
            "invalid proof"
        );
        require(wlMintNumPerAddress == 0 || wlMinted[msg.sender] + num <= wlMintNumPerAddress, "already wl minted");
        require(block.timestamp >= wlMintStartAfter && wlMintStartAfter > 0, "not start yet");
        require(msg.value == num * wlMintPrice, "insufficient funds");

        if (wlMintPrice > 0) {
            AddressUpgradeable.sendValue(_devWallet, msg.value);
        } else {
            require(currentFreeMintNum + num <= freeMintMaxNum, "insufficient free remaining");
            currentFreeMintNum += num;
        }

        wlMinted[msg.sender] += num;

        _rewardToken(num, wlMintReward * num);
    }

    function increaseTokenVAT(uint256 tokenId, uint256 vat) external onlyRole(VAT_ADMIN_ROLE) {
        _increaseTokenVAT(tokenId, vat);
    }

    function _increaseTokenVAT(uint256 tokenId, uint256 vat) internal virtual override {
        super._increaseTokenVAT(tokenId, vat);

        uint256 tradeReward = tradeRewardPerETH * vat;
        if (rewardToken.allowance(tradeRewardWallet, address(this)) >= tradeReward) {
            rewardToken.transferFrom(tradeRewardWallet, currentTradeInfo.seller, tradeReward / 2);
            rewardToken.transferFrom(tradeRewardWallet, currentTradeInfo.buyer, tradeReward / 2);
        }
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721AUpgradeable, ERC721MultiURIUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function _baseURI()
        internal
        view
        override(ERC721Upgradeable, ERC721AUpgradeable, ERC721MultiURIUpgradeable)
        returns (string memory)
    {
        return super._baseURI();
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(
            ERC721Upgradeable,
            ERC721AUpgradeable,
            ERC5058Upgradeable,
            ERC721VATUpgradeable,
            ERC721MultiURIUpgradeable
        )
    {
        require(!openMint, "Not allow burn during minting period");

        if (tokenId < startTokenId) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");
            ERC721Upgradeable._burn(tokenId);
        } else {
            ERC721AUpgradeable._burn(tokenId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(
            ERC721Upgradeable,
            ERC721AUpgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable,
            ERC5058Upgradeable
        )
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        super._afterTokenTransfer(from, to, tokenId);

        _tokenSecondaryMarketTransaction(from, to, tokenId);
    }

    function _rewardToken(uint256 num, uint256 reward) internal {
        _mint(msg.sender, num);

        if (reward > 0 && rewardToken.allowance(tradeRewardWallet, address(this)) >= reward) {
            rewardToken.transferFrom(tradeRewardWallet, msg.sender, reward);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC721Upgradeable,
            ERC721AUpgradeable,
            ERC721EnumerableUpgradeable,
            ERC5058Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function pause() public onlyOwner {
        PausableUpgradeable._pause();
    }

    function unpause() public onlyOwner {
        PausableUpgradeable._unpause();
    }

    receive() external payable {}

    function ERC721A_init() external onlyOwner {
        startTokenId = ERC721EnumerableUpgradeable.totalSupply() + 1;
        ERC721AStorage.layout()._currentIndex = startTokenId;
    }

    function setCurrentIndex(uint256 tokenId) external onlyOwner {
        ERC721AStorage.layout()._currentIndex = tokenId;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return startTokenId;
    }

    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        if (tokenId < startTokenId) {
            return ERC721Upgradeable._exists(tokenId);
        }
        return ERC721AUpgradeable._exists(tokenId);
    }

    function _mint(address to, uint256 quantity) internal virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        ERC721AUpgradeable._mint(to, quantity);
    }

    function _safeMint(address to, uint256 quantity) internal virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        ERC721AUpgradeable._safeMint(to, quantity);
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        ERC721AUpgradeable._safeMint(to, quantity, _data);
    }

    function name() public view virtual override(ERC721Upgradeable, ERC721AUpgradeable) returns (string memory) {
        return ERC721Upgradeable.name();
    }

    function symbol() public view virtual override(ERC721Upgradeable, ERC721AUpgradeable) returns (string memory) {
        return ERC721Upgradeable.symbol();
    }

    function totalSupply()
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, ERC721AUpgradeable)
        returns (uint256)
    {
        return ERC721AUpgradeable.totalSupply() + _startTokenId();
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721AUpgradeable)
        returns (uint256)
    {
        return ERC721AUpgradeable.balanceOf(owner) + ERC721Upgradeable.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721AUpgradeable)
        returns (address)
    {
        if (tokenId < startTokenId) {
            return ERC721Upgradeable.ownerOf(tokenId);
        }
        return ERC721AUpgradeable.ownerOf(tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        if (tokenId < startTokenId) {
            ERC721Upgradeable.approve(to, tokenId);
        } else {
            ERC721AUpgradeable.approve(to, tokenId);
        }
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721AUpgradeable)
        returns (address)
    {
        if (tokenId < startTokenId) {
            return ERC721Upgradeable.getApproved(tokenId);
        }
        return ERC721AUpgradeable.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721Upgradeable, ERC721AUpgradeable)
    {
        ERC721Upgradeable.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.isApprovedForAll(owner, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        if (tokenId < startTokenId) {
            ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);
        } else {
            ERC721AUpgradeable.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        if (tokenId < startTokenId) {
            ERC721Upgradeable.safeTransferFrom(from, to, tokenId, "");
        } else {
            ERC721AUpgradeable.safeTransferFrom(from, to, tokenId, "");
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable, ERC721AUpgradeable) {
        if (tokenId < startTokenId) {
            ERC721Upgradeable.transferFrom(from, to, tokenId);
        } else {
            ERC721AUpgradeable.transferFrom(from, to, tokenId);
        }
    }
}