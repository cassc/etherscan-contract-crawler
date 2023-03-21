// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IMergeRouter} from "./interfaces/IMergeRouter.sol";
import {IGold} from "./interfaces/IGold.sol";
import {IUSDC} from "./interfaces/IUSDC.sol";

/// @title BullionFX Periphery smart contract
/// @notice A contract that enables the acquisition of a large quantity of gold while minimizing the impact on the price.
contract BullionFxPeriphery is Ownable {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Merge router contract.
    IMergeRouter public constant MERGE_ROUTER =
        IMergeRouter(0xB5ff179A82CEB9d9cF4e5B6416b3C714900E7Db2);

    /// @notice The address of the USDC contract.
    IUSDC public constant USDC =
        IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @notice The address of the BullionFX Gold token contract.
    IGold public constant GOLD =
        IGold(0x57c88ed53d53fDc6B41D57463E6C405dE162843e);

    /// @notice Address linked to the private key utilized for signing the message.
    address public signer;

    /// @notice The address of the recipient of treasury fees.
    address public treasuryFeeRecipient;

    /// @notice Current treasury fee percentage, measured in basis points.
    uint96 public treasuryFeePercentage;

    // @notice Max treasury fee percentage that can be set.
    uint256 public constant MAX_TREASURY_FEE = 500; //5%

    /// @notice Utilized to calculate treasury fees and is measured in basis points.
    uint256 public constant PERCENTAGE_CALCULATION = 10000; // 100%

    /// @notice Tracks message hashes that have been used, to prevent message replay.
    mapping(bytes32 => bool) public messageHashesUsed;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event BoughtGoldWithUSDC(
        address indexed caller,
        uint256 totalUSDC,
        uint256 dexAmountInUSDC,
        uint256 dexAmountOutGold,
        uint256 indexed mintedGoldTokens,
        uint256 indexed goldPrice,
        uint256 usdcMintFee
    );

    event GoldMinted(address indexed recipient, uint256 indexed amount);
    event TreasuryFeeRecipientChanged(
        address oldTreasuryFeeRecipient,
        address newTreasuryFeeRecipient
    );
    event TreasuryFeeChanged(uint256 oldPercentage, uint256 newPercentage);
    event SignerChanged(address oldSigner, address newSigner);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AlreadyUsedMessageHash(bytes32 messageHash);
    error ExceedsMaxTreasuryFeePercentage(uint96 treasuryFeePercentage);
    error SignerAddressMismatch(address recoveredSignerAddress);
    error ZeroAddress();
    error ZeroAmount();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the signer address and approves the transfer of USDC held by this contract to the Merge Router contract.
    /// @param _signer Address of the signer
    constructor(
        address _signer,
        address _treasuryFeeRecipient,
        uint96 _treasuryFeePercentage
    ) {
        if (_signer == address(0) || _treasuryFeeRecipient == address(0)) {
            revert ZeroAddress();
        }

        // Cannot have more than 5% treasury fee percentage.
        if (_treasuryFeePercentage > MAX_TREASURY_FEE) {
            revert ExceedsMaxTreasuryFeePercentage(_treasuryFeePercentage);
        }

        // Approving merge router to transfer USDC stored in this contract.
        USDC.approve(address(MERGE_ROUTER), type(uint256).max);

        signer = _signer;
        treasuryFeeRecipient = _treasuryFeeRecipient;
        treasuryFeePercentage = _treasuryFeePercentage;

        emit SignerChanged(address(0), _signer);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Changes the signer address. Can only be called by the owner of this contract.
    /// @param _newSigner Address of the new signer.
    function changeSigner(address _newSigner) external onlyOwner {
        if (_newSigner == address(0)) {
            revert ZeroAddress();
        }

        emit SignerChanged(signer, _newSigner);

        // Overwrites the old signer address
        signer = _newSigner;
    }

    /// @notice Changes the treasury fee recipient address. Can only be called by the owner of this contract.
    /// @param _newTreasuryFeeRecipient Address of the new treasury fee recipient.
    function changeTreasuryFeeRecipient(
        address _newTreasuryFeeRecipient
    ) external onlyOwner {
        if (_newTreasuryFeeRecipient == address(0)) {
            revert ZeroAddress();
        }

        emit TreasuryFeeRecipientChanged(
            treasuryFeeRecipient,
            _newTreasuryFeeRecipient
        );

        // Overwrites the old treasury fee recipient address
        treasuryFeeRecipient = _newTreasuryFeeRecipient;
    }

    /// @notice Changes the treasury fee percentage. Can only be called by the owner of this contract.
    /// @param _newPercentage New treasury fee percentage. Expressed in basis points.
    function changeTreasuryFeePercentage(
        uint96 _newPercentage
    ) external onlyOwner {
        // Cannot have more than 5% treasury fee percentage.
        if (_newPercentage > MAX_TREASURY_FEE) {
            revert ExceedsMaxTreasuryFeePercentage(_newPercentage);
        }

        emit TreasuryFeeChanged(treasuryFeePercentage, _newPercentage);

        // Overwrites the old treasury fee percentage address
        treasuryFeePercentage = _newPercentage;
    }

    /*//////////////////////////////////////////////////////////////
                       GOLD TOKEN RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints gold token. Can only be called by the owner of this contract.
    /// @param _recipient Address to mint gold tokens at.
    /// @param _amount Amount of gold tokens to mint to the '_recipient' address.
    function mintGold(address _recipient, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert ZeroAmount();

        GOLD.mint(_recipient, _amount);

        emit GoldMinted(_recipient, _amount);
    }

    /// @notice Transfers ownership of BullionFX gold token contract. Can only be called by the owner of this contract.
    /// @param _newOwner Address of the new owner of BullionFX gold token contract.
    function transferGoldContractOwnership(
        address _newOwner
    ) external onlyOwner {
        GOLD.transferOwnership(_newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                       USDC TOKEN RELATED FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Buy physical gold using USDC tokens. Can only be called by the owner of this contract.
    /// @param _recipient Address of the recipient of the USDC tokens.
    /// @param _amount Amount of USDC to transfer to the '_recipient' address.
    function purchasePhysicalGoldWithUSDC(
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        if (_amount == 0) revert ZeroAmount();

        USDC.transfer(_recipient, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                       SWAP USDC & MINT GOLD LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Swaps USDC for a gold token on a DEX in such a way that the price impact reaches one percent. Then, uses the remaining USDC to mint gold tokens.
    /// @param _nonce is a unique number used to prevent signature replay attack.
    /// @param  _totalUSDC is the total amount of USDC used to purchase gold tokens.
    /// @param _amountIn is the amount of USDC to be swapped for gold on the DEX.
    /// @param _amountOutMin is the minimum amount of gold tokens to receive from the DEX for _amountIn.
    /// @param _currentGoldPrice is the current price of gold in an external market.
    /// @param _goldToMint is the amount of gold tokens to mint based on the formula: ((_totalUSDC - _amountIn) / _currentGoldPrice)
    /// @param _deadline is the maximum time for which the signature is valid.
    /// @param _signature is the signed message for the transaction.
    function buyGoldWithUSDC(
        uint256 _nonce,
        uint256 _totalUSDC,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _currentGoldPrice,
        uint256 _goldToMint,
        uint256 _deadline,
        bytes calldata _signature
    ) external {
        // Transfer USDC from the recipient to this contract.
        USDC.transferFrom(msg.sender, address(this), _totalUSDC);

        // Generating hash of the message.
        bytes32 _messageHash = _generateMessageHash(
            _nonce,
            _totalUSDC,
            _amountIn,
            _currentGoldPrice,
            _goldToMint,
            _deadline
        );

        // Signs the message hash first and then verifies the signature.
        _signMessageHashAndVerifySignature(_messageHash, _signature);

        messageHashesUsed[_messageHash] = true;

        // Swapping from the dex
        uint256[] memory amounts = MERGE_ROUTER.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _getPath(),
            msg.sender,
            _deadline
        );

        uint256 _mintFee;

        // Deduct treasury fee if set.
        if (treasuryFeePercentage != 0) {
            // Computing the fees (in USDC) that the treasury wallet will receive.
            unchecked {
                _mintFee =
                    ((_totalUSDC - _amountIn) * treasuryFeePercentage) /
                    PERCENTAGE_CALCULATION;
            }

            // Transferring fees to the treasury wallet.
            USDC.transfer(treasuryFeeRecipient, _mintFee);
        }

        // Minting gold to the caller.
        GOLD.mint(msg.sender, _goldToMint);

        emit BoughtGoldWithUSDC(
            msg.sender,
            _totalUSDC,
            _amountIn,
            amounts[amounts.length - 1],
            _goldToMint,
            _currentGoldPrice,
            _mintFee
        );
    }

    function _generateMessageHash(
        uint256 _nonce,
        uint256 _totalUSDC,
        uint256 _amountIn,
        uint256 _currentGoldPrice,
        uint256 _goldToMint,
        uint256 _deadline
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    address(this),
                    block.chainid,
                    _nonce,
                    _totalUSDC,
                    _amountIn,
                    _currentGoldPrice,
                    _goldToMint,
                    _deadline
                )
            );
    }

    function _signMessageHashAndVerifySignature(
        bytes32 _messageHash,
        bytes calldata _signature
    ) private view {
        // Revert if the generated message hash has been used already.
        if (messageHashesUsed[_messageHash]) {
            revert AlreadyUsedMessageHash(_messageHash);
        }

        // Signing message hash.
        bytes32 _signedMessageHash = _messageHash.toEthSignedMessageHash();

        // Recover address used to sign the message.
        address _recoveredAddress = _signedMessageHash.recover(_signature);

        // Revert if the message was signed with an address other than the signer address.
        if (_recoveredAddress != signer) {
            revert SignerAddressMismatch(_recoveredAddress);
        }
    }

    function _getPath() private pure returns (address[] memory) {
        address[] memory path = new address[](2);

        path[0] = address(USDC);
        path[1] = address(GOLD);
        return path;
    }
}