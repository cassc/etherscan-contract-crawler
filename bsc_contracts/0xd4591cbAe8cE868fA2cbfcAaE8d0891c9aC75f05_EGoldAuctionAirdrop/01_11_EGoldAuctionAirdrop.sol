// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/iEGoldAuction.sol";
import "../../interfaces/iEGoldToken.sol";

contract EGoldAuctionAirdrop is AccessControl {
    using SafeMath for uint256;

    bool public isON;

    iEGoldAuction Auction;

    iEGoldToken Token;

    address private custodian;

    uint256 private StartBlock;

    uint256 private EndBlock;

    mapping ( address => uint256 ) private dispatched;

    modifier isInActive( ){
        require(isON == false ,"EGold Auction : NOT ACTIVE");
        _;
    }

    modifier isActive( ){
        require(isON == true ,"EGold Auction : NOT ACTIVE");
        _;
    }

    event claimEvent( address indexed _addr , uint256 _amt );

    // Setup Start
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        isON = false;
    }

    function setup( uint256 _sb , uint256 _eb , address _token , address _auction, address _custodian ) external onlyRole(DEFAULT_ADMIN_ROLE) isInActive {
        StartBlock = _sb;
        EndBlock = _eb;
        Auction = iEGoldAuction(_auction);
        Token = iEGoldToken(_token);
        custodian = _custodian;
        isON = true;
    }
    // Setup end

    //Core Start
    function Claim ( ) external isActive {
        uint256 given = dispatched[msg.sender];
        uint256 dispatch = ifetchDispatch(msg.sender);
        Token.transferFrom(custodian , msg.sender , dispatch);
        dispatched[msg.sender ] = given.add( dispatch);
        emit claimEvent( msg.sender , dispatch );
    }

    //Core End

    // Fetchers Start
    function ifetchDispatch (address _addr ) internal view returns ( uint256 ){
        uint256 contrib = Auction.fetchContribution(_addr );
        uint256 TotalDiff = EndBlock.sub(StartBlock);
        uint256 currentDiff;
        uint256 dispatch;
        if ( EndBlock < block.number ){
            currentDiff = block.number.sub(StartBlock);
            dispatch = ((contrib.mul(currentDiff)).div(TotalDiff)).sub(dispatched[_addr]);
        }else{
            dispatch = contrib.sub(dispatched[_addr]);
        }
        return dispatch;
    }

    function fetchDispatch (address _addr ) external view returns ( uint256 ){
        return ifetchDispatch(_addr);
    }

    function fetchDispatched( address _addr ) external view returns( uint256 ){
        return dispatched[_addr];
    }

    function fetchStartBlock( ) external view returns( uint256 ){
        return StartBlock;
    }

    function fetchEndBlock( ) external view returns( uint256 ){
        return EndBlock;
    }

    function fetchToken( ) external view returns( address ){
        return address(Token);
    }

    function fetchAuction( ) external view returns( address ){
        return address(Auction);
    }

    function fetchCustodian( ) external view returns( address ){
        return custodian;
    }

    // Fetchers end

}