// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./interfaces/IResonate.sol";
import "./interfaces/IResonateHelper.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IMetadataHandler.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MetadataHandler is IMetadataHandler, Ownable {

    string public constant OR_METADATA = "https://revest.mypinata.cloud/ipfs/QmYCUEaUMBw9EmswM467BCe9AcoshSbqBcawdwoUxvtFQW";
    string public constant AL_METADATA = "https://revest.mypinata.cloud/ipfs/QmXocbAkKiwuF2f9hm7bAZAwsmjY6WCR9cpzwVKe22ELKY";

    /// Precision for calculating rates
    uint public constant PRECISION = 1 ether;

    /// Resonate address
    address public resonate;

    /// Whether or not Resonate is set
    bool private _resonateSet;

    /// Allows us to better display info about the tokens within LP tokens
    mapping(address => string) public tokenDescriptions;

    constructor() {
        
    }

    /**
     * @notice this function will be called during deployment to set Resonate and can only be called once
     * @param _resonate the Resonate.sol address for this deployment
     */
    function setResonate(address _resonate) external onlyOwner {
        require(!_resonateSet, 'ER031');
        _resonateSet = true;
        resonate = _resonate;
    }

    /// @notice This function may be called when new LP tokens are added to improve QoL and UX
    function modifyTokenDescription(address _token, string memory _text) external onlyOwner {
        tokenDescriptions[_token] = _text;
    }

    ///
    /// View Methods
    ///

    /**
     * @notice provides a link to the JSON file for Resonate's output receiver
     * @return a URL pointing to the JSON file describing how to decode getOutputReceiverBytes
     * @dev This file must follow the Revest OutputReceiver JSON format, found at dev.revest.finance
     */
    function getOutputReceiverURL() external pure override returns (string memory) {
        return OR_METADATA;
    }

    /**
     * @notice provides a link to the JSON file for Resonate's address lock proxy
     * @return a URL pointing to the JSON file describing how to decode getAddressLockBytes
     * @dev This file must follow the Revest AddressRegistry JSON format, found at dev.revest.finance
     */
    function getAddressLockURL() external pure override returns (string memory) {
        return AL_METADATA;
    }

    /**
     * @notice Provides a stream of data to the Revest frontend, which is decoded according to the format of the OR JSON file
     * @param fnftId the ID of the FNFT for which view data is requested
     * @return output a bytes array produced by calling abi.encode on all parameters that will be displayed on the FE
     * @dev The order of encoding should line up with the order specified by 'index' parameters in the JSON file
     */
    function getOutputReceiverBytes(uint fnftId) external view override returns (bytes memory output) {
        IResonate instance = IResonate(resonate);
        uint256 principalId;
        bytes32 poolId;
        {
            uint index = instance.fnftIdToIndex(fnftId);
            // Can get interestId from principalId++
            (principalId, ,, poolId) = instance.activated(index);
        }

        (address paymentAsset, address vault, address vaultAdapter,, uint128 rate,, ) = instance.pools(poolId);

        string memory description;
        string[2] memory farmString;
        uint8 dec;
        {
            address farmedAsset = IERC4626(vaultAdapter).asset();
            description = tokenDescriptions[farmedAsset];
            farmString = [string(abi.encodePacked('Farming Asset: ',_formatAsset(farmedAsset))),string(abi.encodePacked( '\nPayment Asset: ', _formatAsset(paymentAsset)))];
            dec = IERC20Detailed(farmedAsset).decimals();
        }
        
        uint accruedInterest;
        if(fnftId > principalId) {
            (accruedInterest,) = IResonateHelper(instance.RESONATE_HELPER()).calculateInterest(fnftId);
            uint residual = instance.residuals(fnftId);
            uint residualValue = IERC4626(vaultAdapter).previewRedeem(residual);
            if(residualValue > 0) {
                accruedInterest -= residualValue;
            }
        } 

        address wallet = IResonateHelper(instance.RESONATE_HELPER()).getAddressForFNFT(poolId);
        bool isPrincipal = fnftId == principalId;
        bool isInterest = !isPrincipal;
        
        output = abi.encode(
            accruedInterest,    // 0
            description,        // 1
            poolId,             // 2
            farmString,         // 3 
            vault,              // 4
            vaultAdapter,       // 5
            wallet,             // 6
            rate,               // 7
            dec,                // 8
            isPrincipal,        // 9
            isInterest          // 10
        );
    }

    /**
     * @notice Provides a stream of data to the Revest frontend, which is decoded according to the format of the AL JSON file
     * @param fnftId the ID of the FNFT for which view data is requested
     * @return output a bytes array produced by calling abi.encode on all parameters that will be displayed on the FE
     * @dev The order of encoding should line up with the order specified by 'index' parameters in the JSON file
     */
    function getAddressLockBytes(uint fnftId, uint) external view override returns (bytes memory output) {
        IResonate instance = IResonate(resonate);
        uint residual = instance.residuals(fnftId);
        uint sharesAtDeposit;
        bytes32 poolId;
        {
            uint index = instance.fnftIdToIndex(fnftId);
            (,, sharesAtDeposit, poolId) = instance.activated(index);
        }
        (,, address vaultAdapter,, uint128 rate, uint128 addInterestRate, uint256 packetSize) = instance.pools(poolId);

        bool unlocked;
        uint128 expectedReturn = rate + addInterestRate; 
        uint tokensExpectedPerPacket = packetSize * expectedReturn / PRECISION;
        uint tokensAccumulatedPerPacket;
        address asset = IERC4626(vaultAdapter).asset();

        if(residual > 0) {
            unlocked = true;
            tokensAccumulatedPerPacket = tokensExpectedPerPacket;
        } else {
            uint previewRedemption = IERC4626(vaultAdapter).previewRedeem(sharesAtDeposit / PRECISION);
            if (previewRedemption >= packetSize) {
                tokensAccumulatedPerPacket =  previewRedemption - packetSize;
            }
            unlocked = tokensAccumulatedPerPacket >= tokensExpectedPerPacket;
        }
         
        output = abi.encode(
            unlocked,                           // 0
            expectedReturn,                     // 1    
            tokensExpectedPerPacket,            // 2
            tokensAccumulatedPerPacket,         // 3
            IERC20Detailed(asset).decimals()    // 4
        );
    }

    function _formatAsset(address asset) private view returns (string memory formatted) {
        formatted = string(abi.encodePacked(_getName(asset)," - ","[",IERC20Detailed(asset).symbol(),"] - ", Strings.toHexString(uint256(uint160(asset)), 20)));
    } 

    function _getName(address asset) internal view returns (string memory ticker) {
        try IERC20Metadata(asset).name() returns (string memory tick) {
            ticker = tick;
        } catch {
            ticker = 'Unknown Token';
        }
    }

}