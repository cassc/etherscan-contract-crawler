// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./common/Utils.sol";
import "./common/BaseModule.sol";

/**
 * @title TransactionManager
 * @notice Module to execute transactions in sequence to e.g. transfer tokens (ETH, ERC20, ERC721, ERC1155) or call third-party contracts.
 */
abstract contract TransactionManager is BaseModule {

    // Static calls
    bytes4 private constant ERC1271_IS_VALID_SIGNATURE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    bytes4 private constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    bytes4 private constant ERC1155_RECEIVED = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    bytes4 private constant ERC1155_BATCH_RECEIVED = bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    bytes4 private constant ERC165_INTERFACE = bytes4(keccak256("supportsInterface(bytes4)"));

    struct Call {
        address to;      //the target address to which transaction to be sent
        uint256 value;   //native amount to be sent.
        bytes data;      //the data for the transaction.
    }

    /**
     * @notice Makes the target vault execute a sequence of transactions
     * The method reverts if any of the inner transactions reverts.
     * @param _vault The target vault.
     * @param _transactions The sequence of transactions.
     * @return bytes array of results for  all low level calls.
     */
    function multiCall(
        address _vault,
        Call[] calldata _transactions
    )
        external 
        onlySelf()
        onlyWhenUnlocked(_vault)
        returns (bytes[] memory)
    {
        return multiCallWithApproval(_vault, _transactions);
    }
    
    /*
    * @notice Enable the static calls required to make the vault compatible with the ERC1155TokenReceiver 
    * interface (see https://eips.ethereum.org/EIPS/eip-1155#erc-1155-token-receiver). This method only 
    * needs to be called for wallets deployed in version lower or equal to 2.4.0 as the ERC1155 static calls
    * are not available by default for these versions of BaseWallet
    * @param _vault The target vault.
    */
    function enableERC1155TokenReceiver(address _vault) external onlyVaultOwnerOrSelf(_vault) onlyWhenUnlocked(_vault) {
        IVault(_vault).enableStaticCall(address(this), ERC165_INTERFACE);
        IVault(_vault).enableStaticCall(address(this), ERC1155_RECEIVED);
        IVault(_vault).enableStaticCall(address(this), ERC1155_BATCH_RECEIVED);
    }

    /**
     * @inheritdoc IModule
     */
    function supportsStaticCall(bytes4 _methodId) external pure override returns (bool _isSupported) {
        return _methodId == ERC1271_IS_VALID_SIGNATURE ||
               _methodId == ERC721_RECEIVED ||
               _methodId == ERC165_INTERFACE ||
               _methodId == ERC1155_RECEIVED ||
               _methodId == ERC1155_BATCH_RECEIVED;
    }

    /**
     * @notice Returns true if this contract implements the interface defined by
     * `interfaceId` (see https://eips.ethereum.org/EIPS/eip-165).
     */
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return  _interfaceID == ERC165_INTERFACE || _interfaceID == (ERC1155_RECEIVED ^ ERC1155_BATCH_RECEIVED);          
    }


    fallback() external {
        bytes4 methodId = Utils.functionPrefix(msg.data);
        if(methodId == ERC721_RECEIVED || methodId == ERC1155_RECEIVED || methodId == ERC1155_BATCH_RECEIVED) {
            // solhint-disable-next-line no-inline-assembly
            assembly {                
                calldatacopy(0, 0, 0x04)
                return (0, 0x20)
            }
        }
    }

    function enableDefaultStaticCalls(address _vault) internal {
        // setup the static calls that are available for free for all wallets
        IVault(_vault).enableStaticCall(address(this), ERC1271_IS_VALID_SIGNATURE);
        IVault(_vault).enableStaticCall(address(this), ERC721_RECEIVED);
    }

    function multiCallWithApproval(address _vault, Call[] calldata _transactions) internal returns (bytes[] memory) {
        bytes[] memory results = new bytes[](_transactions.length);
        for(uint i = 0; i < _transactions.length; i++) {
            results[i] = invokeVault(
                _vault,
                _transactions[i].to,
                _transactions[i].value,
                _transactions[i].data
            );
        }
        return results;
    }
}