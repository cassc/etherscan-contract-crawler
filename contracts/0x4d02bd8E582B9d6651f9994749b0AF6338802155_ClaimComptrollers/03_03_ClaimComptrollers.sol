// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IComptroller {
    /// @notice The COMP accrued but not yet transferred to each user
    function compAccrued(address account) external view returns (uint256);

    /// @notice Claim all the comp accrued by holder in all markets
    function claimComp(address holder) external;

    /// @notice Claim all the comp accrued by cTokens in all markets
    function claimComp(address holder, address[] memory cTokens, bool borrowers, bool suppliers) external;
}

contract ClaimComptrollers is Ownable {
    struct CTokenList {
        address comptroller;
        address[] cTokenList;
    }

    address public admin;
    address[] private comptrollers;

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == admin, "caller is not owner or admin");
        _;
    }

    constructor(address[] memory _comptrollers, address _admin) {
        comptrollers = _comptrollers;
        admin = _admin;
    }

    /**
     * @notice Claim all the comp accrued by holder in the all comptrollers
     * @param holder The address to claim COMP for
     */
    function claimAll(address holder) external {
        address[] memory comptrollers_ = comptrollers;

        for (uint256 i = 0; i < comptrollers_.length; i++) {
            uint256 claimAmount_ = IComptroller(comptrollers_[i]).compAccrued(holder);
            if (claimAmount_ > 0) {
                IComptroller(comptrollers_[i]).claimComp(holder);
            }
        }
    }

    /**
     * @notice Claim all the comp accrued by holder in the all comptrollers
     * @param holder The address to claim COMP for
     * @param _comptrollers The addresses of user with claim COMP
     */
    function claimAllWithAddress(address holder, address[] memory _comptrollers) external {
        for (uint i = 0; i < _comptrollers.length; i++) {
            IComptroller(_comptrollers[i]).claimComp(holder);
        }
    }

    /**
     * @notice Claim all the comp accrued by holder in CTokens of all comptrollers
     * @param holder The address to claim COMP for
     * @param cTokenInfo The addresses of user with claim COMP
     */
    function claimAllWithCTokens(address holder, CTokenList[] memory cTokenInfo) external {
        for (uint i = 0; i < cTokenInfo.length; i++) {
            IComptroller(cTokenInfo[i].comptroller).claimComp(holder, cTokenInfo[i].cTokenList, true, true);
        }
    }

    /**
     * @notice Get total rewards amount to claim
     * @param holder The address to claim COMP for
     */
    function getAllComAccrued(address holder) external view returns (uint256 totalAmount) {
        address[] memory comptrollers_ = comptrollers;

        for (uint256 i = 0; i < comptrollers_.length; i++) {
            uint256 claimAmount_ = IComptroller(comptrollers_[i]).compAccrued(holder);
            totalAmount += claimAmount_;
        }
    }

    /**
     * @notice Get list of Comptroller contract's addresses
     */
    function getAllComptrollers() external view returns (address[] memory) {
        return comptrollers;
    }

    /**
     * @notice Get comptrollers address of user with claim COMP
     * @param holder The address to claim COMP for
     */
    function getCompAddressOf(address holder) external view returns (address[] memory) {
        address[] memory comptrollers_ = comptrollers;
        address[] memory addresses = new address[](comptrollers_.length);

        for (uint256 i = 0; i < comptrollers_.length; i++) {
            uint256 claimAmount_ = IComptroller(comptrollers_[i]).compAccrued(holder);
            if (claimAmount_ > 0) {
                addresses[i] = comptrollers_[i];
            }
        }

        return addresses;
    }

    /**
     * @notice Remove comptroller address for index from the comptroller's address list
     * called by only owner or admin address
     * @param index The uint index of comptroller address to remove
     */
    function removeComptroller(uint index) external onlyOwnerOrAdmin {
        require(index <= comptrollers.length, "index should be less than length of comptrollers");
        comptrollers[index] = comptrollers[comptrollers.length - 1];
        comptrollers.pop();
    }

    /**
     * @notice Add new comptroller address to the comptroller's address list
     * called by only owner or admin address
     * @param comptroller The address of new comptroller to add
     */
    function addComptroller(address comptroller) external onlyOwnerOrAdmin {
        require(comptroller != address(0), "invalid address");
        comptrollers[comptrollers.length] = comptroller;
    }

    /**
     * @notice Change admin address, called by only owner
     * @param newAdmin The address of new admin
     */
    function changeAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "invalid address");
        admin = newAdmin;
    }
}