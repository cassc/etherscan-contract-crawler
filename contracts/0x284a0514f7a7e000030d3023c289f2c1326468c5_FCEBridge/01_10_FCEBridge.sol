// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// @title  FcemBridge
/// @author AkylbekAD
/// @notice FcemBridge contract for locking FCEM to wrapp them into WFCEM at Ethereum

import "./interfaces/IERC20BurnableMintable.sol";
import "./@openzeppelin/contracts/access/AccessControl.sol";

contract FCEBridge is AccessControl {

    /// @notice Special param for each redeem
    enum Status {Nonexist, Undone, Done}

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bool public isContractAvailable;

    bool public isFCEBridgeAvailable;

    /// @dev Some number to make unique hashes
    uint256 private nonce;

    /// @dev Some constants for non-Reentrancy modifier
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;


    mapping (uint => mapping(uint => mapping(address => mapping(address => bool)))) public isBridgeValid;

    mapping (uint => address) public bridgeValidators;

    mapping (bytes32 => Status) public redeemStatus;

    mapping (uint256 => bytes32) public hashByNonce;

    event SwapInitialized(
        address sender,
        uint256 amount,
        uint256 chainIdFrom,
        uint256 chainIdTo,
        address tokenfrom,
        address tokento,
        uint256 nonce,
        bytes32 hashToSign
    );
    
    event RedeemInitialized(
        address recipient,
        uint256 amount,
        uint256 chainIdFrom,
        uint256 chainIdTo,
        address tokenfrom,
        address tokento,
        uint256 nonce
    );

    event BridgeUpdated(
        uint chainIdFrom,
        uint chainIdTo,
        address tokenFrom,
        address tokenTo,
        bool valid,
        address sender
    );

    event BridgeValidatorUpdated(
        uint chainId,
        address newValidator,
        address sender
    );

    event FCEBridgeAvailabilityUpdated(
        address sender,
        bool isAvailable
    );

    constructor(
        address bridgeValidator,
        uint chainIdA,
        uint chainIdB,
        address tokenA,
        address tokenB
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        bridgeValidators[chainIdB] = bridgeValidator;

        isBridgeValid[chainIdA][chainIdB][tokenA][tokenB] = true;
        isBridgeValid[chainIdB][chainIdA][tokenB][tokenA] = true;

        isFCEBridgeAvailable = true;
    }

    /* Prevents a contract function from being reentrant-called. */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered
        _status = _NOT_ENTERED;
    }

    function checkSign(
        address recipient,
        uint256 amount,
        uint256 chainIdFrom,
        uint256 chainIdTo,
        address erc20from,
        address erc20to,
        uint256 nonce_,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(recipient, amount, chainIdFrom, chainIdTo, erc20from, erc20to, nonce_)
        );

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = split(signature);

        address addr = ecrecover(hashMessage(message), v, r, s);

        if(addr == bridgeValidators[chainIdTo]) {
            return true;
        } else {
            return false;
        }
    }

    function hashMessage(bytes32 message) public pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function swap(
        uint256 chainIdTo,
        address tokenFrom,
        address tokenTo,
        uint amount
    ) external returns(bytes32 hashToSign) {
        require(isFCEBridgeAvailable, "Current bridge is not available");
        require(chainIdTo != getChainID(), "'chainIdTo' can not be current");
        require(isBridgeValid[getChainID()][chainIdTo][tokenFrom][tokenTo], "Current Swap is not possible");
        if(!isContractAvailable) require(msg.sender == tx.origin, "Only non contract call");

        hashToSign = keccak256(abi.encodePacked(msg.sender, amount, getChainID(), chainIdTo, tokenFrom, tokenTo, nonce));

        hashByNonce[nonce] = hashToSign;

        emit SwapInitialized(msg.sender, amount, getChainID(), chainIdTo, tokenFrom, tokenTo, nonce, hashToSign);

        nonce++;

        IERC20BurnableMintable(tokenFrom).burn(msg.sender, amount);
    }

    function redeem(
        address recipient,
        uint256 amount,
        uint256 chainIdFrom,
        address tokenFrom,
        address tokenTo,
        uint256 nonce_,
        bytes memory signature
    ) external {
        require(isFCEBridgeAvailable, "Current bridge is not available");
        require(chainIdFrom != getChainID(), "'chainIdFrom' can not be current");
        require(isBridgeValid[chainIdFrom][getChainID()][tokenFrom][tokenTo], "Current Redeem is not possible");
        require(recipient != address(0), "Zero address recipient");
        if(!isContractAvailable) require(msg.sender == tx.origin, "Only non contract call");

        require(checkSign(recipient, amount, chainIdFrom, getChainID(), tokenFrom, tokenTo, nonce_, signature), "Input is not valid");

        bytes32 redeemHash = keccak256(abi.encodePacked(recipient, amount, chainIdFrom, getChainID(), tokenFrom, tokenTo, nonce_, signature));

        emit RedeemInitialized(recipient, amount, chainIdFrom, getChainID(), tokenFrom, tokenTo, nonce_);

        if(redeemStatus[redeemHash] != Status.Done) {
            redeemStatus[redeemHash] = Status.Done;
            IERC20BurnableMintable(tokenTo).mint(recipient, amount);
        } else {
            revert("Arguments to redeem was already used");
        }
    }

    function setBridgeAccess(uint chainIdFrom, uint chainIdTo, address tokenFrom, address tokenTo, bool valid) external onlyRole(ADMIN_ROLE) {
        isBridgeValid[chainIdFrom][chainIdTo][tokenFrom][tokenTo] = valid;

        emit BridgeUpdated(chainIdFrom, chainIdTo, tokenFrom, tokenTo, valid, msg.sender);
    }

    function setDoubleBridgeAccess(uint chainIdA, uint chainIdB, address tokenA, address tokenB, bool valid) external onlyRole(ADMIN_ROLE) {
        isBridgeValid[chainIdA][chainIdB][tokenA][tokenB] = valid;
        isBridgeValid[chainIdB][chainIdA][tokenB][tokenA] = valid;

        emit BridgeUpdated(chainIdA, chainIdB, tokenA, tokenB, valid, msg.sender);
        emit BridgeUpdated(chainIdB, chainIdA, tokenB, tokenA, valid, msg.sender);
    }


    function setBridgeValidator(uint chainId, address newValidator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgeValidators[chainId] = newValidator;

        emit BridgeValidatorUpdated(chainId, newValidator, msg.sender);
    }

    function setContractAvailability(bool value) external onlyRole(ADMIN_ROLE) {
        isContractAvailable = value;
    }

    function setFCEBridgeAvailability(bool value) external onlyRole(ADMIN_ROLE) {
        isFCEBridgeAvailable = value;

        emit FCEBridgeAvailabilityUpdated(msg.sender, value);
    }

    function split(bytes memory signature) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
            assembly {
                id := chainid()
            }
        return id;
    }
}