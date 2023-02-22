interface IWBNB {
  function deposit() external payable;
  function withdraw(uint) external ;
  function transfer(address dst, uint wad) external returns (bool);
  function balanceOf(address account) external view returns (uint);

}