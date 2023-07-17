// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC1155MaxSupply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoonGoonzOriginals is ERC1155MaxSupply, ERC1155Burnable, IERC2981, Ownable {
    using Strings for uint256;

    address private minter;
    address private proxyRegistryAddress;
    bool public isOpenSeaProxyActive = true;

    address public royaltyAddress;
    uint256 public royaltyBasisPoints;
    // set to 10000 so fees are expressed in basis points
    uint256 private constant ROYALTY_DENOMINATOR = 10000;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _minter,
        address _proxyRegistryAddress,
        address _royaltyAddress,
        uint256 _royaltyBasisPoints
    ) ERC1155MaxSupply(_name, _symbol) ERC1155(_uri) {
        minter = _minter;
        proxyRegistryAddress = _proxyRegistryAddress;
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function mintAndSetMaxSupply(
        address[] memory _recipients,
        uint256 _id,
        uint256 maxSupply,
        bool retired
    ) external onlyOwners {
        setMaxSupply(_id, maxSupply, retired);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _id, 1, "");
        }
    }

    function mint(address[] memory _recipients, uint256 _id) external onlyOwners {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _id, 1, "");
        }
    }

    function mintMany(
        address _recipient,
        uint256 _id,
        uint256 quantity
    ) external onlyOwners {
        _mint(_recipient, _id, quantity, "");
    }

    function setMaxSupply(
        uint256 id,
        uint256 supply,
        bool retired
    ) public onlyOwners {
        super._setMaxSupply(id, supply, retired);
    }

    function retire(uint256 id) public onlyOwners {
        super._retire(id);
    }

    function setURI(string memory newuri) external onlyOwners {
        super._setURI(newuri);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        require(exists(id), "URI query for nonexistent token");

        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    /**
     * @dev To disable OpenSea gasless listings proxy in case of an issue
     */
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) external onlyOwners {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    modifier onlyOwners() {
        require(owner() == _msgSender() || minter == _msgSender(), "caller is not the owner or designated minter");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice enable OpenSea gasless listings
     * @dev Overriding `isApprovedForAll` to allowlist user's OpenSea proxy accounts
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155MaxSupply, ERC1155) {
        super._mint(to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155MaxSupply, ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155MaxSupply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwners {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) external onlyOwners {
        require(_royaltyBasisPoints < royaltyBasisPoints, "New royalty amount must be lower");
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(exists(tokenId), "Non-existent token");
        return (royaltyAddress, (salePrice * royaltyBasisPoints) / ROYALTY_DENOMINATOR);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}