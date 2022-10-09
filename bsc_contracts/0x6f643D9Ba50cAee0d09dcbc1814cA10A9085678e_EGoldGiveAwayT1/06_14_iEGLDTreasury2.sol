//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

interface iEGLDTreasury2  {

    function claim(uint256 _amt) external returns (bool);

    function fetchUserDetails(address _addr)
    external
    view
    returns (
        address parent,
        uint256 level,
        uint256 sales,
        uint256 sn,
        uint256 share
    );


    function setUser( address _child, address parent, uint256 level, uint256 sales, uint256 sn, uint256 share ) external returns (bool);

}