// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/utils/ECDSA.sol";
import "solady/src/utils/EIP712.sol";
import "solady/src/utils/ERC1967FactoryConstants.sol";
import "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract EthscriptionsMarketV2 is ReentrancyGuard, EIP712 {
    error NotAdmin();
    error InvalidSignature();
    error NotDeposited();
    error AlreadyReceived();
    error InvalidLength();
    error AlreadyInitialized();
    error NotFactory();
    error ZeroBalance();
    error ZeroPaymentAddress();
    error ZeroAdminAddress();
    
    using SafeTransferLib for address;
    using ECDSA for bytes32;
    
    event ethscriptions_protocol_TransferEthscription(address indexed recipient, bytes32 indexed id);
    
    event EthscriptionPurchased(
        address indexed seller,
        address indexed buyer,
        bytes32 indexed ethscriptionId,
        uint price,
        bytes32 listingId
    );
    
    event ListingCancelled(address indexed seller, bytes32 indexed listingId);
    
    event AllListingsOfEthscriptionCancelledForUser(
        address indexed seller,
        bytes32 indexed ethscriptionId
    );
    
    event AllListingsCancelledForUser(address indexed seller);
    
    event EthscriptionDeposited(
        address indexed owner,
        bytes32 indexed ethscriptionId
    );
    
    event EthscriptionWithdrawn(
        address indexed owner,
        bytes32 indexed ethscriptionId
    );
    
    event AdminAddressChanged(address indexed oldAdminAddress, address indexed newAdminAddress);
    event PaymentAddressChanged(address indexed oldPaymentAddress, address indexed newPaymentAddress);
    event FeeBpsChanged(uint96 oldFeeBps, uint96 newFeeBps);
    
    event FeesWithdrawn(address indexed recipient, uint amount);
    
    struct MarketStorage {
        mapping(address => mapping(bytes32 => bool)) storedEthscriptions;
        mapping(address => mapping(bytes32 => bool)) userListingCancellations;
        mapping(address => mapping(bytes32 => uint)) userListingsOfEthscriptionValidAfterTime;
        mapping(address => uint) userListingsValidAfterTime;
        
        address adminAddress;
        address paymentAddress;
        uint96 feeBps;
    }
    
    function s() internal pure returns (MarketStorage storage cs) {
        bytes32 position = keccak256("MarketStorage.contract.storage.v1");
        assembly {
           cs.slot := position
        }
    }
    
    function buyWithSignature(
        bytes32 listingId,
        address seller,
        bytes32 ethscriptionId,
        uint price,
        uint startTime,
        uint endTime,
        bytes calldata signature
    ) external payable nonReentrant {
        bytes32 hashedMessage = _hashTypedData(keccak256(abi.encode(
            keccak256(
                "Listing(bytes32 listingId,address seller,bytes32 ethscriptionId,"
                "uint256 price,uint256 startTime,uint256 endTime)"
            ),
            listingId,
            seller,
            ethscriptionId,
            price,
            startTime,
            endTime
        )));
        
        address signer = hashedMessage.recoverCalldata(signature);

        if (
            signer != seller ||
            block.timestamp < startTime ||
            block.timestamp > endTime ||
            msg.value != price ||
            s().userListingCancellations[seller][listingId] ||
            startTime <= s().userListingsOfEthscriptionValidAfterTime[seller][ethscriptionId] ||
            startTime <= s().userListingsValidAfterTime[seller] ||
            !s().storedEthscriptions[seller][ethscriptionId]
        ) {
            revert InvalidSignature();
        }
    
        s().userListingsOfEthscriptionValidAfterTime[seller][ethscriptionId] = block.timestamp;
        
        delete s().storedEthscriptions[seller][ethscriptionId];
        
        seller.forceSafeTransferETH(price - computeFee(price));
        
        emit ethscriptions_protocol_TransferEthscription(msg.sender, ethscriptionId);
        
        emit EthscriptionPurchased(seller, msg.sender, ethscriptionId, price, listingId);
    }
    
    function computeFee(uint amount) public view returns (uint) {
        return (amount * s().feeBps) / 10000;
    }
    
    function getFeeBps() external view returns (uint) {
        return s().feeBps;
    }
    
    function cancelListing(bytes32 listingId) external {
        s().userListingCancellations[msg.sender][listingId] = true;
        emit ListingCancelled(msg.sender, listingId);
    }
    
    function cancelAllListings() external {
        s().userListingsValidAfterTime[msg.sender] = block.timestamp;
        emit AllListingsCancelledForUser(msg.sender);
    }
    
    function cancelAllListingsForEthscription(bytes32 ethscriptionId) external {
        s().userListingsOfEthscriptionValidAfterTime[msg.sender][ethscriptionId] = block.timestamp;
        emit AllListingsOfEthscriptionCancelledForUser(msg.sender, ethscriptionId);
    }
    
    function withdrawEthscription(bytes32 ethscriptionId) external {
        if (!s().storedEthscriptions[msg.sender][ethscriptionId]) {
            revert NotDeposited();
        }
        
        s().userListingsOfEthscriptionValidAfterTime[msg.sender][ethscriptionId] = block.timestamp;
        delete s().storedEthscriptions[msg.sender][ethscriptionId];
        
        emit ethscriptions_protocol_TransferEthscription(msg.sender, ethscriptionId);
        
        emit EthscriptionWithdrawn(msg.sender, ethscriptionId);
    }
    
    function onEthscriptionReceived(bytes32 ethscriptionId, address sender) internal {
        if (s().storedEthscriptions[msg.sender][ethscriptionId]) {
            revert AlreadyReceived();
        }

        s().storedEthscriptions[sender][ethscriptionId] = true;
        
        emit EthscriptionDeposited(sender, ethscriptionId);
    }
    
    function getStoredEthscriptions(address owner, bytes32 ethscriptionId) external view returns (bool) {
        return s().storedEthscriptions[owner][ethscriptionId];
    }

    function getUserListingCancellations(address owner, bytes32 listingId) external view returns (bool) {
        return s().userListingCancellations[owner][listingId];
    }

    function getUserEthscriptionCancellationTime(address owner, bytes32 ethscriptionId) external view returns (uint) {
        return s().userListingsOfEthscriptionValidAfterTime[owner][ethscriptionId];
    }

    function getUserCancellationTime(address owner) external view returns (uint) {
        return s().userListingsValidAfterTime[owner];
    }
    
    function setAdminAddress(address adminAddress) external {
        if (msg.sender != s().adminAddress) revert NotAdmin();
        
        emit AdminAddressChanged(s().adminAddress, adminAddress);

        s().adminAddress = adminAddress;
    }
    
    function setPaymentAddress(address paymentAddress) external {
        if (msg.sender != s().adminAddress) revert NotAdmin();
        
        emit PaymentAddressChanged(s().paymentAddress, paymentAddress);
        
        s().paymentAddress = paymentAddress;
    }
    
    function setFeeBps(uint96 feeBps) external {
        if (msg.sender != s().adminAddress) revert NotAdmin();
        
        emit FeeBpsChanged(s().feeBps, feeBps);
        
        s().feeBps = feeBps;
    }
    
    function sendFeesToPaymentAddress() external {
        if (address(this).balance == 0) revert ZeroBalance();
        if (s().paymentAddress == address(0)) revert ZeroPaymentAddress();
        
        emit FeesWithdrawn(s().paymentAddress, address(this).balance);
        
        s().paymentAddress.forceSafeTransferETH(address(this).balance);
    }
    
    function initialize(
        address adminAddress,
        address paymentAddress,
        uint96 feeBps
    ) public {
        if (msg.sender != ERC1967FactoryConstants.ADDRESS) revert NotFactory();
        if (paymentAddress == address(0)) revert ZeroPaymentAddress();
        if (adminAddress == address(0)) revert ZeroPaymentAddress();
        
        s().adminAddress = adminAddress;
        s().paymentAddress = paymentAddress;
        
        s().feeBps = feeBps;
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        revert();
        if (data.length != 32) revert InvalidLength();
        
        bytes32 potentialHash = abi.decode(data, (bytes32));
        
        onEthscriptionReceived(potentialHash, msg.sender);

        return data;
    }

    function _domainNameAndVersion() 
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Ethscriptions Market";
        version = "1";
    }
}