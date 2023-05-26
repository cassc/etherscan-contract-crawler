pragma solidity 0.5.9; //0.5.9+commit.e560f70d.Emscripten.clang


import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";
import "./AirdroperRole.sol";

contract BNFToken is ERC20Pausable, ERC20Burnable, AirdroperRole {

  string public name             = "300FIT Network";
  string public symbol           = "FIT";
  uint   public decimals         = 18;

  uint   public airdropCounts ; 
  uint   public airdropAmounts ; 


  
  constructor() public
  { 
    _mint(0xC4F551FcCf5B7E5d7ECd31BBa135B989369d5fE3 ,4999980000 * 10 ** decimals );	//49.9998%
    _mint(0xf2425e64B2e25683467a720E2EcE1E9872A509d1 ,850020000	* 10 ** decimals );  //8.5002%
    _mint(0x7F795ee1274d462E3Dc3B2EAa35B765A774B990c ,825000000	* 10 ** decimals );  //8.2500%
    _mint(0x7Ca0Eb4016B0970Eac9A48F3243919d2f7dd6D0f ,825000000	* 10 ** decimals);  //8.2500%
    _mint(0x447076a45EBC9202958E0924D0Ed1FFd73D7C84a ,500000000	* 10 ** decimals);  //5.0000%
    _mint(0x777DF4745D2ddD7d50002BC6A751aB962Ff92925 ,500000000	* 10 ** decimals);  //5.0000%
    _mint(0x06903102b75d73bCe4040Ef5CCEA6613c8E64a5a ,500000000	* 10 ** decimals);  //5.0000%
    _mint(0x529f5B039eceE1788327a4D10A0f2077952D4dbf ,500000000	* 10 ** decimals);  //5.0000%
    _mint(0xc4B95e41421dEa851997321cEf76929A9E9d1278 ,500000000 * 10 ** decimals);  //5.0000%
  }   

// airdrop
  mapping (uint => mapping (address => bool) ) public airdrops; // [0|1|2|n ..] => address => [false|true]
  function airdropTokens(uint _airdropNumber, address[] memory _receiver, uint[] memory _value) public onlyAirdroper
  {
      require(_receiver.length == _value.length);
      uint airdropped;
      for(uint256 i = 0; i< _receiver.length; i++)
      {
          require(airdrops[_airdropNumber][_receiver[i]] == false);
          ERC20.transfer(_receiver[i], _value[i]);
          airdrops[_airdropNumber][_receiver[i]] = true;
          airdropped = airdropped.add(_value[i]);
      }
      airdropCounts  = airdropCounts.add(1) ;
      airdropAmounts = airdropAmounts.add(airdropped) ;
  }

}





