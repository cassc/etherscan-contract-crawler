// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../universal/UniversalRegistrar.sol";
import "./IExtensionPayee.sol";
import "./IExtensionAccess.sol";

// The ImperviousRoot contract transforms provably locked TLDs on Handshake into NFT TLDs.
contract ImperviousRoot is ERC165, ERC721Enumerable, ERC2981, Ownable, IExtensionPayee, IExtensionAccess {
    UniversalRegistrar public registrar;
    Root public root;
    string private metadataUri;

    mapping(uint256 => string) public names;
    mapping(bytes32 => address) public claims;

    event NewOwnershipClaim(bytes32 indexed node, address indexed owner);
    event OperatorChanged(bytes32 indexed node, address indexed oldOperator, address indexed newOperator);
    event PaymentReceived(address indexed from, uint256 amount);
    event NewTLD(string name, bytes32 indexed node, address indexed owner);
    event PermanentControllerApproved(address indexed controller, bool approved);
    event PermanentControllerAdded(bytes32 indexed node, address indexed controller);

    // Operators can manage the TLD but can't transfer it.
    mapping(uint256 => address) private _operators;

    // Permanent controllers cannot be removed. They provide guaranteed functionality
    // to SLD holders such as fixed price renewals.
    mapping(uint256 => mapping(address => bool)) public permanentControllers;
    mapping(address => bool) public approvedPermanentControllers;

    // If burned for the token ID, the token will be permanently
    // locked to this contract.
    mapping(uint256 => bool) public unwrapFuse;

    // Whether unwrapping is enabled by the registry.
    bool private canUnwrap = false;

    modifier onlyTokenOperator(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId) ||
            _operators[tokenId] == msg.sender, "caller must be owner, approved or an operator");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not owner nor approved");
        _;
    }

    constructor(Root _root, UniversalRegistrar _registrar) ERC721("Impervious Root", "IRR") {
        root = _root;
        registrar = _registrar;
    }

    /**
     * Claim ownership of a TLD you own in the UniversalRegistrar.
     * **MUST** be called before transferring ownership to this contract.
     *
     * @param node the namehash of the TLD
     */
    function claimOwnership(bytes32 node) public {
        address owner = registrar.ownerOfNode(node);
        require(owner != address(this) && owner != address(0), "invalid owner");

        claims[node] = owner;
        emit NewOwnershipClaim(node, owner);
    }

    function bulkClaimOwnership(bytes32[] calldata nodes) external {
        for (uint256 i = 0; i < nodes.length; i++) {
            claimOwnership(nodes[i]);
        }
    }

    /**
     * Claim ownership of a TLD you own in the UniversalRegistrar.
     * This version ensures the TLD is locked first. Still, it **MUST**
     * be called before transferring ownership to this contract.
     *
     * @param name the TLD name.
     */
    function safeClaimOwnership(string calldata name) external {
        bytes32 label = keccak256(bytes(name));
        require(root.locked(label), "name must be locked");
        bytes32 node = keccak256(abi.encodePacked(bytes32(0), label));
        claimOwnership(node);
    }

    /**
     * Mints an NFT TLD token. The mint workflow:
     *
     *  1. The TLD owner calls `safeClaimOwnership`
     *  2. Transfers the TLD to this contract (step 1 is critical before transfer).
     *  3. mint the NFT token.
     *
     * @param name the name of the TLD
     * @param owner the NFT TLD recipient (if address(0), msg.sender is used)
     */
    function mint(address owner, string calldata name) external {
        bytes32 label = keccak256(bytes(name));
        require(root.locked(label), "name must be locked");

        bytes32 node = keccak256(abi.encodePacked(bytes32(0), label));
        require(claims[node] == msg.sender, "caller has not proven ownership");
        require(registrar.ownerOfNode(node) == address(this), "must transfer name to this contract first");

        names[uint256(node)] = name;

        if (owner == address(0)) {
            _safeMint(msg.sender, uint256(node));
            emit NewTLD(name, node, msg.sender);

            return;
        }

        _safeMint(owner, uint256(node));
        emit NewTLD(name, node, owner);
    }

    /**
     * Authorizes an operator for the TLD. Operators cannot sell or transfer the name
     * but can manage it i.e by setting a resolver, changing controllers ... etc.
     *
     * @param operator the operator.
     * @param tokenId the token ID.
     */
    function setOperator(address operator, uint256 tokenId) external onlyTokenOwner(tokenId) {
        _setOperator(operator, tokenId);
    }

    function _setOperator(address operator, uint256 tokenId) internal {
        emit OperatorChanged(bytes32(tokenId), _operators[tokenId], operator);
        _operators[tokenId] = operator;
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external view override returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    /**
     * Sets a resolver address for the TLD.
     *
     * @param tokenId the token ID
     * @param resolver the resolver to set.
     */
    function setResolver(uint256 tokenId, address resolver) external onlyTokenOperator(tokenId) {
        registrar.setResolver(bytes32(tokenId), resolver);
    }

    /**
     * Authorizes a controller to register and renew SLDs for the specified token ID.
     *
     * @param tokenId the token ID
     * @param controller the controller to authorize
     */
    function addController(uint256 tokenId, address controller) external onlyTokenOperator(tokenId) {
        registrar.addController(bytes32(tokenId), controller);
    }

    /**
     * Revokes a controller from the authorized list for the given token id.
     *
     * @param tokenId the token ID
     * @param controller the controller to remove
     */
    function removeController(uint256 tokenId, address controller) external onlyTokenOperator(tokenId) {
        require(!permanentControllers[tokenId][controller], "permanent controllers cannot be removed");
        registrar.removeController(bytes32(tokenId), controller);
    }

    /**
     * Enables NFT owners to add a permanent controller to guarantee specific functionality
     * to SLD holders. For example, fixed price renewals. Once added, it can NEVER be removed.
     * Note: Controller addresses specified here must be whitelisted by the registry.
     *
     * @param tokenId the token id.
     * @param controller the controller address.
     */
    function unsafeAddPermanentController(uint256 tokenId, address controller) external onlyTokenOwner(tokenId) {
        require(unwrapFuse[tokenId], "unwrapping must be permanently disabled");
        require(approvedPermanentControllers[controller], "controller must be approved first");
        registrar.addController(bytes32(tokenId), controller);
        permanentControllers[tokenId][controller] = true;

        emit PermanentControllerAdded(bytes32(tokenId), controller);
    }

    /**
     * Approves a controller to be used as a permanent controller by TLD owners.
     * Can only be called by the registry.
     *
     * @param controller the controller address.
     * @param approved whether the controller should be approved
     */
    function approvePermanentController(address controller, bool approved) external onlyOwner {
        approvedPermanentControllers[controller] = approved;
        emit PermanentControllerApproved(controller, approved);
    }

    /**
     * For implementors of IPayee interface.
     * Returns the address that must receive payments for the specified node.
     *
     * @param node the namehash of the TLD
     */
    function payeeOf(bytes32 node) external override view returns (address) {
        return ownerOf(uint256(node));
    }

    /**
     * Returns the authorized token operator. Operators that can manage
     * the token but cannot sell it or transfer it.
     *
     * @param tokenId the token ID
     */
    function getOperator(uint256 tokenId) external view override returns (address) {
        return _operators[tokenId];
    }

    /**
     * Returns the owner of the token for IExtensionAccess interface.
     *
     * @param tokenId the token ID
     */
    function getOwner(uint256 tokenId) external view override returns (address) {
        return ownerOf(tokenId);
    }

    // Change metadata uri
    function setUri(string memory _uri) external onlyOwner {
        metadataUri = _uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return metadataUri;
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. This contract
     * shouldn't receive any Ether but in case some contract sends Ether by mistake.
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function withdraw() external {
        payable(owner()).transfer(address(this).balance);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);

        // clear operator after transfers
        _setOperator(address(0), tokenId);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, ERC721Enumerable, ERC2981) returns (bool) {
        return interfaceId == type(IExtensionAccess).interfaceId ||
        interfaceId == type(IExtensionPayee).interfaceId ||
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // burn the NFT and claim back ownership in the UniversalRegistrar
    // can only be called by token owner and unwrapping must be enabled.
    function unsafeBurnAndUnwrap(uint256 tokenId) external onlyTokenOwner(tokenId) {
        require(canUnwrap, "unwrapping is disabled");
        require(!unwrapFuse[tokenId], "unwrapping is permanently disabled");

        delete claims[bytes32(tokenId)];
        _burn(tokenId);
        registrar.transferNodeOwnership(bytes32(tokenId), msg.sender);
    }

    /**
     * Permanently disable unwrapping for a TLD to lock it permanently as an NFT in this contract.
     * This enables features such as permanent controllers.
     *
     * @param tokenId the token id.
     */
    function unsafeDisableUnwrapping(uint256 tokenId) external onlyTokenOwner(tokenId) {
        unwrapFuse[tokenId] = true;
    }

    // Enable or disable the ability to burn the NFTs
    // to claim ownership back in the UniversalRegistrar
    function setCanUnwrap(bool _canUnwrap) external onlyOwner {
        canUnwrap = _canUnwrap;
    }
}