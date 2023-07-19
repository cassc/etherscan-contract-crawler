// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract MarketplaceETHScription is Context, Initializable, AccessControlEnumerable {
    using SafeMath for uint256;

    event ethscriptions_protocol_TransferEthscription(address indexed recipient, bytes32 indexed ethscriptionId);

    event PlaceOrder(bytes32 indexed inscription, address seller, uint256 price);
    event FillOrder(bytes32 indexed inscription, address buyer, address seller, uint256 price);
    event CancelOrder(bytes32 indexed inscription, address seller);

    struct Order {
        address owner;
        uint256 price;
        uint256 updatedAt;
    }

    bytes32 public constant MARKET_ADMIN = keccak256('MARKET_ADMIN');

    mapping(bytes32 => Order) public market;
    mapping(bytes32 => uint256) public latestUpdateTime;
    uint256 public feeRate;
    address public feeAddress;
    bool public paused;
    address signer;

    modifier notPaused() {
        require(!paused, 'Market is paused');
        _;
    }

    modifier restricted() {
        require(hasRole(MARKET_ADMIN, _msgSender()), 'access denied');
        _;
    }

    modifier isSellerOrAdmin(bytes32 _inscription) {
        require(
            market[_inscription].owner == _msgSender() || hasRole(MARKET_ADMIN, _msgSender()),
            'Need permission to cancel'
        );
        _;
    }

    modifier delayAction(bytes32 _id) {
        require(latestUpdateTime[_id].add(5) < block.timestamp, 'Please wait: Cancel Order And Replace');
        latestUpdateTime[_id] = block.timestamp;
        _;
    }

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MARKET_ADMIN, _msgSender());
        feeRate = 200;
        feeAddress = _msgSender();
        paused = false;
    }

    function placeOrder(
        bytes32 _inscription,
        uint256 _price,
        string memory id,
        bytes memory signature
    ) public notPaused delayAction(_inscription) {
        require(
            (market[_inscription].price == 0 && market[_inscription].owner == address(0)) ||
                market[_inscription].owner == _msgSender(),
            'The item already exists'
        );
        require(verifyInscriptionOwnership(id, signature));
        market[_inscription].owner = _msgSender();
        market[_inscription].price = _price;
        market[_inscription].updatedAt = block.timestamp;

        emit PlaceOrder(_inscription, _msgSender(), _price);
    }

    function updatePrice(
        bytes32 _inscription,
        uint256 _newPrice
    ) public notPaused isSellerOrAdmin(_inscription) delayAction(_inscription) {
        require(_newPrice > 0 && market[_inscription].price != _newPrice, 'Invalid price');
        market[_inscription].price = _newPrice;
        market[_inscription].updatedAt = block.timestamp;
    }

    function fillOrder(bytes32 _inscription) public payable notPaused {
        address seller = market[_inscription].owner;
        uint256 price = market[_inscription].price;

        require(msg.value == price, 'Not enough balance');

        uint256 fee = price.mul(feeRate).div(10000);

        payable(seller).transfer(price - fee);
        payable(feeAddress).transfer(fee);

        delete market[_inscription];

        emit ethscriptions_protocol_TransferEthscription(_msgSender(), _inscription);
        emit FillOrder(_inscription, _msgSender(), seller, price);
    }

    function cancelOrder(bytes32 _inscription) public notPaused isSellerOrAdmin(_inscription) {
        address seller = market[_inscription].owner;
        emit ethscriptions_protocol_TransferEthscription(seller, _inscription);
        delete market[_inscription];
        emit CancelOrder(_inscription, seller);
    }

    function togglePause() public restricted {
        paused = !paused;
    }

    function setFeeAddress(address _feeAddress) public restricted {
        feeAddress = _feeAddress;
    }

    function setFeeMarketRate(uint256 _fee) public restricted {
        feeRate = _fee;
    }

    fallback() external payable {}

    receive() external payable {}

    function setSigner(address _signer) public restricted {
        signer = _signer;
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, 'invalid signature length');

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // use this function to get the hash of any string
    function getHash(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    // take the keccak256 hashed message from the getHash function above and input into this function
    // this function prefixes the hash above with \x19Ethereum signed message:\n32 + hash
    // and produces a new hash signature
    function getEthSignedHash(string memory str) public pure returns (bytes32) {
        bytes32 messageHash = keccak256(abi.encodePacked(str));
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', messageHash));
    }

    // input the getEthSignedHash results and the signature hash results
    // the output of this function will be the account number that signed the original message
    function verify(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function verifyInscriptionOwnership(string memory str, bytes memory signature) public view returns (bool) {
        bytes32 ethSignedHash = getEthSignedHash(str);
        address recoverAddress = verify(ethSignedHash, signature);
        return signer == recoverAddress;
    }
}