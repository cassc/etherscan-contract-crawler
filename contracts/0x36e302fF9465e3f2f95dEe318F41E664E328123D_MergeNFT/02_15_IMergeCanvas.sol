// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error MergeCanvas_AlreadyMerged(string reason);
error MergeCanvas_NotOwner(address sender);
error MergeCanvas_XCoordinateOutOfBounds(uint16 x, uint16 max_value);
error MergeCanvas_YCoordinateOutOfBounds(uint16 y, uint16 max_value);
error MergeCanvas_InvalidRGBColor(uint16 invalid_num);
error MergeCanvas_InsufficientBid(uint256 bid, uint256 curr_price);
error MergeCanvas_FailedBidRefund();
error MergeCanvas_NotContributor(address sender);
error MergeCanvas_AddressAtMaxPixelCapacity(address sender);

interface IMergeCanvas {
    struct RGB {
        uint8 R;
        uint8 G;
        uint8 B;
    }

    event PixelChange(
        uint16 x,
        uint16 y,
        RGB new_color,
        address indexed new_owner,
        uint256 new_price
    );

    event PixelChangeFail(
        uint16 x,
        uint16 y,
        RGB new_color,
        address indexed old_owner,
        address indexed new_owner
    );

    function hasContributed(address _address) external view returns (bool);

    function changePixelColor(
        uint16 _x,
        uint16 _y,
        RGB calldata _new_color
    )
    external
    payable;

    //
    // @dev Change color of multiple pixels
    //
    function changePixelsColor(
        uint16[] memory _x,
        uint16[] memory _y,
        RGB[] calldata _new_color,
        uint256[] memory _prices
    )
    external
    payable;

    function getPixelOwner(uint16 _x, uint16 _y)
    external
    view
    returns (address owner);

    function getPixelColor(uint16 _x, uint16 _y)
    external
    view
    returns (RGB memory color);

    function getPixelPrice(uint16 _x, uint16 _y)
    external
    view
    returns (uint256 pixel_price);

    // Could remove function and instead use getPixelsForAddress()
    function getAddressPixels(address _address)
    external
    view
    returns (uint256[] memory address_pixels);

    function numberOfPixels(address _address) external view returns (uint256);

    function mergeNow() external;

    function withdraw() external;

    function mergeStatus() external view returns (bool);

    function setBatchAllowed(bool _allow) external;
}