pragma solidity ^0.5.9;

import '../openzeppelin/TokenVesting.sol';

//Beneficieries template
import "../helpers/BeneficiaryOperations.sol";

contract AkropolisTokenVesting is TokenVesting, BeneficiaryOperations {

    IERC20 private token;

    address private _pendingBeneficiary;

    event LogBeneficiaryTransferProposed(address _beneficiary);
    event LogBeneficiaryTransfered(address _beneficiary);

    constructor (IERC20 _token, uint256 _start, uint256 _cliffDuration, uint256 _duration) public 
        TokenVesting(msg.sender, _start, _cliffDuration, _duration, false) {
            token = _token;
        }

     /**
     * @notice Transfers vested tokens to beneficiary.
     */

    function release() public {
        super.release(token);
    }


     /**
     * @return the token being held.
     */
    function tokenAddress() public view returns (IERC20) {
        return token;
    }

    // MODIFIERS
    /**
    * @dev Allows to perform method by existing beneficiary
    */
    modifier onlyExistingBeneficiary(address _beneficiary) {
        require(isExistBeneficiary(_beneficiary), "address is not in beneficiary array");
        _;
    }

    /**
    * @dev Allows to perform method by pending beneficiary
    */

    modifier onlyPendingBeneficiary {
        require(msg.sender  == _pendingBeneficiary, "Unpermitted operation.");
        _;
    }

    function pendingBeneficiary() public view returns (address) {
        return _pendingBeneficiary;
    }

     /**
        * @dev Allows beneficiaries to change beneficiaryShip and set first beneficiary as default
        * @param _newBeneficiaries defines array of addresses of new beneficiaries
    */
    function transferBeneficiaryShip(address[] memory _newBeneficiaries) public {
        super.transferBeneficiaryShip(_newBeneficiaries);
        _setPendingBeneficiary(beneficiaries[0]);
    }

     /**
        * @dev Allows beneficiaries to change beneficiaryShip and set first beneficiary as default
        * @param _newBeneficiaries defines array of addresses of new beneficiaries
        * @param _newHowManyBeneficiariesDecide defines how many beneficiaries can decide
    */
    
    function transferBeneficiaryShipWithHowMany(address[] memory _newBeneficiaries, uint256 _newHowManyBeneficiariesDecide) public  {
        super.transferBeneficiaryShipWithHowMany(_newBeneficiaries, _newHowManyBeneficiariesDecide);
        _setPendingBeneficiary(beneficiaries[0]);
    }

    /**
        * @dev Allows beneficiaries to change beneficiary as default
         * @param _newBeneficiary defines address of new beneficiary
    */
    function changeBeneficiary(address _newBeneficiary) public onlyManyBeneficiaries {
        _setPendingBeneficiary(_newBeneficiary);
    }

    /**
        * @dev Claim Beneficiary
    */
    function claimBeneficiary() public onlyPendingBeneficiary {
        _changeBeneficiary(_pendingBeneficiary);
        emit LogBeneficiaryTransfered(_pendingBeneficiary);
        _pendingBeneficiary = address(0);
    }

    /*
     * Internal Functions
     *
     */
    /**
        * @dev Set pending Beneficiary address
        * @param _newBeneficiary defines address of new beneficiary
    */
    function _setPendingBeneficiary(address _newBeneficiary) internal onlyExistingBeneficiary(_newBeneficiary) {
        _pendingBeneficiary = _newBeneficiary;
        emit LogBeneficiaryTransferProposed(_newBeneficiary);
    }
}