// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./AnycallFlags.sol";

abstract contract AdminControl {
    address public admin;
    address public pendingAdmin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    constructor(address _admin) {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        pendingAdmin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function applyAdmin() external {
        require(msg.sender == pendingAdmin, "AdminControl: Forbidden");
        emit ApplyAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

interface CircleBridge {
    function depositForBurn(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken
    ) external returns (uint64 _nonce);
}

interface USDCMessageTransmitter {
    function receiveMessage(bytes memory _message, bytes calldata _attestation)
        external
        returns (uint64 _nonce);
}

contract UsdcRelayer is AdminControl{
    using SafeERC20 for IERC20;

    address usdcBridge;
    address usdcMessageTransmitter;
    address usdcToken;
    address feeAddress;

    mapping(uint32 => uint256) public feeByDestinationDomain; 
    mapping(string => bool) public completedCallin;

    event LogCallout(
        address sender,
        uint256 amount,
        uint256 fee,
        address receiver,
        uint32 destinationDomain
    );

    constructor(
        address _admin,
        address _feeAddress,
        address _usdcBridge,
        address _usdcMessageTransmitter,
        address _usdcToken
     )AdminControl(_admin) {
        usdcBridge = _usdcBridge;
        usdcMessageTransmitter = _usdcMessageTransmitter;
        usdcToken = _usdcToken;
        feeAddress = _feeAddress;
    }
    
    function setFeeByDestinationDomain(uint32 _destinationDomain, uint256 _fee) external onlyAdmin {
        feeByDestinationDomain[_destinationDomain] = _fee;
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function callout(
        uint256 _amount,
        uint32 _destinationDomain,
        address _mintRecipient,
        address _burnToken
    ) external payable {
        // if msg.value is more than enough we will proceed otherwise revert
        require(msg.value >= feeByDestinationDomain[_destinationDomain], "not enough fee");

        // transfer the fee to feeAddress
        payable(feeAddress).transfer(msg.value);

        // transfer usdc from msg.sender to this contract
        IERC20(usdcToken).safeTransferFrom(msg.sender, address(this), _amount);

        // approve usdc to usdcBridge
        IERC20(usdcToken).safeIncreaseAllowance(usdcBridge, _amount);
        
        // call depositForBurnWithCaller
        CircleBridge(usdcBridge).depositForBurn(
            _amount,
            _destinationDomain,
            toBytes32(_mintRecipient),
            _burnToken
        );

        emit LogCallout(msg.sender, _amount,msg.value, _mintRecipient, _destinationDomain);
    }

}