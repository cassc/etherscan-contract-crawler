pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./NameState.sol";
import "./StringUtils.sol";
import "./PriceOracle.sol";
import "./INameValidator.sol";
import "./BaseRegistrarImplementation.sol";
import "../resolvers/Resolver.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RegistrarController is Ownable {
    using StringUtils for *;

    uint256 public constant MIN_REGISTRATION_DURATION = 365 days;

    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant COMMITMENT_CONTROLLER_ID =
        bytes4(
            keccak256("rentPrice(string,uint256)") ^
                keccak256("available(string)") ^
                keccak256("makeCommitment(string,address,bytes32)") ^
                keccak256("commit(bytes32)") ^
                keccak256("register(string,address,uint256,bytes32)") ^
                keccak256("renew(string,uint256)")
        );

    bytes4 private constant COMMITMENT_WITH_CONFIG_CONTROLLER_ID =
        bytes4(
            keccak256(
                "registerWithConfig(string,address,uint256,bytes32,address,address)"
            ) ^
                keccak256(
                    "makeCommitmentWithConfig(string,address,bytes32,address,address)"
                ) ^
                keccak256(
                    "registerWithWhitelist(string,address,uint256,bytes32,address,address,bytes32[])"
                )
        );

    BaseRegistrarImplementation base;
    PriceOracle prices;
    INameValidator nameValidator;
    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;

    bool public isNameValidation;
    bool public isPublicMint;
    bool public isMintStarted;
    bool public isWhitelistOn;
    mapping(uint256 => bool) public isReserve;
    mapping(uint256 => bool) public isWhitelist;
    bytes32 public root;

    mapping(bytes32 => uint256) public commitments;

    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner,
        uint256 tokenId,
        uint256 createdAt,
        uint256 cost,
        uint256 expires
    );
    event NameRenewed(
        string name,
        bytes32 indexed label,
        uint256 cost,
        uint256 expires
    );
    event NewPriceOracle(address indexed oracle);
    event NewNameValidator(address indexed validator);

    event ModifyMerkleRoot(bytes32 newRoot);
    event IsPublicMint(bool enableOrNot);
    event IsNameValidation(bool enableOrNot);
    event IsWhitelistOn(bool enableOrNot);
    event IsMintStarted(bool enableOrNot);
    event ReservationName(string name, bool enableOrNot);
    event WhitelistName(string name, bool enableOrNot);

    constructor(
        BaseRegistrarImplementation _base,
        PriceOracle _prices,
        INameValidator _nameValidator,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge
    ) public {
        require(_maxCommitmentAge > _minCommitmentAge);

        base = _base;
        prices = _prices;
        nameValidator = _nameValidator;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;

        isNameValidation = true;
        isPublicMint = false;
        isMintStarted = false;
        isWhitelistOn = true;
    }

    function nameState(string memory name)
        external
        view
        returns (NameState.State state)
    {
        if (!valid(name)) return NameState.State.INVALID_NAME;
        uint256 labelhash = uint256(keccak256(bytes(name)));
        if (!base.available(labelhash))
            return NameState.State.NOT_AVAILABLE_NAME;
        if (isWhitelistOn && isWhitelist[labelhash])
            return NameState.State.WHITELIST_NAME;
        if (isReserve[labelhash]) return NameState.State.RESERVATION_NAME;
        if (!isPublicMint && name.strlen() <= 3)
            return NameState.State.NOT_AVAILABLE_NAME;

        return NameState.State.AVAILABLE_NAME;
    }

    function rentPrice(string memory name, uint256 duration)
        public
        view
        returns (uint256)
    {
        bytes32 hash = keccak256(bytes(name));
        return prices.price(name, base.nameExpires(uint256(hash)), duration);
    }

    function valid(string memory name) public view returns (bool) {
        if (isNameValidation) {
            return nameValidator.valid(name);
        } else {
            return name.strlen() >= 1;
        }
    }

    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function makeCommitment(
        string memory name,
        address owner,
        bytes32 secret
    ) public pure returns (bytes32) {
        return
            makeCommitmentWithConfig(
                name,
                owner,
                secret,
                address(0),
                address(0)
            );
    }

    function makeCommitmentWithConfig(
        string memory name,
        address owner,
        bytes32 secret,
        address resolver,
        address addr
    ) public pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return
            keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function registerWithWhitelist(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr,
        bytes32[] calldata proof
    ) external payable {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, name));
        require(MerkleProof.verify(proof, root, node), "merkle");
        _registerWithConfig(name, owner, duration, secret, resolver, addr);
    }

    function registerWithAdmin(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external onlyOwner {
        _registerWithConfig(name, owner, duration, secret, resolver, addr);
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        bytes32 secret
    ) external payable {
        require(isMintStarted, "not start");
        if (name.strlen() <= 3) {
            require(isPublicMint, "public");
        }
        uint256 labelhash = uint256(keccak256(bytes(name)));
        if (isWhitelistOn) {
            require(!isWhitelist[labelhash], "whitelist");
        }
        require(!isReserve[labelhash], "reserve");
        _registerWithConfig(
            name,
            owner,
            duration,
            secret,
            address(0),
            address(0)
        );
    }

    function registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) public payable {
        require(isMintStarted, "not start");
        if (name.strlen() <= 3) {
            require(isPublicMint, "public");
        }
        uint256 labelhash = uint256(keccak256(bytes(name)));
        if (isWhitelistOn) {
            require(!isWhitelist[labelhash], "whitelist");
        }
        require(!isReserve[labelhash], "reserve");
        _registerWithConfig(name, owner, duration, secret, resolver, addr);
    }

    function _registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) internal {
        bytes32 commitment = makeCommitmentWithConfig(
            name,
            owner,
            secret,
            resolver,
            addr
        );
        uint256 cost = _consumeCommitment(name, duration, commitment);

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        uint256 expires;
        if (resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(tokenId, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(
                abi.encodePacked(base.baseNode(), label)
            );

            // Set the resolver
            base.bns().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, owner);
            base.transferFrom(address(this), owner, tokenId);
        } else {
            require(addr == address(0));
            expires = base.register(tokenId, owner, duration);
        }

        emit NameRegistered(
            name,
            label,
            owner,
            tokenId,
            block.timestamp,
            cost,
            expires
        );

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function renew(string calldata name, uint256 duration) external payable {
        uint256 cost = rentPrice(name, duration);
        require(msg.value >= cost);
        require(duration == MIN_REGISTRATION_DURATION);

        bytes32 label = keccak256(bytes(name));
        uint256 expires = base.renew(uint256(label), duration);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(name, label, cost, expires);
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setCommitmentAges(
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge
    ) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        root = _root;
        emit ModifyMerkleRoot(_root);
    }

    function setIsPublicMintOpen(bool enableOrNot) public onlyOwner {
        isPublicMint = enableOrNot;
        emit IsPublicMint(isWhitelistOn);
    }

    function setNameValidation(bool enableOrNot) public onlyOwner {
        isNameValidation = enableOrNot;
        emit IsNameValidation(isWhitelistOn);
    }

    function setIsWhitelistOn(bool enableOrNot) public onlyOwner {
        isWhitelistOn = enableOrNot;
        emit IsWhitelistOn(isWhitelistOn);
    }

    function setIsMintStarted(bool enableOrNot) public onlyOwner {
        isMintStarted = enableOrNot;
        emit IsMintStarted(isMintStarted);
    }

    function changeNameValidation(INameValidator _validator)
        external
        onlyOwner
    {
        nameValidator = _validator;
        emit NewNameValidator(address(nameValidator));
    }

    function setReservationNames(
        string[] calldata names,
        bool[] calldata enableOrNots
    ) public onlyOwner {
        require(names.length == enableOrNots.length, "length");
        for (uint256 idx = 0; idx < names.length; idx++) {
            isReserve[uint256(keccak256(bytes(names[idx])))] = enableOrNots[
                idx
            ];
            emit ReservationName(names[idx], enableOrNots[idx]);
        }
    }

    function setWhitelistNames(
        string[] calldata names,
        bool[] calldata enableOrNots
    ) public onlyOwner {
        require(names.length == enableOrNots.length, "length");
        for (uint256 idx = 0; idx < names.length; idx++) {
            isWhitelist[uint256(keccak256(bytes(names[idx])))] = enableOrNots[
                idx
            ];
            emit WhitelistName(names[idx], enableOrNots[idx]);
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == COMMITMENT_CONTROLLER_ID ||
            interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(
        string memory name,
        uint256 duration,
        bytes32 commitment
    ) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(name));

        delete (commitments[commitment]);

        uint256 cost = rentPrice(name, duration);
        require(duration == MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);

        return cost;
    }
}