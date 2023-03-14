// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICryptoCoaster.sol";

contract Thumbnail {

    bytes constant BASE = '<path class="l1" d="M.006 0h511.993v383.997H.002C-.006 263.19.006 0 .006 0Z"/><path class="l2" d="M512 229.868s-68.63 47.607-139.47 44.655c-70.842-2.952-146.81-30.585-146.81-30.585s-106.132-43.602-151.091-43.431C29.669 200.677 0 215.187 0 215.187v230.136h512z"/><path class="l3" d="M147.137 117.002c-50.043.204-93.869 28.627-98.075 75.914v158.74l417.184 16.867s-2.445-95.713-4.414-113.525c-1.968-17.812-15.591-40.98-51.71-41.324-28.638-.273-61.043 19.505-78.653 27.137-.753-.352-20.145-16.8-42.336-39.014-22.856-22.878-32.808-36.846-52.028-52.137-17.91-14.25-47.157-32.92-89.968-32.658zm3.408 16.95c1.298-.014 2.408-.006 3.3.01 14.278.27 43.839 4.066 68.817 25.388 15.679 13.383 20.343 17.772 48.813 46.607 23.333 23.633 44.779 44.23 44.779 44.23s-59.769 36.223-141.61 33.338c-21.365-.753-53.836-6.784-77.302-26.586-12.04-10.16-35.255-32.383-33.112-57.83 5.031-59.724 66.844-64.958 86.315-65.158z"/><path class="l4" d="M0 296.545s68.63 47.607 139.47 44.655c70.842-2.953 146.81-30.585 146.81-30.585s106.132-43.602 151.091-43.432c44.96.17 74.629 14.681 74.629 14.681V512H0Z"/><path class="l3" d="M157.625 128.372h6.743v157.647h-6.743z"/><path class="l3" d="M175.378 129.993h6.743V287.64h-6.743z"/><path class="l3" d="M193.131 134.176h6.743v157.647h-6.743z"/><path class="l3" d="M210.878 147.926h6.743v141.647h-6.743z"/><path class="l3" d="M228.628 160.176h6.743v123.513h-6.743z"/><path class="l3" d="M246.378 177.744h6.743v105.945h-6.743z"/><path class="l3" d="M264.128 194.789h6.743v83.195h-6.743z"/><path class="l3" d="M281.878 213h6.743v59.523h-6.743z"/><path class="l3" d="M299.628 228.239h6.743v38.944h-6.743z"/><path class="l3" d="M68.878 157.542h6.743v83.05h-6.743z"/><path class="l3" d="M86.628 143.975h6.743v123.208h-6.743z"/><path class="l3" d="M104.378 137.463h6.743v136.232h-6.743z"/><path class="l3" d="M122.128 130.951h6.743v149.257h-6.743z"/><path class="l3" d="M139.878 128.372h6.743v155.317h-6.743z"/>';

    bytes constant SUN = '<circle cx="448.545" cy="71.741" r="38.217" style="fill:#fff"/>';

    bytes constant SNOW = '<style>.sn{fill:#fff}</style><circle class="sn" cx="208.174" cy="102.449" r="4.848"/><circle class="sn" cx="125.499" cy="36.538" r="4.848"/><circle class="sn" cx="73.118" cy="90.464" r="7.136"/><circle class="sn" cx="349.836" cy="125.563" r="5.992"/><circle class="sn" cx="428.432" cy="26.94" r="5.992"/><circle class="sn" cx="390.254" cy="92.982" r="4.619"/><circle class="sn" cx="483.828" cy="190.385" r="4.619"/><circle class="sn" cx="473.288" cy="114.821" r="4.619"/><circle class="sn" cx="337.348" cy="226.96" r="5.992"/><circle class="sn" cx="63.308" cy="206.578" r="11.942"/><circle class="sn" cx="257.836" cy="74.299" r="5.077"/><circle class="sn" cx="288.372" cy="139.537" r="5.077"/><circle class="sn" cx="207.259" cy="16.399" r="4.848"/><circle class="sn" cx="168.013" cy="68.994" r="7.365"/><circle class="sn" cx="452.046" cy="69.223" r="7.594"/><circle class="sn" cx="417.821" cy="170.136" r="4.619"/><circle class="sn" cx="102.541" cy="304.314" r="4.619"/><circle class="sn" cx="200.622" cy="139.295" r="5.077"/><circle class="sn" cx="50.95" cy="162.409" r="7.594"/><circle class="sn" cx="257.149" cy="289.195" r="5.534"/><circle class="sn" cx="406.92" cy="226.045" r="5.534"/><circle class="sn" cx="462.303" cy="217.806" r="5.534"/><circle class="sn" cx="324.433" cy="36.538" r="7.136"/><circle class="sn" cx="350.98" cy="174.755" r="7.136"/><circle class="sn" cx="126.472" cy="257.613" r="6.221"/><circle class="sn" cx="46.602" cy="42.717" r="11.942"/><circle class="sn" cx="24.424" cy="256" r="7.365"/>';

    bytes constant TREES = '<path style="fill:#97ad89" d="m473.282 208.809-3.703 21.978-3.708 21.983 2.767-.624-2.256 17.652a145.48 145.48 0 0 1 15.029 2.759l-2.895-22.644 4.081-.922-4.656-20.093zm-441.281 3.439L24.957 268.1l-5.144 40.794a82.398 82.398 0 0 0 4.218 2.275c3.654 1.814 7.361 3.515 10.959 5.435a100.553 100.553 0 0 0 6.25 3.057c1.512.68 3.031 1.33 4.558 1.976l-6.753-53.537z"/><path style="fill:#c6e9af" d="m491.066 193.394-6.209 25.508-6.205 25.509 5.608 1.209-.317 1.738-4.88 26.48a150.01 150.01 0 0 1 12.558 3.242c3.96 1.213 7.868 2.592 11.693 4.195 2.645 1.107 7.218 2.902 8.446 3.386l-2.067-18.117-3.851-33.81-3.855 33.81-.786 6.916-4.64-25.191 4.38.945-4.94-27.912zm-470.913 34.6L11.3 257.086l-8.865 29.091 6.764.688L6.1 302.758c2.887 1.739 5.775 3.48 8.688 5.181 3.065 1.792 6.103 3.658 9.285 5.23 2.256 1.12 4.524 2.207 6.78 3.315l-5.457-27.972 3.522.355-4.38-30.436zm24.488 40.38-7.41 37.993-2.37 12.142.19.095a98.76 98.76 0 0 0 6.261 3.057c2.951 1.323 5.948 2.547 8.926 3.817 3 1.194 4.667 1.87 6.012 2.392l-4.194-21.503zm468.218 25.969-.004 6.008h.692z"/>';

    bytes constant SINGLE_CHEVERON = '<path class="l2" d="M8.487 0A8.487 8.487 0 0 0 0 8.487a8.487 8.487 0 0 0 8.487 8.488 8.487 8.487 0 0 0 8.488-8.488A8.487 8.487 0 0 0 8.487 0zm0 5.095c.114 0 .212.041.295.124l4.865 4.858a.407.407 0 0 1 .125.299.407.407 0 0 1-.125.298l-1.088 1.081a.404.404 0 0 1-.295.125.404.404 0 0 1-.295-.125l-3.482-3.48-3.48 3.48a.404.404 0 0 1-.296.125.404.404 0 0 1-.295-.125l-1.088-1.081a.407.407 0 0 1-.125-.298c0-.116.042-.216.125-.299L8.192 5.22a.403.403 0 0 1 .295-.124z"/>';

    bytes constant DOUBLE_CHEVERON = '<path class="l2" d="M0 8.487A8.487 8.487 0 0 0-8.487 0a8.487 8.487 0 0 0-8.488 8.487 8.487 8.487 0 0 0 8.488 8.488A8.487 8.487 0 0 0 0 8.487zm-3.664 0c0 .09-.033.167-.098.232l-3.816 3.821a.32.32 0 0 1-.234.098.32.32 0 0 1-.235-.098l-.85-.855a.316.316 0 0 1-.097-.231c0-.09.033-.167.098-.232l2.735-2.735-2.735-2.734a.316.316 0 0 1-.098-.231c0-.09.033-.167.098-.232l.85-.855a.32.32 0 0 1 .234-.098c.091 0 .169.033.234.098l3.816 3.82a.316.316 0 0 1 .098.232zm-4.317 0c0 .09-.033.167-.098.232l-3.816 3.821a.32.32 0 0 1-.234.098.319.319 0 0 1-.234-.098l-.85-.855a.316.316 0 0 1-.098-.231c0-.09.033-.167.098-.232l2.735-2.735-2.735-2.734a.316.316 0 0 1-.098-.231c0-.09.033-.167.098-.232l.85-.855a.319.319 0 0 1 .234-.098c.091 0 .169.033.234.098l3.816 3.82a.317.317 0 0 1 .098.232z" transform="rotate(-90)"/>';

    bytes constant FACING = '<path class="l2" d="M8.487 0A8.487 8.487 0 0 0 0 8.487a8.487 8.487 0 0 0 8.487 8.488 8.487 8.487 0 0 0 8.488-8.488A8.487 8.487 0 0 0 8.487 0zm1.48 4.337c.092 0 .17.033.235.098l3.816 3.82a.316.316 0 0 1 .097.232c0 .09-.032.167-.097.232l-3.816 3.821a.32.32 0 0 1-.234.098.32.32 0 0 1-.235-.098l-.85-.855a.316.316 0 0 1-.097-.231c0-.09.032-.167.098-.232l2.734-2.735-2.734-2.734a.316.316 0 0 1-.098-.231c0-.09.032-.167.098-.232l.85-.855a.32.32 0 0 1 .234-.098zm-4.579.9a1.445 1.445 0 0 1 0 2.89A1.445 1.445 0 0 1 3.943 6.68a1.445 1.445 0 0 1 1.445-1.445zm0 3.612a2.529 2.529 0 0 1 2.529 2.529.361.361 0 0 1-.361.36H3.22a.361.361 0 0 1-.36-.36 2.529 2.529 0 0 1 2.528-2.529z"/>';

    bytes constant WANG = '<path class="l2" d="M348.918 441.374a32.079 32.079 0 0 0-32.079 32.078 32.079 32.079 0 0 0 32.079 32.08 32.079 32.079 0 0 0 32.08-32.08 32.079 32.079 0 0 0-32.08-32.078zm-12.29 13.642h24.58a2.048 2.048 0 0 1 2.05 2.05 14.339 14.339 0 0 1-28.678 0 2.048 2.048 0 0 1 2.049-2.05zm12.29 20.485a8.193 8.193 0 0 1 8.193 8.193 8.193 8.193 0 1 1-8.193-8.193z" transform="matrix(.26458 0 0 .26458 -83.83 -116.78)"/>';

    bytes constant TRACK = '<path class="trackColor" d="M8.487 0A8.487 8.487 0 0 0 0 8.487a8.487 8.487 0 0 0 8.487 8.488 8.487 8.487 0 0 0 8.488-8.488A8.487 8.487 0 0 0 8.487 0zM5.188 3.312h1.5a.44.44 0 0 1 .442.441v.307h2.715v-.307a.44.44 0 0 1 .441-.441h1.5a.44.44 0 0 1 .442.441v9.468a.44.44 0 0 1-.441.442h-1.5a.44.44 0 0 1-.442-.442v-.367H7.13v.367a.44.44 0 0 1-.442.442h-1.5a.44.44 0 0 1-.441-.442V3.753a.44.44 0 0 1 .441-.441zm1.942 2.1V6.54h2.715V5.413H7.13zm0 2.481V9.02h2.715V7.893H7.13zm0 2.48v1.128h2.715v-1.127H7.13z"/>';

    /**
     * @dev Array order
     *      0. Snow
     *      1. Forest
     *      2. Desert
     */
    string[3] STYLES = [
        '<style>.l1{fill:#d9eaf1}.l2{fill:#8b9a9f}.l3{fill:#bfd3da}.l4{fill:#ffffff}</style>',
        '<style>.l1{fill:#f2fee8}.l2{fill:#615f60}.l3{fill:#9bac8c}.l4{fill:#cce8b5}</style>',
        '<style>.l1{fill:#fea}.l2{fill:#ffc460}.l3{fill:#cca066}.l4{fill:#ffffda}</style>'
    ];

    /**
     * @notice Build the SVG thumbnail
     * @param settings - Track settings struct
     * @return final svg as bytes
     */
    function buildThumbnail(Settings calldata settings) external view returns(bytes memory) {

        // Default to SNOW
        bytes memory biomeExtra = SNOW;
        if (settings.biomeIDX == 1) biomeExtra = TREES;
        else if (settings.biomeIDX == 2) biomeExtra = SUN;

        return abi.encodePacked(
            '<svg preserveAspectRatio="xMidYMid meet" width="100%" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">',
            STYLES[settings.biomeIDX],
            BASE,
            biomeExtra,
            addIcons(settings),
            '</svg>'
        );
    }

    /**
     * @notice Pack att the icons into SVGs
     * @param settings - Track settings struct
     * @return icons as bytes
     */
    function addIcons(Settings memory settings) internal pure returns(bytes memory) {
        return abi.encodePacked(
            '<svg x="20px" y="446"><g transform="scale(3, 3)">',
            '<svg x="0">', buildSize(settings.scale), '</svg>',
            '<svg x="20">', buildTrackColor(settings.color.iconHex), '</svg>',
            '<svg x="40">', buildSpeed(settings.speed), '</svg>',
            '<svg x="60">', buildFacing(settings.flip), '</svg>',
            '</g></svg>'
        );
    }

    /**
     * @notice Handle track color styling for SVG
     * @param colorHex - Color settings
     * @return track color icon path with styling as bytes
     */
    function buildTrackColor(string memory colorHex) internal pure returns(bytes memory) {
        return abi.encodePacked(
            '<style>.trackColor{fill:', colorHex, '}</style>',
            TRACK
        );
    }

    /**
     * @notice Handle train orientation styling for SVG
     * @param flip - Train orientation settings
     * @return train orientation icon path with styling as bytes
     */
    function buildFacing(uint256 flip) internal pure returns(bytes memory) {
        if (flip == 1) {
            return abi.encodePacked(
                '<g transform="scale(-1,1) translate(-16.975,0)">',
                FACING,
                '</g>'
            );
        }

        if (flip == 2) return WANG;

        return FACING;
    }

    /**
     * @notice Handle world scale styling for SVG
     * @param scale - Scale settings
     * @return world scale icon path with styling as bytes
     */
    function buildSize(uint256 scale) internal pure returns(bytes memory) {
        return (scale == 1) ? SINGLE_CHEVERON : DOUBLE_CHEVERON;
    }

    /**
     * @notice Handle train speed styling for SVG
     * @param speed - Speed settings
     * @return train speed icon path with styling as bytes
     */
    function buildSpeed(uint256 speed) internal pure returns(bytes memory) {
        bytes memory icon = (speed == 1) ? SINGLE_CHEVERON : DOUBLE_CHEVERON;
        return abi.encodePacked(
            '<g transform="rotate(90 8.4875 8.4875)">',
            icon,
            '</g>'
        );
    }
}