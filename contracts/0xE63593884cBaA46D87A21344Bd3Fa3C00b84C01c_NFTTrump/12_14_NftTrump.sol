// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator() virtual {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract OwnedRegistrant is Ownable2Step {
    address constant registry = 0x000000000000AAeB6D7670E522A718067333cd4E;

    constructor(address _owner) {
        IOperatorFilterRegistry(registry).register(address(this));
        transferOwnership(_owner);
    }
}

contract OperatorFilterRegistryErrorsAndEvents {
    error CannotFilterEOAs();
    error AddressAlreadyFiltered(address operator);
    error AddressNotFiltered(address operator);
    error CodeHashAlreadyFiltered(bytes32 codeHash);
    error CodeHashNotFiltered(bytes32 codeHash);
    error OnlyAddressOrOwner();
    error NotRegistered(address registrant);
    error AlreadyRegistered();
    error AlreadySubscribed(address subscription);
    error NotSubscribed();
    error CannotUpdateWhileSubscribed(address subscription);
    error CannotSubscribeToSelf();
    error CannotSubscribeToZeroAddress();
    error NotOwnable();
    error AddressFiltered(address filtered);
    error CodeHashFiltered(address account, bytes32 codeHash);
    error CannotSubscribeToRegistrantWithSubscription(address registrant);
    error CannotCopyFromSelf();

    event RegistrationUpdated(address indexed registrant, bool indexed registered);
    event OperatorUpdated(address indexed registrant, address indexed operator, bool indexed filtered);
    event OperatorsUpdated(address indexed registrant, address[] operators, bool indexed filtered);
    event CodeHashUpdated(address indexed registrant, bytes32 indexed codeHash, bool indexed filtered);
    event CodeHashesUpdated(address indexed registrant, bytes32[] codeHashes, bool indexed filtered);
    event SubscriptionUpdated(address indexed registrant, address indexed subscription, bool indexed subscribed);
}

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract OperatorFilterRegistry is IOperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 constant EOA_CODEHASH = keccak256("");

    mapping(address => EnumerableSet.AddressSet) private _filteredOperators;
    mapping(address => EnumerableSet.Bytes32Set) private _filteredCodeHashes;
    mapping(address => address) private _registrations;
    mapping(address => EnumerableSet.AddressSet) private _subscribers;

    modifier onlyAddressOrOwner(address addr) {
        if (msg.sender != addr) {
            try Ownable(addr).owner() returns (address owner) {
                if (msg.sender != owner) {
                    revert OnlyAddressOrOwner();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NotOwnable();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        _;
    }

    function isOperatorAllowed(address registrant, address operator) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            EnumerableSet.AddressSet storage filteredOperatorsRef;
            EnumerableSet.Bytes32Set storage filteredCodeHashesRef;

            filteredOperatorsRef = _filteredOperators[registration];
            filteredCodeHashesRef = _filteredCodeHashes[registration];

            if (filteredOperatorsRef.contains(operator)) {
                revert AddressFiltered(operator);
            }
            if (operator.code.length > 0) {
                bytes32 codeHash = operator.codehash;
                if (filteredCodeHashesRef.contains(codeHash)) {
                    revert CodeHashFiltered(operator, codeHash);
                }
            }
        }
        return true;
    }

    function register(address registrant) external onlyAddressOrOwner(registrant) {
        if (_registrations[registrant] != address(0)) {
            revert AlreadyRegistered();
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
    }

    function unregister(address registrant) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = address(0);
        emit RegistrationUpdated(registrant, false);
    }

    function registerAndSubscribe(address registrant, address subscription) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        if (registrant == subscription) {
            revert CannotSubscribeToSelf();
        }
        address subscriptionRegistration = _registrations[subscription];
        if (subscriptionRegistration == address(0)) {
            revert NotRegistered(subscription);
        }
        if (subscriptionRegistration != subscription) {
            revert CannotSubscribeToRegistrantWithSubscription(subscription);
        }

        _registrations[registrant] = subscription;
        _subscribers[subscription].add(registrant);
        emit RegistrationUpdated(registrant, true);
        emit SubscriptionUpdated(registrant, subscription, true);
    }

    function registerAndCopyEntries(address registrant, address registrantToCopy)
    external
    onlyAddressOrOwner(registrant)
    {
        if (registrantToCopy == registrant) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
        _copyEntries(registrant, registrantToCopy);
    }

    function updateOperator(address registrant, address operator, bool filtered)
    external
    onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrant];

        if (!filtered) {
            bool removed = filteredOperatorsRef.remove(operator);
            if (!removed) {
                revert AddressNotFiltered(operator);
            }
        } else {
            bool added = filteredOperatorsRef.add(operator);
            if (!added) {
                revert AddressAlreadyFiltered(operator);
            }
        }
        emit OperatorUpdated(registrant, operator, filtered);
    }

    function updateCodeHash(address registrant, bytes32 codeHash, bool filtered)
    external
    onlyAddressOrOwner(registrant)
    {
        if (codeHash == EOA_CODEHASH) {
            revert CannotFilterEOAs();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrant];

        if (!filtered) {
            bool removed = filteredCodeHashesRef.remove(codeHash);
            if (!removed) {
                revert CodeHashNotFiltered(codeHash);
            }
        } else {
            bool added = filteredCodeHashesRef.add(codeHash);
            if (!added) {
                revert CodeHashAlreadyFiltered(codeHash);
            }
        }
        emit CodeHashUpdated(registrant, codeHash, filtered);
    }

    function updateOperators(address registrant, address[] calldata operators, bool filtered)
    external
    onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrant];
        uint256 operatorsLength = operators.length;
    unchecked {
        if (!filtered) {
            for (uint256 i = 0; i < operatorsLength; ++i) {
                address operator = operators[i];
                bool removed = filteredOperatorsRef.remove(operator);
                if (!removed) {
                    revert AddressNotFiltered(operator);
                }
            }
        } else {
            for (uint256 i = 0; i < operatorsLength; ++i) {
                address operator = operators[i];
                bool added = filteredOperatorsRef.add(operator);
                if (!added) {
                    revert AddressAlreadyFiltered(operator);
                }
            }
        }
    }
        emit OperatorsUpdated(registrant, operators, filtered);
    }

    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered)
    external
    onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrant];
        uint256 codeHashesLength = codeHashes.length;
    unchecked {
        if (!filtered) {
            for (uint256 i = 0; i < codeHashesLength; ++i) {
                bytes32 codeHash = codeHashes[i];
                bool removed = filteredCodeHashesRef.remove(codeHash);
                if (!removed) {
                    revert CodeHashNotFiltered(codeHash);
                }
            }
        } else {
            for (uint256 i = 0; i < codeHashesLength; ++i) {
                bytes32 codeHash = codeHashes[i];
                if (codeHash == EOA_CODEHASH) {
                    revert CannotFilterEOAs();
                }
                bool added = filteredCodeHashesRef.add(codeHash);
                if (!added) {
                    revert CodeHashAlreadyFiltered(codeHash);
                }
            }
        }
    }
        emit CodeHashesUpdated(registrant, codeHashes, filtered);
    }

    function subscribe(address registrant, address newSubscription) external onlyAddressOrOwner(registrant) {
        if (registrant == newSubscription) {
            revert CannotSubscribeToSelf();
        }
        if (newSubscription == address(0)) {
            revert CannotSubscribeToZeroAddress();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == newSubscription) {
            revert AlreadySubscribed(newSubscription);
        }
        address newSubscriptionRegistration = _registrations[newSubscription];
        if (newSubscriptionRegistration == address(0)) {
            revert NotRegistered(newSubscription);
        }
        if (newSubscriptionRegistration != newSubscription) {
            revert CannotSubscribeToRegistrantWithSubscription(newSubscription);
        }

        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = newSubscription;
        _subscribers[newSubscription].add(registrant);
        emit SubscriptionUpdated(registrant, newSubscription, true);
    }

    function unsubscribe(address registrant, bool copyExistingEntries) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == registrant) {
            revert NotSubscribed();
        }
        _subscribers[registration].remove(registrant);
        _registrations[registrant] = registrant;
        emit SubscriptionUpdated(registrant, registration, false);
        if (copyExistingEntries) {
            _copyEntries(registrant, registration);
        }
    }

    function copyEntriesOf(address registrant, address registrantToCopy) external onlyAddressOrOwner(registrant) {
        if (registrant == registrantToCopy) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _copyEntries(registrant, registrantToCopy);
    }

    function _copyEntries(address registrant, address registrantToCopy) private {
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrantToCopy];
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrantToCopy];
        uint256 filteredOperatorsLength = filteredOperatorsRef.length();
        uint256 filteredCodeHashesLength = filteredCodeHashesRef.length();
    unchecked {
        for (uint256 i = 0; i < filteredOperatorsLength; ++i) {
            address operator = filteredOperatorsRef.at(i);
            bool added = _filteredOperators[registrant].add(operator);
            if (added) {
                emit OperatorUpdated(registrant, operator, true);
            }
        }
        for (uint256 i = 0; i < filteredCodeHashesLength; ++i) {
            bytes32 codehash = filteredCodeHashesRef.at(i);
            bool added = _filteredCodeHashes[registrant].add(codehash);
            if (added) {
                emit CodeHashUpdated(registrant, codehash, true);
            }
        }
    }
    }

    function subscriptionOf(address registrant) external view returns (address subscription) {
        subscription = _registrations[registrant];
        if (subscription == address(0)) {
            revert NotRegistered(registrant);
        } else if (subscription == registrant) {
            subscription = address(0);
        }
    }

    function subscribers(address registrant) external view returns (address[] memory) {
        return _subscribers[registrant].values();
    }

    function subscriberAt(address registrant, uint256 index) external view returns (address) {
        return _subscribers[registrant].at(index);
    }

    function isOperatorFiltered(address registrant, address operator) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].contains(operator);
        }
        return _filteredOperators[registrant].contains(operator);
    }


    function isCodeHashFiltered(address registrant, bytes32 codeHash) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external view returns (bool) {
        bytes32 codeHash = operatorWithCode.codehash;
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    function isRegistered(address registrant) external view returns (bool) {
        return _registrations[registrant] != address(0);
    }

    function filteredOperators(address registrant) external view returns (address[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].values();
        }
        return _filteredOperators[registrant].values();
    }

    function filteredCodeHashes(address registrant) external view returns (bytes32[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].values();
        }
        return _filteredCodeHashes[registrant].values();
    }

    function filteredOperatorAt(address registrant, uint256 index) external view returns (address) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].at(index);
        }
        return _filteredOperators[registrant].at(index);
    }

    function filteredCodeHashAt(address registrant, uint256 index) external view returns (bytes32) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].at(index);
        }
        return _filteredCodeHashes[registrant].at(index);
    }

    function codeHashOf(address a) external view returns (bytes32) {
        return a.codehash;
    }
}

contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

    error NotInWhitelist();
    error InvalidAmountOfEthers();
    error CantSendEthersToWallet();
    error LimitExceeded();
    error PrivateSaleNotStarted();


contract NFTTrump is ERC721A, Ownable, Pausable, DefaultOperatorFilterer, ERC2981 {
    using Counters for Counters.Counter;

    uint256 public immutable totalNFTSupply;
    uint256 public mintPricePublic;
    uint256 public mintPricePrivate;
    uint256 public constant _maxCountMintPublic = 100;
    uint256 public constant _maxCountMintPrivate = 10;
    string private _baseURIAddress;
    address private immutable _wallet;
    // whitelist
    bytes32 private _merkleRoot;
    bool public isPrivateSale;

    mapping(address => uint256) private _walletMintCount;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _mintPricePublic,
        uint256 _mintPricePrivate,
        address wallet_,
        string memory baseURIAddress_,
        bytes32 merkleRoot,
        bool isPrivate
    ) ERC721A(_name, _symbol) {
        totalNFTSupply = _totalSupply;
        mintPricePublic = _mintPricePublic;
        mintPricePrivate = _mintPricePrivate;
        _wallet = wallet_;
        _baseURIAddress = baseURIAddress_;
        _merkleRoot = merkleRoot;
        isPrivateSale = isPrivate;
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721A, ERC2981)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function burnNFT(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    function setPrivateSale() public onlyOwner {
        isPrivateSale = true;
    }

    function setPublicSale() public onlyOwner {
        isPrivateSale = false;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIAddress = baseURI_;
    }

    function setMintPricePublic(uint256 _price) public onlyOwner {
        mintPricePublic = _price;
    }

    function setMintPricePrivate(uint256 _price) public onlyOwner {
        mintPricePrivate = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIAddress;
    }

    function getPricePublic(uint256 _count) public view returns (uint256) {
        return _count * mintPricePublic;
    }

    function getPricePrivate(uint256 _count) public view returns (uint256) {
        return _count * mintPricePrivate;
    }

    function getCountWalletNft() public view returns (uint) {
        return _walletMintCount[_msgSender()];
    }

    function ownerMint(address _to, uint256 _count) public payable onlyOwner {
        _safeMint(_to, _count);
    }

    function privateMint(uint256 _count, bytes32[] calldata _merkleProof) public whenNotPaused payable validateProof(_merkleProof){
        require(isPrivateSale, "Buying nft is only available for public");
        require((getCountWalletNft() + _count) <= _maxCountMintPrivate, "You cant by nft.");
        require((totalSupply() + _count) <= totalNFTSupply, "Total supply exceeded. Use less amount.");
        uint costWei = getPricePrivate(_count);
        require(msg.value >= costWei, "Not enough ethers to buy");
        (bool sent, ) = payable(_wallet).call{value: address(this).balance}("");
        require(sent, 'Cant send money to owners wallet.');
        _walletMintCount[_msgSender()] += _count;

        _safeMint(_msgSender(), _count);
    }

    function publicMint(uint256 _count) public whenNotPaused payable {
        require(!isPrivateSale, "Buying nft is only available for private");
        require((getCountWalletNft() + _count) <= _maxCountMintPublic, "You cant by nft.");
        require((totalSupply() + _count) <= totalNFTSupply, "Total supply exceeded. Use less amount.");
        uint costWei = getPricePublic(_count);
        require(msg.value >= costWei, "Not enough ethers to buy");
        (bool sent, ) = payable(_wallet).call{value: address(this).balance}("");
        require(sent, 'Cant send money to owners wallet.');
        _walletMintCount[_msgSender()] += _count;

        _safeMint(_msgSender(), _count);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier validateProof(bytes32[] calldata _merkleProof) {
        if (isPrivateSale) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(_merkleProof, _merkleRoot, leaf)) {
                revert NotInWhitelist();
            }
        }
        _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator
    payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}