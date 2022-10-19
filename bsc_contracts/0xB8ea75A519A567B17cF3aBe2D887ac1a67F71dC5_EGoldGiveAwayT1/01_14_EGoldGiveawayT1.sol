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

    uint256 private TotalBNBInflow;

    uint256 private cashback;

    bytes32 public constant LAMDA_ROLE = keccak256("LAMDA_ROLE");

    mapping ( address => bool ) private isMinted;

    struct NFTinfo{
        string uri;
        string name;
        uint256 hashRate;
        uint256 powerFactor;
        uint256 price;
    }

    address private beneficiary;

    mapping ( uint256 => NFTinfo) private NFTi;

    uint256 private totalNFTMint;
    uint256 private totalHashPowerMinted;

    modifier isVaildMint( address _user  ) {
        require(isMinted[_user] == false , "EGoldGiveAwayT1 : Is Invalid Mint");
        ( address parent,,,,) = Treasury.fetchUserDetails( msg.sender );
        require( parent != address(0) , "EGoldGiveAwayT1 : Not valid Referer");
        ( address p1,,,,) = Treasury.fetchUserDetails( _user );
        require( p1 == address(0) , "EGoldGiveAwayT1 : Not valid Referer");
        _;
    }

    event AirdropEvent( address _sender , uint256 _type );

    constructor (  )AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function recive() payable external {
        TotalBNBInflow = TotalBNBInflow + msg.value;
    }

    // Setup Start
    function setup( address _nft , address _treasury , address _BUSD , uint256 _cashBack ) external onlyRole(DEFAULT_ADMIN_ROLE){
        NFT = iEGoldMinerNFT( _nft);
        Treasury = iEGLDTreasury2( _treasury);
        BUSD = IERC20( _BUSD);
        cashback = _cashBack;
    }
    // Setup End

    // Setter Start
    function setBeneficiary( address _bene ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        beneficiary = _bene;
    }

    function setMiner( uint256 _type , NFTinfo memory _nft ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NFTi[_type] = _nft;
    }
    // Setter End


    // Fetecher Start
    function fetchMiner( uint256 _type  ) external view returns ( NFTinfo memory ) {
        return NFTi[_type];
    }

    function fetchBeneficiary() external view returns ( address ) {
        return beneficiary;
    }

    function fetchTotalNFTMinted() external view returns ( uint256 ) {
        return totalNFTMint;
    }

    function fetchTotalHashpowerMinted() external view returns ( uint256 ) {
        return totalHashPowerMinted;
    }

    function fetchisMinted( address _addr) external view returns ( bool ) {
        return isMinted[_addr];
    }

    function fetchTotalBNBDeposit() external view returns ( uint256 ) {
        return TotalBNBInflow;
    }

    function fetchCashback() external view returns ( uint256 ) {
        return cashback;
    }
    // Fetecher End

    // Claim can only be done by valid referer
    function Giveaway( uint256 _type , address _user  ) external isVaildMint( _user) {
        iAddUser( _user ,msg.sender);
        iTransferBUSD( _type);
        iMint(_user, _type);
        emit AirdropEvent( _user , _type );
        isMinted[msg.sender] = true;
        payable(_user).transfer(cashback);
    }

    function iAddUser( address _user , address _ref) internal {
        Treasury.setUser( _user , _ref , 1 , 0 , 0 , 0 );
    }

    function iTransferBUSD(uint256 _type) internal {
        BUSD.transferFrom(msg.sender , beneficiary ,NFTi[_type].price );
    }

    function iMint(address _user , uint256 _type) internal {
        NFT.mint( _user,  NFTi[_type].uri , NFTi[_type].name , NFTi[_type].hashRate, NFTi[_type].powerFactor );
        totalHashPowerMinted = totalHashPowerMinted + NFTi[_type].hashRate;
        totalNFTMint = totalNFTMint + 1;
    }


}