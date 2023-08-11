// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./interfaces/IFactory.sol";
import "./interfaces/IPeriphery.sol";
import "./interfaces/rate_oracles/IRateOracle.sol";
import "./interfaces/IMarginEngine.sol";
import "./interfaces/IVAMM.sol";
import "./interfaces/fcms/IFCM.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/utils/CustomErrors.sol";

contract VoltzERC1967Proxy is ERC1967Proxy, CustomErrors {
  constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}
}


/// @title Voltz Factory Contract
/// @notice Deploys Voltz VAMMs and MarginEngines and manages ownership and control over amm protocol fees
// Following this example https://github.com/OriginProtocol/minimal-proxy-example/blob/master/contracts/PairFactory.sol
contract Factory is IFactory, Ownable {

  /// @dev master MarginEngine implementation that MarginEngine proxies can delegate call to
  IMarginEngine public override masterMarginEngine;

  /// @dev master VAMM implementation that VAMM proxies can delegate call to
  IVAMM public override masterVAMM;

  /// @dev yieldBearingProtocolID --> master FCM implementation for the underlying yield bearing protocol with the corresponding id
  mapping(uint8 => IFCM) public override masterFCMs;

  /// @dev owner --> integration contract address --> isApproved
  /// @dev if an owner wishes to allow a given intergration contract to act on thir behalf with Voltz Core
  /// @dev they need to set the approval via the setApproval function
  mapping(address => mapping(address => bool)) private _isApproved;
  
  /// @dev Voltz Periphery
  IPeriphery public override periphery;  

  function setApproval(address intAddress, bool allowIntegration) external override {
    _isApproved[msg.sender][intAddress] = allowIntegration;
    emit Approval(msg.sender, intAddress, allowIntegration);
  }

  function isApproved(address _owner, address _intAddress) override view public returns (bool) {

    require(_owner != address(0), "owner does not exist");
    require(_intAddress != address(0), "int does not exist");

    /// @dev Voltz periphery is always approved to act on behalf of the owner
    if (_intAddress == address(periphery)) {
      return true;
    } else {
      return _isApproved[_owner][_intAddress];
    }

  }

  constructor(IMarginEngine _masterMarginEngine, IVAMM _masterVAMM) {
    require(address(_masterMarginEngine) != address(0), "master me must exist");
    require(address(_masterVAMM) != address(0), "master vamm must exist");

    masterMarginEngine = _masterMarginEngine;
    masterVAMM = _masterVAMM;
  }

  function setMasterFCM(IFCM _masterFCM, uint8 _yieldBearingProtocolID) external override onlyOwner {

    require(address(_masterFCM) != address(0), "master fcm must exist");
    masterFCMs[_yieldBearingProtocolID] = _masterFCM;
    emit MasterFCM(_masterFCM, _yieldBearingProtocolID);
  }

  function setMasterMarginEngine(IMarginEngine _masterMarginEngine) external override onlyOwner {
    require(address(_masterMarginEngine) != address(0), "master me must exist");

    if (address(masterMarginEngine) != address(_masterMarginEngine)) {
      masterMarginEngine = _masterMarginEngine;
    }

  }


  function setMasterVAMM(IVAMM _masterVAMM) external override onlyOwner {

    require(address(_masterVAMM) != address(0), "master vamm must exist");

    if (address(masterVAMM) != address(_masterVAMM)) {
      masterVAMM = _masterVAMM;
    }

  }


  function setPeriphery(IPeriphery _periphery) external override onlyOwner {
    
    require(address(_periphery) != address(0), "periphery must exist");

    if (address(periphery) != address(_periphery)) {
      periphery = _periphery;
      emit PeripheryUpdate(periphery);
    }

  }


  function deployIrsInstance(IERC20Minimal _underlyingToken, IRateOracle _rateOracle, uint256 _termStartTimestampWad, uint256 _termEndTimestampWad, int24 _tickSpacing) external override onlyOwner returns (IMarginEngine marginEngineProxy, IVAMM vammProxy, IFCM fcmProxy) {
    IMarginEngine marginEngine = IMarginEngine(address(new VoltzERC1967Proxy(address(masterMarginEngine), "")));
    IVAMM vamm = IVAMM(address(new VoltzERC1967Proxy(address(masterVAMM), "")));
    marginEngine.initialize(_underlyingToken, _rateOracle, _termStartTimestampWad, _termEndTimestampWad);
    vamm.initialize(marginEngine, _tickSpacing);
    marginEngine.setVAMM(vamm);

    IRateOracle r = IRateOracle(_rateOracle);
    require(r.underlying() == _underlyingToken, "Tokens do not match");
    uint8 yieldBearingProtocolID = r.UNDERLYING_YIELD_BEARING_PROTOCOL_ID();
    IFCM _masterFCM = masterFCMs[yieldBearingProtocolID];
    IFCM fcm;

    if (address(_masterFCM) != address(0)) {
      fcm = IFCM(address(new VoltzERC1967Proxy(address(_masterFCM), "")));
      fcm.initialize(vamm, marginEngine);
      marginEngine.setFCM(fcm);
      Ownable(address(fcm)).transferOwnership(msg.sender);
    }

    uint8 underlyingTokenDecimals = _underlyingToken.decimals();

    emit IrsInstance(_underlyingToken, _rateOracle, _termStartTimestampWad, _termEndTimestampWad, _tickSpacing, marginEngine, vamm, fcm, yieldBearingProtocolID, underlyingTokenDecimals);

    // Transfer ownership of all instances to the factory owner
    Ownable(address(vamm)).transferOwnership(msg.sender);
    Ownable(address(marginEngine)).transferOwnership(msg.sender);

    return(marginEngine, vamm, fcm);
  }



}