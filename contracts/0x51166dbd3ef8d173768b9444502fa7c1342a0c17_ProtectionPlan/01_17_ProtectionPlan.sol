// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IProtocolRegistry} from "./interfaces/IProtocolRegistry.sol";
import {IProtectionPlan} from "./interfaces/IProtectionPlan.sol";

/**
 * @dev This struct is used to pass the parameters to the panic function
 *
 * @param tokenAddresses address[] array of token addresses
 * @param tokenIds uint256[] array of token ids
 * @param tokenAmounts uint256[] array of token amounts
 * @param tokenTypes string[] array of token types
 * @param approvedWallets address[] array of approved wallets
 * @param approvalIds uint256[] array of approval ids
 * @param backUpWallet address of the backup wallet
 * @param uid string of the user id
 *
 */
struct PanicParams {
    address[] tokenAddresses;
    uint256[] tokenIds;
    uint256[] tokenAmounts;
    string[] tokenTypes;
    address backUpWallet;
}

contract ProtectionPlan is
    IProtectionPlan,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    // @notice address for string member address
    address public member;

    // @notice variable to store ipfsHash of Member
    string public ipfsHash;

    // @notice variable to store related wallets
    mapping(address => bool) public relatedWallets;

    // @notice keep track of burned nonces
    mapping(address => mapping(uint256 => bool)) private _nonces;

    IProtocolRegistry public protocolRegistry;

    /**
     * @notice Event for Querying Approvals
     *
     * @param approvedWallet address of the wallet owning the asset
     * @param tokenId uint256 tokenId of asset being backed up
     * @param tokenAddress address contract of the asset being protectd
     * @param tokenType string i.e. ERC20 | ERC1155 | ERC721
     * @param tokensAllocated uint256 number of tokens to be protected
     * @param success whether the transfer was successful or not
     * @param claimedWallet address of receipient of assets
     *
     * @dev We ommited the backupWallets array and the dateApproved fields here
     * is that ok?
     */
    event PanicApprovalsEvent(
        address approvedWallet,
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        bool success,
        address claimedWallet,
        uint256 datePanicked
    );

    /**
     * @notice this event is emitted when a related wallet is added
     * @param member wallet address of member
     * @param relatedWallet wallet address of related wallet
     * @param approved whether the member is related or not
     */
    event RelatedWalletEvent(
        address member,
        address relatedWallet,
        bool approved
    );

    /**
     * @notice This initializer sets up the constructor and initial relayer address
     * @param _member parameter to pass in the member on initializing
     */
    function initialize(
        address _member,
        address _protocolDirectoryAddr
    ) public initializer {
        require(_member != address(0), "Error: Member cannot be address zero");
        require(_protocolDirectoryAddr != address(0), "Error: Registry cannot be address zero");
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        member = _member;
        protocolRegistry = IProtocolRegistry(_protocolDirectoryAddr);
    }

    // @notice Modifier to limit access to onlyRelayer
    modifier onlyRelayer() {
        require(
            msg.sender == protocolRegistry.getRelayerAddress(),
            "Error: Only the relayer can invoke this function"
        );
        _;
    }

    // @notice Modifier to limit access to onlyMember invoked by member
    modifier onlyMember() {
        require(
            msg.sender == member,
            "Error: Only the member can invoke this function"
        );
        _;
    }

    /**
     * @notice This modifier limits access to only related wallets, owner of the contract to execute functions
     */
    modifier onlyAuthorizedUsers() {
        bool found = false;
        // Check in relatedWallets

        if (relatedWallets[msg.sender] == true) {
            found = true;
        }

        // If not found in relatedWallets, check in member
        if (!found) {
            if (msg.sender == member) {
                found = true;
            }
        }

        // If not found in either, revert the transaction
        if (!found) {
            revert UserNotAuthorized();
        }
        _;
    }

    /**
     * @notice Validates whether a message has been signed by correct signer
     */
    modifier isValidSignature(
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    ) {
        address signer = protocolRegistry.getSignerAddress();
        if (signer == address(0)) revert SignerAddressZero();
        bytes32 messageHash = keccak256(
            abi.encode(msg.sender, _nonce, _deadline)
        ).toEthSignedMessageHash();
        if (
            !SignatureCheckerUpgradeable.isValidSignatureNow(
                signer,
                messageHash,
                _signature
            )
        ) revert InvalidSignature();
        if (_nonces[msg.sender][_nonce]) revert NonceAlreadyUsed();
        if (block.timestamp > _deadline) revert DeadlineExceeded();
        _nonces[msg.sender][_nonce] = true;
        _;
    }

    /**
     * @notice setRelatedWallets sets related wallets of a user
     * @param _wallets contains related wallets or users wallets that can be backups or normal wallets
     * @param _approvals contains whether the wallet is related or not
     * @param _nonce unique nonce for transaction
     * @param _deadline the transaction deadline
     * @param _signature used to validate the transaction
     */
    function setRelatedWallets(
        address[] calldata _wallets,
        bool[] calldata _approvals,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    ) external onlyMember isValidSignature(_nonce, _deadline, _signature) {
        if (_wallets.length != _approvals.length)
            revert WalletsApprovalsLengthMismatch();
        for (uint256 i = 0; i < _wallets.length; ) {
            relatedWallets[_wallets[i]] = _approvals[i];
            emit RelatedWalletEvent(member, _wallets[i], _approvals[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Allows to update member IPFS CID information onChain to a unique UID passed.
     * @dev setIPFSHash
     * @param _ipfsHash ipfs Hash of the new user information
     * @param _nonce unique nonce for transaction
     * @param _deadline the transaction deadline
     * @param _signature used to validate the transaction
     *
     */
    function setIPFSHash(
        string calldata _ipfsHash,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    ) external onlyMember isValidSignature(_nonce, _deadline, _signature) {
        ipfsHash = _ipfsHash;
    }

    /**
     * @notice Panic used by related wallets to transfer assets from the policy holder.
     * @param params panic params struct
     */
    function panic(PanicParams calldata params) public onlyAuthorizedUsers {
        if (bytes(ipfsHash).length == 0) {
            revert IPFSDoesNotExist();
        }

        //check if approvals exist for the token
        for (uint256 i = 0; i < params.tokenAddresses.length; i++) {
            bool success = false;
            if (
                keccak256(abi.encodePacked((params.tokenTypes[i]))) ==
                keccak256(abi.encodePacked(("ERC20")))
            ) {
                success = _transferERC20(
                    params.tokenAddresses[i],
                    params.backUpWallet,
                    0
                );
            } else if (
                keccak256(abi.encodePacked((params.tokenTypes[i]))) ==
                keccak256(abi.encodePacked(("ERC721")))
            ) {
                success = _transferERC721(
                    params.tokenAddresses[i],
                    params.backUpWallet,
                    params.tokenIds[i]
                );
            } else if (
                keccak256(abi.encodePacked((params.tokenTypes[i]))) ==
                keccak256(abi.encodePacked(("ERC1155")))
            ) {
                success = _transfer1155(
                    params.tokenAddresses[i],
                    params.backUpWallet,
                    params.tokenIds[i],
                    0
                );
            } else {
                // unknown token type
            }
            emit PanicApprovalsEvent(
                member,
                params.tokenIds[i],
                params.tokenAddresses[i],
                params.tokenTypes[i],
                params.tokenAmounts[i],
                success,
                params.backUpWallet,
                block.timestamp
            );
        }
    }

    /**
     * @dev transfers an amount of ERC20 to a recipient and the webacy vault
     *      if the amount param is zero, it attempts to transfer the entire balance
     * @param contractAddress the ERC20 contract
     * @param recipient the transfer to address
     * @param amount the tokens to transfer, if zero then this will transfer the balanceOf instead
     */
    function _transferERC20(
        address contractAddress,
        address recipient,
        uint256 amount
    ) private returns (bool) {
        IERC20 erc20 = IERC20(contractAddress);

        uint256 tokenBalance = erc20.balanceOf(member);
        uint256 allowance = erc20.allowance(member, address(this));

        if (tokenBalance > 0) {
            uint256 transferAmount;
            if (amount > 0 && amount <= tokenBalance && amount <= allowance) {
                transferAmount = amount;
            } else if (tokenBalance <= allowance) {
                transferAmount = tokenBalance;
            } else {
                transferAmount = allowance;
            }

            uint256 webacyFees = transferAmount / 100;
            if (webacyFees > 0) {
                try
                    erc20.transferFrom(
                        member,
                        recipient,
                        transferAmount - webacyFees
                    )
                {
                    try
                        erc20.transferFrom(
                            member,
                            protocolRegistry.getVaultAddress(),
                            webacyFees
                        )
                    {
                        return true;
                    } catch {
                        return false;
                    }
                } catch {
                    return false;
                }
            } else {
                try erc20.transferFrom(member, recipient, transferAmount) {
                    return true;
                } catch {
                    return false;
                }
            }
        }
        return false;
    }

    /**
     * @dev transfers an amount of ERC20 to a recipient and the webacy vault
     *      if the amount param is zero, it attempts to transfer the entire balance
     * @param contractAddress the ERC20 contract
     * @param recipient the transfer to address
     * @param tokenId the token to transfer
     */
    function _transferERC721(
        address contractAddress,
        address recipient,
        uint256 tokenId
    ) private returns (bool) {
        IERC721 erc721 = IERC721(contractAddress);
        try erc721.safeTransferFrom(member, recipient, tokenId) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @dev transfers an amount of ERC20 to a recipient and the webacy vault
     *      if the amount param is zero, it attempts to transfer the entire balance of the tokenId
     * @param contractAddress the ERC20 contract
     * @param recipient the transfer to address
     * @param tokenId the token to transfer balance from
     * @param amount the amount to transfer for the tokenId, if zero then this will transfer the balanceOf instead
     */
    function _transfer1155(
        address contractAddress,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) private returns (bool) {
        IERC1155 erc1155 = IERC1155(contractAddress);

        uint256 balance = erc1155.balanceOf(member, tokenId);
        uint256 transferAmount;
        if (balance > 0) {
            if (amount > 0 && amount <= balance) {
                transferAmount = amount;
            } else {
                transferAmount = balance;
            }
            try
                erc1155.safeTransferFrom(
                    member,
                    recipient,
                    tokenId,
                    transferAmount,
                    bytes("")
                )
            {
                return true;
            } catch {
                return false;
            }
        }
        return false;
    }
}