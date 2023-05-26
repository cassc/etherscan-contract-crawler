// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BandVesting is AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    address public tokenAddress;
    mapping(bytes32 => bool) public processedTransactions;

    event TokensClaimed(
        address indexed userAddress,
        uint256 tokenAmount,
        uint256 indexed timestamp
    );

    constructor(address _token, address _signerAddress) {
        tokenAddress = _token;
        _setupRole(SIGNER_ROLE, _signerAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Claims tokens for user
     * @param amount Tokens amount
     * @param timestamp Timestamp to release tokens
     * @param signature Signature of params
     */
    function claimTokens(
        uint256[] memory amount,
        uint256[] memory timestamp,
        bytes[] memory signature
    ) public {
        address account = _msgSender();
        uint256 sum;
        require(amount.length == timestamp.length, "Wrong arguments!");
        for (uint256 i = 0; i < signature.length; i++) {
            bytes32 hashedParams = keccak256(
                abi.encodePacked(account, amount[i], timestamp[i])
            );
            bool isProcessed = processedTransactions[hashedParams];
            require(!isProcessed, "TokensClaim: Transaction already processed");
            require(
                hasRole(
                    SIGNER_ROLE,
                    ECDSA.recover(
                        ECDSA.toEthSignedMessageHash(hashedParams),
                        signature[i]
                    )
                ),
                "TokensClaim: Transaction signature is not correct"
            );
            processedTransactions[hashedParams] = true;
            emit TokensClaimed(account, amount[i], timestamp[i]);
            sum += amount[i];
        }
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("mintTo(address,uint256)", account, sum)
        );
        require(success);
    }
}