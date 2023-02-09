// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "ERC721A/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

error ZeroBytes(string);
error ZeroAddress();
error NotAdmin();
error NotMinter();
error NotOpenSale();
error LargeThanMaxSupply();
error OwnerMaxSupply();

contract EIGHTIMMORTALS is ERC721AQueryable, AccessControl {
    using Strings for uint256;

    uint256 public maxSupply = 8000;

    string public baseTokenURI;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    bool public pause = false;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) ERC721A(name_, symbol_) {
        if (bytes(name_).length == 0) {
            revert ZeroBytes("_name");
        }
        if (bytes(symbol_).length == 0) {
            revert ZeroBytes("_symbol");
        }
        if (bytes(baseTokenURI_).length == 0) {
            revert ZeroBytes("_baseTokenURI");
        }

        baseTokenURI = baseTokenURI_;

        // grant admin role to address during construct
        _grantRole(ADMIN_ROLE, msg.sender);

        // grant minter role to address during construct
        _grantRole(MINTER_ROLE, msg.sender);

        // ADMIN_ROLE is now admin of MINTER_ROLE
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);

        // ADMIN_ROLE is now admin of ADMIN_ROLE
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) {
            revert NotAdmin();
        }
        _;
    }

    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, msg.sender)) {
            revert NotMinter();
        }
        _;
    }

    modifier saleIsOpen() {
        if (pause) {
            revert NotOpenSale();
        }
        _;
    }

    modifier lessThanMaxSupply(uint256 amount) {
        if (totalSupply() + amount > maxSupply) {
            revert LargeThanMaxSupply();
        }
        _;
    }

    function mint(address to_, uint256 amount_) external lessThanMaxSupply(amount_) saleIsOpen onlyMinter {
        _safeMint(to_, amount_);
    }

    function ownerMint(uint256 amount_) external lessThanMaxSupply(amount_) onlyAdmin {
        _safeMint(msg.sender, amount_);
    }

    /// @notice Handover new admin for new undertaker and revoke origin admin
    /// @dev Should GrantRole and RevokeRole
    /// @param undertaker_ The address of undertaker who is next admin
    function handoverAdmin(address undertaker_) external onlyAdmin {
        grantRole(ADMIN_ROLE, undertaker_);
        revokeRole(ADMIN_ROLE, msg.sender);
    }

    function flipPause() public onlyAdmin {
        pause = !pause;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 889;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
        Setter function
    */
    function _setBaseURI(string memory baseURI_) external onlyAdmin {
        baseTokenURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, AccessControl)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }
}