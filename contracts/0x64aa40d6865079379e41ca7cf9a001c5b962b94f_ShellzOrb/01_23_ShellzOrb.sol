// SPDX-License-Identifier: MIT
// Built for Shellz Orb by Pagzi / NFTApi
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "erc721psi/contracts/ERC721PsiUpgradeable.sol";
import "./interfaces/ILaunchpadNFT.sol";
import "./ERC721Retreatable.sol";

contract ShellzOrb is
    ILaunchpadNFT,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ERC721PsiUpgradeable,
    ERC721Retreatable
{
    error Ended();
    error NotStarted();
    error NotEOA();
    error MintTooManyAtOnce();
    error InvalidSignature();
    error ZeroQuantity();
    error ExceedMaxSupply();
    error ExceedAllowedQuantity();
    error NotEnoughETH();
    error TicketUsed();
    error ApprovalNotEnabled();

    mapping(address => uint256) public userMinted;
    mapping(address => bool) public operatorProxies;

    /* within a single storage slot */
    address public launchpad; //1-20
    uint32 public launchpadQuantity; // 21-24
    address public signer; //1-20
    uint256 public saleQuantity; // 21-24
    address public payoutWallet; //1-20
    uint32 constant LAUNCHPAD_MAX_SUPPLY = 1000; // 21-24
    uint256 public publicPrice;

    modifier onlyLaunchpad() {
        require(launchpad != address(0), "launchpad address must set");
        require(msg.sender == launchpad, "must call by launchpad");
        _;
    }

    modifier onlySigner() {
        require(msg.sender == signer, "must call by signer");
        _;
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    function initialize() public initializer {
        __ERC2981_init();
        __ERC721Psi_init("Shellz Orb", "SHELLZ");
        __Ownable_init();

        _setDefaultRoyalty(
            address(0x4393DC2e19dAa06935deD20376965b667ABA4a6F),
            500
        );

        signer = address(0xDe1736B2F811a1e43EF92f6A707b198B6C09FAa8);
        saleQuantity = 8000;
        publicPrice = 0.089 ether;
        payoutWallet = address(0x3A7606611c643bfBbc75f8BcE0cc9927Dd980Fb5); // Payout wallet
        launchpad = address(0xa2833c0fDeacfD2510243222f6FeA7881e8E6c68); // Launchpad wallet
        launchpadQuantity = LAUNCHPAD_MAX_SUPPLY;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://shellzorb.nftapi.art/meta/";
    }

    /**
    
        Retreating related functions.

     */
    function setRetreatingEnable(bool enableRetreating) external onlyOwner {
        _setRetreatingEnable(enableRetreating);
    }

    function kickFromRetreat(uint256 tokenId) external onlyOwner {
        _kickRetreating(tokenId);
    }

    function swapRetreatOperator(address operator) external onlyOwner {
        _swapOperator(operator);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            tokenId++
        ) {
            _transferCheck(tokenId);
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
    
        Retreating-based approval control: The users cannot approve their token if it is retreating.

     */

    function approve(address to, uint256 tokenId) public override {
        _transferCheck(tokenId);
        super.approve(to, tokenId);
    }

    /**
    
        Operator control and auto approvals.

     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(ERC721PsiUpgradeable)
        returns (bool)
    {
        if (operatorProxies[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function swapOperatorProxies(address _proxyAddress) public onlyOwner {
        operatorProxies[_proxyAddress] = !operatorProxies[_proxyAddress];
    }

    /*

    1000 NFTs are reserved for Binance NFT launchpad with the mintTo function.

     */

    function getMaxLaunchpadSupply() external pure override returns (uint256) {
        return LAUNCHPAD_MAX_SUPPLY;
    }

    function getLaunchpadSupply() external view override returns (uint256) {
        return LAUNCHPAD_MAX_SUPPLY - launchpadQuantity;
    }

    function mintTo(address to, uint256 size) external override onlyLaunchpad {
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(size <= launchpadQuantity, "max supply reached");

        launchpadQuantity -= uint32(size);
        _mint(to, size);
    }

    // devMint for vault and team minting.
    function devMint(address to, uint32 quantity) external onlyOwner {
        if (quantity > saleQuantity) {
            revert ExceedMaxSupply();
        }
        saleQuantity -= quantity;
        _mint(to, quantity);
    }

    /// @param quantity Amount of NFT to be minted.
    /// @param allowedQuantity Maximum allowed NFTs to be minted from a given amount.
    /// @param startTime The start time of the mint.
    /// @param endTime The end time of the mint.
    /// @param signature The NFT can only be minted with the valid signature.
    function mint(
        uint256 quantity,
        uint256 allowedQuantity,
        uint256 startTime,
        uint256 endTime,
        bytes calldata signature
    ) external payable onlyEOA {
        // quantity check
        if (quantity == 0) {
            revert ZeroQuantity();
        }

        if (quantity + userMinted[msg.sender] > allowedQuantity) {
            revert ExceedAllowedQuantity();
        }

        if (quantity > saleQuantity) {
            revert ExceedMaxSupply();
        }

        // timestamp check
        if (block.timestamp < startTime) {
            revert NotStarted();
        }
        if (block.timestamp >= endTime) {
            revert Ended();
        }

        // price check
        if (msg.value < quantity * publicPrice) {
            revert NotEnoughETH();
        }

        // signature check
        // The address of the contract is specified in the signature. This prevents the replay attact accross contracts.
        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    allowedQuantity,
                    startTime,
                    endTime,
                    address(this)
                )
            )
        );

        if (ECDSAUpgradeable.recover(hash, signature) != signer) {
            revert InvalidSignature();
        }

        userMinted[msg.sender] += quantity;
        saleQuantity -= quantity;

        // mint
        _mint(msg.sender, quantity);
    }

    function setLaunchpad(address launchpad_) external onlyOwner {
        launchpad = launchpad_;
    }

    function setPayoutWallet(address _payoutWallet) external onlyOwner {
        payoutWallet = _payoutWallet;
    }

    function setLaunchpadSupply(uint32 launchpad_supply) external onlyOwner {
        launchpadQuantity = launchpad_supply;
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function setMintPrice(uint256 newPrice_) external onlyOwner {
        publicPrice = newPrice_;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external onlyOwner {
        payable(payoutWallet).transfer(address(this).balance);
    }

    /**
    
        Operator control and auto approvals.

     */
    function getHash(
        address buyer,
        uint256 allowedQuantity,
        uint256 startTime,
        uint256 endTime
    ) external view onlySigner returns (bytes32) {
        // Hash Generation for Backend
        // toEthSignedMessageHash adds Ethereum headers to signed message.
        bytes32 hash = keccak256(
            abi.encodePacked(
                buyer, // 20
                allowedQuantity, // 4
                startTime, // 32
                endTime, // 32
                address(this) // 20
            )
        );
        return hash;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721PsiUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}