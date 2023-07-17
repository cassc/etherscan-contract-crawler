import "./OmegaCoinToken.sol";

pragma solidity >=0.4.0 <0.6.0;

contract OmegaPLN is OmegaCoinToken {

  string public constant name = "Omega PLN";
  string public constant symbol = "oPLN";
  uint8 public constant decimals = 18;

  constructor() public {
      owner = msg.sender;
      totalSupply = 0;
  }

}
