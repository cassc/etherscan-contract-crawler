// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

//////////////////////////////////////////////////////////////////////////////////////
// @title   Peanut Protocol
// @notice  This contract is used to send non front-runnable link payments. These can
//          be erc20, erc721, erc1155 or just plain eth. The recipient address is arbitrary.
//          Links use asymmetric ECDSA encryption by default to be secure & enable trustless,
//          gasless claiming.
//          more at: https://peanut.to
// @version 0.4.1
// @author  H & K
//////////////////////////////////////////////////////////////////////////////////////
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//                         ⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣶⣦⣌⠙⠋⢡⣴⣶⡄⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⣿⣿⣿⡿⢋⣠⣶⣶⡌⠻⣿⠟⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⡆⠸⠟⢁⣴⣿⣿⣿⣿⣿⡦⠉⣴⡇⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⠟⠀⠰⣿⣿⣿⣿⣿⣿⠟⣠⡄⠹⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⢸⡿⢋⣤⣿⣄⠙⣿⣿⡿⠟⣡⣾⣿⣿⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣾⠿⠀⢠⣾⣿⣿⣿⣦⠈⠉⢠⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⣀⣤⣦⣄⠙⠋⣠⣴⣿⣿⣿⣿⠿⠛⢁⣴⣦⡄⠙⠛⠋⠁⠀⠀⠀⠀
// ⠀⠀⢀⣾⣿⣿⠟⢁⣴⣦⡈⠻⣿⣿⡿⠁⡀⠚⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠘⣿⠟⢁⣴⣿⣿⣿⣿⣦⡈⠛⢁⣼⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⢰⡦⠀⢴⣿⣿⣿⣿⣿⣿⣿⠟⢀⠘⠿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠘⢀⣶⡀⠻⣿⣿⣿⣿⡿⠋⣠⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⢿⣿⣿⣦⡈⠻⣿⠟⢁⣼⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠈⠻⣿⣿⣿⠖⢀⠐⠿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀
//
//////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@helix-foundation/contracts/currency/IECO.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PeanutV4 is IERC721Receiver, IERC1155Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Deposit {
        address pubKey20; // last 20 bytes of the hash of the public key for the deposit
        uint256 amount; // amount of the asset being sent
        address tokenAddress; // address of the asset being sent. 0x0 for eth
        uint8 contractType; // 0 for eth, 1 for erc20, 2 for erc721, 3 for erc1155 4 for ECO-like rebasing erc20
        uint256 tokenId; // id of the token being sent (if erc721 or erc1155)
        address senderAddress; // address of the sender
        uint256 timestamp; // timestamp of the deposit
    }

    Deposit[] public deposits; // array of deposits

    // events
    event DepositEvent(
        uint256 indexed _index, uint8 indexed _contractType, uint256 _amount, address indexed _senderAddress
    );
    event WithdrawEvent(
        uint256 indexed _index, uint8 indexed _contractType, uint256 _amount, address indexed _recipientAddress
    );
    event MessageEvent(string message);

    // constructor
    constructor() {
        emit MessageEvent("Hello World, have a nutty day!");
    }

    /**
     * @notice supportsInterface function
     *     @dev ERC165 interface detection
     *     @param _interfaceId bytes4 the interface identifier, as specified in ERC-165
     *     @return bool true if the contract implements the interface specified in _interfaceId
     */
    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return _interfaceId == type(IERC165).interfaceId || _interfaceId == type(IERC721Receiver).interfaceId
            || _interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
     * @notice Function to make a deposit
     * @dev For token deposits, allowance must be set before calling this function
     * @param _tokenAddress address of the token being sent. 0x0 for eth
     * @param _contractType uint8 for the type of contract being sent. 0 for eth, 1 for erc20, 2 for erc721, 3 for erc1155, 4 for ECO-like rebasing erc20
     * @param _amount uint256 of the amount of tokens being sent (if erc20)
     * @param _tokenId uint256 of the id of the token being sent if erc721 or erc1155
     * @param _pubKey20 last 20 bytes of the public key of the deposit signer
     * @return uint256 index of the deposit
     */
    function makeDeposit(
        address _tokenAddress,
        uint8 _contractType,
        uint256 _amount,
        uint256 _tokenId,
        address _pubKey20
    ) public payable nonReentrant returns (uint256) {
        // check that the contract type is valid
        require(_contractType < 5, "INVALID CONTRACT TYPE");

        // handle deposit types
        if (_contractType == 0) {
            // check that the amount sent is equal to the amount being deposited
            require(msg.value > 0, "NO ETH SENT");
            // override amount with msg.value
            _amount = msg.value;
        } else if (_contractType == 1) {
            // REMINDER: User must approve this contract to spend the tokens before calling this function
            // Unfortunately there's no way of doing this in just one transaction.
            // Wallet abstraction pls

            IERC20 token = IERC20(_tokenAddress);

            // transfer the tokens to the contract
            token.safeTransferFrom(msg.sender, address(this), _amount);
        } else if (_contractType == 2) {
            // REMINDER: User must approve this contract to spend the tokens before calling this function.
            // alternatively, the user can call the safeTransferFrom function directly and append the appropriate calldata

            IERC721 token = IERC721(_tokenAddress);
            // require(token.ownerOf(_tokenId) == msg.sender, "Invalid token id");
            token.safeTransferFrom(msg.sender, address(this), _tokenId, "Internal transfer");
        } else if (_contractType == 3) {
            // REMINDER: User must approve this contract to spend the tokens before calling this function.
            // alternatively, the user can call the safeTransferFrom function directly and append the appropriate calldata

            IERC1155 token = IERC1155(_tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "Internal transfer");
        } else if (_contractType == 4) {
            // REMINDER: User must approve this contract to spend the tokens before calling this function
            IECO token = IECO(_tokenAddress);

            // transfer the tokens to the contract
            require(
                token.transferFrom(msg.sender, address(this), _amount), "TRANSFER FAILED. CHECK ALLOWANCE & BALANCE"
            );

            // calculate the rebase invariant amount to store in the deposits array
            _amount *= token.getPastLinearInflation(block.number);
        }

        // create deposit
        deposits.push(
            Deposit({
                tokenAddress: _tokenAddress,
                contractType: _contractType,
                amount: _amount,
                tokenId: _tokenId,
                pubKey20: _pubKey20,
                senderAddress: msg.sender,
                timestamp: block.timestamp
            })
        );

        // emit the deposit event
        emit DepositEvent(deposits.length - 1, _contractType, _amount, msg.sender);

        // return id of new deposit
        return deposits.length - 1;
    }

    /**
     * @notice Erc721 token receiver function
     * @dev These functions are called by the token contracts when a token is sent to this contract
     * @dev If calldata is "Internal transfer" then the token was sent by this contract and we don't need to do anything
     * @dev Otherwise, calldata needs a 20 byte pubkey20
     * @param _operator address operator requesting the transfer
     * @param _from address address which previously owned the token
     * @param _tokenId uint256 ID of the token being transferred
     * @param _data bytes data to send along with a safe transfer check (has to be 32 bytes)
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
        external
        override
        returns (bytes4)
    {
        if (_operator == address(this)) {
            // if operator is this contract, nothing to do, return
            return this.onERC721Received.selector;
        } else if (_data.length != 32) {
            // if data is not 32 bytes, revert (don't want to accept and lock up tokens!)
            revert("INVALID CALLDATA");
        }

        // create deposit
        deposits.push(
            Deposit({
                tokenAddress: msg.sender,
                contractType: 2,
                amount: 1,
                tokenId: _tokenId,
                pubKey20: address(abi.decode(_data, (bytes20))),
                senderAddress: _from,
                timestamp: block.timestamp
            })
        );

        // emit the deposit event
        emit DepositEvent(deposits.length - 1, 2, 1, _from);

        // return correct bytes4
        return this.onERC721Received.selector;
    }

    /**
     * @notice Erc1155 token receiver function
     *     @dev These functions are called by the token contracts when a token is sent to this contract
     *     @dev If calldata is "Internal transfer" then the token was sent by this contract and we don't need to do anything
     *     @dev Otherwise, calldata needs 20 bytes pubKey20
     *     @param _operator address operator requesting the transfer
     *     @param _from address address which previously owned the token
     *     @param _tokenId uint256 ID of the token being transferred
     *     @param _value uint256 amount of tokens being transferred
     *     @param _data bytes data passed with the call
     */
    function onERC1155Received(address _operator, address _from, uint256 _tokenId, uint256 _value, bytes calldata _data)
        external
        override
        returns (bytes4)
    {
        if (_operator == address(this)) {
            return this.onERC1155Received.selector;
        } else if (_data.length != 32) {
            // if data is not 32 bytes, revert (don't want to accept and lock up tokens!)
            revert("INVALID CALLDATA");
        }

        deposits.push(
            Deposit({
                tokenAddress: msg.sender,
                contractType: 3,
                amount: _value,
                tokenId: _tokenId,
                // pubKey20: abi.decode(abi.encodePacked(_data, bytes12(0)), (address)),
                pubKey20: address(abi.decode(_data, (bytes20))),
                senderAddress: _from,
                timestamp: block.timestamp
            })
        );

        // emit the deposit event
        emit DepositEvent(deposits.length - 1, 3, _value, _from);

        // return correct bytes4
        return this.onERC1155Received.selector;
    }

    /**
     * @notice Erc1155 token receiver function
     * @dev These functions are called by the token contracts when a set of tokens is sent to this contract
     * @dev If calldata is "Internal transfer" then the token was sent by this contract and we don't need to do anything
     * @param _operator address operator requesting the transfer
     * @param _from address address which previously owned the token
     * @param _ids uint256[] IDs of each token being transferred (order and length must match _values array)
     * @param _values uint256[] amount of each token being transferred (order and length must match _ids array)
     * @param _data bytes data forwarded from the caller
     * @dev _data needs to contain array of 32 byte pubKey20s (length must match _ids and _values arrays). Encode with abi.encode()
     */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (_operator == address(this)) {
            return this.onERC1155BatchReceived.selector;
        } else if (_data.length != (_ids.length * 32)) {
            // dont accept if data is not 32 bytes per token
            revert("INVALID CALLDATA");
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            deposits.push(
                Deposit({
                    tokenAddress: msg.sender, // token address (not the address of transaction sender)
                    contractType: 3, // 3 is for ERC1155 (should be uint8)
                    amount: _values[i], // amount of this token
                    tokenId: _ids[i], // token id
                    pubKey20: address(bytes20(_data[i * 32:i * 32 + 20])),
                    senderAddress: _from,
                    timestamp: block.timestamp
                })
            );

            // emit the deposit event
            emit DepositEvent(
                deposits.length - 1,
                3,
                _values[i], // amount of this token
                _from
            );
        }

        // return correct bytes4
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Function to withdraw a deposit. Withdraws the deposit to the recipient address.
     * @dev _recipientAddressHash is hash("\x19Ethereum Signed Message:\n32" + hash(_recipientAddress))
     * @dev The signature should be signed with the private key corresponding to the public key stored in the deposit
     * @dev We don't check the unhashed address for security reasons. It's preferable to sign a hash of the address.
     * @param _index uint256 index of the deposit
     * @param _recipientAddress address of the recipient
     * @param _recipientAddressHash bytes32 hash of the recipient address (prefixed with "\x19Ethereum Signed Message:\n32")
     * @param _signature bytes signature of the recipient address (65 bytes)
     * @return bool true if successful
     */
    function withdrawDeposit(
        uint256 _index,
        address _recipientAddress,
        bytes32 _recipientAddressHash,
        bytes memory _signature
    ) external nonReentrant returns (bool) {
        // check that the deposit exists and that it isn't already withdrawn
        require(_index < deposits.length, "DEPOSIT INDEX DOES NOT EXIST");
        Deposit memory _deposit = deposits[_index];
        require(_deposit.amount > 0, "DEPOSIT ALREADY WITHDRAWN");
        // check that the recipientAddress hashes to the same value as recipientAddressHash
        require(
            _recipientAddressHash == ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_recipientAddress))),
            "HASHES DO NOT MATCH"
        );
        // check that the signer is the same as the one stored in the deposit
        address depositSigner = getSigner(_recipientAddressHash, _signature);
        require(depositSigner == _deposit.pubKey20, "WRONG SIGNATURE");

        // emit the withdraw event
        emit WithdrawEvent(_index, _deposit.contractType, _deposit.amount, _recipientAddress);

        // delete the deposit
        delete deposits[_index];

        // Deposit request is valid. Withdraw the deposit to the recipient address.
        if (_deposit.contractType == 0) {
            /// handle eth deposits
            payable(_recipientAddress).transfer(_deposit.amount);
        } else if (_deposit.contractType == 1) {
            /// handle erc20 deposits
            IERC20 token = IERC20(_deposit.tokenAddress);
            token.safeTransfer(_recipientAddress, _deposit.amount);
        } else if (_deposit.contractType == 2) {
            /// handle erc721 deposits
            IERC721 token = IERC721(_deposit.tokenAddress);
            token.safeTransferFrom(address(this), _recipientAddress, _deposit.tokenId);
        } else if (_deposit.contractType == 3) {
            /// handle erc1155 deposits
            IERC1155 token = IERC1155(_deposit.tokenAddress);
            token.safeTransferFrom(address(this), _recipientAddress, _deposit.tokenId, _deposit.amount, "");
        } else if (_deposit.contractType == 4) {
            /// handle rebasing erc20 deposits
            IECO token = IECO(_deposit.tokenAddress);
            uint256 scaledAmount = _deposit.amount / token.getPastLinearInflation(block.number);
            require(token.transfer(_recipientAddress, scaledAmount), "TRANSFER FAILED");
        }

        return true;
    }

    /**
     * @notice Function to allow a sender to withdraw their deposit after 24 hours
     * @param _index uint256 index of the deposit
     * @return bool true if successful
     */
    function withdrawDepositSender(uint256 _index) external nonReentrant returns (bool) {
        // check that the deposit exists
        require(_index < deposits.length, "DEPOSIT INDEX DOES NOT EXIST");
        Deposit memory _deposit = deposits[_index];
        // check that the sender is the one who made the deposit
        require(_deposit.senderAddress == msg.sender, "NOT THE SENDER");
        // check that 24 hours have passed since the deposit
        require(block.timestamp >= _deposit.timestamp + 24 hours, "NOT 24 HOURS YET");

        // emit the withdraw event
        emit WithdrawEvent(_index, _deposit.contractType, _deposit.amount, _deposit.senderAddress);

        // Delete the deposit
        delete deposits[_index];

        if (_deposit.contractType == 0) {
            /// handle eth deposits
            payable(_deposit.senderAddress).transfer(_deposit.amount);
        } else if (_deposit.contractType == 1) {
            /// handle erc20 deposits
            IERC20 token = IERC20(_deposit.tokenAddress);
            token.safeTransfer(_deposit.senderAddress, _deposit.amount);
        } else if (_deposit.contractType == 2) {
            /// handle erc721 deposits
            IERC721 token = IERC721(_deposit.tokenAddress);
            token.safeTransferFrom(address(this), _deposit.senderAddress, _deposit.tokenId);
        } else if (_deposit.contractType == 3) {
            /// handle erc1155 deposits
            IERC1155 token = IERC1155(_deposit.tokenAddress);
            token.safeTransferFrom(address(this), _deposit.senderAddress, _deposit.tokenId, _deposit.amount, "");
        } else if (_deposit.contractType == 4) {
            /// handle rebasing erc20 deposits
            IECO token = IECO(_deposit.tokenAddress);
            uint256 scaledAmount = _deposit.amount / token.getPastLinearInflation(block.number);
            require(token.transfer(_deposit.senderAddress, scaledAmount), "TRANSFER FAILED");
        }

        return true;
    }

    //// Some utility functions ////

    /**
     * @notice Gets the signer of a messageHash. Used for signature verification.
     * @dev Uses ECDSA.recover. On Frontend, use secp256k1 to sign the messageHash
     * @dev also remember to prepend the messageHash with "\x19Ethereum Signed Message:\n32"
     * @param messageHash bytes32 hash of the message
     * @param signature bytes signature of the message
     * @return address of the signer
     */
    function getSigner(bytes32 messageHash, bytes memory signature) public pure returns (address) {
        address signer = ECDSA.recover(messageHash, signature);
        return signer;
    }

    /**
     * @notice Simple way to get the total number of deposits
     * @return uint256 number of deposits
     */
    function getDepositCount() external view returns (uint256) {
        return deposits.length;
    }

    /**
     * @notice Simple way to get single deposit
     * @param _index uint256 index of the deposit
     * @return Deposit struct
     *     // TODO: Can also potentially add link time expiry here. Future approach.
     * }
     */
    function getDeposit(uint256 _index) external view returns (Deposit memory) {
        return deposits[_index];
    }

    /**
     * @notice Get all deposits in contract
     * @return Deposit[] array of deposits
     */
    function getAllDeposits() external view returns (Deposit[] memory) {
        return deposits;
    }

    /**
     * @notice Get all deposits for a given address
     * @param _address address of the deposits
     * @return Deposit[] array of deposits
     */
    function getAllDepositsForAddress(address _address) external view returns (Deposit[] memory) {
        Deposit[] memory _deposits = new Deposit[](deposits.length);
        uint256 count = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].senderAddress == _address) {
                _deposits[count] = deposits[i];
                count++;
            }
        }
        return _deposits;
    }

    // and that's all! Have a nutty day!
}