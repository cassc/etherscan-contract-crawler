// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface iEGoldAuction is IAccessControl {

    //Setup Start
    function setup( uint256 _SB , uint256 _EB , uint256 _DBS, uint256 _DBE, uint256 _QTY , address _token1 , address _token2, address _Custodial ) external;
    //Setup End

    //Core Start

    function contribute( uint256 _amt ) external;

    function claim( ) external;

    //Core End

    // Fetchers Start
    function fetchStartBlock( ) external view returns( uint256 );

    function fetchEndBlock( ) external view returns( uint256 );

    function fetchDistributionStartBlock( ) external view returns( uint256 );

    function fetchDistributionEndBlock( ) external view returns( uint256 );

    function fetchQTY( ) external view returns( uint256 );

    function fetchToken1( ) external view returns( address );

    function fetchToken2( ) external view returns( address );

    function fetchCustodial( ) external view returns( address );

    function fetchContribution( address _addr) external view returns( uint256 );

    function fetchTotalContribution( ) external view returns( uint256 );

    function fetchRate( ) external view returns( uint256 );

    function fetchShare( address _addr ) external  view returns( uint256 );

    // Fetchers end

}