// SPDX-License-Identifier: GPL-3.0-or-later

interface IXCAmpleControllerGateway {
    function nextGlobalAmpleforthEpoch() external view returns (uint256);

    function nextGlobalAMPLSupply() external view returns (uint256);

    function mint(address recipient, uint256 xcAmplAmount) external;

    function burn(address depositor, uint256 xcAmplAmount) external;

    function reportRebase(uint256 nextGlobalAmpleforthEpoch_, uint256 nextGlobalAMPLSupply_)
        external;
}