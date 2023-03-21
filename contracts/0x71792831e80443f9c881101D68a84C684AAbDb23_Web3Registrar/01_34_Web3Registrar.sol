// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWeb3Registry.sol";
import "./interfaces/IAddressSetter.sol";
import "./libraries/LibWeb3Domain.sol";
import "./libraries/LibTransferHelper.sol";
import "./libraries/LibURI.sol";
import "./Web3RegistrarVerifier.sol";
import "./Web3ReverseRegistrar.sol";

contract Web3Registrar is ERC721EnumerableUpgradeable, Web3RegistrarVerifier {
    using LibTransferHelper for address;
    using SafeERC20 for IERC20;

    IWeb3Registry public registry;
    Web3ReverseRegistrar public reverseRegistrar;
    uint256 public maxSignInterval;
    bytes32 public baseNode;
    string private _contractURI;
    string public _baseUri;
    mapping(uint256 => string) private _tokenURIs;
    address public defaultResolver;

    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ERC721_ID =
        bytes4(
            keccak256("balanceOf(address)") ^
                keccak256("ownerOf(uint256)") ^
                keccak256("approve(address,uint256)") ^
                keccak256("getApproved(uint256)") ^
                keccak256("setApprovalForAll(address,bool)") ^
                keccak256("isApprovedForAll(address,address)") ^
                keccak256("transferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256,bytes)")
        );
    bytes4 private constant RECLAIM_ID =
        bytes4(keccak256("reclaim(uint256,address)"));

    event NameRegistered(
        string name,
        uint256 indexed tokenId,
        address indexed owner
    );
    event Withdraw(address receiver, uint256 amount);

    function __Web3Registrar_init(
        IWeb3Registry _registry,
        Web3ReverseRegistrar _reverseRegistrar,
        bytes32 _baseNode,
        uint256 _maxSignInterval,
        address verifierAddress
    ) external initializer {
        __Web3Registrar_init_unchained(
            _registry,
            _reverseRegistrar,
            _baseNode,
            _maxSignInterval,
            verifierAddress
        );
    }

    function __Web3Registrar_init_unchained(
        IWeb3Registry _registry,
        Web3ReverseRegistrar _reverseRegistrar,
        bytes32 _baseNode,
        uint256 _maxSignInterval,
        address verifierAddress
    ) internal onlyInitializing {
        __ERC721_init_unchained("Web3ite Pass", "WEB3");
        __Web3RegistrarVerifier_init_unchained(verifierAddress);
        registry = _registry;
        reverseRegistrar = _reverseRegistrar;
        baseNode = _baseNode;
        maxSignInterval = _maxSignInterval;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseUri = baseURI;
    }

    function setResolver(address resolver) external onlyOwner {
        registry.setResolver(baseNode, resolver);
    }

    function setDefaultResolver(address resolver) public onlyOwner {
        require(
            address(resolver) != address(0),
            "Resolver address must not be 0"
        );
        defaultResolver = resolver;
    }

    function setMaxSignInterval(uint256 _maxSignInterval) external onlyOwner {
        maxSignInterval = _maxSignInterval;
    }

    function register(
        LibWeb3Domain.Order memory order,
        bytes memory signature
    ) external payable {
        require(order.owner == msg.sender, "not authorized");
        require(order.timestamp <= block.timestamp, "register too early");
        require(
            order.timestamp + maxSignInterval > block.timestamp,
            "register too late"
        );
        require(!_exists(order.tokenId), "already registered");
        verifyOrder(order, signature);
        checkTokenId(order.name, order.tokenId);

        _mint(order.owner, order.tokenId);
        _setTokenURI(order.tokenId, order.tokenURI);
        _setSubnodeOwnerAndAddr(
            bytes32(order.tokenId),
            order.owner,
            order.owner
        );

        uint256 remain = msg.value - order.price;
        if (remain > 0) {
            msg.sender.transferETH(remain);
        }

        emit NameRegistered(order.name, order.tokenId, order.owner);
    }

    function reclaim(uint256 tokenId, address owner) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not authorized");
        registry.setSubnodeOwner(baseNode, bytes32(tokenId), owner);
    }

    function reclaimAndSetAddr(
        uint256 tokenId,
        address owner,
        address addr
    ) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not authorized");
        _setSubnodeOwnerAndAddr(bytes32(tokenId), owner, addr);
    }

    function _setSubnodeOwnerAndAddr(
        bytes32 label,
        address owner,
        address addr
    ) internal {
        // set owner to this address
        bytes32 node = registry.setSubnodeOwner(baseNode, label, address(this));
        // set resolver and addr
        registry.setResolver(node, defaultResolver);
        IAddressSetter(defaultResolver).setAddr(node, addr);
        // transfer owner
        registry.setOwner(node, owner);
    }

    function checkTokenId(string memory name, uint256 tokenId) internal pure {
        bytes32 id = keccak256(abi.encodePacked(name));
        require(uint256(id) == tokenId, "invalid tokenId");
    }

    function withdrawETH(address receiver) external onlyOwner {
        uint256 amount = address(this).balance;
        receiver.transferETH(amount);
        emit Withdraw(receiver, amount);
    }

    function withdrawERC20(IERC20 token, address receiver) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.safeTransfer(receiver, amount);
        }
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return LibURI.checkPrefix(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public pure override returns (bool) {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == ERC721_ID ||
            interfaceID == RECLAIM_ID;
    }

    uint256[42] private __gap;
}