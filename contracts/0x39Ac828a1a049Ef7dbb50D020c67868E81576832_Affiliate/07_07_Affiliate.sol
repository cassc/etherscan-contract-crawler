// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAddressRegistry {
    function affiliate() external view returns (address);

    function neonRain() external view returns (address);

    function marketplace() external view returns (address);

    function auction() external view returns (address);

    function tokenRegistry() external view returns (address);

    function priceFeed() external view returns (address);
}

contract Affiliate is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Affiliate fee (in basis points); default is set to 20%
    uint256 public affiliateFee = 2000;
    /// @notice Keeps track of whether a user signed up using a promo code
    mapping(address => address) public affiliateLink;
    /// @notice Keeps track of whether a user has transacted on the platform
    mapping(address => bool) public hasTransacted;
    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    /// @notice to receive ETH from Auction.sol for platform fee distributions
    receive() external payable {}

    /// @notice Stores the affiliate link if a user uses a promo code when signing up
    /// @dev If does not pass checks, just silently "fails" so that the transaction is not reverted
    /// @param _userToRegister The user that is signing up
    /// @param _affliateOwner Affiliate owner
    function signUpWithPromo(address _userToRegister, address _affliateOwner)
        public
    {
        if (_affliateOwner == address(0)) {
            //Invalid Referrer
            return;
        }
        if (affiliateLink[_userToRegister] != address(0)) {
            //Already signed up using affiliate code
            return;
        }
        if (_userToRegister == _affliateOwner) {
            //Can't sign up using own affiliate
            return;
        }
        if (hasTransacted[_userToRegister] == true) {
            //Not eligible - Already transacted on the marketplace
            return;
        }

        affiliateLink[_userToRegister] = _affliateOwner;
    }

    /// @notice Properly transfers the Platform fee (not royalties) according to any applicable referral lines
    /// @dev Bypasses Stack Too Deep error if the logic is in a function in this contract, as opposed to being executed in Marketplace.sol and Auction.sol
    /// @param _payToken Token to be used to pay fees
    /// @param _feeAmount Amount of fees
    /// @param _userToCheckAffiliate Check affiliate association for this user
    /// @param _feeSender address where the fees will be sent from
    /// @param _feeReceipient address where the protocol's allocation of fees are sent to
    /// @param _maxFeeCalculation used to calculate maximum allowed affiliate fees
    function splitFeeWithAffiliate(
        IERC20 _payToken,
        uint256 _feeAmount,
        address _userToCheckAffiliate,
        address _feeSender,
        address _feeReceipient,
        uint256 _maxFeeCalculation
    ) public {
        address affiliateOwner = getAffiliateOwner(_userToCheckAffiliate);
        if (affiliateOwner != address(0)) {
            //if there is an affiliate
            uint256 protocolFeePortion = returnFeeAfterAffiliateAllocation(
                _feeAmount
            );
            uint256 affiliatePortion = _feeAmount - protocolFeePortion;
            uint256 protocolFeePortionMaxCalc = returnFeeAfterAffiliateAllocation(
                    _maxFeeCalculation
                );
            uint256 affiliatePortionMaxCalc = _maxFeeCalculation -
                (protocolFeePortionMaxCalc);

            if (affiliatePortion > affiliatePortionMaxCalc) {
                _payToken.safeTransferFrom(
                    _feeSender,
                    _feeReceipient,
                    _feeAmount - affiliatePortionMaxCalc
                );
                _payToken.safeTransferFrom(
                    _feeSender,
                    affiliateOwner,
                    affiliatePortionMaxCalc
                );
            } else {
                _payToken.safeTransferFrom(
                    _feeSender,
                    _feeReceipient,
                    protocolFeePortion
                );
                _payToken.safeTransferFrom(
                    _feeSender,
                    affiliateOwner,
                    affiliatePortion
                );
            }
        } else {
            _payToken.safeTransferFrom(_feeSender, _feeReceipient, _feeAmount);
        }
    }

    /// @notice Properly transfers the fees in native ETH according to any applicable referral lines
    /// @dev Bypasses Stack Too Deep error if the logic is in a function in this contract, as opposed to being executed in Auction.sol
    /// @param _feeAmount Amount of fees
    /// @param _userToCheckAffiliate Check affiliate association for this user
    /// @param _feeReceipient address where the protocol's allocation of fees are sent to
    /// @param _maxFeeCalculation used to calculate maximum allowed affiliate fees
    function splitFeeWithAffiliateETH(
        uint256 _feeAmount,
        address _userToCheckAffiliate,
        address _feeReceipient,
        uint256 _maxFeeCalculation
    ) public {
        address affiliateOwner = getAffiliateOwner(_userToCheckAffiliate);
        if (affiliateOwner != address(0)) {
            //if there is an affiliate

            uint256 protocolFeePortion = returnFeeAfterAffiliateAllocation(
                _feeAmount
            );
            uint256 affiliatePortion = _feeAmount - protocolFeePortion;

            uint256 protocolFeePortionMaxCalc = returnFeeAfterAffiliateAllocation(
                    _maxFeeCalculation
                );
            uint256 affiliatePortionMaxCalc = _maxFeeCalculation -
                protocolFeePortionMaxCalc;

            if (affiliatePortion > affiliatePortionMaxCalc) {
                (bool platformTransferSuccess, ) = payable(_feeReceipient).call{
                    value: _feeAmount - affiliatePortionMaxCalc
                }("");
                require(platformTransferSuccess, "failed to send platform fee");
                (bool platformTransferAffiliateSuccess, ) = payable(
                    affiliateOwner
                ).call{value: affiliatePortionMaxCalc}("");
                require(
                    platformTransferAffiliateSuccess,
                    "failed to send platform fee to affiliate"
                );
            } else {
                (bool platformTransferSuccess, ) = payable(_feeReceipient).call{
                    value: protocolFeePortion
                }("");
                require(platformTransferSuccess, "failed to send platform fee");
                (bool platformTransferAffiliateSuccess, ) = payable(
                    affiliateOwner
                ).call{value: affiliatePortion}("");
                require(
                    platformTransferAffiliateSuccess,
                    "failed to send platform fee to affiliate"
                );
            }
        } else {
            (bool platformTransferSuccess, ) = payable(_feeReceipient).call{
                value: _feeAmount
            }("");
            require(platformTransferSuccess, "failed to send platform fee");
        }
    }

    /////////////////////////////////////////////////////////////////////////////Utility Functions////////////////////////////////////////////////////
    /// @notice Utility function used to set the status of a user to having transacted on the marketplace
    /// @param _user User that has transacted on the marketplace
    function setHasTransacted(address _user) public {
        require(
            msg.sender == addressRegistry.auction() ||
                msg.sender == addressRegistry.marketplace(),
            "Only Auction or Marketplace Contract can Call"
        );
        hasTransacted[_user] = true;
    }

    ///@notice Update AddressRegistry contract
    ///@param _registry Registery address
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IAddressRegistry(_registry);
    }

    /// @notice Utility function used to set the affiliate fee rate
    /// @param _newFee New fee rate in basis points
    function setAffiliateFee(uint256 _newFee) public onlyOwner {
        affiliateFee = _newFee;
    }

    /// @notice Utility function used to fetch the owner of the affiliate link that a user used when signing up (if any)
    /// @param _user The user
    function getAffiliateOwner(address _user) public view returns (address) {
        return affiliateLink[_user];
    }

    /// @notice Utility function used to calculate fees taking into account the affiliate allocation
    /// @param _amount fee amount
    function returnFeeAfterAffiliateAllocation(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 affiliateAllocation = (_amount * affiliateFee) / 10000;
        uint256 amountAfterFee = _amount - affiliateAllocation;
        return amountAfterFee;
    }
}