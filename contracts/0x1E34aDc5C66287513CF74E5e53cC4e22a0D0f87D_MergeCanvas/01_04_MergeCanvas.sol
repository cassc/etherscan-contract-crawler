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

contract MergeCanvas {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    struct RGB {
        uint8 R;
        uint8 G;
        uint8 B;
    }

    uint16 public immutable CANVAS_DIMENSION;
    address immutable OWNER_ADDRESS;
    // TODO: directly measure closeness to merge
    // uint256 immutable DEPLOY_TIMESTAMP;

    uint256 immutable ESTIMATED_CLOSE_TIMESTAMP = 1663200000; // Sep 15, 2022, 00:00:00 GMT

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

    struct PixelColorChangeInfo {
        uint16 x;
        uint16 y;
        address old_owner;
        address new_owner;
        RGB old_color;
        RGB new_color;
        uint256 old_price;
        uint256 new_price;
    }


    event PixelColorChanged(
        uint16 x,
        uint16 y,
        address old_owner,
        address new_owner,
        RGB old_color,
        RGB new_color,
        uint256 old_price,
        uint256 new_price
    );

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

    function Contributed(address _address) public view returns (bool) {
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
        if (address_pixel_capacity >= 500) {
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
        // Get the hash of the (x,y) coordinates
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);

        // Update the owner of the pixel
        address old_owner = pixel_owner[coordinates_hash];
        pixel_owner[coordinates_hash] = msg.sender;

        // Update the color (R,G,B) of the pixel
        RGB memory old_color = pixel_color[coordinates_hash];
        pixel_color[coordinates_hash] = _new_color;

        // Update pixel paid, and refund previous owner
        uint256 old_price = pixel_price_paid[coordinates_hash];
        pixel_price_paid[coordinates_hash] = msg.value;
        if (old_price > 0) {
            (bool sent, ) = old_owner.call{value: old_price}("");
            if (!sent) {
                revert MergeCanvas_FailedBidRefund();
            }
        }

        // Update the address mapping
        uint256 pixel_encoded = (uint32(_x) << 16) + _y;
        pixel_lookup[old_owner].remove(pixel_encoded);
        pixel_lookup[msg.sender].add(pixel_encoded);

        // Circumvent "Stack too deep, try removing local variables." when
        // emitting PixelColorChanged
        PixelColorChangeInfo memory change_info = PixelColorChangeInfo(
            _x,
            _y,
            old_owner,
            msg.sender,
            old_color,
            _new_color,
            old_price,
            msg.value
        );

        emit PixelColorChanged(
            change_info.x,
            change_info.y,
            change_info.old_owner,
            change_info.new_owner,
            change_info.old_color,
            change_info.new_color,
            change_info.old_price,
            change_info.new_price
        );
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
        require(_x.length == _y.length);
        require(_x.length == _new_color.length);
        require(_x.length == _prices.length);

        // first iteration to check info
        // NOTE: https://github.com/crytic/slither/wiki/Detector-Documentation/#msgvalue-inside-a-loop
        uint256 remainder = msg.value;
        for (uint i = 0; i < _x.length; i++) {
            uint256 pixel_price = _calculatePixelPrice(_x[i], _y[i]);
            require(remainder >= pixel_price, "Insufficient balance for batch change");
            if (pixel_price > 0 && _prices[i] <= pixel_price) {
                revert MergeCanvas_InsufficientBid(_prices[i], pixel_price);
            }
            remainder -= pixel_price;
        }

        // intermediary check to make sure all requirements are met
        // require(msg.value >= min_cost, "Batch paid less than minimum cost!");

        // second iteration to actually change pixel colors
        for (uint i = 0; i < _x.length; i++) {
            // Get the hash of the (x,y) coordinates
            bytes32 coordinates_hash = _calculateCoordinatesHash(_x[i], _y[i]);

            pixel_price_paid[coordinates_hash] = _prices[i];

            // Update the owner of the pixel
            address old_owner = pixel_owner[coordinates_hash];
            pixel_owner[coordinates_hash] = msg.sender;

            // Update the color (R,G,B) of the pixel
            RGB memory old_color = pixel_color[coordinates_hash];
            pixel_color[coordinates_hash] = _new_color[i];

            // Update pixel paid, and refund previous owner
            uint256 old_price = pixel_price_paid[coordinates_hash];
            pixel_price_paid[coordinates_hash] = _prices[i];
            if (old_price > 0) {
                (bool sent, ) = old_owner.call{value: old_price}("");
                if (!sent) {
                    revert MergeCanvas_FailedBidRefund();
                }
            }

            // Update the address mapping
            uint256 pixel_encoded = (uint32(_x[i]) << 16) + _y[i];
            pixel_lookup[old_owner].remove(pixel_encoded);
            pixel_lookup[msg.sender].add(pixel_encoded);

            // Circumvent "Stack too deep, try removing local variables." when
            // emitting PixelColorChanged
            PixelColorChangeInfo memory change_info = PixelColorChangeInfo(
                _x[i],
                _y[i],
                old_owner,
                msg.sender,
                old_color,
                _new_color[i],
                old_price,
                _prices[i]
            );

            emit PixelColorChanged(
                change_info.x,
                change_info.y,
                change_info.old_owner,
                change_info.new_owner,
                change_info.old_color,
                change_info.new_color,
                change_info.old_price,
                change_info.new_price
            );
        }
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

    function mergeStatus() public view returns (bool) {
        return merged;
    }

    function setBatchAllowed(bool _allow) public OnlyOwner {
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