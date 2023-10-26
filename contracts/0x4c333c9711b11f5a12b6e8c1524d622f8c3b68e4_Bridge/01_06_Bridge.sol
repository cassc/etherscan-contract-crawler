// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bridge is OwnableUpgradeable {
    IERC20 public EPIC;
    IERC20 public USDC;

    /// @notice This mapping tracks if a nonce is used in sidechain for an account
    mapping (address => mapping (uint256 => bool)) isNonceProcessed;

    /// @notice This variable store the total validators in the sidechain
    uint8 public totalValidators;
    
    /// @notice This mapping tells us if an sidechain account is a validator or not
    mapping(address => bool) public validators;

    /// @notice Tracks which validator has signed the transaction
    mapping (address => mapping(uint => mapping(address => bool))) validatorSigned;

    /// @notice unique ID assigned to each deposit
    uint256 public depositId;
    
    event Deposited (
        IERC20 token,
        address user,
        uint256 amount,
        address account,
        uint256 depositId
    );

    event TransactionProcessed (
        address account,
        uint nonce,
        TransactionType txnType,
        uint amount,
        IERC20 token
    );

    enum TransactionType {
      ADD_VALIDATOR,
      REMOVE_VALIDATOR,
      WITHDRAW  
    }

    function initialize(IERC20 _EPIC, IERC20 _USDC, address validator) public initializer {
        EPIC = _EPIC;
        USDC = _USDC;
        totalValidators = 1;
        validators[validator] = true;

        __Ownable_init();
    }

    function deposit(
        IERC20 token, uint256 amount, address account
    ) external {
        require(
            address(token) == address(EPIC) ||
            address(token) == address(USDC),
            "token not supported"
        );

        token.transferFrom(msg.sender, address(this), amount);
        emit Deposited(token, msg.sender, amount, account, depositId);
        depositId++;
    }

    function getMessageHash(
        address account,
        uint nonce,
        TransactionType txnType,
        uint amount,
        IERC20 token
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(account, nonce, txnType, amount, token, getChainID()));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

     function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function processTransaction(
        address account,
        uint nonce,
        TransactionType txnType,
        uint amount,
        IERC20 token,
        bytes[] memory signatures
    ) external {
        require(signatures.length >= (totalValidators / 2) + 1, "more than half of validators need to sign");
        require(isNonceProcessed[account][nonce] == false, "invalid nonce");

        uint totalSigned; 

        for(uint i = 0; i < signatures.length; i++) {
            bytes32 messageHash = getMessageHash(account, nonce, txnType, amount, token);
            bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
            address signer = recoverSigner(ethSignedMessageHash, signatures[i]);

            if (validatorSigned[account][nonce][signer] == false && validators[signer] == true) {
                totalSigned++;
                validatorSigned[account][nonce][signer] = true;
            }
        }

        require(totalSigned >= (totalValidators / 2) + 1, "insufficient validators signed");
       isNonceProcessed[account][nonce] = true;

        if (txnType == TransactionType.ADD_VALIDATOR) {
            totalValidators++;
            validators[account] = true;
        } else if (txnType == TransactionType.REMOVE_VALIDATOR) {
            totalValidators--;
            validators[account] = false;
        } else if (txnType == TransactionType.WITHDRAW) {
            require(
                address(token) == address(EPIC) ||
                address(token) == address(USDC),
                "token not supported"
            );
            token.transfer(account, amount);
        }

        emit TransactionProcessed(account, nonce, txnType, amount, token);
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}