pragma solidity ^0.5.15;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

import "../interfaces/IENSRegistry.sol";
import "../interfaces/IDCLRegistrar.sol";
import "../interfaces/IERC20Token.sol";

contract DCLControllerV2 is Ownable {
    using Address for address;

    // Price of each name
    uint256 constant public PRICE = 100 ether;

    // Accepted ERC20 token
    IERC20Token public acceptedToken;
    // DCL Registrar
    IDCLRegistrar public registrar;
    // Fee Collector
    address public feeCollector;

    // Emitted when a name is bought
    event NameBought(address indexed _caller, address indexed _beneficiary, uint256 _price, string _name);

    // Emitted when the fee collector is changed
    event FeeCollectorChanged(address indexed _oldFeeCollector, address indexed _newFeeCollector);

    /**
	 * @dev Constructor of the contract
     * This contract does not support ERC20 tokens that do not revert on an invalid transfer.
     * @param _acceptedToken - address of the accepted ERC20 token
     * @param _registrar - address of the DCL registrar contract
     * @param _feeCollector - address of the fee collector
     * @param _owner - address of the contract owner
	 */
    constructor(IERC20Token _acceptedToken, IDCLRegistrar _registrar, address _feeCollector, address _owner) public {
        require(address(_acceptedToken).isContract(), "Accepted token should be a contract");
        require(address(_registrar).isContract(), "Registrar should be a contract");

        // Accepted token
        acceptedToken = _acceptedToken;
        // DCL registrar
        registrar = _registrar;

        _setFeeCollector(_feeCollector);

        _transferOwnership(_owner);
    }

    /**
	 * @dev Register a name
     * This function transfers the PRICE from the sender to the fee collector without checking the return value of the transferFrom function.
     * This means that only tokens that revert when the transfer fails due to insufficient balance or insufficient approve should be used.
     * If the token does not revert on an invalid transfer, the register will succeed and a name will be minted without being paid for.
     * @param _name - name to be registered
	 * @param _beneficiary - owner of the name
	 */
    function register(string memory _name, address _beneficiary) public {
        // Check for valid beneficiary
        require(_beneficiary != address(0), "Invalid beneficiary");

        // Check if the name is valid
        _requireNameValid(_name);

        // Register the name
        registrar.register(_name, _beneficiary);
        // Transfer PRICE to the fee collector
        acceptedToken.transferFrom(msg.sender, feeCollector, PRICE);
        // Log
        emit NameBought(msg.sender, _beneficiary, PRICE, _name);
    }

    /**
     * @notice Set the fee collector
     * @dev Only the owner can change the fee collector
     * @param _feeCollector - the address of the new collector
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /**
    * @dev Validate a name
    * @notice that only a-z is allowed
    * @param _name - string for the name
    */
    function _requireNameValid(string memory _name) internal pure {
        bytes memory tempName = bytes(_name);
        require(
            tempName.length >= 2 && tempName.length <= 15,
            "Name should be greater than or equal to 2 and less than or equal to 15"
        );
        for(uint256 i = 0; i < tempName.length; i++) {
            require(_isLetter(tempName[i]) || _isNumber(tempName[i]), "Invalid Character");
        }
    }

    function _isLetter(bytes1 _char) internal pure returns (bool) {
        return (_char >= 0x41 && _char <= 0x5A) || (_char >= 0x61 && _char <= 0x7A);
    }

    function _isNumber(bytes1 _char) internal pure returns (bool) {
        return (_char >= 0x30 && _char <= 0x39);
    }

    function _setFeeCollector(address _feeCollector) internal {
        require(_feeCollector != address(0), "Invalid fee collector");
        
        emit FeeCollectorChanged(feeCollector, _feeCollector);

        feeCollector = _feeCollector;
    }

}