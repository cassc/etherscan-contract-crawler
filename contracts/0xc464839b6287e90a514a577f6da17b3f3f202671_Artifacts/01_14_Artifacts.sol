// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Artifacts is AccessControl, Ownable, ERC1155Supply {
    address public proxyRegistryAddress =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    mapping(uint256 => string) public tokenIdToUri;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address private _manager = 0xf5383b4e0d3EDDA3B6c091e51AbE58F882c98ce3;

    constructor() ERC1155("ipfs://") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _manager);
    }

    receive() external payable {}

    modifier onlyOwnerOrManager() {
        require(
            owner() == _msgSender() || _manager == _msgSender(),
            "Caller not the owner or manager"
        );
        _;
    }

    function setTokenIdURI(string memory newuri, uint256 tokenId)
        public
        onlyOwnerOrManager
    {
        tokenIdToUri[tokenId] = newuri;
    }

    function setProxyRegistry(address preg) external onlyOwnerOrManager {
        proxyRegistryAddress = preg;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenIdToUri[_tokenId];
    }

    function setManager(address manager) external onlyOwnerOrManager {
        _manager = manager;
    }

    function withdraw() public onlyOwnerOrManager {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintTo(
        address _to,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        _mint(_to, tokenId, amount, "");
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, amount);
    }

    function burnAsBurner(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) {
        _burn(account, id, amount);
    }

    // allow gasless listings on opensea
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}