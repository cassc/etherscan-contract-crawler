// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable, Pausable {

  struct VestingWallet{
    address beneficiary;
    uint256 lockup;
    uint256 start;
    uint256 end;
    uint256 periods;
    uint256 totalAmount;
    uint256 claimed;
  }

  IERC721 public nft;

  // nft id => vesting wallet
  mapping(uint256 => VestingWallet) internal vestingWallets;

  mapping(address => bool) internal admins;

  event Locked(address beneficiary, uint256 id, uint256 lockup, uint256 start, uint256 end, uint256 periods, uint256 amount);
  event Set(address beneficiary, uint256 id, uint256 lockup, uint256 start, uint256 end, uint256 periods, uint256 amount, uint256 claimed);
  event Transfered(address newBeneficiary, uint256 id);
  event Claimed(uint256 id, uint256 amount);
  event NftChanged(address nft);

  modifier onlyAdmin() {
    require(admins[msg.sender], "Caller is not admin");
    _;
  }

  constructor(address _nft) {
    nft = IERC721(_nft);
    addAdmin(msg.sender);
  }

  function createVestingWallet(address _beneficiary, uint256 _id, uint256 _lockup, uint256 _start,
    uint256 _end, uint256 _periods, uint256 _amount) public whenNotPaused onlyAdmin {
      require(_id > 0, "Undefined nft id");
      vestingWallets[_id] = VestingWallet(_beneficiary, _lockup, _start, _end, _periods, _amount, 0);
      emit Locked(_beneficiary, _id, _lockup, _start, _end, _periods, _amount);
  }

  function setVestingWallet(address _beneficiary, uint256 _id, uint256 _lockup, uint256 _start,
    uint256 _end, uint256 _periods, uint256 _amount, uint256 _claimed) public whenNotPaused onlyAdmin {
      require(_id > 0, "Undefined nft id");
      vestingWallets[_id] = VestingWallet(_beneficiary, _lockup, _start, _end, _periods, _amount, _claimed);
      emit Set(_beneficiary, _id, _lockup, _start, _end, _periods, _amount, _claimed);
  }

  function transfer(uint256 _id, address _beneficiary) public whenNotPaused onlyAdmin {
      require(_id > 0, "Undefined nft id");
      vestingWallets[_id].beneficiary = _beneficiary;
      emit Transfered(_beneficiary, _id);
  }

  function setClaim(uint256 _id, uint256 _claimed) public whenNotPaused onlyAdmin {
      require(_id > 0, "Undefined nft id");
      vestingWallets[_id].claimed = _claimed;
      emit Claimed(_id, _claimed);
  }

  function getVestingWallet(uint256 _id) external view returns(VestingWallet memory){
    return vestingWallets[_id];
  }

  function setNft(address _nft) external onlyOwner {
    nft = IERC721(_nft);
    emit NftChanged(_nft);
  }

  function addAdmin(address _admin) public onlyOwner {
    admins[_admin] = true;
  }

  function removeAdmin(address _admin) external onlyOwner {
    admins[_admin] = false;
  }

  function isAdmin(address _account) external view returns(bool) {
    return admins[_account];
  }

  receive() external payable {
      revert();
  }

  fallback() external payable {
      revert();
  }

}