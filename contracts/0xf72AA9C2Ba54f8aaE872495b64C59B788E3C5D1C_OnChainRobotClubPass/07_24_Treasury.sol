// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Administered.sol";

error CannotSetZeroAddress();

contract Treasury is Administered, ERC2981 {
    using Address for address;

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Sets Treasury Address for withdraw() and ERC2981 royaltyInfo
    address public treasuryAddress;

    /**
     * @dev Withdraw funds to treasuryAddress
     */
    function withdraw() external onlyAdmin {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    /**
     * @dev Update the royalty percentage (100 = 1%)
     */
    function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyAdmin {
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
    }

    /**
     * @dev Update the royalty wallet address
     */
    function setTreasuryAddress(address payable newAddress) public onlyAdmin {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
    }

    /**
     * @dev {ERC165-supportsInterface} Adding IERC2981
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC2981)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }
}