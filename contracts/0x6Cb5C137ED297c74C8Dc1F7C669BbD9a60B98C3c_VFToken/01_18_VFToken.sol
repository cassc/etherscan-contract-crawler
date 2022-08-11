// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./erc721vf/contracts/ERC721VF.sol";
import "./VFAccessControl.sol";
import "./IVFAccessControl.sol";
import "./VFRoyalties.sol";
import "./IVFRoyalties.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract VFToken is ERC721VF, IERC2981 {
    //Token base URI
    string private _baseUri;

    //Flag to permanently lock minting
    bool public mintingPermanentlyLocked = false;
    //Flag to activate or disable minting
    bool public isMintActive = false;
    //Flag to activate or disable burning
    bool public isBurnActive = false;

    //Contract for function access control
    VFAccessControl private _controlContract;

    //Contract for royalties
    VFRoyalties private _royaltiesContract;

    /**
     * @dev Initializes the contract by setting a `initialBaseUri`, `name`, `symbol`,
     * and a `controlContractAddress` to the token collection.
     */
    constructor(
        string memory initialBaseUri,
        string memory name,
        string memory symbol,
        address controlContractAddress
    ) ERC721VF(name, symbol) {
        _controlContract = VFAccessControl(controlContractAddress);
        setBaseURI(initialBaseUri);
    }

    modifier onlyRole(bytes32 role) {
        _controlContract.checkRole(role, _msgSender());
        _;
    }

    modifier onlyRoles(bytes32[] memory roles) {
        bool hasRequiredRole = false;
        for (uint256 i; i < roles.length; i++) {
            bytes32 role = roles[i];
            if (_controlContract.hasRole(role, _msgSender())) {
                hasRequiredRole = true;
                break;
            }
        }
        require(hasRequiredRole, "Missing required role");
        _;
    }

    modifier notLocked() {
        require(!mintingPermanentlyLocked, "Minting permanently locked");
        _;
    }

    modifier mintActive() {
        require(isMintActive, "Mint is not active");
        _;
    }

    modifier burnActive() {
        require(isBurnActive, "Burn is not active");
        _;
    }

    /**
     * @dev Get the base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev Update the base token URI
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setBaseURI(string memory baseUri)
        public
        onlyRole(_controlContract.getAdminRole())
    {
        _baseUri = baseUri;
    }

    /**
     * @dev Update the access control contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `controlContractAddress` must support the IVFAccesControl interface
     */
    function setControlContract(address controlContractAddress)
        external
        onlyRole(_controlContract.getAdminRole())
    {
        require(
            IERC165(controlContractAddress).supportsInterface(
                type(IVFAccessControl).interfaceId
            ),
            "Contract does not support required interface"
        );
        _controlContract = VFAccessControl(controlContractAddress);
    }

    /**
     * @dev Update the royalties contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `royaltiesContractAddress` must support the IVFRoyalties interface
     */
    function setRoyaltiesContract(address royaltiesContractAddress)
        external
        onlyRole(_controlContract.getAdminRole())
    {
        require(
            IERC165(royaltiesContractAddress).supportsInterface(
                type(IVFRoyalties).interfaceId
            ),
            "Contract does not support required interface"
        );
        _royaltiesContract = VFRoyalties(royaltiesContractAddress);
    }

    /**
     * @dev Permanently lock minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function lockMintingPermanently()
        external
        onlyRole(_controlContract.getAdminRole())
    {
        mintingPermanentlyLocked = true;
    }

    /**
     * @dev Set the active/inactive state of minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleMintActive()
        external
        onlyRole(_controlContract.getAdminRole())
    {
        isMintActive = !isMintActive;
    }

    /**
     * @dev Set the active/inactive state of burning
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleBurnActive()
        external
        onlyRole(_controlContract.getAdminRole())
    {
        isBurnActive = !isBurnActive;
    }

    /**
     * @dev Airdrop `addresses` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     * - `addresses` and `quantities` must have the same length
     */
    function airdrop(
        address[] memory addresses,
        uint16[] memory quantities,
        uint256 startTokenId
    )
        external
        onlyRoles(_controlContract.getMinterRoles())
        notLocked
        mintActive
    {
        require(
            addresses.length == quantities.length,
            "Address and quantities need to be equal length"
        );

        for (uint256 i; i < addresses.length; i++) {
            startTokenId = _mintBatch(
                addresses[i],
                quantities[i],
                startTokenId
            );
        }
    }

    /**
     * @dev Airdrop `addresses` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     * - `addresses` and `quantities` must have the same length
     */
    function safeAirdrop(
        address[] memory addresses,
        uint16[] memory quantities,
        uint256 startTokenId
    )
        external
        onlyRoles(_controlContract.getMinterRoles())
        notLocked
        mintActive
    {
        require(
            addresses.length == quantities.length,
            "Address and quantities need to be equal length"
        );

        for (uint256 i; i < addresses.length; i++) {
            startTokenId = _safeMintBatch(
                addresses[i],
                quantities[i],
                startTokenId
            );
        }
    }

    /**
     * @dev mint batch `to` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     */
    function mintBatch(
        address to,
        uint8 quantity,
        uint256 startTokenId
    )
        external
        onlyRoles(_controlContract.getMinterRoles())
        notLocked
        mintActive
    {
        _mintBatch(to, quantity, startTokenId);
    }

    /**
     * @dev mint batch `to` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     */
    function safeMintBatch(
        address to,
        uint8 quantity,
        uint256 startTokenId
    )
        external
        onlyRoles(_controlContract.getMinterRoles())
        notLocked
        mintActive
    {
        _safeMintBatch(to, quantity, startTokenId);
    }

    /**
     * @dev mint `to` token `tokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     */
    function mint(address to, uint256 tokenId)
        external
        onlyRoles(_controlContract.getMinterRoles())
        notLocked
        mintActive
    {
        _mint(to, tokenId);
    }

    /**
     * @dev mint `to` token `tokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     */
    function safeMint(address to, uint256 tokenId)
        external
        onlyRoles(_controlContract.getMinterRoles())
        notLocked
        mintActive
    {
        _safeMint(to, tokenId);
    }

    /**
     * @dev burn `from` token `tokenId`
     *
     * Requirements:
     *
     * - the caller must be a burner role
     * - burning must be active
     */
    function burn(address from, uint256 tokenId)
        external
        onlyRole(_controlContract.getBurnerRole())
        burnActive
    {
        _burn(from, tokenId);
    }

    /**
     * @dev Get royalty information for a token based on the `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return
            _royaltiesContract.royaltyInfo(tokenId, address(this), salePrice);
    }

    /**
     * @dev Widthraw balance on contact to msg sender
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function withdrawMoney()
        external
        onlyRole(_controlContract.getAdminRole())
    {
        address payable to = payable(_msgSender());
        to.transfer(address(this).balance);
    }
}