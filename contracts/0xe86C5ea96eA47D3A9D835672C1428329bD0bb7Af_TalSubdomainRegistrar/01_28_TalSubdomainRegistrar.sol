pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PublicResolver} from "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import {DNSRegistrar} from "@ensdomains/ens-contracts/contracts/dnsregistrar/DNSRegistrar.sol";
import {ENS} from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import {DNSSEC} from "@ensdomains/ens-contracts/contracts/dnssec-oracle/DNSSEC.sol";
import {ITalRegistrarInterface} from "./ITalRegistrarInterface.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * Critically, this contract does not check one key property of a listed domain:
 *
 * - Is the name UTS46 normalised?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.
 */
contract TalSubdomainRegistrar is Ownable, ITalRegistrarInterface {
    bytes32 public immutable ROOT_NODE;

    ENS public ensRegistry;
    PublicResolver public publicResolver;
    DNSRegistrar public dnsRegistrar;
    AggregatorV3Interface internal priceFeed;
    uint256 public subdomainFee;
    bool public stopped = false;

    /// Multiplier used to get integer values
    uint256 internal constant MUL = 1e18;

    /**
     * @dev Constructor.
     * @param ens The address of the ENS registry.
     * @param resolver The address of the Resolver.
     * @param registrar The address of the ENS DNS registrar.
     * @param node The node that this registrar administers.
     * @param contractOwner The owner of the contract.
     * @param initialSubdomainFee The amount to pay for a subdomain in usd.
     */
    constructor(
        ENS ens,
        PublicResolver resolver,
        DNSRegistrar registrar,
        AggregatorV3Interface priceFeedAddress,
        bytes32 node,
        address contractOwner,
        uint256 initialSubdomainFee
    ) {
        ensRegistry = ens;
        publicResolver = resolver;
        dnsRegistrar = registrar;
        ROOT_NODE = node;
        subdomainFee = initialSubdomainFee;
        priceFeed = priceFeedAddress;

        transferOwnership(contractOwner);
    }

    modifier notStopped() {
        require(!stopped, "TALSUBDOMAIN_REGISTRAR: Contract is currently stopped.");
        _;
    }

    /**
     * @notice Transfer the root domain ownership of the TalSubdomain Registrar to a new owner.
     * @dev Can be called by the owner of the registrar.
     * @param newDomainOwner The address of the new owner of `tal.community`.
     */
    function transferDomainOwnership(address newDomainOwner) public override onlyOwner {
        ensRegistry.setOwner(ROOT_NODE, newDomainOwner);

        emit DomainOwnershipTransferred(newDomainOwner);
    }

    /**
     * @notice Returns the address that owns the subdomain.
     * @param subdomainLabel The subdomain label to get the owner.
     */
    function subDomainOwner(string memory subdomainLabel) public view override returns (address subDomainOwnerAddress) {
        bytes32 labelHash = keccak256(bytes(subdomainLabel));

        return ensRegistry.owner(keccak256(abi.encodePacked(ROOT_NODE, labelHash)));
    }

    /**
     * @notice Register a name.
     * @dev Can only be called if and only if the subdomain of the root node is free
     * @param subdomainLabel The label hash of the domain to register a subdomain of.
     */
    function register(string memory subdomainLabel) public payable override notStopped {
        bytes32 labelHash = keccak256(bytes(subdomainLabel));
        bytes32 childNode = keccak256(abi.encodePacked(ROOT_NODE, labelHash));
        address subdomainOwner = ensRegistry.owner(childNode);
        require(subdomainOwner == address(0x0), "TALSUBDOMAIN_REGISTRAR: SUBDOMAIN_ALREADY_REGISTERED");
        _payAndRegister(_msgSender(), subdomainLabel, labelHash, childNode);
    }

    /**
     * @notice Register a name for free.
     * @dev Can only be called by the owner if and only if the subdomain of the root node is free
     * @param subdomainLabel The label hash of the domain to register a subdomain of.
     * @param subdomainNewOwner The address that will own the sudomain.
     */
    function freeRegister(string memory subdomainLabel, address subdomainNewOwner) public override onlyOwner {
        bytes32 labelHash = keccak256(bytes(subdomainLabel));
        bytes32 childNode = keccak256(abi.encodePacked(ROOT_NODE, labelHash));
        address subdomainOwner = ensRegistry.owner(childNode);
        require(subdomainOwner == address(0x0), "TALSUBDOMAIN_REGISTRAR: SUBDOMAIN_ALREADY_REGISTERED");

        _register(subdomainNewOwner, subdomainLabel, labelHash, childNode, 0);
    }

    /**
     * @notice Removes the owner of a subdomain.
     * @dev Can only be called by the owner if and only if the subdomain is taken
     * @param subdomainLabel The subdomain label to register.
     */
    function revokeSubdomain(string memory subdomainLabel) public override onlyOwner {
        _revoke(subdomainLabel);
    }

    /**
     * @notice Sets the new resolver address.
     */
    function setPublicResolver(PublicResolver resolver) public override onlyOwner {
        publicResolver = resolver;
    }

    /**
     * @notice Sets the price to pay for upcoming subdomain registrations in usd.
     */
    function setSubdomainFee(uint256 newSubdomainFee) public override onlyOwner {
        require(newSubdomainFee != subdomainFee, "TALSUBDOMAIN_REGISTRAR: New fee matches the current fee");

        subdomainFee = newSubdomainFee;
        emit SubDomainFeeChanged(subdomainFee);
    }

    /**
     * @notice Stops the registrar, disabling the register of new domains.
     * @dev Can only be called by the owner.
     */
    function stop() public override notStopped onlyOwner {
        stopped = true;
    }

    /**
     * @notice Opens the registrar, enabling configuring of new domains.
     * @dev Can only be called by the owner.
     */
    function open() public override onlyOwner {
        stopped = false;
    }

    /**
     * @notice Submits ownership proof to the DNS registrar contract.
     * @dev Can only be called by the owner.
     */
    function configureDnsOwnership(
        bytes memory name,
        DNSSEC.RRSetWithSignature[] memory input,
        bytes memory proof
    ) public override onlyOwner {
        dnsRegistrar.proveAndClaimWithResolver(name, input, proof, address(publicResolver), address(this));
    }

    /**
     * @notice Return the price in eth to pay for a subdomain.
     */
    function domainPriceInEth() public view override returns (uint256 price) {
        if (subdomainFee == 0) {
            return 0;
        }

        (, int256 ethUsdPrice, , , ) = priceFeed.latestRoundData();
        // The priceFeed returns only 8 decimals
        uint256 adjustedPrice = SafeMath.mul(uint256(ethUsdPrice), 10**10); // 18 decimals
        uint256 subdomainFeeWithMUL = SafeMath.mul(subdomainFee, MUL);

        return SafeMath.div(SafeMath.mul(subdomainFeeWithMUL, MUL), uint256(adjustedPrice));
    }

    /**
     * @dev Register a name when the correct amount is passed.
     *      Can only be called if and only if the subdomain is free to be registered.
     * @param account The address that will receive the subdomain.
     * @param subdomainLabel The label to register.
     * @param labelHash Encrypted representation of the label to register.
     * @param childNode Encrypted representation of the label to register plus the root domain.
     */
    function _payAndRegister(
        address account,
        string memory subdomainLabel,
        bytes32 labelHash,
        bytes32 childNode
    ) internal {
        // User must have paid enough
        uint256 ethSubdomainFee = domainPriceInEth();

        require(msg.value >= ethSubdomainFee, "TALSUBDOMAIN_REGISTRAR: Amount passed is not enough");

        // Send any extra back
        if (msg.value > ethSubdomainFee) {
            payable(_msgSender()).transfer(msg.value - ethSubdomainFee);
        }

        payable(owner()).transfer(ethSubdomainFee);

        _register(account, subdomainLabel, labelHash, childNode, ethSubdomainFee);
    }

    /**
     * @dev Register a name.
     *      Can only be called if and only if the subdomain is free to be registered.
     * @param account The address that will receive the subdomain.
     * @param subdomainLabel The label to register.
     * @param labelHash Encrypted representation of the label to register.
     * @param childNode Encrypted representation of the label to register plus the root domain.
     */
    function _register(
        address account,
        string memory subdomainLabel,
        bytes32 labelHash,
        bytes32 childNode,
        uint256 fee
    ) internal {
        // Set ownership to TalRegistrar, so that the contract can set resolver
        ensRegistry.setSubnodeRecord(ROOT_NODE, labelHash, address(this), address(publicResolver), 0);

        // Setting the resolver for the user
        publicResolver.setAddr(childNode, account);

        // Giving back the ownership to the user
        ensRegistry.setSubnodeOwner(ROOT_NODE, labelHash, account);

        emit SubDomainRegistered(subdomainLabel, fee, account);
    }

    /**
     * @notice Removes the owner of a subdomain.
     * @dev Can only be called by the owner if and only if the subdomain is taken
     * @param subdomainLabel The subdomain label to register.
     */
    function _revoke(string memory subdomainLabel) internal {
        bytes32 labelHash = keccak256(bytes(subdomainLabel));
        bytes32 childNode = keccak256(abi.encodePacked(ROOT_NODE, labelHash));
        address subdomainOwner = ensRegistry.owner(childNode);
        require(subdomainOwner != address(0x0), "TALSUBDOMAIN_REGISTRAR: SUBDOMAIN_NOT_REGISTERED");

        // Revoke ownership
        ensRegistry.setSubnodeRecord(ROOT_NODE, labelHash, address(0x0), address(0x0), 0);
    }
}