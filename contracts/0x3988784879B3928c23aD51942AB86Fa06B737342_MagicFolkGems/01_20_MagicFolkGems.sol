// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**  
    @notice By default this ERC20 token cannot be transferred between 
    regular accounts. The Magic Council DAO must vote to enable this 
    feature.
*/

import "../utils/Common.sol";
import "../utils/SigVer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";

contract MagicFolkGems is ERC20, AccessControl, Ownable, SigVer {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    IERC721 MAGIC_FOLK_CONTRACT;
    IERC1155 MAGIC_FOLK_MAINHAND;
    IERC1155 MAGIC_FOLK_OFFHAND;
    IERC1155 MAGIC_FOLK_PET;
    IGovernor DAO;
    address public _signer;

    mapping(address => bool) public _freeGemsClaimed;
    bool public _transferLock;
    bool public _devMintLock;
    bool public _freeGemClaim = true;

    constructor(
        address magicFolkContract,
        address magicFolkMainhand,
        address magicFolkOffhand,
        address magicFolkPet
    ) ERC20("MagicFolkGems", "MFGEM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, magicFolkContract);
        MAGIC_FOLK_CONTRACT = IERC721(magicFolkContract);

        _grantRole(BURNER_ROLE, magicFolkMainhand);
        MAGIC_FOLK_MAINHAND = IERC1155(magicFolkMainhand);

        _grantRole(BURNER_ROLE, magicFolkOffhand);
        MAGIC_FOLK_OFFHAND = IERC1155(magicFolkOffhand);

        _grantRole(BURNER_ROLE, magicFolkPet);
        MAGIC_FOLK_PET = IERC1155(magicFolkPet);

        _transferLock = true;
    }

    modifier onlyAdminOrDAO() {
        if (
            !(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(DAO_ROLE, _msgSender()))
        ) {
            revert("NOT_AUTHORISED");
        }
        _;
    }

    function setMagicFolkAddress(address newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, address(MAGIC_FOLK_CONTRACT));
        MAGIC_FOLK_CONTRACT = IERC721(newAddress);
        _grantRole(MINTER_ROLE, newAddress);
    }

    function setMagicFolkItemAddress(address newAddress, ItemType itemType)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address oldAddress;
        if (itemType == ItemType.Mainhand) {
            oldAddress = address(MAGIC_FOLK_MAINHAND);
            MAGIC_FOLK_MAINHAND = IERC1155(newAddress);
        } else if (itemType == ItemType.Offhand) {
            oldAddress = address(MAGIC_FOLK_OFFHAND);
            MAGIC_FOLK_OFFHAND = IERC1155(newAddress);
        } else if (itemType == ItemType.Pet) {
            oldAddress = address(MAGIC_FOLK_PET);
            MAGIC_FOLK_PET = IERC1155(newAddress);
        } else {
            revert();
        }

        _revokeRole(MINTER_ROLE, oldAddress);
        _revokeRole(BURNER_ROLE, oldAddress);

        _grantRole(MINTER_ROLE, newAddress);
        _grantRole(BURNER_ROLE, newAddress);
    }

    function setDAO(address _DAO) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(DAO) == address(0), "DAO_ALREADY_SET");
        DAO = IGovernor(_DAO);
        _grantRole(DAO_ROLE, _DAO);
    }

    function claimFreeGems(
        uint256 qty,
        bytes32 msgHash,
        bytes calldata signature
    ) external {
        address to = _msgSender();
        require(_freeGemClaim, "FREE_GEMZ_DISABLED");
        require(
            _verifyMsg(to, qty, msgHash, signature, _signer),
            "INVALID_SIG"
        );
        require(!_freeGemsClaimed[to], "GEMZ_ALREADY_CLAIMED");
        _mint(to, qty);
        _freeGemsClaimed[to] = true;
    }

    function toggleFreeGems() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _freeGemClaim = !_freeGemClaim;
    }

    function enableTransfers() public onlyRole(DAO_ROLE) {
        require(_transferLock, "ALREADY_ENABLED");
        _transferLock = false;
    }

    function disableTransfers() public onlyRole(DAO_ROLE) {
        require(!_transferLock, "ALREADY_DISABLED");
        _transferLock = true;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        require(!_transferLock, "TRANSFERS_LOCKED");
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(!_transferLock, "TRANSFERS_LOCKED");
        return super.transferFrom(from, to, amount);
    }

    function addBurner(address newBurner) external onlyAdminOrDAO {
        _grantRole(BURNER_ROLE, newBurner);
    }

    function removeBurner(address oldBurner) external onlyAdminOrDAO {
        _revokeRole(BURNER_ROLE, oldBurner);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function setSignerAddress(address signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _signer = signer;
    }

    function lockDevMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_devMintLock, "DEVMINT_LOCKED");
        _devMintLock = true;
    }

    function devMint(address to, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!_devMintLock, "DEVMINT_LOCKED");
        _mint(to, amount);
    }
}