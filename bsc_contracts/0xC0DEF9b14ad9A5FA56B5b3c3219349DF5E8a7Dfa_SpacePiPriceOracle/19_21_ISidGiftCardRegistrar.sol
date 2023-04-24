// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISidGiftCardRegistrar is IERC1155 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    //Authorises a controller, who can issue a gift card.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    //Register new gift card voucher
    function register(
        address to,
        uint256 id,
        uint256 amount
    ) external returns (uint256, uint256);

    //batch register new gift card voucher
    function batchRegister(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}