// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RoyaltyNFT is Ownable, IERC2981 {
    address private _royaltiesReceiver; // royalties
    uint256 public constant royaltiesPercentage = 8; // solhint-disable-line

    /// @notice Getter function for _royaltiesReceiver
    /// @return the address of the royalties recipient
    function royaltiesReceiver() external view returns (address) {
        return _royaltiesReceiver;
    }

    function _setRoyaltiesReceiver(address newReceiver) internal {
        _royaltiesReceiver = newReceiver;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesReceiver, (_salePrice * royaltiesPercentage) / 100);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == 0x01ffc9a7 ||
            interfaceId == type(IERC165).interfaceId;
    }
}