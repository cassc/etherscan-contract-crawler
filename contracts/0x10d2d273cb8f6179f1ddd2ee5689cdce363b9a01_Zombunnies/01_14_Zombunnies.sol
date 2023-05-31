// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./ERC721A.sol";

contract Zombunnies is ERC721A, AccessControl {
    uint256 public mintedZombunnies;

    string _baseTokenURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public upgradedToAddress = address(0);
    uint256 public zombunniescap = 5000; 

    constructor() ERC721A("Zombunnies", "ZBY") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function upgrade(address _upgradedToAddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        upgradedToAddress = _upgradedToAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        _baseTokenURI = baseURI;
    }

    function getMintedZombunnies() external view returns (uint256) {
        return mintedZombunnies;
    }

    function mintTokens(address _mintTo, uint256 quantity)
        external
        returns (bool)
    {
        require(
            address(0) == upgradedToAddress,
            "Contract has been upgraded to a new address"
        );
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(_mintTo != address(0), "ERC721: mint to the zero address");
        require(
            mintedZombunnies + quantity <= zombunniescap,
            "Maximum cap of mints reached"
        );

        _safeMint(_mintTo, quantity);
        mintedZombunnies += quantity;

        return true;
    }

}