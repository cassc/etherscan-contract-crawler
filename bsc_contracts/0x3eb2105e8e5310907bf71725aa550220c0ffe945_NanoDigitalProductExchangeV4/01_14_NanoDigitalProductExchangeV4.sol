// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract NanoDigitalProductExchangeV4 is UUPSUpgradeable, OwnableUpgradeable {

    struct Transaction { 
        address userAddress;
        uint256 amount;
        bool hasRefund;
    }

    struct Order { 
        string inquiryId;
        string productCode;
        uint256 productPrice;
        uint deadline;
    }
   
    mapping(string => Transaction) public transactions;

    mapping(string => uint256) public prices;
    uint256 public rate;
    IERC20Upgradeable public paymentToken;
    
    address private validator;
    string constant private nameDomain = "Marketplace";
    uint constant private version = 4;

    function updateValidator(address _validator) external onlyOwner {
        require(_validator != address(0), "Validator cannot be zero");
        validator = _validator;
    }
    
    event onSuccess(
        string inquiryId,
        string productCode,
        uint256 productPrice
    ); 
    
    event onRefund(
        string inquiryId
    ); 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _tokenAddress, address _validator) initializer external {
        __UUPSUpgradeable_init();
        __Ownable_init();
        paymentToken = IERC20Upgradeable(_tokenAddress);
        require(_validator != address(0), "Validator cannot be zero");
        validator = _validator;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function verifyOrder(uint8 _v, bytes32 _r, bytes32 _s, Order calldata _order) private view returns(bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(nameDomain)),
                keccak256(bytes(Strings.toString(version))),
                block.chainid,
                address(this)
            )
        );  

        bytes32 hashStruct = keccak256(
        abi.encode(
            keccak256("buy(string inquiryId,string productCode,uint256 productPrice,uint deadline)"),
            keccak256(bytes(_order.inquiryId)),
            keccak256(bytes(_order.productCode)),
            _order.productPrice,
            _order.deadline
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, _v, _r, _s);

        return signer == validator;
    }

    function buyProduct(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        Order calldata _order
    ) external {
        require(block.timestamp < _order.deadline, "Signed transaction expired");
        require(verifyOrder(_v, _r, _s, _order), "Invalid signature");

        Transaction memory trx = transactions[_order.inquiryId];

        require(_order.productPrice > 0, "Product Price cannot be null");  
        require(trx.amount == 0, "Transaction already created");

        SafeERC20Upgradeable.safeTransferFrom(paymentToken, msg.sender, address(this), _order.productPrice); // transfer token to wallet

        transactions[_order.inquiryId] = Transaction(msg.sender, _order.productPrice, false);

        emit onSuccess(_order.inquiryId, _order.productCode, _order.productPrice);
    }

    function refund(string memory _inquiryId) external onlyOwner {
        Transaction memory trx = transactions[_inquiryId];

        require(trx.amount > 0, "Transaction not found");
        require(!trx.hasRefund, "Transaction has been refunded");

        trx.hasRefund = true;
        transactions[_inquiryId] = trx;
        SafeERC20Upgradeable.safeTransfer(paymentToken, trx.userAddress, trx.amount);   

        emit onRefund(_inquiryId);
    }

    function withdraw(address _receiverAddress, uint256 _amount) external onlyOwner {
        SafeERC20Upgradeable.safeTransfer(paymentToken, _receiverAddress, _amount);
    }

    function versions() public pure returns(uint) {
        return version;
    }

    function chainId() external view returns(uint) {
        return block.chainid;
    }
}