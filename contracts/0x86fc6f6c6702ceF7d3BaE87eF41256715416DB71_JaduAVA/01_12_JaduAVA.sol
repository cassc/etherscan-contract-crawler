// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JaduAVA is ERC721AQueryable, AccessControl {
    uint256 private MAX_SUPPLY = 11111; // max launch supply

    string public _baseTokenURI = "https://backend.jadu-prod.org/token/";

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public upgradedToAddress = address(0);

    constructor() ERC721A("Jadu AVA", "AVA") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getMaxSupply() external view returns (uint256) {
        return MAX_SUPPLY;
    }

    function getCurrentTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function upgrade(address _upgradedToAddress) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        upgradedToAddress = _upgradedToAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            super.supportsInterface(interfaceId);
    }

    function setBaseURI(string calldata baseURI) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "unauthorized access"
        );
        _baseTokenURI = baseURI;
    }

    function mint(address to, uint256 size) external returns (bool) {
        require(
            address(0) == upgradedToAddress,
            "Contract upgraded to new address"
        );
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(totalSupply() + size <= MAX_SUPPLY, "Max supply reached");
        _mint(to, size);
        return true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}