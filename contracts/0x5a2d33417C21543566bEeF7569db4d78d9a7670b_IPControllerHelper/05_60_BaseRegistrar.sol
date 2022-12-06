pragma solidity >=0.8.4;

import "./IBaseRegistrar.sol";
import "./IPRegistrarController.sol";
import "./IPTokenRenderer.sol";
import "./ERC721PTO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseRegistrar is ERC721PTO, IBaseRegistrar, Ownable {
    ENS public ens;
    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public immutable baseNode;
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;
    
    IPTokenRenderer public tokenRenderer;
    IPRegistrarController public registrarController;
    
    uint256 public constant GRACE_PERIOD = 90 days;
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

    function setENS(ENS _ens) public onlyOwner {
        ens = _ens;
    }
    
    function setRenderer(IPTokenRenderer _renderer) public onlyOwner {
        tokenRenderer = _renderer;
    }
    
    function setRegistrarController(IPRegistrarController _registrarController) external onlyOwner {
        registrarController = _registrarController;
        setOperator(address(_registrarController), true);
        addController(address(_registrarController));
    }
    
    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }
    
    constructor(ENS _ens, bytes32 _baseNode) ERC721PTO("EBPTO: IP Domains", "IP") {
        ens = _ens;
        baseNode = _baseNode;
    }
    
    function setTokenRenderer(IPTokenRenderer _tokenRenderer) public onlyOwner {
        tokenRenderer = _tokenRenderer;
    }

    modifier live() {
        require(ens.owner(baseNode) == address(this));
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId)
        public
        view
        override(IERC721, ERC721PTO)
        returns (address)
    {
        require(_getExpiryTimestamp(tokenId) > block.timestamp, "Expiration invalid");
        return super.ownerOf(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721PTO) returns (string memory) {
        require(_exists(tokenId), "Doesn't exist");
        
        return tokenRenderer.constructTokenURI(tokenId);
    }
    
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) public override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }
    
    function setOperator(address operator, bool status) public onlyOwner {
        ens.setApprovalForAll(operator, status);
    }
    
    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external override onlyOwner {
        ens.setResolver(baseNode, resolver);
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view override returns (uint256) {
        return _getExpiryTimestamp(id);
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view override returns (bool) {
        // Not available if it's registered here or in its grace period.
        return _getExpiryTimestamp(id) + GRACE_PERIOD < block.timestamp;
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external override returns (uint256) {
        return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256) {
        return _register(id, owner, duration, false);
    }

    function _register(
        uint256 id,
        address owner,
        uint256 duration,
        bool updateRegistry
    ) internal live onlyController returns (uint256) {
        require(available(id), "Name not available");
        
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);

        _setExpiryTimestamp(id, uint48(block.timestamp + duration));

        if (updateRegistry) {
            ens.setSubnodeOwner(baseNode, bytes32(id), owner);
        }

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    function renew(uint256 id, uint256 duration)
        external
        override
        live
        onlyController
        returns (uint256)
    {
        uint currentExpiry = _getExpiryTimestamp(id);
        uint48 newExpiry = uint48(currentExpiry + duration);
        
        require(currentExpiry + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period

        _setExpiryTimestamp(id, newExpiry);
        emit NameRenewed(id, newExpiry);
        return newExpiry;
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external override live {
        require(_isApprovedOrOwner(msg.sender, id));
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721PTO, IERC165)
        returns (bool)
    {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == ERC721_ID ||
            interfaceID == RECLAIM_ID;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721PTO)
    {
        registrarController.beforeTokenTransfer(from, to, tokenId, batchSize);
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721PTO)
    {
        registrarController.afterTokenTransfer(from, to, tokenId, batchSize);
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}