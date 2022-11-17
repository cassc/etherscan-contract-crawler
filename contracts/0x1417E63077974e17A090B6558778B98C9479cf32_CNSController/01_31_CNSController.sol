//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/ENSController.sol";
import "./token/CNSToken.sol";

contract CNSController is Ownable, ENSController {
    /*
    |--------------------------------------------------------------------------
    | CNS SBT Token
    |--------------------------------------------------------------------------
    */

    CNSToken internal token;

    /*
    |--------------------------------------------------------------------------
    | Constructor
    |--------------------------------------------------------------------------
    */
    constructor(
        address _ensAddr,
        address _baseRegistrarAddr,
        address _resolverAddr,
        address _cnsTokenAddr
    ) ENSController(_ensAddr, _baseRegistrarAddr, _resolverAddr) {
        require(address(_ensAddr) != address(0));
        require(address(_baseRegistrarAddr) != address(0));
        require(address(_resolverAddr) != address(0));
        token = CNSToken(_cnsTokenAddr);
    }

    /*
    |--------------------------------------------------------------------------
    | Event
    |--------------------------------------------------------------------------
    */

    event RegisterDomain(
        string domain,
        bytes32 node,
        address owner,
        address policy,
        uint256 subdomainCount
    );

    event RegisterSubdomain(
        string domain,
        string subdomain,
        bytes32 node,
        bytes32 subnode,
        address owner,
        address policy,
        uint256 cnsTokenId
    );

    event UnregisterDomain(bytes32 node, string domain);
    event UnregisterSubdomain(bytes32 _subnode, string _subdomain);

    event MintCNSToken(bytes32 _subnode, address _owner, uint256 _tokenId);
    event BurnCNSToken(bytes32 _subnode, address _owner, uint256 _tokenId);

    /*
    |--------------------------------------------------------------------------
    | Controller 
    |--------------------------------------------------------------------------
    */

    mapping(address => bool) internal controller;

    function addController(address _controller) public onlyOwner {
        require(controller[_controller] == false);
        controller[_controller] = true;
    }

    function removeController(address _controller) public onlyOwner {
        require(controller[_controller] == true);
        controller[_controller] = false;
    }

    /*
    |--------------------------------------------------------------------------
    | Domain
    |--------------------------------------------------------------------------
    */

    mapping(bytes32 => string) public name;
    mapping(bytes32 => address) public domainOwner;
    mapping(bytes32 => uint256) public tokenId;
    mapping(bytes32 => uint256) public count;
    mapping(bytes32 => address) public policyAddr;

    function registerDomain(
        string calldata _name,
        bytes32 _node,
        uint256 _tokenId,
        address _owner
    ) public {
        require(controller[msg.sender], "Only controller can register domain");
        require(!isRegister(_node), "Already registered this Domain");
        setName(_node, _name);
        setOwner(_node, _owner);
        setTokenId(_node, _tokenId);
        setPolicy(_node, msg.sender);
        setCount(_node, 0);
        emit RegisterDomain(
            getName(_node),
            _node,
            getOwner(_node),
            getPolicy(_node),
            getCount(_node)
        );
    }

    function setName(bytes32 _node, string memory _name) internal {
        name[_node] = _name;
    }

    function getName(bytes32 _node) public view returns (string memory) {
        return name[_node];
    }

    function setOwner(bytes32 _node, address _owner) internal {
        domainOwner[_node] = _owner;
    }

    function getOwner(bytes32 _node) public view returns (address) {
        return domainOwner[_node];
    }

    function setTokenId(bytes32 _node, uint256 _domainId) internal {
        tokenId[_node] = _domainId;
    }

    function getTokenId(bytes32 _node) public view returns (uint256) {
        return tokenId[_node];
    }

    function setCount(bytes32 _node, uint256 _count) internal {
        count[_node] = _count;
    }

    function getCount(bytes32 _node) public view returns (uint256) {
        return count[_node];
    }

    function setPolicy(bytes32 _node, address _policy) internal {
        policyAddr[_node] = _policy;
    }

    function getPolicy(bytes32 _node) public view returns (address) {
        return policyAddr[_node];
    }

    function isRegister(bytes32 _node) public view returns (bool) {
        return getOwner(_node) != address(0);
    }

    function unRegisterDomain(bytes32 _node) public {
        require(isRegister(_node), "This Domain is not registered");
        require(
            controller[msg.sender],
            "Only controller can unregister domain"
        );
        emit UnregisterDomain(_node, getName(_node));
        delete name[_node];
        delete domainOwner[_node];
        delete tokenId[_node];
        delete count[_node];
        delete policyAddr[_node];
    }

    function getDomain(bytes32 _node)
        public
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            address
        )
    {
        return (
            getName(_node),
            getOwner(_node),
            getTokenId(_node),
            getCount(_node),
            getPolicy(_node)
        );
    }

    function isDomainOwner(uint256 _tokenId, address _account)
        public
        view
        returns (bool)
    {
        return (registrar.ownerOf(_tokenId) == _account);
    }

    /*
    |--------------------------------------------------------------------------
    | Subdomain
    |--------------------------------------------------------------------------
    */

    mapping(bytes32 => string) public subDomainLabel;
    mapping(bytes32 => address) public subDomainOwner;
    mapping(bytes32 => uint256) public subDomainTokenId;
    mapping(bytes32 => string) public subDomainName;

    function registerSubdomain(
        string memory _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        address _owner
    ) public {
        require(isRegister(_node), "Domain is not registered");
        require(
            !isRegisterSubdomain(_subnode),
            "Already registered this subdomain"
        );
        require(
            controller[msg.sender],
            "Only controller can register subdomain"
        );
        ens.setSubnodeRecord(
            _node,
            keccak256(abi.encodePacked(_subDomainLabel)),
            address(this),
            address(resolver),
            0
        );
        resolver.setAddr(_subnode, _owner);
        setCount(_node, getCount(_node) + 1);
        setSubDomainLabel(_subnode, _subDomainLabel);
        setSubDomainName(
            _subnode,
            concat(getSubDomainLabel(_subnode), getName(_node))
        );
        setSubDomainOwner(_subnode, _owner);
        token.incrementId();
        setSubDomainTokenId(_subnode, token.currentId());
        token.mint(_owner, token.currentId());
        token.setTokenURI(
            token.currentId(),
            string(
                abi.encodePacked(
                    token.getMetadataEndpoint(),
                    Strings.toString(token.currentId())
                )
            )
        );
        emit RegisterSubdomain(
            getSubDomainName(_subnode),
            getSubDomainLabel(_subnode),
            _node,
            _subnode,
            getSubDomainOwner(_subnode),
            getPolicy(_node),
            token.currentId()
        );
        emit MintCNSToken(_subnode, _owner, token.currentId());
    }

    function setSubDomainLabel(bytes32 _subnode, string memory _name) internal {
        subDomainLabel[_subnode] = _name;
    }

    function getSubDomainLabel(bytes32 _subnode)
        public
        view
        returns (string memory)
    {
        return subDomainLabel[_subnode];
    }

    function setSubDomainName(bytes32 _subnode, string memory _name) internal {
        subDomainName[_subnode] = _name;
    }

    function getSubDomainName(bytes32 _subnode)
        public
        view
        returns (string memory)
    {
        return subDomainName[_subnode];
    }

    function setSubDomainOwner(bytes32 _subnode, address _owner) internal {
        subDomainOwner[_subnode] = _owner;
    }

    function getSubDomainOwner(bytes32 _subnode) public view returns (address) {
        return subDomainOwner[_subnode];
    }

    function setSubDomainTokenId(bytes32 _subnode, uint256 _domainId) internal {
        subDomainTokenId[_subnode] = _domainId;
    }

    function getSubDomainTokenId(bytes32 _subnode)
        public
        view
        returns (uint256)
    {
        return subDomainTokenId[_subnode];
    }

    function concat(string memory _label, string memory _domain)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_label, ".", _domain));
    }

    function isRegisterSubdomain(bytes32 _node) public view returns (bool) {
        return getSubDomainOwner(_node) != address(0);
    }

    function unRegisterSubdomain(
        string memory _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) public {
        require(isRegisterSubdomain(_subnode), "Subdomain is not registered");
        require(
            controller[msg.sender],
            "Only controller can unregister subdomain"
        );

        emit UnregisterSubdomain(_subnode, getSubDomainName(_subnode));
        ens.setSubnodeRecord(
            _node,
            keccak256(abi.encodePacked(_subDomainLabel)),
            address(0),
            address(0),
            0
        );
        setCount(_node, getCount(_node) - 1);
        token.burn(getSubDomainTokenId(_subnode));
        emit BurnCNSToken(
            _subnode,
            getSubDomainOwner(_subnode),
            getSubDomainTokenId(_subnode)
        );
        delete subDomainName[_subnode];
        delete subDomainLabel[_subnode];
        delete subDomainOwner[_subnode];
        delete subDomainTokenId[_subnode];
    }

    function getSubdomain(bytes32 _subnode)
        public
        view
        returns (
            string memory,
            string memory,
            address,
            uint256
        )
    {
        return (
            getSubDomainName(_subnode),
            getSubDomainLabel(_subnode),
            getSubDomainOwner(_subnode),
            getSubDomainTokenId(_subnode)
        );
    }

    function isSubdomainOwner(bytes32 _subnode, address _account)
        public
        view
        returns (bool)
    {
        return (getSubDomainOwner(_subnode) == _account);
    }

    /*
    |--------------------------------------------------------------------------
    | Set Subdomain Text Record
    |--------------------------------------------------------------------------
    */
    function setText(
        bytes32 _node,
        string memory _key,
        string memory _value
    ) public {
        require(isSubdomainOwner(_node, msg.sender));
        resolver.setText(_node, _key, _value);
    }

    function multicall(bytes[] calldata data, bytes32 _subnode)
        external
        returns (bytes[] memory results)
    {
        require(isSubdomainOwner(_subnode, msg.sender));
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(resolver)
                .delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }
}