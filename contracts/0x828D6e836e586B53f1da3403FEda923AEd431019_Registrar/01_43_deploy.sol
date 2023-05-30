pragma solidity >=0.8.0;

import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "@ensdomains/ens-contracts/contracts/root/Controllable.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IBaseRegistrar is IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRegistered(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRenewed(uint256 indexed id, uint256 expires);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns (uint256);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration,
        bool avoidable
    ) external returns (uint256);

    function renew(uint256 id, uint256 duration) external returns (uint256);
}

contract Registrar is ERC721, IBaseRegistrar, Ownable {

    using Strings for uint256;

    // A map of expiry times
    mapping(uint256 => uint256) expiries;
    // The ENS registry
    ENS public ens;
    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;

    string private baseURI;


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

    function namehash(bytes32 node, bytes32 label) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }
    
    constructor(address _ens, bytes32 _baseNode) ERC721("ART Ethereum Name Service", "ART") {
        ens = ENS(_ens);
        baseNode = _baseNode;
    }

    function reconfigure(address _ens, bytes32 _baseNode) public virtual onlyOwner{
        ens = ENS(_ens);
        baseNode = _baseNode;
    }

    modifier live() {
        require(ens.owner(baseNode) == address(this));
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
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
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view override returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
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
        uint256 duration,
        bool avoidable
    ) external returns (uint256) {
        return _register(id, owner, duration, avoidable);
    }

    function _register(
        uint256 id,
        address owner,
        uint256 duration,
        bool avoidable
    ) internal live onlyController returns (uint256) {
        require(available(id));
        require(
            block.timestamp + duration + GRACE_PERIOD >
                block.timestamp + GRACE_PERIOD
        ); // Prevent future 

        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }

        if (avoidable){
            expiries[id] = 0;
        }else{
            expiries[id] = block.timestamp + duration;        
        }
        
        _mint(owner, id);
        
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
        
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
        require(expiries[id] + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period
        require(
            expiries[id] + duration + GRACE_PERIOD > duration + GRACE_PERIOD
        ); // Prevent future overflow

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external  live {
        require(_isApprovedOrOwner(msg.sender, id));
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function setBaseURI(string memory uri) public virtual onlyOwner{
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override(IERC721, ERC721)
        returns (address)
    {
        require(expiries[tokenId] > block.timestamp);
        return super.ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == ERC721_ID ||
            interfaceID == RECLAIM_ID;
    }
}


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RegistrarController is Ownable {
    using ECDSA for bytes32;

    Registrar base;
    
    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);


    address[] private witnesses;

    address private pool;

    constructor(address _base) { 
        base = Registrar(_base);
        pool = msg.sender;
    }

    function setWitnesses(address[] memory _witnesses) public onlyOwner{
        witnesses = _witnesses;
    }

    function setPool(address _pool) public virtual onlyOwner{
        pool = _pool;
    }


    function setRegistrar(address _registrar) public onlyOwner{
        base = Registrar(_registrar);
    }

    function verifyRenew(uint256 id, uint256 price, uint256 duration, uint256 timelock, bytes[] calldata signatures) internal view returns(bool){
        require(timelock>=block.timestamp, "RegistrarController: Call expired");
        for (uint i = 0; i<witnesses.length; i++){
            if (keccak256(abi.encode(id, price,duration,timelock)).toEthSignedMessageHash().recover(signatures[i])!=witnesses[i]){
                return false;
            }
        }
        return true;
    }

    function verifyRegister(uint256 id, address owner, uint256 price, uint256 duration, bool avoidable, address resolver, address addr, uint256 timelock, bytes[] calldata signatures) internal view returns(bool){
        require(timelock>=block.timestamp, "RegistrarController: Call expired");
        for (uint i = 0; i<witnesses.length; i++){
            if (keccak256(abi.encode(id, owner, price, duration, avoidable, resolver, addr, timelock)).toEthSignedMessageHash().recover(signatures[i])!=witnesses[i]){
                return false;
            }
        }
        return true;
    }

    function register(
        string memory name,
        address owner,
        uint256 price,
        uint256 duration,
        bool avoidable,
        address resolver,
        address addr,
        uint256 timelock,
        bytes[] calldata signatures
    ) public payable {
     
       
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);
        
        require(verifyRegister(tokenId, owner, price, duration, avoidable, resolver, addr, timelock, signatures), "Registrar: Invalid signature");
        require(msg.value==price, "Registrar: Wrong eth value");
        require(payable(pool).send(price), "Registrar: Failed to send eth");
        
        uint expires;
        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            base.register(tokenId, address(this), duration, true );

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

            // Set the resolver
            base.ens().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            expires = base.register(tokenId, owner, duration, avoidable);

        } else {
            require(addr == address(0));
            expires = base.register(tokenId, owner, duration, avoidable);
        }
        
        emit NameRegistered(name, label, owner, price, expires);


    }

    function renew(string calldata name, uint256 price, uint256 duration, uint256 timelock, bytes[] calldata signatures) external payable {

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        require(verifyRenew(tokenId, price, duration, timelock, signatures), "Registrar: Invalid signature");
        require(msg.value==price, "Registrar: Wrong eth value");
        require(payable(pool).send(price), "Registrar: Failed to send eth");
        
        uint expires = base.renew(tokenId, duration);

        emit NameRenewed(name, label, price, expires);
    }
}