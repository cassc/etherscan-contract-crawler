// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./../utils/Governable.sol";
import "./../interfaces/utils/ISolaceSigner.sol";


/**
 * @title SolaceSigner
 * @author solace.fi
 * @notice Verifies off-chain data.
*/
contract SolaceSigner is ISolaceSigner, EIP712, Governable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /***************************************
    STATE VARIABLES
    ***************************************/

    /// @notice The authorized off-chain signers.
    EnumerableSet.AddressSet private _signers;

    /***************************************
    CONSTRUCTOR
    ***************************************/

    /**
     * @notice Constructs the Solace Signer contract.
     * @param _governance The address of the [governor](/docs/protocol/governance).
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _governance) EIP712("Solace.fi-SolaceSigner", "1") Governable(_governance) {}

    /***************************************
    VERIFY FUNCTIONS
    ***************************************/

    /**
     * @notice Verifies `SOLACE` price data.
     * @param token The token to verify price.
     * @param price The `SOLACE` price in wei(usd).
     * @param deadline The deadline for the price.
     * @param signature The `SOLACE` price signature.
     */
    function verifyPrice(address token, uint256 price, uint256 deadline, bytes calldata signature) public view override returns (bool) {
        require(token != address(0x0), "zero address token");
        require(price > 0, "zero price");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("PriceData(address token,uint256 price,uint256 deadline)"),
                token,
                price,
                deadline
            )
        );
        bytes32 hashTypedData = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hashTypedData, signature);
        return isSigner(signer);
    }

    /**
     * @notice Verifies cover premium data.
     * @param premium The premium amount to verify.
     * @param policyholder The policyholder address.
     * @param deadline The deadline for the signature.
     * @param signature The premium data signature.
     */
    function verifyPremium(uint256 premium, address policyholder, uint256 deadline, bytes calldata signature) public view override returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "expired deadline");
        require(policyholder != address(0x0), "zero address policyholder");
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("PremiumData(uint256 premium,address policyholder,uint256 deadline)"),
                premium,
                policyholder,
                deadline
            )
        );
        bytes32 hashTypedData = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hashTypedData, signature);
        return isSigner(signer);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the number of signers.
     * @return count The number of signers.
     */
    function numSigners() external override view returns (uint256 count) {
        return _signers.length();
    }

    /**
     * @notice Returns the signer at the given index.
     * @param index The index to query.
     * @return signer The address of the signer.
     */
    function getSigner(uint256 index) external override view returns (address signer) {
        return _signers.at(index);
    }

    /**
     * @notice Checks whether given signer is an authorized signer or not.
     * @param signer The signer address to check.
     * @return bool True if signer is a authorized signer.
     */
    function isSigner(address signer) public view override returns (bool) {
        return _signers.contains(signer);
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a new signer.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param signer The signer to add.
     */
     function addSigner(address signer) external override onlyGovernance {
        require(signer != address(0x0), "zero address signer");
        _signers.add(signer);
        emit SignerAdded(signer);
    }

    /**
     * @notice Removes a signer.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param signer The signer to remove.
     */
    function removeSigner(address signer) external override onlyGovernance {
        _signers.remove(signer);
        emit SignerRemoved(signer);
    }
}