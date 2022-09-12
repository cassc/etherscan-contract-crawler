// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IMergeCanvas.sol";

contract MergeCanvas is IMergeCanvas {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    uint16 public immutable CANVAS_DIMENSION;
    address immutable OWNER_ADDRESS;
    // TODO: directly measure closeness to merge
    // uint256 immutable DEPLOY_TIMESTAMP;

    uint256 immutable ESTIMATED_CLOSE_TIMESTAMP = 1663088400; // September 13, 2022 12:00:00 PM GMT-05:00
    uint256 immutable MIN_BID_AMOUNT = 1 ether / 1000; // 0.001 ether min bid

    bool private merged = false;
    bool private batchAllowed = true;

    mapping(bytes32 => address) private pixel_owner;
    // Colors represented as rgb values
    mapping(bytes32 => RGB) private pixel_color;
    mapping(bytes32 => uint256) private pixel_price_paid;
    // Quick look-up of pixel(s) owned by an address
    // The 16 most significant bits will be the x-coordinate
    // The 16 least significant bits will be the y-coordinate
    // Note: Encoding the (x,y) values would result in bytes instead of bytes32
    mapping(address => EnumerableSet.UintSet) private pixel_lookup;

    modifier OnlyOwner() {
        if (msg.sender != OWNER_ADDRESS) {
            revert MergeCanvas_NotOwner(msg.sender);
        }
        _;
    }

    modifier ValidCoordinates(uint16 _x, uint16 _y) {
        if (_x > (CANVAS_DIMENSION - 1)) {
            revert MergeCanvas_XCoordinateOutOfBounds(_x, CANVAS_DIMENSION);
        } else if (_y > (CANVAS_DIMENSION - 1)) {
            revert MergeCanvas_YCoordinateOutOfBounds(_y, CANVAS_DIMENSION);
        }
        _;
    }

    function hasContributed(address _address) external view returns (bool) {
        if (pixel_lookup[_address].length() == 0) {
            revert MergeCanvas_NotContributor(_address);
        }
        return true;
    }

    modifier SufficientBid(uint16 _x, uint16 _y) {
        uint256 pixel_price = _calculatePixelPrice(_x, _y);
        uint256 val = msg.value; // https://github.com/crytic/slither/wiki/Detector-Documentation/#msgvalue-inside-a-loop
        if (pixel_price > 0 && val <= pixel_price) {
            revert MergeCanvas_InsufficientBid(val, pixel_price);
        }
        _;
    }

    //OPTIONAL: Limit the number of pixels an address can own
    modifier NotAtMaxPixelCapacity() {
        uint256 address_pixel_capacity = pixel_lookup[msg.sender].length();
        if (address_pixel_capacity >= CANVAS_DIMENSION) {
            revert MergeCanvas_AddressAtMaxPixelCapacity(msg.sender);
        }
        _;
    }

    // TODO: Logic to ensure that change takes place before merge
    modifier BeforeMerge() {
        if (merged) {
            revert MergeCanvas_AlreadyMerged("Merge has occurred");
        }
        _;
    }

    constructor(uint16 _canvas_dimension) {
        OWNER_ADDRESS = msg.sender;
        CANVAS_DIMENSION = _canvas_dimension;
        // DEPLOY_TIMESTAMP = block.timestamp;
    }

    function _calculateCoordinatesHash(uint16 _x, uint16 _y)
        internal
        view
        ValidCoordinates(_x, _y)
        returns (bytes32 coordinates_hash)
    {
        coordinates_hash = keccak256(abi.encode(_x, _y));
        return coordinates_hash;
    }

    function _calculatePixelPrice(uint16 _x, uint16 _y)
        internal
        view
        returns (uint256 pixel_price)
    {
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);
        return pixel_price_paid[coordinates_hash];
    }

    function _changePixelColor(
        uint16 _x,
        uint16 _y,
        RGB calldata _new_color,
        uint256 _new_price,
        uint256 _remainder
    )
        internal
        returns (bool)
    {
        // Get the hash of the (x,y) coordinates
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);

        uint256 old_price = pixel_price_paid[coordinates_hash];
        address old_owner = pixel_owner[coordinates_hash];

        if (
            // either old price is 0 (no price set)
            // or new price exceeds (old price + min bid) && user has balance to pay
            old_price == 0
            || (_new_price >= old_price + MIN_BID_AMOUNT && _remainder >= _new_price)
        ) {
            // Update pixel price, owner, and color
            pixel_price_paid[coordinates_hash] = _new_price;
            pixel_owner[coordinates_hash] = msg.sender;
            pixel_color[coordinates_hash] = _new_color;

            // Update the address mapping
            uint256 pixel_encoded = (uint32(_x) << 16) + _y;
            pixel_lookup[old_owner].remove(pixel_encoded);
            pixel_lookup[msg.sender].add(pixel_encoded);

            emit PixelChange(_x, _y, _new_color, msg.sender, _new_price);

            // Refund all new money to previous owner, at last for CIE pattern
            if (_new_price > 0) {
                if (old_owner != address(0)) {
                    (bool sent, ) = old_owner.call{value: _new_price}("");
                    if (!sent) {
                        revert MergeCanvas_FailedBidRefund();
                    }
                }
            }
            return true;
        } else {
            emit PixelChangeFail(_x, _y, _new_color, old_owner, msg.sender);
            return false;
        }
    }

    function changePixelColor(
        uint16 _x,
        uint16 _y,
        RGB calldata _new_color
    )
        external
        payable
        BeforeMerge
        NotAtMaxPixelCapacity
        SufficientBid(_x, _y)
    {
        _changePixelColor(_x, _y, _new_color, msg.value, msg.value);
    }

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
        payable
        BeforeMerge
        NotAtMaxPixelCapacity
    {
        require(batchAllowed, "Batch change color paused!");
        require(_x.length == _y.length && _x.length == _new_color.length && _x.length == _prices.length);

        // first iteration to check info
        // NOTE: https://github.com/crytic/slither/wiki/Detector-Documentation/#msgvalue-inside-a-loop
//        uint256 remainder = msg.value;
//        for (uint i = 0; i < _x.length; i++) {
//            uint256 pixel_price = _calculatePixelPrice(_x[i], _y[i]);
//            if (pixel_price > 0) {
//                if (_prices[i] <= pixel_price + MIN_BID_AMOUNT) {
//                    revert MergeCanvas_InsufficientBid(_prices[i], pixel_price);
//                }
//                require(remainder > pixel_price + MIN_BID_AMOUNT, "Insufficient balance for batch change");
//            } else {
//                require(remainder >= pixel_price, "Insufficient balance for batch change");
//            }
//            remainder -= _prices[i];
//        }

        uint256 remainder = msg.value;
        for (uint i = 0; i < _x.length; i++) {
            bool changed = _changePixelColor(_x[i], _y[i], _new_color[i], _prices[i], remainder);
            if (changed) {
                remainder -= _prices[i];
            }
        }

        // Refund whatever remainder from failing bids
        (bool sent, ) = msg.sender.call{value: remainder}("");
        require(sent, "Failed to refund any unused bid!");
    }

    function getPixelOwner(uint16 _x, uint16 _y)
        external
        view
        returns (address owner)
    {
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);
        owner = pixel_owner[coordinates_hash];
    }

    function getPixelColor(uint16 _x, uint16 _y)
        external
        view
        returns (RGB memory color)
    {
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);
        color = pixel_color[coordinates_hash];
    }

    function getPixelPrice(uint16 _x, uint16 _y)
        external
        view
        returns (uint256 pixel_price)
    {
        pixel_price = _calculatePixelPrice(_x, _y);
    }

    // Could remove function and instead use getPixelsForAddress()
    function getAddressPixels(address _address)
        external
        view
        returns (uint256[] memory address_pixels)
    {
        address_pixels = pixel_lookup[_address].values();
    }

    function numberOfPixels(address _address) external view returns (uint256) {
        uint256[] memory address_pixels = pixel_lookup[_address].values();
        return address_pixels.length;
    }

    function mergeNow() external OnlyOwner {
        require(block.timestamp >= ESTIMATED_CLOSE_TIMESTAMP, "Not at the estimated close timestamp!");
        merged = true;
    }

    function mergeStatus() external view returns (bool) {
        return merged;
    }

    function setBatchAllowed(bool _allow) external OnlyOwner {
        batchAllowed = _allow;
    }

    function withdraw() external OnlyOwner {
        require(merged, "Merge has to happen!");
        (bool sent, ) = OWNER_ADDRESS.call{value: address(this).balance}("");
        if (!sent) {
            revert MergeCanvas_FailedBidRefund();
        }
    }
}