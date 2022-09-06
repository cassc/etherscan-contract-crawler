// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract CyanWrappedNFTV1 is
    AccessControlUpgradeable,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant CYAN_ROLE = keccak256("CYAN_ROLE");
    bytes32 public constant CYAN_PAYMENT_PLAN_ROLE =
        keccak256("CYAN_PAYMENT_PLAN_ROLE");

    string private baseURI;
    string private baseExtension;

    address private originalNFT;
    address private cyanVaultAddress;
    ERC721Upgradeable private originalNFTContract;

    event Wrap(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Unwrap(
        address indexed to,
        uint256 indexed tokenId,
        bool indexed isDefaulted
    );
    event WithdrewERC20(address indexed token, address to, uint256 amount);
    event WithdrewERC721(
        address indexed collection,
        address to,
        uint256 indexed tokenId
    );

    function initialize(
        address _originalNFT,
        address _cyanVaultAddress,
        address cyanPaymentPlanContractAddress,
        address cyanSuperAdmin,
        string memory _name,
        string memory _symbol,
        string memory uri,
        string memory extension
    ) public initializer {
        require(
            _originalNFT != address(0),
            "Original NFT address cannot be zero"
        );
        require(
            _cyanVaultAddress != address(0),
            "Cyan Vault address cannot be zero"
        );

        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __ERC721_init(_name, _symbol);

        originalNFT = _originalNFT;
        cyanVaultAddress = _cyanVaultAddress;
        originalNFTContract = ERC721Upgradeable(_originalNFT);

        baseURI = uri;
        baseExtension = extension;

        _setupRole(DEFAULT_ADMIN_ROLE, cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CYAN_PAYMENT_PLAN_ROLE, cyanPaymentPlanContractAddress);
    }

    function wrap(
        address from,
        address to,
        uint256 tokenId
    ) external nonReentrant onlyRole(CYAN_PAYMENT_PLAN_ROLE) {
        require(to != address(0), "Wrap to the zero address");
        require(!_exists(tokenId), "Token already wrapped");

        originalNFTContract.safeTransferFrom(from, address(this), tokenId);
        _safeMint(to, tokenId);

        emit Wrap(from, to, tokenId);
    }

    function unwrap(uint256 tokenId, bool isDefaulted)
        external
        nonReentrant
        onlyRole(CYAN_PAYMENT_PLAN_ROLE)
    {
        require(_exists(tokenId), "Token is not wrapped");

        address to;
        if (isDefaulted) {
            to = cyanVaultAddress;
        } else {
            to = ownerOf(tokenId);
        }

        _burn(tokenId);
        originalNFTContract.safeTransferFrom(address(this), to, tokenId);

        emit Unwrap(to, tokenId, isDefaulted);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getOriginalNFTAddress() external view returns (address) {
        return originalNFT;
    }

    function getCyanVaultAddress() external view returns (address) {
        return cyanVaultAddress;
    }

    function updateCyanVaultAddress(address _cyanVaultAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_cyanVaultAddress != address(0), "Zero Cyan Vault address");
        cyanVaultAddress = _cyanVaultAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _baseExtension() internal view returns (string memory) {
        return baseExtension;
    }

    function setBaseURI(string calldata newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = newBaseURI;
    }

    function setBaseExtension(string calldata newBaseExtension)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseExtension = newBaseExtension;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Wrapped token does not exist");

        string memory uri = _baseURI();
        if (bytes(uri).length > 0) {
            string memory extension = _baseExtension();
            if (bytes(extension).length > 0) {
                return
                    string(
                        abi.encodePacked(uri, tokenId.toString(), extension)
                    );
            }
            return string(abi.encodePacked(uri, tokenId.toString()));
        }

        return "";
    }

    function withdrawAirDroppedERC721(address contractAddress, uint256 tokenId)
        external
        nonReentrant
        onlyRole(CYAN_ROLE)
    {
        require(
            contractAddress != address(this),
            "Cannot withdraw own wrapped token"
        );
        require(
            contractAddress != originalNFT,
            "Cannot withdraw original NFT of the wrapper contract"
        );
        ERC721Upgradeable erc721Contract = ERC721Upgradeable(contractAddress);
        erc721Contract.safeTransferFrom(address(this), msg.sender, tokenId);

        emit WithdrewERC721(contractAddress, msg.sender, tokenId);
    }

    function withdrawAirDroppedERC20(address contractAddress, uint256 amount)
        external
        nonReentrant
        onlyRole(CYAN_ROLE)
    {
        IERC20Upgradeable erc20Contract = IERC20Upgradeable(contractAddress);
        require(
            erc20Contract.balanceOf(address(this)) >= amount,
            "ERC20 balance not enough"
        );
        erc20Contract.safeTransfer(msg.sender, amount);

        emit WithdrewERC20(contractAddress, msg.sender, amount);
    }

    function withdrawApprovedERC20(
        address contractAddress,
        address from,
        uint256 amount
    ) external nonReentrant onlyRole(CYAN_ROLE) {
        IERC20Upgradeable erc20Contract = IERC20Upgradeable(contractAddress);
        require(
            erc20Contract.allowance(from, address(this)) >= amount,
            "ERC20 allowance not enough"
        );
        erc20Contract.safeTransferFrom(from, msg.sender, amount);

        emit WithdrewERC20(contractAddress, msg.sender, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}