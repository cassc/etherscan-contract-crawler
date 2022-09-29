// contracts/delegator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Vault.sol";

/// @notice This contract is designed to move ERC20s and ERC721s from user wallets into the noncustodial Vault contract.
/// After receiving user Approval, it uses server-side EOAs to call below functions when we detect malicious transactions.
contract Transfer {
    /// @dev We use safeERC20 to work with noncompliant ERC20s
    using SafeERC20 for IERC20; 

    /// @dev ERC20Details and ERC721Details are used to define an individual
    /// token, along with its owner. these are used in our batchTransfer functions
    /// @param ownerAddress The owner of the token
    /// @param fee The fee we charge users as they recover their assets
    struct ERC20Details {
        address ownerAddress;
        address erc20Address;
        uint128 erc20Fee;
    }
    struct ERC721Details {
        address ownerAddress;
        address erc721Address;
        uint128 erc721Fee;
        uint256 erc721Id;
    }

    /// @notice We've hardcoded the address that this contract transfers tokens to,
    /// so your Approved tokens can only move to our noncustodial vault
    /// @dev vaultAddress is the address of our noncustodial Vault contract
    address immutable private vaultAddress;

    /// @dev transferEOASetter is an EOA that can set other EOAs as callers of the
    /// Transfer functions below
    address immutable private transferEOASetter;

    /// @dev a mapping of all possible EOAs that can call Transfer functions
    mapping(address => bool) private _transferEOAs;

    /// @dev Immutables are set upon contract construction for safety
    constructor(address _vaultAddress, address _transferEOASetter) {
        vaultAddress = _vaultAddress;
        transferEOASetter = _transferEOASetter;
    } 

    /// @dev These events fire when a token transfer and subsequent logging is successful
    event successfulERC721Transfer(address ownerAddress, address erc721Address, uint256 tokenId);
    event successfulERC20Transfer(address ownerAddress, address erc20Address);

    /// @dev These events fire when an individual Transfer in a batchTransfer fails
    event failedERC721Transfer(address ownerAddress, address erc721Address, uint256 tokenId);
    event failedERC20Transfer(address ownerAddress, address erc20Address);
 
    /// @notice This function transfers ERC721s to a noncustodial vault contract.
    function transferERC721(address _ownerAddress, address _erc721Address, uint256 _erc721Id, uint128 _fee) public returns (bool) {
        require(_transferEOAs[msg.sender] == true || msg.sender == address(this), "Caller must be an approved caller.");
        require(_erc721Address != address(this));
        (bool transferSuccess, bytes memory transferResult) = address(_erc721Address).call(
            abi.encodeCall(IERC721(_erc721Address).transferFrom, (_ownerAddress, vaultAddress, _erc721Id))
        );
        require(transferSuccess, string (transferResult));
        (bool loggingSuccess, bytes memory loggingResult) = address(vaultAddress).call(
            abi.encodeCall(Vault.logIncomingERC721, (_ownerAddress, _erc721Address, _erc721Id, _fee))
        );
        require(loggingSuccess, string (loggingResult));
        emit successfulERC721Transfer(_ownerAddress, _erc721Address, _erc721Id);
        return transferSuccess;
    }

    /// @notice Batch transfering ERC721s in case we need to handle a large set of addresses at once (ie. protocol attack)
    /// @dev Care must be taken to pass good data, this function does not revert when a single transaction throws 
    function batchTransferERC721(ERC721Details[] memory _details) public returns (bool) {
        require(_transferEOAs[msg.sender] == true, "Caller must be an approved caller.");
        for (uint256 i=0; i<_details.length; i++ ) {
            // If statement adds a bit more gas cost, but allows us to continue the loop even if a
            // token is not in a user's wallet anymore, instead of reverting the whole batch
            try this.transferERC721{gas:400e3}(_details[i].ownerAddress, _details[i].erc721Address, _details[i].erc721Id, _details[i].erc721Fee) {}
            catch {
                emit failedERC721Transfer(_details[i].ownerAddress, _details[i].erc721Address, _details[i].erc721Id);
            }
        }
        return true;
    }

    /// @notice This function transfers ERC20s to a noncustodial vault contract.
    function transferERC20(address _ownerAddress, address _erc20Address, uint128 _fee) public returns (bool) {
        require (_transferEOAs[msg.sender] == true || msg.sender == address(this), "Caller must be an approved caller.");
        require(_erc20Address != address(this));
        
        // Get balance of vault prior to our transfer
        uint256 vaultBalanceBeforeTransfer = IERC20(_erc20Address).balanceOf(vaultAddress);

        // Transfer a user's current balance in their wallet
        uint256 balance = IERC20(_erc20Address).balanceOf(_ownerAddress);
        IERC20(_erc20Address).safeTransferFrom(
            _ownerAddress, 
            vaultAddress, 
            balance
        );

        // Instead of using that transferred balance as the logged balance, we use the change in vaultBalance
        // This is for fee-on-transfer tokens
        uint256 vaultBalanceAfterTransfer = IERC20(_erc20Address).balanceOf(vaultAddress) - vaultBalanceBeforeTransfer;

        (bool loggingSuccess, bytes memory loggingResult) = address(vaultAddress).call(
            abi.encodeCall(Vault.logIncomingERC20, (_ownerAddress, _erc20Address, vaultBalanceAfterTransfer, _fee))
        );
        require(loggingSuccess, string (loggingResult));

        emit successfulERC20Transfer(_ownerAddress, _erc20Address);
        return loggingSuccess;
    }

    /// @notice Batch transfering ERC20s in case we need to handle a large set of addresses at once (ie. protocol attack)
    /// @dev Care must be taken to pass good data, this function does not revert when a single transaction throws
    function batchTransferERC20(ERC20Details[] memory _details) public returns (bool) {
        require(_transferEOAs[msg.sender] == true, "Caller must be an approved caller.");
        for (uint256 i=0; i<_details.length; i++ ) {
            try this.transferERC20{gas:400e3}(_details[i].ownerAddress, _details[i].erc20Address, _details[i].erc20Fee) {}
            catch {
                emit failedERC20Transfer(_details[i].ownerAddress, _details[i].erc20Address);
            }
        }
        return true;
    }

    /// @dev This adds or removes transferEOAs that can call the above functions
    function setTransferEOA(address _newTransferEOA, bool _value) public {
        require(msg.sender == transferEOASetter, "Caller must be an approved caller.");
        _transferEOAs[_newTransferEOA] = _value;
    }
}