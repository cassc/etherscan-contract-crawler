// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PermitLight.sol";
import "./Equity.sol";
import "./IReserve.sol";
import "./IFrankencoin.sol";

contract Frankencoin is ERC20PermitLight, IFrankencoin {

   uint256 public constant MIN_FEE = 1000 * (10**18);
   uint256 public immutable MIN_APPLICATION_PERIOD; // for example 10 days

   IReserve override public immutable reserve;
   uint256 private minterReserveE6;

   mapping (address => uint256) public minters;
   mapping (address => address) public positions;

   event MinterApplied(address indexed minter, uint256 applicationPeriod, uint256 applicationFee, string message);
   event MinterDenied(address indexed minter, string message);

   constructor(uint256 _minApplicationPeriod) ERC20(18){
      MIN_APPLICATION_PERIOD = _minApplicationPeriod;
      reserve = new Equity(this);
   }

   function name() override external pure returns (string memory){
      return "Frankencoin V1";
   }

   function symbol() override external pure returns (string memory){
      return "ZCHF";
   }

   /**
    * @notice Minting is suggested either by (1) person applying for a new original position,
    * or (2) by the minting hub when cloning a position. The minting hub has the priviledge
    * to call with zero application fee and period.
    * @param _minter             address of the position want to add to the minters
    * @param _applicationPeriod  application period in seconds
    * @param _applicationFee     application fee in parts per million
    * @param _message            message string
    */
   function suggestMinter(address _minter, uint256 _applicationPeriod, 
      uint256 _applicationFee, string calldata _message) override external 
   {
      require(_applicationPeriod >= MIN_APPLICATION_PERIOD || totalSupply() == 0, "period too short");
      require(_applicationFee >= MIN_FEE || totalSupply() == 0, "fee too low");
      require(minters[_minter] == 0, "already registered");
      _transfer(msg.sender, address(reserve), _applicationFee);
      minters[_minter] = block.timestamp + _applicationPeriod;
      emit MinterApplied(_minter, _applicationPeriod, _applicationFee, _message);
   }

   function minterReserve() public view returns (uint256) {
      return minterReserveE6 / 1000000;
   }

   function registerPosition(address _position) override external {
      require(isMinter(msg.sender), "not minter");
      positions[_position] = msg.sender;
   }

   /**
    * @notice Get reserve balance (amount of ZCHF)
    * @return ZCHF in dec18 format
    */
   function equity() public view returns (uint256) {
      uint256 balance = balanceOf(address(reserve));
      uint256 minReserve = minterReserve();
      if (balance <= minReserve){
        return 0;
      } else {
        return balance - minReserve;
      }
    }

   function denyMinter(address _minter, address[] calldata _helpers, string calldata _message) override external {
      require(block.timestamp <= minters[_minter], "too late");
      require(reserve.isQualified(msg.sender, _helpers), "not qualified");
      delete minters[_minter];
      emit MinterDenied(_minter, _message);
   }

   /**
 * @notice Mint amount of ZCHF for address _target
 * @param _target       address that receives ZCHF if it's a minter
 * @param _amount       amount ZCHF before fees and pool contribution requested
 *                      number in dec18 format
 * @param _reservePPM   reserve requirement in parts per million
 * @param _feesPPM      fees in parts per million
 */
   function mint(address _target, uint256 _amount, uint32 _reservePPM, uint32 _feesPPM) override external minterOnly {
      uint256 _minterReserveE6 = _amount * _reservePPM;
      uint256 reserveMint = (_minterReserveE6 + 999_999) / 1000_000; // make sure rounded up
      uint256 fees = (_amount * _feesPPM + 999_999) / 1000_000; // make sure rounded up
      _mint(_target, _amount - reserveMint - fees);
      _mint(address(reserve), reserveMint + fees);
      minterReserveE6 += reserveMint * 1000_000;
   }

   /**
    * @notice Mint amount of ZCHF for address _target
    * @param _target   address that receives ZCHF if it's a minter
    * @param _amount   amount in dec18 format
    */
   function mint(address _target, uint256 _amount) override external minterOnly {
      _mint(_target, _amount);
   }

   function burn(uint256 _amount) external {
      _burn(msg.sender, _amount);
   }

   function burn(uint256 amount, uint32 reservePPM) external override minterOnly {
      _burn(msg.sender, amount);
      minterReserveE6 -= amount * reservePPM;
   }

   function calculateAssignedReserve(uint256 mintedAmount, uint32 _reservePPM) public view returns (uint256) {
      uint256 theoreticalReserve = _reservePPM * mintedAmount / 1000000;
      uint256 currentReserve = balanceOf(address(reserve));
      if (currentReserve < minterReserve()){
         // not enough reserves, owner has to take a loss
         return theoreticalReserve * currentReserve / minterReserve();
      } else {
         return theoreticalReserve;
      }
   }

   function burnFrom(address payer, uint256 targetTotalBurnAmount, uint32 _reservePPM) external override minterOnly returns (uint256) {
      uint256 assigned = calculateAssignedReserve(targetTotalBurnAmount, _reservePPM);
      _transfer(address(reserve), payer, assigned); 
      _burn(payer, targetTotalBurnAmount); // and burn everything
      minterReserveE6 -= targetTotalBurnAmount * _reservePPM; // reduce reserve requirements by original ratio
      return assigned;
   }

   function burnWithReserve(uint256 _amountExcludingReserve /* 41 */, uint32 _reservePPM /* 20% */) 
      external override minterOnly returns (uint256) {
      uint256 currentReserve = balanceOf(address(reserve)); // 18, 10% below what we should have
      uint256 minterReserve_ = minterReserve(); // 20
      uint256 adjustedReservePPM = currentReserve < minterReserve_ ? _reservePPM * currentReserve / minterReserve_ : _reservePPM; // 18%
      uint256 freedAmount = _amountExcludingReserve / (1000000 - adjustedReservePPM); // 0.18 * 41 /0.82 = 50
      minterReserveE6 -= freedAmount * _reservePPM; // reduce reserve requirements by original ratio, here 10
      _transfer(address(reserve), msg.sender, freedAmount - _amountExcludingReserve); // collect 9 assigned reserve, maybe less than original reserve
      _burn(msg.sender, freedAmount); // 41
      return freedAmount;
   }

   function burn(address _owner, uint256 _amount) override external minterOnly {
      _burn(_owner, _amount);
   }

   modifier minterOnly() {
      require(isMinter(msg.sender) || isMinter(positions[msg.sender]), "not approved minter");
      _;
   }

   function notifyLoss(uint256 _amount) override external minterOnly {
      uint256 reserveLeft = balanceOf(address(reserve));
      if (reserveLeft >= _amount){
         _transfer(address(reserve), msg.sender, _amount);
      } else {
         _transfer(address(reserve), msg.sender, reserveLeft);
         _mint(msg.sender, _amount - reserveLeft);
      }
   }
   function isMinter(address _minter) override public view returns (bool){
      return minters[_minter] != 0 && block.timestamp >= minters[_minter];
   }

   function isPosition(address _position) override public view returns (address){
      return positions[_position];
   }

}

