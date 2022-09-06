// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    TokenWithdrawUpgradeable
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

    function initialize() public initializer {
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
    }

    function setRewardToken(address token) external onlyOwner {
        rewardToken = IERC20Upgradeable(token);
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
            rewardToken.transferFrom(tradeRewardWallet, currentTradeInfo.seller, tradeReward);
        }
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721MultiURIUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function _baseURI() internal view override(ERC721Upgradeable, ERC721MultiURIUpgradeable) returns (string memory) {
        return super._baseURI();
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC5058Upgradeable, ERC721VATUpgradeable, ERC721MultiURIUpgradeable)
    {
        require(!openMint, "Not allow burn during minting period");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");

        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable, ERC5058Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._afterTokenTransfer(from, to, tokenId);

        _tokenSecondaryMarketTransaction(from, to, tokenId);
    }

    function _rewardToken(uint256 num, uint256 reward) internal {
        for (uint256 i = 0; i < num; i++) {
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current());
        }

        if (rewardToken.allowance(tradeRewardWallet, address(this)) >= reward) {
            rewardToken.transferFrom(tradeRewardWallet, msg.sender, reward);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC5058Upgradeable)
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
}