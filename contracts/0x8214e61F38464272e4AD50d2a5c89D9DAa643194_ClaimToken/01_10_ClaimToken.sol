// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../claimtoken/IClaimToken.sol";
import "../admin/SuperAdminControl.sol";

/// @dev this contract is used for setting the suntoken percentages which is the peg price of the native token
contract ClaimToken is OwnableUpgradeable, SuperAdminControl, IClaimToken {
    function initialize() external initializer {
        __Ownable_init();
    }

    address public govAdminRegistry;

    /// @dev mapping for enable or disbale the claimToken
    mapping(address => bool) public approvedClaimTokens;

    mapping(address => ClaimTokenData) public claimTokens;
    //sun token mapping to the claimToken
    mapping(address => address) public claimTokenofSUN;

    address[] public sunTokens;

    function configureAdminRegistry(address _adminRegistry) external onlyOwner {
        require(_adminRegistry != address(0), "ClaimToken: null address");
        govAdminRegistry = _adminRegistry;
    }

    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _claimTokenAddress of the new claim token Address
    *@param _claimtokendata struct of the _claimTokenAddress
    */
    function addClaimToken(
        address _claimTokenAddress,
        ClaimTokenData memory _claimtokendata
    )
        external
        onlySuperAdmin(govAdminRegistry, msg.sender) /** only super admin wallet can add sun tokens */
    {
        require(_claimTokenAddress != address(0), "GCL: null address error");
        require(
            _claimtokendata.pegTokens.length ==
                _claimtokendata.pegTokensPricePercentage.length,
            "GCL: length mismatch"
        );
        require(
            !approvedClaimTokens[_claimTokenAddress],
            "GCL: already approved"
        );
        approvedClaimTokens[_claimTokenAddress] = true;
        claimTokens[_claimTokenAddress] = _claimtokendata;
        for (uint256 i = 0; i < _claimtokendata.pegTokens.length; i++) {
            claimTokenofSUN[_claimtokendata.pegTokens[i]] = _claimTokenAddress;
            sunTokens.push(_claimtokendata.pegTokens[i]);
        }
    }

    /**
     @dev function to update the token market data
     *@param _claimTokenAddress to check if it exit in the array and mapping
     *@param _newClaimtokendata struct to update the token market
     */
    function updateClaimToken(
        address _claimTokenAddress,
        ClaimTokenData memory _newClaimtokendata
    )
        external
        onlySuperAdmin(govAdminRegistry, msg.sender) /** only super admin wallet can add sun tokens */
    {
       
        require(
            approvedClaimTokens[_claimTokenAddress],
            "GCL: claim token not approved"
        );

        claimTokens[_claimTokenAddress] = _newClaimtokendata;
    }

    /**
     *@dev function to make claim token false
     *@param _removeClaimTokenAddress the key to remove
     */
    function enableClaimToken(address _removeClaimTokenAddress, bool _status)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(
            approvedClaimTokens[_removeClaimTokenAddress] != _status,
            "GCL: already in desired state"
        );
        approvedClaimTokens[_removeClaimTokenAddress] = _status;
    }

    function isClaimToken(address _claimTokenAddress)
        external
        view
        override
        returns (bool)
    {
        return approvedClaimTokens[_claimTokenAddress];
    }

    /// @dev get the ClaimToken address of the sunToken
    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        override
        returns (address)
    {
        return claimTokenofSUN[_sunToken];
    }

    /// @dev get the claimToken struct ClaimTokenData
    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        override
        returns (ClaimTokenData memory)
    {
        return claimTokens[_claimTokenAddress];
    }

    /// @dev get all the sun or peg token contract addresses
    function getSunTokens() external view returns (address[] memory) {
        return sunTokens;
    }
}