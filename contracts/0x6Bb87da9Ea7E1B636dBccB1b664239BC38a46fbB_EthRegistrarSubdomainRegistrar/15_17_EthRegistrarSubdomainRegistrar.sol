// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {BaseRegistrarImplementation} from "@ensdomains/ens-contracts/contracts/ethregistrar/BaseRegistrarImplementation.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./AbstractSubdomainRegistrar.sol";

/**
 * @dev Implements an ENS registrar that allows for the tribe holders to create subdomains.
 */

contract EthRegistrarSubdomainRegistrar is AbstractSubdomainRegistrar {
    struct Domain {
        string name;
        address payable owner;
    }

    IERC721 tribe;

    mapping(bytes32 => Domain) domains;
    mapping(address => bool) created;

    constructor(address _ens, address _tribe)
        AbstractSubdomainRegistrar(ENS(_ens))
    {
        tribe = IERC721(_tribe);
    }

    /**
     * @dev owner returns the address of the account that controls a domain.
     *      Initially this is a null address. If the name has been
     *      transferred to this contract, then the internal mapping is consulted
     *      to determine who controls it. If the owner is not set,
     *      the owner of the domain in the Registrar is returned.
     * @param label The label hash of the deed to check.
     * @return The address owning the deed.
     */
    function owner(bytes32 label) public view override returns (address) {
        if (domains[label].owner != address(0x0)) {
            return domains[label].owner;
        }

        return BaseRegistrarImplementation(registrar).ownerOf(uint256(label));
    }

    /**
     * @dev Transfers internal control of a name to a new account. Does not update
     *      ENS.
     * @param name The name to transfer.
     * @param newOwner The address of the new owner.
     */
    function transfer(string memory name, address payable newOwner)
        public
        owner_only(keccak256(bytes(name)))
    {
        bytes32 label = keccak256(bytes(name));
        emit OwnerChanged(label, domains[label].owner, newOwner);
        domains[label].owner = newOwner;
    }

    /**
     * @dev Configures a domain, optionally transferring it to a new owner.
     * @param name The name to configure. i.e. mockens.eth => mockens
     * @param _owner The address to assign ownership of this domain to.
     */
    function configureDomainFor(string memory name, address payable _owner)
        public
        override
        owner_only(keccak256(bytes(name)))
    {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        if (
            BaseRegistrarImplementation(registrar).ownerOf(uint256(label)) !=
            address(this)
        ) {
            BaseRegistrarImplementation(registrar).transferFrom(
                msg.sender,
                address(this),
                uint256(label)
            );
            BaseRegistrarImplementation(registrar).reclaim(
                uint256(label),
                address(this)
            );
        }

        if (domain.owner != _owner) {
            domain.owner = _owner;
        }

        if (keccak256(bytes(domain.name)) != label) {
            // New listing
            domain.name = name;
        }

        emit DomainConfigured(label);
    }

    /**
     * @dev Unlists a domain
     * May only be called by the owner.
     * @param name The name of the domain to unlist.
     */
    function unlistDomain(string memory name)
        public
        owner_only(keccak256(bytes(name)))
    {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        if (
            BaseRegistrarImplementation(registrar).ownerOf(uint256(label)) !=
            msg.sender
        ) {
            BaseRegistrarImplementation(registrar).transferFrom(
                address(this),
                msg.sender,
                uint256(label)
            );
            BaseRegistrarImplementation(registrar).reclaim(
                uint256(label),
                msg.sender
            );
        }

        emit DomainUnlisted(label);

        domain.name = "";
    }

    /**
     * @dev Returns information about a subdomain.
     * @param label The label hash for the domain.
     * @param subdomain The label for the subdomain.
     * @return domain The name of the domain, or an empty string if the subdomain
     *                is unavailable.
     */
    function query(bytes32 label, string calldata subdomain)
        external
        view
        override
        returns (string memory domain)
    {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(
            abi.encodePacked(node, keccak256(bytes(subdomain)))
        );

        if (ens.owner(subnode) != address(0x0)) {
            return "";
        }

        Domain storage data = domains[label];
        return (data.name);
    }

    /**
     * @dev Registers a subdomain.
     * @param label The label hash of the domain to register a subdomain of.
     * @param subdomain The desired subdomain label.
     */
    function register(
        bytes32 label,
        string calldata subdomain,
        address resolver
    ) external payable not_stopped {
        address subdomainOwner = msg.sender;
        require(
            allowedToRegister(subdomainOwner),
            "Only holders can register a subdomain"
        );
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subdomainLabel = keccak256(bytes(subdomain));

        // Subdomain must not be registered already.
        require(
            ens.owner(
                keccak256(abi.encodePacked(domainNode, subdomainLabel))
            ) == address(0)
        );

        Domain storage domain = domains[label];

        // Domain must be available for registration
        require(keccak256(bytes(domain.name)) == label);

        doRegistration(
            domainNode,
            subdomainLabel,
            subdomainOwner,
            Resolver(resolver)
        );
        created[subdomainOwner] = true;
        emit NewRegistration(label, subdomain, subdomainOwner);
    }

    function allowedToRegister(address account) public view returns (bool) {
        uint256 tribe_balance = tribe.balanceOf(account);
        if (tribe_balance > 0 && !created[account]) return true;
        else return false;
    }
}