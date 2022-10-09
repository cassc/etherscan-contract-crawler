// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/iEGoldMinerNFT.sol";
import "../../interfaces/iEGLDTreasury2.sol";

contract EGoldGiveAwayT1 is AccessControl {

    iEGoldMinerNFT NFT;

    iEGLDTreasury2 Treasury;

    IERC20 public BUSD;

    bytes32 public constant LAMDA_ROLE = keccak256("LAMDA_ROLE");

    mapping ( address => bool ) private isClaimed;

    struct NFTinfo{
        string uri;
        string name;
        uint256 hashRate;
        uint256 powerFactor;
        uint256 price;
        address claimer;
    }

    NFTinfo val;

    modifier isVaildClaim( address _addr  ) {
        require(isClaimed[msg.sender] == false , "EGoldGiveAwayT1 : Already Claimed by address");
        ( address parent,,,,) = Treasury.fetchUserDetails( _addr );
        require( parent != address(0) , "EGoldGiveAwayT1 : Not valid Referer");
        _;
    }

    event AirdropEvent( address _sender );

    constructor (  )AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setup( address _nft , address _treasury , address _BUSD , NFTinfo memory _info ) external onlyRole(DEFAULT_ADMIN_ROLE){
        NFT = iEGoldMinerNFT( _nft);
        Treasury = iEGLDTreasury2( _treasury);
        BUSD = IERC20( _BUSD);
        val = _info;
    }

    function Claim ( address _referer ) external isVaildClaim( _referer) {
        iAddUser( _referer);
        iTransferBUSD();
        iMint();
        isClaimed[msg.sender ] = true;
    }

    function fetchUserClaimed( address _addr  ) external view returns ( bool ){
        return isClaimed[_addr];
    }

    function iAddUser(address _addr) internal {
        Treasury.setUser(msg.sender , _addr , 1 , 0 , 0 , 0 );
    }

    function iTransferBUSD() internal {
        BUSD.transferFrom(msg.sender , val.claimer ,val.price );
    }


    function iMint() internal {
        NFT.mint(msg.sender,  val.uri , val.name , val.hashRate, val.powerFactor);
    }


}