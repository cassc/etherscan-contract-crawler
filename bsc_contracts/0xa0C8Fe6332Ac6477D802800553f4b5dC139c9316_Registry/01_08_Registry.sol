// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/Iregistry.sol";
import "./interface/Isettings.sol";
import "./interface/Ibridge.sol";
import "./interface/Icontroller.sol";
import "./interface/IERCOwnable.sol";

contract Registry is Ownable {
    struct Transaction {
        uint256 chainId;
        address assetAddress;
        uint256 amount;
        address receiver;
        uint256 nounce;
        bool isCompleted;
    }
    struct validation {
        uint256 validationCount;
        bool validated;
    }
    enum transactionType {
        send,
        burn,
        mint,
        claim
    }

    mapping(address => uint256) public assetTotalTransactionCount;
    mapping(address => mapping(uint256 => uint256))
        public assetTransactionTypeCount;
    mapping(address => mapping(uint256 => uint256)) public assetChainBalance;
    mapping(address => uint256) public getUserNonce;
    mapping(bytes32 => bool) public isSendTransaction;
    mapping(bytes32 => Transaction) public sendTransactions;
    mapping(bytes32 => bool) public isClaimTransaction;
    mapping(bytes32 => Transaction) public claimTransactions;
    mapping(bytes32 => Transaction) public mintTransactions;
    mapping(bytes32 => bool) public isMintTransaction;
    mapping(bytes32 => Transaction) public burnTransactions;
    mapping(bytes32 => bool) public isburnTransaction;
    mapping(bytes32 => validation) public transactionValidations;
    mapping(bytes32 => address[]) public TransactionValidators;
    mapping(bytes32 => mapping(address => bool)) public hasValidatedTransaction;
    uint256 public totalTransactions;

    event TransactionValidated(bytes32 indexed transactionID);
    event SendTransactionCompleted(bytes32 indexed transactionID);
    event BurnTransactionCompleted(bytes32 indexed transactionID);
    event MintTransactionCompleted(bytes32 indexed transactionID);
    event ClaimTransactionCompleted(bytes32 indexed transactionID);

    constructor() {}

    function completeSendTransaction(bytes32 transactionID) external {
        require(isSendTransaction[transactionID], "invalid Transaction");
        emit SendTransactionCompleted(transactionID);
        sendTransactions[transactionID].isCompleted = true;
    }

    function completeBurnTransaction(bytes32 transactionID) external {
        require(isburnTransaction[transactionID], "invalid Transaction");
        emit BurnTransactionCompleted(transactionID);
        burnTransactions[transactionID].isCompleted = true;
    }

    function completeMintTransaction(bytes32 transactionID) external {
        require(isMintTransaction[transactionID], "invalid Transaction");
        emit MintTransactionCompleted(transactionID);
        mintTransactions[transactionID].isCompleted = true;
    }

    function completeClaimTransaction(bytes32 transactionID) external {
        require(isClaimTransaction[transactionID], "invalid Transaction");
        emit ClaimTransactionCompleted(transactionID);
        assetChainBalance[claimTransactions[transactionID].assetAddress][
            claimTransactions[transactionID].chainId
        ] -= convertToAssetDecimals(
            claimTransactions[transactionID].amount,
            claimTransactions[transactionID].assetAddress
        );
        claimTransactions[transactionID].isCompleted = true;
    }

    function registerTransaction(
        uint256 chainTo,
        address assetAddress,
        uint256 amount,
        address receiver,
        transactionType _transactionType
    ) public onlyOwner returns (bytes32 transactionID, uint256 nounce) {
        if (_transactionType == transactionType.send) {
            nounce = getUserNonce[receiver];
            transactionID = keccak256(
                abi.encodePacked(
                    getChainId(),
                    chainTo,
                    assetAddress,
                    amount,
                    receiver,
                    nounce
                )
            );

            sendTransactions[transactionID] = Transaction(
                chainTo,
                assetAddress,
                amount,
                receiver,
                nounce,
                false
            );
            isSendTransaction[transactionID] = true;
            getUserNonce[receiver]++;
            assetChainBalance[assetAddress][chainTo] += convertToAssetDecimals(
                amount,
                assetAddress
            );
        } else if (_transactionType == transactionType.burn) {
            nounce = getUserNonce[receiver];
            transactionID = keccak256(
                abi.encodePacked(
                    getChainId(),
                    chainTo,
                    assetAddress,
                    amount,
                    receiver,
                    nounce
                )
            );

            burnTransactions[transactionID] = Transaction(
                chainTo,
                assetAddress,
                amount,
                receiver,
                nounce,
                false
            );
            isburnTransaction[transactionID] = true;
            getUserNonce[receiver]++;
        }
        assetTotalTransactionCount[assetAddress]++;
        totalTransactions++;
    }

    function _registerTransaction(
        bytes32 transactionID,
        uint256 chainId,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint256 nounce,
        transactionType _transactionType
    ) internal {
        if (_transactionType == transactionType.mint) {
            mintTransactions[transactionID] = Transaction(
                chainId,
                assetAddress,
                amount,
                receiver,
                nounce,
                false
            );
            isMintTransaction[transactionID] = true;
        } else if (_transactionType == transactionType.claim) {
            claimTransactions[transactionID] = Transaction(
                chainId,
                assetAddress,
                amount,
                receiver,
                nounce,
                false
            );
            isClaimTransaction[transactionID] = true;
        }
    }

    function registerClaimTransaction(
        bytes32 claimID,
        uint256 chainFrom,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint256 nounce
    ) external {
        require(
            IController(Ibridge(owner()).controller()).isOracle(msg.sender),
            "U_A"
        );
        require(!isClaimTransaction[claimID], "registerred");
        require(
            Ibridge(owner()).isAssetSupportedChain(assetAddress, chainFrom),
            "chain_err"
        );
        bytes32 requiredClaimID = keccak256(
            abi.encodePacked(
                chainFrom,
                getChainId(),
                assetAddress,
                amount,
                receiver,
                nounce
            )
        );

        require(claimID == requiredClaimID, "claimid_err");
        _registerTransaction(
            claimID,
            chainFrom,
            assetAddress,
            amount,
            receiver,
            nounce,
            transactionType.claim
        );
    }

    function registerMintTransaction(
        bytes32 mintID,
        uint256 chainFrom,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint256 nounce
    ) external {
        require(
            IController(Ibridge(owner()).controller()).isOracle(msg.sender),
            "U_A"
        );
        require(!isMintTransaction[mintID], "registerred");
        Ibridge bridge = Ibridge(owner());
        address wrappedAddress = bridge.wrappedForiegnPair(
            assetAddress,
            chainFrom
        );
        // require(wrappedAddress != address(0), "I_A");
        if (!bridge.isDirectSwap(assetAddress, chainFrom)) {
            Ibridge.asset memory foriegnAsset = bridge.foriegnAssets(
                wrappedAddress
            );
            require(foriegnAsset.isSet, "asset_err");
            require(
                bridge.foriegnAssetChainID(wrappedAddress) == chainFrom,
                "chain_err"
            );
        }

        bytes32 requiredmintID = keccak256(
            abi.encodePacked(
                chainFrom,
                bridge.chainId(),
                assetAddress,
                amount,
                receiver,
                nounce
            )
        );
        require(mintID == requiredmintID, "mint: error validation mint ID");
        _registerTransaction(
            mintID,
            chainFrom,
            wrappedAddress,
            amount,
            receiver,
            nounce,
            transactionType.mint
        );
    }

    function convertToAssetDecimals(uint256 amount, address assetAddress)
        internal
        view
        returns (uint256)
    {
        uint256 decimals;
        if (assetAddress == address(0)) {
            decimals = Ibridge(owner()).standardDecimals();
        } else {
            decimals = IERCOwnable(assetAddress).decimals();
        }
        return amount / (10**(Ibridge(owner()).standardDecimals() - decimals));
    }

    function validateTransaction(
        bytes32 transactionId,
        bytes[] memory signatures,
        bool mintable
    ) external {
        require(
            IController(Ibridge(owner()).controller()).isValidator(msg.sender),
            "U_A"
        );
        require(
            Isettings(Ibridge(owner()).settings()).minValidations() != 0,
            "minvalidator_err"
        );
        Transaction memory transaction;
        if (mintable) {
            require(isMintTransaction[transactionId], "mintID_err");
            transaction = mintTransactions[transactionId];
            if (
                !Ibridge(owner()).isDirectSwap(
                    transaction.assetAddress,
                    transaction.chainId
                )
            ) {
                (, uint256 max) = Ibridge(owner()).assetLimits(
                    transaction.assetAddress,
                    false
                );
                require(
                    convertToAssetDecimals(
                        transaction.amount,
                        transaction.assetAddress
                    ) <= max,
                    "Amount_limit_Err"
                );
            }
        } else {
            require(isClaimTransaction[transactionId], "caimID_err");
            transaction = claimTransactions[transactionId];
            (, uint256 max) = Ibridge(owner()).assetLimits(
                transaction.assetAddress,
                true
            );
            require(
                convertToAssetDecimals(
                    transaction.amount,
                    transaction.assetAddress
                ) <=
                    max &&
                    convertToAssetDecimals(
                        transaction.amount,
                        transaction.assetAddress
                    ) <=
                    assetChainBalance[transaction.assetAddress][
                        transaction.chainId
                    ],
                "Amount_limit_Err"
            );
        }
        require(!transaction.isCompleted, "completed");
        uint256 validSignatures;
        for (uint256 i; i < signatures.length; i++) {
            address signer = getSigner(
                getChainId(),
                transaction.chainId,
                transaction.assetAddress,
                transaction.amount,
                transaction.receiver,
                transaction.nounce,
                signatures[i]
            );
            if (
                IController(Ibridge(owner()).controller()).isValidator(
                    signer
                ) && !hasValidatedTransaction[transactionId][signer]
            ) {
                validSignatures = validSignatures + 1;
                TransactionValidators[transactionId].push(signer);
                hasValidatedTransaction[transactionId][signer] = true;
            }
        }

        require(
            validSignatures >=
                Isettings(Ibridge(owner()).settings()).minValidations(),
            "insuficient_signers"
        );
        transactionValidations[transactionId].validationCount = validSignatures;
        transactionValidations[transactionId].validated = true;
        emit TransactionValidated(transactionId);
        if (mintable) {
            Ibridge(owner()).mint(transactionId);
        } else {
            Ibridge(owner()).claim(transactionId);
        }
    }

    function getEthSignedMessageHash(
        uint256 chainID,
        uint256 interfacingChainId,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint256 nounce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encodePacked(
                            chainID,
                            interfacingChainId,
                            assetAddress,
                            amount,
                            receiver,
                            nounce
                        )
                    )
                )
            );
    }

    function getSigner(
        uint256 chainID,
        uint256 interfacingChainId,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint256 nounce,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(
            chainID,
            interfacingChainId,
            assetAddress,
            amount,
            receiver,
            nounce
        );
        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function transactionValidated(bytes32 transactionID)
        external
        view
        returns (bool)
    {
        return transactionValidations[transactionID].validated;
    }

    function getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getID(
        uint256 chainFrom,
        uint256 chainTo,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint256 nounce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    chainFrom,
                    chainTo,
                    assetAddress,
                    amount,
                    receiver,
                    nounce
                )
            );
    }
}