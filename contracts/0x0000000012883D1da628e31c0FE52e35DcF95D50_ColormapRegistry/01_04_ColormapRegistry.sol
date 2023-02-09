// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@/contracts/utils/Constants.sol";
import {IColormapRegistry} from "@/contracts/interfaces/IColormapRegistry.sol";
import {IPaletteGenerator} from "@/contracts/interfaces/IPaletteGenerator.sol";

/// @title An on-chain registry for colormaps.
/// @author fiveoutofnine
contract ColormapRegistry is IColormapRegistry {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc IColormapRegistry
    mapping(bytes32 => SegmentData) public override segments;

    /// @inheritdoc IColormapRegistry
    mapping(bytes32 => IPaletteGenerator) public override paletteGenerators;

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /// @dev Reverts a function if a colormap does not exist.
    /// @param _colormapHash Hash of the colormap's definition.
    modifier colormapExists(bytes32 _colormapHash) {
        SegmentData memory segmentData = segments[_colormapHash];

        // Revert if a colormap corresponding to `_colormapHash` has never been
        // set.
        if (
            // Segment data is uninitialized.  We don't need to check `g` and
            // `b` because the segment data would've never been initialized if
            // any of `r`, `g`, or `b` were 0.
            segmentData.r == 0 &&
            // Palette generator is uninitialized.
            address(paletteGenerators[_colormapHash]) == address(0)
        ) {
            revert ColormapDoesNotExist(_colormapHash);
        }

        _;
    }

    // -------------------------------------------------------------------------
    // Actions
    // -------------------------------------------------------------------------

    /// @inheritdoc IColormapRegistry
    function register(IPaletteGenerator _paletteGenerator) external {
        bytes32 colormapHash = _computeColormapHash(_paletteGenerator);

        // Store palette generator.
        paletteGenerators[colormapHash] = _paletteGenerator;

        // Emit event.
        emit RegisterColormap(colormapHash, _paletteGenerator);
    }

    /// @inheritdoc IColormapRegistry
    function register(SegmentData memory _segmentData) external {
        bytes32 colormapHash = _computeColormapHash(_segmentData);

        // Check if `_segmentData` is valid.
        _checkSegmentDataValidity(_segmentData.r);
        _checkSegmentDataValidity(_segmentData.g);
        _checkSegmentDataValidity(_segmentData.b);

        // Store segment data.
        segments[colormapHash] = _segmentData;

        // Emit event.
        emit RegisterColormap(colormapHash, _segmentData);
    }

    // -------------------------------------------------------------------------
    // View
    // -------------------------------------------------------------------------

    /// @inheritdoc IColormapRegistry
    function getValue(bytes32 _colormapHash, uint256 _position)
        external
        view
        colormapExists(_colormapHash)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IPaletteGenerator paletteGenerator = paletteGenerators[_colormapHash];

        // Compute using the palette generator, if there exists one.
        if (address(paletteGenerator) != address(0)) {
            return (
                paletteGenerator.r(_position),
                paletteGenerator.g(_position),
                paletteGenerator.b(_position)
            );
        }

        // Compute the value with a piece-wise interpolation on the segments
        // given by the segment data.
        SegmentData memory segmentData = segments[_colormapHash];
        return (
            _computeLinearInterpolationFPM(segmentData.r, _position),
            _computeLinearInterpolationFPM(segmentData.g, _position),
            _computeLinearInterpolationFPM(segmentData.b, _position)
        );
    }

    /// @inheritdoc IColormapRegistry
    function getValueAsUint8(bytes32 _colormapHash, uint8 _position)
        public
        view
        colormapExists(_colormapHash)
        returns (
            uint8,
            uint8,
            uint8
        )
    {
        IPaletteGenerator paletteGenerator = paletteGenerators[_colormapHash];

        // Compute using the palette generator, if there exists one.
        if (address(paletteGenerator) != address(0)) {
            unchecked {
                // All functions in {IPaletteGenerator} represent a position in
                // the colormap as a 18 decimal fixed point number in [0, 1], so
                // we must convert it.
                uint256 positionAsFixedPointDecimal = FIXED_POINT_COLOR_VALUE_SCALAR *
                        _position;

                // This function returns `uint8` for each of the R, G, and B's
                // values, while all functions in {IPaletteGenerator} use the
                // 18 decimal fixed point representation, so we must convert it
                // back.
                return (
                    uint8(
                        paletteGenerator.r(positionAsFixedPointDecimal) /
                            FIXED_POINT_COLOR_VALUE_SCALAR
                    ),
                    uint8(
                        paletteGenerator.g(positionAsFixedPointDecimal) /
                            FIXED_POINT_COLOR_VALUE_SCALAR
                    ),
                    uint8(
                        paletteGenerator.b(positionAsFixedPointDecimal) /
                            FIXED_POINT_COLOR_VALUE_SCALAR
                    )
                );
            }
        }

        // Compute the value with a piece-wise interpolation on the segments
        // given by the segment data.
        SegmentData memory segmentData = segments[_colormapHash];
        return (
            _computeLinearInterpolation(segmentData.r, _position),
            _computeLinearInterpolation(segmentData.g, _position),
            _computeLinearInterpolation(segmentData.b, _position)
        );
    }

    /// @inheritdoc IColormapRegistry
    function getValueAsHexString(bytes32 _colormapHash, uint8 _position)
        external
        view
        returns (string memory)
    {
        (uint8 r, uint8 g, uint8 b) = getValueAsUint8(_colormapHash, _position);

        return
            string(
                abi.encodePacked(
                    HEXADECIMAL_DIGITS[r >> 4],
                    HEXADECIMAL_DIGITS[r & 0xF],
                    HEXADECIMAL_DIGITS[g >> 4],
                    HEXADECIMAL_DIGITS[g & 0xF],
                    HEXADECIMAL_DIGITS[b >> 4],
                    HEXADECIMAL_DIGITS[b & 0xF]
                )
            );
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// @notice Checks if a colormap exists.
    /// @dev The function reverts if the colormap corresponding to
    /// `_colormapHash` was never registered.
    /// @param _colormapHash Hash of the colormap's definition.
    function _checkColormapDoesNotExist(bytes32 _colormapHash) internal view {
        SegmentData memory segmentData = segments[_colormapHash];

        // Revert if a colormap corresponding to `colormapHash` has already
        // been set.
        if (
            // Segment data is initialized. We don't need to check `g` and `b`
            // because the segment data would've never been initialized if any
            // of `r`, `g`, or `b` were 0.
            (segmentData.r > 0) ||
            // Palette generator is initialized.
            address(paletteGenerators[_colormapHash]) != address(0)
        ) {
            revert ColormapAlreadyExists(_colormapHash);
        }
    }

    /// @notice Checks if a `uint256` corresponds to a valid segment data.
    /// @dev The function reverts if `_segmentData` is not a valid
    /// representation for a colormap.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    function _checkSegmentDataValidity(uint256 _segmentData) internal pure {
        uint256 prevPosition = (_segmentData >> 16) & 0xFF;

        // Revert if the colormap isn't defined from the start.
        if (prevPosition > 0) {
            revert SegmentDataInvalid(_segmentData);
        }

        for (
            // We shift `_segmentData` right by 24 because the first segment was
            // read already.
            uint256 partialSegmentData = _segmentData >> 24;
            partialSegmentData > 0;
            partialSegmentData >>= 24
        ) {
            uint256 position = (partialSegmentData >> 16) & 0xFF;

            // Revert if the position did not increase.
            if (position <= prevPosition) {
                revert SegmentDataInvalid(_segmentData);
            }

            prevPosition = (partialSegmentData >> 16) & 0xFF;
        }

        // Revert if the colormap isn't defined til the end.
        if (prevPosition < 0xFF) {
            revert SegmentDataInvalid(_segmentData);
        }
    }

    /// @notice Computes the hash of a colormap defined via a palette generator.
    /// @dev The function reverts if the colormap already exists.
    /// @param _paletteGenerator Palette generator for the colormap.
    /// @return bytes32 Hash of `_paletteGenerator`.
    function _computeColormapHash(IPaletteGenerator _paletteGenerator)
        internal
        view
        returns (bytes32)
    {
        // Compute hash.
        bytes32 colormapHash = keccak256(abi.encodePacked(_paletteGenerator));

        // Revert if colormap does not exist.
        _checkColormapDoesNotExist(colormapHash);

        return colormapHash;
    }

    /// @notice Computes the hash of a colormap defined via segment data.
    /// @dev The function reverts if the colormap already exists.
    /// @param _segmentData Segment data for the colormap. See
    /// {IColormapRegistry} for its representation.
    /// @return bytes32 Hash of the contents of `_segmentData`.
    function _computeColormapHash(SegmentData memory _segmentData)
        internal
        view
        returns (bytes32)
    {
        // Compute hash.
        bytes32 colormapHash = keccak256(
            abi.encodePacked(_segmentData.r, _segmentData.g, _segmentData.b)
        );

        // Revert if colormap does not exist.
        _checkColormapDoesNotExist(colormapHash);

        return colormapHash;
    }

    /// @notice Computes the value at the position `_position` along some
    /// segment data defined by `_segmentData`.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    /// @param _position Position along the colormap.
    /// @return uint8 Intensity of the color at the position in the colormap.
    function _computeLinearInterpolation(uint256 _segmentData, uint8 _position)
        internal
        pure
        returns (uint8)
    {
        // We loop until we find the segment with the greatest position less
        // than `_position`.
        while ((_segmentData >> 40) & 0xFF < _position) {
            _segmentData >>= 24;
        }

        // Retrieve the start and end of the identified segment.
        uint256 segmentStart = _segmentData & 0xFFFFFF;
        uint256 segmentEnd = (_segmentData >> 24) & 0xFFFFFF;

        // Retrieve start/end position w.r.t. the entire colormap.
        uint256 startPosition = (segmentStart >> 16) & 0xFF;
        uint256 endPosition = (segmentEnd >> 16) & 0xFF;

        // Retrieve start/end intensities.
        uint256 startIntensity = segmentStart & 0xFF;
        uint256 endIntensity = (segmentEnd >> 8) & 0xFF;

        // Compute the value with a piece-wise linear interpolation on the
        // segments.
        unchecked {
            // This will never underflow because we ensure the start segment's
            // position is less than or equal to `_position`.
            uint256 positionChange = _position - startPosition;

            // This will never be 0 because we ensure each segment must increase
            // in {ColormapRegistry.register} via
            // {ColormapRegistry._checkSegmentDataValidity}.
            uint256 segmentLength = endPosition - startPosition;

            // Check if end intensity is larger to prevent under/overflowing (as
            // well as to compute the correct value).
            if (endIntensity >= startIntensity) {
                return
                    uint8(
                        startIntensity +
                            ((endIntensity - startIntensity) * positionChange) /
                            segmentLength
                    );
            }

            return
                uint8(
                    startIntensity -
                        ((startIntensity - endIntensity) * positionChange) /
                        segmentLength
                );
        }
    }

    /// @notice Computes the value at the position `_position` along some
    /// segment data defined by `_segmentData`.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    /// @param _position 18 decimal fixed-point number in [0, 1] representing
    /// the position along the colormap.
    /// @return uint256 Intensity of the color at the position in the colormap.
    function _computeLinearInterpolationFPM(
        uint256 _segmentData,
        uint256 _position
    ) internal pure returns (uint256) {
        unchecked {
            // We need to truncate `_position` to be in [0, 0xFF] pre-scaling.
            _position = _position > 0xFF * FIXED_POINT_COLOR_VALUE_SCALAR
                ? 0xFF * FIXED_POINT_COLOR_VALUE_SCALAR
                : _position;

            // We look until we find the segment with the greatest position less
            // than `_position`.
            while (
                ((_segmentData >> 40) & 0xFF) * FIXED_POINT_COLOR_VALUE_SCALAR <
                _position
            ) {
                _segmentData >>= 24;
            }

            // Retrieve the start and end of the identified segment.
            uint256 segmentStart = _segmentData & 0xFFFFFF;
            uint256 segmentEnd = (_segmentData >> 24) & 0xFFFFFF;

            // Retrieve start/end position w.r.t. the entire colormap and
            // convert them to the 18 decimal fixed point number representation.
            uint256 startPosition = ((segmentStart >> 16) & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;
            uint256 endPosition = ((segmentEnd >> 16) & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;

            // Retrieve start/end intensities and convert them to the 18 decimal
            // fixed point number representation.
            uint256 startIntensity = (segmentStart & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;
            uint256 endIntensity = ((segmentEnd >> 8) & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;

            // This will never underflow because we ensure the start segment's
            // position is less than or equal to `_position`.
            uint256 positionChange = _position - startPosition;

            // This will never be 0 because we ensure each segment must increase
            // in {ColormapRegistry.register} via
            // {ColormapRegistry._checkSegmentDataValidity}.
            uint256 segmentLength = endPosition - startPosition;

            // Check if end intensity is larger to prevent under/overflowing (as
            // well as to compute the correct value).
            if (endIntensity >= startIntensity) {
                return
                    startIntensity +
                    ((endIntensity - startIntensity) * positionChange) /
                    segmentLength;
            }

            return
                startIntensity -
                ((startIntensity - endIntensity) * positionChange) /
                segmentLength;
        }
    }
}