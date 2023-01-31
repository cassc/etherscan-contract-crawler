// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "./06_21_NotionalJoin.sol";
import "./02_21_AccessControl.sol";
import {IEmergencyBrake} from "./03_21_EmergencyBrake.sol";
import {ILadleGov} from "./04_21_ILadleGov.sol";
import {INotionalJoin} from "./07_21_INotionalJoin.sol";
import {ILadle} from "./05_21_ILadle.sol";

/// @dev NotionalJoinFactory creates new join contracts supporting Notional Finance's fCash tokens.
/// @author @calnix
contract NotionalJoinFactory is AccessControl {

    ILadleGov public ladle;

    event JoinCreated(address indexed asset, address indexed join);
    event Point(bytes32 indexed param, address indexed oldValue, address indexed newValue);
    event Log(string message);

    error UnrecognisedParam(bytes32 param);

    constructor(ILadleGov ladle_) {
        ladle = ladle_;
    }

    /// @dev Deploys a new notional join using create2
    /// @param oldAssetId Id of prior matured fCash token. (e.g. fDAIJUN22)
    /// @param newAssetId Id of incoming fCash token. (e.g. fDAISEP22)
    /// @param salt Random number of choice
    /// @return join Deployed notional join address
    function deploy(
        bytes6 oldAssetId,
        bytes6 newAssetId,
        address newAssetAddress,
        uint256 salt
    ) external auth returns (NotionalJoin) {
        require(address(ladle.joins(oldAssetId)) != address(0), "oldAssetId invalid");
        require(address(ladle.joins(newAssetId)) == address(0), "newAssetId join exists"); 

        // get join of oldAssetId
        INotionalJoin oldJoin = INotionalJoin(address(ladle.joins(oldAssetId)));

        // njoin check
        // check could be bypassed if Join has a fallback function 
        try oldJoin.fCashId() returns (uint256) {
            emit Log("valid njoin");
        } catch {
            emit Log("oldAssetId join invalid");
        }
        
        // get underlying, underlyingJoin addresses
        address underlying = oldJoin.underlying(); 
        address underlyingJoin = oldJoin.underlyingJoin();
        
        // get new maturity
        uint16 currencyId = oldJoin.currencyId();
        uint40 oldMaturity = oldJoin.maturity();
        uint40 maturity = oldMaturity + 90 days;
  
        NotionalJoin join = new NotionalJoin{salt: bytes32(salt)}(
            newAssetAddress,
            underlying,
            underlyingJoin,
            maturity,
            currencyId
        );

        address joinAddress = address(join);

        // grant ROOT to msg.sender
        AccessControl(joinAddress).grantRole(ROOT, msg.sender);  
        // revoke ROOT from NotionalJoinFactory
        AccessControl(joinAddress).renounceRole(ROOT, address(this));

        emit JoinCreated(newAssetAddress, address(join));
        return join;
    }

    /// @dev Get address of contract to be deployed
    /// @param bytecode Bytecode of the contract to be deployed (include constructor params)
    /// @param salt Random number of choice
    function getAddress(bytes memory bytecode, uint256 salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        // cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /// @dev Get bytecode of contract to be deployed
    /// @param asset Address of the ERC1155 token. (e.g. fDai2203)
    /// @param underlying Address of the underlying token. (e.g. Dai)
    /// @param underlyingJoin Address of the underlying join contract. (e.g. Dai join contract)
    /// @param maturity Maturity of fCash token. (90-day intervals)
    /// @param currencyId Maturity of fCash token. (90-day intervals)
    /// @return bytes Bytecode of notional join to be passed into getAddress()
    function getByteCode(
        address asset,
        address underlying,
        address underlyingJoin,
        uint40 maturity,
        uint16 currencyId
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(NotionalJoin).creationCode;

        //append constructor arguments
        return abi.encodePacked(bytecode, abi.encode(asset, underlying, underlyingJoin, maturity, currencyId));
    }

    /// @dev Point to a different ladle
    /// @param param Name of parameter to set (must be "ladle")
    /// @param value Address of new contract
    function point(bytes32 param, address value) external auth {
        if (param != "ladle") {
            revert UnrecognisedParam(param);
        }
        address oldLadle = address(ladle);
        ladle = ILadleGov(value);
        emit Point(param, oldLadle, value);
    }
    
}