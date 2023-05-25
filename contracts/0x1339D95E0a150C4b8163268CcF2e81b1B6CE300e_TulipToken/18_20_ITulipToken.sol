// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

interface ITulipToken {
    function setBaseURI(string memory _newURI) external;

    function setDefaultRoyalty(address _royaltyReceiver, uint96 _royaltyFeeNumerator) external;

    function isController(address _controllerAddress)
        external
        view
        returns (bool);

    function changeControllerRole(address _controller, bool _role) external;

    function setTokenWinner(address _winner) external returns (uint256);

    function claimAll() external;

    function burn(uint256 _tokenId) external;

    function recoverTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external;
}