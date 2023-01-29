// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/iEGoldMinerNFT.sol";
import "../../interfaces/iEGLDTreasury2.sol";

contract EGoldGiveAwayT3 is AccessControl , ReentrancyGuard{

    iEGoldMinerNFT NFT;

    iEGLDTreasury2 Treasury;

    bytes32 public constant LAMDA_ROLE = keccak256("LAMDA_ROLE");

    struct NFTinfo{
        string uri;
        string name;
        uint256 hashRate;
        uint256 powerFactor;
        uint256 price;
    }

    mapping ( uint256 => NFTinfo) private NFTi;

    uint256 private totalNFTMint;
    uint256 private totalHashPowerMinted;

    mapping ( address => bool ) private isMinted;


    modifier isVaildMint( address _user  ) {
        require(isMinted[_user] == false , "EGoldGiveAwayT3 : Is Invalid Mint");
        ( address p1,,,,) = Treasury.fetchUserDetails( _user );
        require( p1 != address(0) , "EGoldGiveAwayT3 : Not valid Referer");
        _;
    }

    event AirdropEvent( address _sender , uint256 _type );

    constructor (  )AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Setup Start
    function setup( address _nft , address _treasury ) external onlyRole(DEFAULT_ADMIN_ROLE){
        NFT = iEGoldMinerNFT( _nft);
        Treasury = iEGLDTreasury2( _treasury);
    }
    // Setup End


    function setMiner( uint256 _type , NFTinfo memory _nft ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NFTi[_type] = _nft;
    }
    // Setter End


    // Fetecher Start
    function fetchMiner( uint256 _type  ) external view returns ( NFTinfo memory ) {
        return NFTi[_type];
    }

    function fetchTotalNFTMinted() external view returns ( uint256 ) {
        return totalNFTMint;
    }

    function fetchTotalHashpowerMinted() external view returns ( uint256 ) {
        return totalHashPowerMinted;
    }

    // Fetecher End

    // Claim can only be done by valid referer
    function Giveaway( uint256 _type , address _user , address _ref  ) external isVaildMint( _ref) nonReentrant onlyRole(LAMDA_ROLE) {
        iAddUser( _user ,_ref);
        iMint(_user, _type);
        emit AirdropEvent( _user , _type );
        isMinted[msg.sender] = true;
    }

    function iAddUser( address _user , address _ref) internal {
        Treasury.setUser( _user , _ref , 1 , 0 , 0 , 0 );
    }

    function iMint(address _user , uint256 _type) internal {
        NFT.mint( _user,  NFTi[_type].uri , NFTi[_type].name , NFTi[_type].hashRate, NFTi[_type].powerFactor );
        totalHashPowerMinted = totalHashPowerMinted + NFTi[_type].hashRate;
        totalNFTMint = totalNFTMint + 1;
    }


}