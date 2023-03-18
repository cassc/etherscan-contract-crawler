pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../resolvers/Resolver.sol";

/**
 * @dev A registrar controller for registering names at fixed cost.
 * An updated version of the previously deployed ETHRegistrarController.
 */
contract ForeverRegistrarController is Ownable {
    using StringUtils for *;

    bool public requireCommitReveal = false;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("price(string)") ^
        keccak256("available(string)") ^
        keccak256("makeCommitment(string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(string,address,bytes32)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)")
    );

    BaseRegistrarImplementation base;
    PriceOracle prices;
    uint public minCommitmentAge;
    uint public maxCommitmentAge;

    mapping(bytes32=>uint) public commitments;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost);
    event NewPriceOracle(address indexed oracle);

    constructor(BaseRegistrarImplementation _base, PriceOracle _prices, uint _minCommitmentAge, uint _maxCommitmentAge) public {
        require(_maxCommitmentAge > _minCommitmentAge);

        base = _base;
        prices = _prices;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function setRequireCommitReveal(bool _requireCommitReveal) external onlyOwner {
        requireCommitReveal = _requireCommitReveal;
    }

    function price(string memory name) view public returns(uint) {
        return prices.price(name);
    }

    function valid(string memory name) public pure returns(bool) {
        return name.strlen() >= 1;
    }

    function available(string memory name) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function makeCommitment(string memory name, address owner, bytes32 secret) pure public returns(bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function register(string calldata name, address owner, bytes32 secret) external payable {
        registerWithConfig(name, owner, secret, address(0), address(0));
    }

    function registerWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) public payable {
        bytes32 commitment = requireCommitReveal ? makeCommitmentWithConfig(name, owner, secret, resolver, addr) : bytes32(0);
        uint cost = _consumeCommitment(name, commitment);

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            base.register(tokenId, address(this));

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

            // Set the resolver
            base.ens().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expected owner
            base.reclaim(tokenId, owner);
            base.transferFrom(address(this), owner, tokenId);
        } else {
            require(addr == address(0));
            base.register(tokenId, owner);
        }

        emit NameRegistered(name, label, owner, cost);

        // Refund any extra payment
        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setCommitmentAges(uint _minCommitmentAge, uint _maxCommitmentAge) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
        interfaceID == COMMITMENT_CONTROLLER_ID ||
        interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(string memory name, bytes32 commitment) internal returns (uint256) {
        // If the name is registered, stop
        require(available(name));

        if (requireCommitReveal) {
            // Require a valid commitment
            require(commitments[commitment] + minCommitmentAge <= block.timestamp);

            // If the commitment is too old, stop
            require(commitments[commitment] + maxCommitmentAge > block.timestamp);

            delete(commitments[commitment]);
        }

        uint cost = price(name);
        require(msg.value >= cost);

        return cost;
    }
}