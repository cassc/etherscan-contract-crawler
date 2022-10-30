// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/access/Ownable.sol";


abstract contract BetaTestable is Ownable {

    bool public inBetaMode = true; //TODO

    mapping( address => bool) public isBetaTester;


    event BetaModeChanged( bool indexed inBetaMode, bool indexed oldBetaMode);

    event SetBetaTester( address indexed testerAddress, bool indexed isBetaTester);


    modifier onlyValidBetaTester() {
        require( _isValidBetaTester(), "not a valid beta tester");
        _;
    }

    function _isValidBetaTester() private view returns(bool) {
        if( !inBetaMode) {
            return true; // not in beta mode - allow all in
        }

        return isBetaTester[ msg.sender];
    }


    /*
     * @title setBetaMode()
     *
     * @dev Set beta mode flag. When in beta mode only beta users are allowed as project teams
     *
     * @event: BetaModeChanged
     */
    function setBetaMode(bool inBetaMode_) external onlyOwner { //@PUBFUNC
        bool oldMode = inBetaMode;
        inBetaMode = inBetaMode_;
        emit BetaModeChanged( inBetaMode, oldMode);
    }

    /*
     * @title setBetaTester()
     *
     * @dev Set a beta tester boolean flag. This call allows both approving and disapproving a beta tester address
     *
     * @event: SetBetaTester
     */
    function setBetaTester(address testerAddress, bool isBetaTester_) external onlyOwner { //@PUBFUNC
        //require( inBetaMode); -- not needed
        isBetaTester[ testerAddress] = isBetaTester_;
        emit SetBetaTester( testerAddress, isBetaTester_);
    }

}