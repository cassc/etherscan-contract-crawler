// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/ISun.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IWarRoom.sol";

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract Yard is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC2981Upgradeable,
    ERC721AQueryableUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /* ============ State Variables ============ */
    // metadata URI
    string private _baseTokenURI;
    // mint price
    uint256 public MINT_PRICE;
    // max number of tokens that can be minted
    uint256 public MAX_SUPPLY;
    // number of tokens that can be claimed for free - 20% of MAX_SUPPLY
    uint256 public PAID_TOKENS;
    // number of tokens that can be minted per wallet
    uint256 public MAX_PER_WALLET;
    // number of tokens that can be minted per transaction
    uint256 public MAX_PER_TX;
    // signer for verifying signatures
    address public signer;

    ISun public sun;
    ITraits public traits;
    IWarRoom public warRoom;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _maxSupply)
        public
        initializerERC721A
        initializer
    {
        __ERC721A_init("GardenLockdown", "PLANT");
        __ERC2981_init();
        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        MAX_PER_TX = 5;
        MAX_PER_WALLET = 5;
        MAX_SUPPLY = _maxSupply;
        PAID_TOKENS = _maxSupply / 5;
        MINT_PRICE = 0.01 ether;
    }

    function mint(uint256 _quantity, bytes calldata _signature)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(tx.origin == msg.sender, "Only EOA");
        require(_mintVerify(_signature), "Invalid signature");
        require(_quantity <= MAX_PER_TX, "Exceeds max per tx");
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(
            _totalMinted() + _quantity <= PAID_TOKENS,
            "All paid tokens minted"
        );
        require(
            _numberMinted(msg.sender) + _quantity <= MAX_PER_WALLET,
            "Invalid mint amount"
        );
        if (_numberMinted(msg.sender) == 0)
            require(
                msg.value >= (_quantity - 1) * MINT_PRICE,
                "Not enough ETH to pay for mint"
            );
        else
            require(
                msg.value >= _quantity * MINT_PRICE,
                "Not enough ETH to pay for mint"
            );

        _mint(msg.sender, _quantity);
    }

    function mintWithSun(uint256 _quantity)
        external
        nonReentrant
        whenNotPaused
    {
        require(tx.origin == msg.sender, "Only EOA");
        require(_quantity <= MAX_PER_TX, "Exceeds max per tx");
        require(_totalMinted() >= PAID_TOKENS, "Paid tokens not minted");
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Exceeds max supply");

        uint256 totalCost;
        for (uint256 i = 0; i < _quantity; i++) {
            totalCost += mintPrice(_nextTokenId());
        }
        require(
            sun.balanceOf(msg.sender) >= totalCost,
            "Not enough SUN to pay for mint"
        );
        sun.burn(msg.sender, totalCost);

        _mint(msg.sender, _quantity);
    }

    function _mintVerify(bytes memory signature) internal view returns (bool) {
        return
            keccak256(abi.encode(msg.sender, signer))
                .toEthSignedMessageHash()
                .recover(signature) == signer;
    }

    function mintPrice(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId <= PAID_TOKENS) return 0;
        if (_tokenId <= (MAX_SUPPLY * 2) / 5) return 20000 ether;
        if (_tokenId <= (MAX_SUPPLY * 4) / 5) return 40000 ether;
        return 80000 ether;
    }

    function setWarRoom(address _warRoom) external onlyOwner {
        warRoom = IWarRoom(_warRoom);
    }

    function setSun(address _sun) external onlyOwner {
        sun = ISun(_sun);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string calldata baseURI)
        external
        onlyRole(MANAGER_ROLE)
    {
        _baseTokenURI = baseURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyRole(MANAGER_ROLE) {
        MINT_PRICE = _mintPrice;
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function withdraw(address _reciver) external onlyOwner {
        payable(_reciver).transfer(address(this).balance);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721AUpgradeable,
            ERC2981Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}