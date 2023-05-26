// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPixereum {
    /**************************************************************************
     * public methods
     ***************************************************************************/

    function getPixel(uint16 _pixelNumber)
        external
        view
        returns (
            address,
            string memory,
            uint256,
            bool
        );

    function getColors() external view returns (uint24[10000] memory);

    function buyPixel(
        address beneficiary,
        uint16 _pixelNumber,
        uint24 _color,
        string memory _message
    ) external payable;

    function setOwner(uint16 _pixelNumber, address _owner) external;

    function setColor(uint16 _pixelNumber, uint24 _color) external;

    function setMessage(uint16 _pixelNumber, string memory _message) external;

    function setPrice(uint16 _pixelNumber, uint256 _weiAmount) external;

    function setSaleState(uint16 _pixelNumber, bool _isSale) external;
}