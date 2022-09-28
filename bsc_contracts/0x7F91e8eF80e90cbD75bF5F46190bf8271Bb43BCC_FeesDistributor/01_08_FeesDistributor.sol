// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IJimizzFeeReceiver.sol";

contract FeesDistributor is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;


  // ==== Structs ==== //

  struct Service {
    string name;
    uint16 totalPercentage;
    Beneficiary[] beneficiaries;
    mapping(string => uint) beneficiaryIndexes;
  }

  struct Beneficiary {
    string name;
    uint16 percentage;
    address beneficiary;
    bool isContract;
  }


  // ==== State ==== //

  IERC20 immutable public token;
  address public charityBeneficiary;
  mapping(string => Service) services;


  // ==== Events ==== //

  event CharityBeneficiaryChanged(address oldBeneficiary, address newBeneficiary);
  event BeneficiaryChanged(string service, string name, address beneficiary, uint16 percentage);
  event ServiceAdded(string serviceName);
  event ServiceBeneficiariesUpdated(string serviceName, string beneficiaryName, uint16 percentage, address beneficiaryAddress);
  event BeneficiaryContractFailed(string name, address beneficiary, uint cut);


  // ==== Modifiers ==== //

  /**
   * @dev Check if the caller is the Charity beneficiary or the owner
   */
  modifier onlyCharityBeneficiaryOrOwner() {
    require(
      charityBeneficiary == _msgSender() || owner() == _msgSender(),
      "Caller is not the Charity beneficiary, nor the owner"
    );
    _;
  }



  // ==== Constructor ==== //

  /**
   * @dev constructor
   * @param _token Address of the BEP20
   * @param _charityBeneficiary Address of the Charity beneficiary
   */
  constructor(
    address _token,
    address _charityBeneficiary
  )
  {
    require(
      _token != address(0),
      "Token address is not valid"
    );
    token = IERC20(_token);

    require(
      _charityBeneficiary != address(0),
      "Charity beneficiary address is not valid"
    );
    charityBeneficiary = _charityBeneficiary;
  }


  // ==== Public methods ==== //

  function distribute(
    string calldata _serviceName,
    uint _amount
  )
    external
    nonReentrant
  {
    uint remains = _amount;

    Service storage service = services[_serviceName];
    for (uint i = 1; i < service.beneficiaries.length; i++) {
      Beneficiary memory beneficiary = service.beneficiaries[i];

      uint cut = _amount * beneficiary.percentage / 10000;
      remains -= cut;

      // Send funds
      token.safeTransferFrom(
        _msgSender(),
        beneficiary.beneficiary,
        cut
      );

      if (beneficiary.isContract) {
        try IJimizzFeeReceiver(beneficiary.beneficiary).onJimizzFeeReceived(cut) {
          // succeed
        } catch {
          emit BeneficiaryContractFailed(beneficiary.name, beneficiary.beneficiary, cut);
        }
      }
    }

    if (remains > 0) {
      token.safeTransferFrom(
        _msgSender(),
        charityBeneficiary,
        remains
      );
    }
  }


  // ==== Views ==== //
  /**
   * @notice Get beneficiary informations for a given service
   * @param _serviceName The service name
   */
  function getBeneficiaries(
    string calldata _serviceName
  )
    external
    view
    returns (Beneficiary[] memory)
  {
    Service storage service = services[_serviceName];
    require(
      bytes(service.name).length > 0,
      "Service does not exist"
    );

    uint n = service.beneficiaries.length - 1;
    Beneficiary[] memory beneficiaries = new Beneficiary[](n);
    for (uint i = 1; i < service.beneficiaries.length; i++) {
      beneficiaries[i - 1] = service.beneficiaries[i];
    }
    return beneficiaries;
  }



  // ==== Restricted methods ==== //

  /**
   * @notice Change the Charity beneficiary
   * @param _beneficiary The new Charity beneficiary address
   */
  function setCharityBeneficiary(
    address _beneficiary
  )
    external
    onlyCharityBeneficiaryOrOwner
  {
    require(
      _beneficiary != address(0),
      "Beneficiary address is not valid"
    );

    require(
      charityBeneficiary != _beneficiary,
      "Charity beneficiary cannot be the same as the old one"
    );

    address oldBeneficiary = charityBeneficiary;
    charityBeneficiary = _beneficiary;
    emit CharityBeneficiaryChanged(oldBeneficiary, _beneficiary);
  }

  /**
   * @notice Add a new service
   * @param _serviceName Service name
   */
  function addService(
    string calldata _serviceName
  )
    external
    onlyOwner
  {
    require(
      bytes(services[_serviceName].name).length == 0,
      "Service already exists"
    );

    services[_serviceName].name = _serviceName;

    // Avoid index 0 to prevent index-1 bug
    services[_serviceName].beneficiaries.push();

    emit ServiceAdded(_serviceName);
  }

  /**
   * @notice Add or update beneficiary to a service
   * @param _serviceName The service name
   * @param _name The beneficiary name
   * @param _percentage The beneficiary percentage
   * @param _beneficiary The beneficiary address
   * @param _isContract Bool indicates if the beneficiary is a contract implementing onJimizzFeeReceived()
   */
  function updateBeneficiary(
    string calldata _serviceName,
    string calldata _name,
    uint16 _percentage,
    address _beneficiary,
    bool _isContract
  )
    external
    onlyOwner
  {
    Service storage service = services[_serviceName];
    require(
      bytes(service.name).length > 0,
      "Service does not exist"
    );

    require(
      _percentage <= 10000,
      "Percentage should not exceed 10000"
    );

    require(
      _beneficiary != address(0),
      "Beneficiary address is not valid"
    );

    uint index = service.beneficiaryIndexes[_name];
    if (index == 0) {
      // Add new beneficiary and update indexes
      service.beneficiaries.push();
      index = service.beneficiaries.length - 1;
      service.beneficiaryIndexes[_name] = index;
    }

    Beneficiary storage beneficiary = service.beneficiaries[index];

    uint16 totalPercentage = service.totalPercentage - beneficiary.percentage + _percentage;
    require(
      totalPercentage <= 10000,
      "The percentage exceeds the remaining percentage on this service. Please review the beneficiary percentages."
    );

    // Update beneficiary
    beneficiary.name = _name;
    beneficiary.percentage = _percentage;
    beneficiary.beneficiary = _beneficiary;
    beneficiary.isContract = _isContract;

    // Update total percentage
    service.totalPercentage = totalPercentage;

    emit ServiceBeneficiariesUpdated(_serviceName, _name, _percentage, _beneficiary);
  }

}