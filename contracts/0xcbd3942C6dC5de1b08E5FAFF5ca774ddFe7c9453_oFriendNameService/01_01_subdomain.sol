// SPDX-License-Identifier: MIT
// oLand ENS Registration


pragma solidity ^0.8.14;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface INFTNames {
    function names(uint256 tokenId) external view returns (string memory);
}

interface IENSResolver {
    function setAddr(bytes32 node, address addr) external;
    function addr(bytes32 node) external view returns (address);
}

interface IENSRegistry {
    function setOwner(bytes32 node, address owner) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
}

contract oFriendNameService {
    bytes32 private constant EMPTY_NAMEHASH = 0x00;
    address private owner;
    IERC721 private immutable tdbc;
    INFTNames private immutable nftNames;
    IENSRegistry private registry;
    IENSResolver private resolver;
    bool public locked;

    event SubdomainCreated(address indexed creator, address indexed owner, uint256 subdomain, string domain, string topdomain);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RegistryUpdated(address indexed previousRegistry, address indexed newRegistry);
    event ResolverUpdated(address indexed previousResolver, address indexed newResolver);
    event DomainTransfersLocked();


    // 0x6761BC096d2537b47673476B483ec1dA54C8088D
    // 0x6761BC096d2537b47673476B483ec1dA54C8088D
    // 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
    // 0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63

    constructor(IERC721 _swampBoats, INFTNames _nftNames, IENSRegistry _registry, IENSResolver _resolver) {
        owner = msg.sender;
        tdbc = _swampBoats;
        nftNames = _nftNames;
        registry = _registry;
        resolver = _resolver;
        locked = false;
    }

    function normalizeSubdomain(string memory _subdomain) internal pure returns (string memory) {
        bytes memory subdomainBytes = bytes(_subdomain);
        for (uint i = 0; i < subdomainBytes.length; i++) {
            if (subdomainBytes[i] >= 0x41 && subdomainBytes[i] <= 0x5A) {
                // Convert to lowercase
                subdomainBytes[i] |= 0x20;
            }
        }
        return string(subdomainBytes);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function newSubdomain(uint256 _tokenId, string calldata _domain, string calldata _topdomain, address _owner, address _target) external {
        require(tdbc.ownerOf(_tokenId) == _owner, "UNAUTHORIZED");
        uint256 _subdomain = _tokenId;

        bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
        bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
        require(registry.owner(domainNamehash) == address(this), "INVALID_DOMAIN");


        bytes32 subdomainLabelhash = keccak256(abi.encodePacked(_subdomain));
        bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, subdomainLabelhash));
        require(registry.owner(subdomainNamehash) == address(0) || registry.owner(subdomainNamehash) == msg.sender, "SUB_DOMAIN_ALREADY_OWNED");

        registry.setSubnodeOwner(domainNamehash, subdomainLabelhash, address(this));
        registry.setResolver(subdomainNamehash, address(resolver));
        resolver.setAddr(subdomainNamehash, _target);
        registry.setOwner(subdomainNamehash, _owner);

        emit SubdomainCreated(msg.sender, _owner, _subdomain, _domain, _topdomain);
    }

    function domainOwner(string calldata _domain, string calldata _topdomain) external view returns (address) {
        bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
        bytes32 namehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
        return registry.owner(namehash);
    }

    function subdomainOwner(string calldata _subdomain, string calldata _domain, string calldata _topdomain) external view returns (address) {
        bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
        bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
        bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain))));

        return registry.owner(subdomainNamehash);
    }

    function subdomainTarget(string calldata _subdomain, string calldata _domain, string calldata _topdomain) external view returns (address) {
        bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
        bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
        bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain))));
        address currentResolver = registry.resolver(subdomainNamehash);

        return IENSResolver(currentResolver).addr(subdomainNamehash);
    }

    function transferDomainOwnership(bytes32 _node, address _owner) external onlyOwner {
        require(!locked);
        registry.setOwner(_node, _owner);
    }

    function lockDomainOwnershipTransfers() external onlyOwner {
        require(!locked);
        locked = true;
        emit DomainTransfersLocked();
    }

    function updateRegistry(IENSRegistry _registry) external onlyOwner {
        require(registry != _registry, "INVALID_REGISTRY");
        emit RegistryUpdated(address(registry), address(_registry));
        registry = _registry;
    }

    function updateResolver(IENSResolver _resolver) external onlyOwner {
        require(resolver != _resolver, "INVALID_RESOLVER");
        emit ResolverUpdated(address(resolver), address(_resolver));
        resolver = _resolver;
    }
}