// contracts/delegator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @notice This contract is designed to hold ERC20s and ERC721s from user wallets and allow only them to withdraw.
/// Users will have to pay a designated fee in order to withdraw their ERC20s and ERC721s.
/// In case we need to reduce fees for each user, we have reduceFee functions we can call. 
contract Vault {
    using ECDSA for bytes32;
    using SafeCast for uint128;
    using SafeCast for uint256;

    /// @dev We use safeERC20 for noncompliant ERC20s
    using SafeERC20 for IERC20;

    /// @dev This struct defines the amount of an ERC20 stored, and the fee required to withdraw
    struct erc20Struct {
        uint128 amountStored;
        uint128 fee;
    }

    /// @dev This struct defines if an ERC721 id is stored, and the fee required to withdraw
    struct erc721Struct {
        bool isStored;
        uint128 fee;
    }

    /// @dev The address of the Transfer contract linked to this contract
    address private immutable transferer;
    /// @notice The serverSigner is an EOA responsible for providing the signature of changeRecipientAddress
    address private immutable serverSigner;
    /// @notice The feeController is an EOA that's able to only reduce the fees of users and withdraw our fees
    address payable private feeController;

    /// @dev This mapping is a one-to-one that defines who can withdraw a user's transfered funds
    mapping(address => address) private _recipientAddress;
    
    /// @dev These mappings define the tokens a user can withdraw from the Vault and the fees to withdraw
    mapping(address => mapping(address => erc20Struct)) private _erc20WithdrawalAllowances;
    mapping(address => mapping(address => mapping (uint256 => erc721Struct))) private _erc721WithdrawalAllowances;

    /// @dev This mapping prevents the reuse of a signature to changeRecipientAddress or an out-of-order usage
    mapping(address => uint256) private _changeRecipientNonces;

    /// @dev This mapping stores the block.timestamp of a changeFeeControllerRequest
    /// @dev A request is in the shape of `currentFeeController` => `newFeeController` => `block.timestamp`
    mapping(address => mapping(address => uint256)) private _changeFeeControllerRequestTimestamps;

    /// @dev Immutables like transferer and serverSigner are set during construction for safety
    constructor(address _transferer, address _serverSigner, address payable _feeController) {
        transferer = _transferer;
        serverSigner = _serverSigner;
        feeController = _feeController;
    }

    /// @notice Allow users to set up a recipient address for collecting stored assets
    function setupRecipientAddress(address _recipient) external {
        require(_recipientAddress[msg.sender] == address(0), "You already have registered a recipient address");
        _recipientAddress[msg.sender] = _recipient;
    }   

    /// @notice Allow users to change their recipient address. Requires a signature from our serverSigner
    /// to allow this transaction to fire
    function changeRecipientAddress(bytes memory _signature, address _newRecipientAddress, uint256 expiry) external {
        /// @dev Have server sign a message in the format [protectedWalletAddress, newRecipientAddress, exp, nonce, vaultAddress, block.chainId]
        /// msg.sender == protectedWalletAddress (meaning that the protected wallet will submit this transaction)
        /// @notice We require the extra signature in case we add 2fa in some way in future

        bytes32 data = keccak256(abi.encodePacked(msg.sender, _newRecipientAddress, expiry, getNonce(msg.sender), address(this), block.chainid));
        require(data.toEthSignedMessageHash().recover(_signature) == serverSigner, "Invalid signature. Signature source may be incorrect, or a provided parameter is invalid");
        require(block.timestamp <= expiry, "Signature expired");
        _changeRecipientNonces[msg.sender]++;
        _recipientAddress[msg.sender] = _newRecipientAddress;
    }

    /// @notice Get nonces for the above function
    function getNonce(address _caller) public view returns (uint256) {
        return _changeRecipientNonces[_caller];
    }

    /// @notice View which address is authorized to withdraw assets
    function viewRecipientAddress(address _originalAddress) public view returns (address) {
        return _recipientAddress[_originalAddress];
    }


    /// @notice Log functions fire when the vault receives an ERC20 or ER721 from Transfer.sol
    function logIncomingERC20(address _originalAddress, address _erc20Address, uint256 _amount, uint128 _fee) external{
        require(msg.sender == transferer, "Only the transferer contract can log funds.");
        _erc20WithdrawalAllowances[_originalAddress][_erc20Address].fee += _fee;
        _erc20WithdrawalAllowances[_originalAddress][_erc20Address].amountStored += _amount.toUint128();
    }

    function logIncomingERC721(address _originalAddress, address _erc721Address, uint256 _id, uint128 _fee) external {
        require(msg.sender == transferer, "Only the transferer contract can log funds.");
        _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].fee += _fee;
        _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].isStored = true;
    }


    /// @notice These functions can be called to view an addresses' stored balances and the fees to withdraw them
    function canWithdrawERC20(address _originalAddress, address _erc20Address) public view returns (uint256) {
        return _erc20WithdrawalAllowances[_originalAddress][_erc20Address].amountStored;
    }

    function canWithdrawERC721(address _originalAddress, address _erc721Address, uint256 _id) public view returns (bool) {
        return _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].isStored;
    }

    function erc20Fee(address _originalAddress, address _erc20Address) public view returns (uint128) {
        return _erc20WithdrawalAllowances[_originalAddress][_erc20Address].fee;
    }

    function erc721Fee(address _originalAddress, address _erc721Address, uint256 _id) public view returns (uint128) {
        return _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].fee;
    }

    /// @notice Withdrawal functions allow users to withdraw their assets after paying the ETH withdrawal fee
    /// @dev A few guards are placed to avoid erroneous withdrawals.
    /// - caller must be a recipient address of the assets of _originalAddress
    /// - there must be an allowance in the _originalAddress's withdrawal allowance
    /// - the _erc20Address must not be address(this)
    /// - the msg.value must be >= the withdrawal fee
    function withdrawERC20(address _originalAddress, address _erc20Address) payable external {
        require(_recipientAddress[_originalAddress] == msg.sender, "Function caller is not an authorized recipientAddress.");
        require(_erc20Address != address(this), "The vault is not a token address");
        require(canWithdrawERC20(_originalAddress, _erc20Address) > 0, "No withdrawal allowance.");
        require(msg.value >= _erc20WithdrawalAllowances[_originalAddress][_erc20Address].fee, "Insufficient payment.");

        uint256 amount = canWithdrawERC20(_originalAddress, _erc20Address);
        _erc20WithdrawalAllowances[_originalAddress][_erc20Address].amountStored = 0;
        _erc20WithdrawalAllowances[_originalAddress][_erc20Address].fee = 0;
        IERC20(_erc20Address).safeTransfer(msg.sender, amount);
    }
    function withdrawERC721(address _originalAddress, address _erc721Address, uint256 _id) payable external {
        require(_recipientAddress[_originalAddress] == msg.sender, "Function caller is not an authorized recipientAddress.");
        require(_erc721Address != address(this), "The vault is not a token address");
        require(canWithdrawERC721(_originalAddress, _erc721Address, _id), "Insufficient withdrawal allowance.");
        require(msg.value >= _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].fee, "Insufficient payment.");

        _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].isStored = false;
        _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].fee = 0;
        IERC721(_erc721Address).safeTransferFrom(address(this), msg.sender, _id);
    }

    /// @notice These functions allow Harpie to reduce (but never increase) the fee upon a user
    function reduceERC20Fee(address _originalAddress, address _erc20Address, uint128 _reduceBy) external returns (uint128) {
        require(msg.sender == feeController, "msg.sender must be feeController.");
        require(_erc20WithdrawalAllowances[_originalAddress][_erc20Address].fee >= _reduceBy, "You cannot reduce more than the current fee.");
        _erc20WithdrawalAllowances[_originalAddress][_erc20Address].fee -= _reduceBy;
        return _erc20WithdrawalAllowances[_originalAddress][_erc20Address].fee;
    }

    function reduceERC721Fee(address _originalAddress, address _erc721Address, uint256 _id, uint128 _reduceBy) external returns (uint128) {
        require(msg.sender == feeController, "msg.sender must be feeController.");
        require(_erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].fee >= _reduceBy, "You cannot reduce more than the current fee.");
        _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].fee -= _reduceBy;
        return _erc721WithdrawalAllowances[_originalAddress][_erc721Address][_id].fee;
    }

    /// @notice This function allows us to withdraw the fees we collect in this contract
    function withdrawPayments(uint256 _amount) external {
        require(msg.sender == feeController, "msg.sender must be feeController.");
        require(address(this).balance >= _amount, "Cannot withdraw more than the amount in the contract.");

        (bool success, ) = feeController.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    /// @notice This function creates a timelock for the changeFeeController functionality
    function changeFeeControllerRequest(address _newFeeController) external {
        require(msg.sender == feeController, "msg.sender must be the current feeController.");
        // This sets the timestamp, regardless of if a previous timestamp exists already
        _changeFeeControllerRequestTimestamps[feeController][_newFeeController] = block.timestamp;
    }

    /// @notice This function allows us to change the signer that we use to reduce and withdraw fees
    function changeFeeController(address payable _newFeeController) external {
        require(msg.sender == feeController, "msg.sender must be the current feeController.");
        // If no timelock request is available, revert
        require(_changeFeeControllerRequestTimestamps[feeController][_newFeeController] > 0, "Submit a timelock request before calling this function.");
        // If the most recent request timestamp + 2 weeks < the current timestamp, revert
        require(_changeFeeControllerRequestTimestamps[feeController][_newFeeController] + 1209600 < block.timestamp, "Request must pass a two-week timelock.");
        // Change requests only have a single day to execute after passing timelock
        require(_changeFeeControllerRequestTimestamps[feeController][_newFeeController] + 1296000 > block.timestamp, "Request expired. Requests must occur within 24 hours of a completed timelock.");
        feeController = _newFeeController;
    }
}