pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IDO.sol";
 
contract IDOFactory is AccessControl {
    bytes32 public constant OPS_ROLE = keccak256("OPS_ROLE");

    struct StructIDO {
        address tokenAddress;
        string uri;
    }

    uint256 public totalIdos;
    address public feeAddress;
    address[] public idosAddress;

    mapping(address => StructIDO) public listIDOs;

    event IdoCreated(address indexed ido, address indexed tokenPaymentAddress, address indexed tokenAddress, string uri);
    event onFeeAddressChanged(address indexed _feeAddress);
 
    constructor(address _feeAddress) {
        require(_feeAddress != address(0), "Address cannot be null");
        feeAddress = _feeAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
 
    function changeFeeAddress(address _feeAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeAddress != address(0), "Address cannot be null");
        feeAddress = _feeAddress;
        emit onFeeAddressChanged(feeAddress);
    }
 
    function createIDO(
        IDO.Initialize memory _initialize,
        string memory _uri,
        address _tokenPaymentAddress,
        bool _hasTokenPayment,
        address _tokenAddress,
        uint256 _feePercentage,
        address _newAddressOwner
    ) external onlyRole(OPS_ROLE) {
        require(_tokenPaymentAddress != address(0) && _newAddressOwner != address(0) && _tokenAddress != address(0), "Address cannot be null");
        IDO _ido = new IDO(
            _initialize,
            _uri,
            _tokenPaymentAddress,
            _hasTokenPayment,
            _tokenAddress,
            _feePercentage,
            feeAddress
        );
        address idoAddress = address(_ido);
        _ido.transferOwnership(_newAddressOwner);
        listIDOs[idoAddress] = StructIDO(_tokenAddress, _uri);
        idosAddress.push(idoAddress);
        totalIdos++;
        emit IdoCreated(idoAddress, _tokenPaymentAddress, _tokenAddress, _uri);
    }
}