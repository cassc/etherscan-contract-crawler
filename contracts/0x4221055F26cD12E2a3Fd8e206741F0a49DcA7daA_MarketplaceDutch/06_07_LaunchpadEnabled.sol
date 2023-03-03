//SPDX-License-Identifier: MIT
/**
 * @dev @brougkr
 */
pragma solidity 0.8.17;
abstract contract LaunchpadEnabled
{
    /**
     * @dev The Launchpad Address
     */
    address public _LAUNCHPAD = 0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700;

    /**
     * @dev Overrides The Launchpad Address
     */
    function _____OverrideLaunchpadAddress(address NewAddress) internal { _LAUNCHPAD = NewAddress; }

    /**
     * @dev Updates The Launchpad Address From Launchpad (batch upgrade)
     */ 
    function _____NewLaunchpadAddress(address NewAddress) external onlyLaunchpad { _LAUNCHPAD = NewAddress; }

    /**
     * @dev Access Control Needed For A Contract To Be Able To Use The Launchpad
    */
    modifier onlyLaunchpad()
    {
        require(_LAUNCHPAD == msg.sender, "onlyLaunchpad: Caller Is Not Launchpad");
        _;
    }
}