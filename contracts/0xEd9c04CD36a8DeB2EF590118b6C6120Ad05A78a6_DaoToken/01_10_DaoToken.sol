///SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./dao.sol";
contract DaoToken is ERC20, Ownable {

  using SafeERC20 for IERC20Metadata;

  LockingDAO public dao;
  address public multisig;
  IERC20Metadata public stablecoin;
  uint256 public mintOpenUntilTimestamp;
  uint256 public mintOpenFromTimestamp;
  uint8 private _decimals;

  uint256 public maxSupply;


    constructor(
        string memory _name,
        string memory _symbol,
        address _dao,
        address _stablecoin,
        uint256 _maxSupply
    ) ERC20(_name, _symbol) {
        dao = LockingDAO(_dao);
        multisig = address(dao.multisig());
        stablecoin = IERC20Metadata(_stablecoin);
        _decimals = stablecoin.decimals();
        maxSupply = _maxSupply * 10**_decimals;
    }

    function decimals() public view override returns (uint8){
      return _decimals;
    }

    function setMintingTimestamp(uint256 _mintOpenFromTimestamp, uint256 _mintOpenUntilTimestamp) public onlyOwner {
      require(mintOpenFromTimestamp == 0 && mintOpenUntilTimestamp == 0, "Minting timestamps already set");
      mintOpenFromTimestamp = _mintOpenFromTimestamp;
      mintOpenUntilTimestamp = _mintOpenUntilTimestamp;
    }

    function setNewStablecoin(address _newToken) public onlyOwner {
      uint256 intMaxSupply = maxSupply / 10**_decimals;

      // set new stablecoin address
      stablecoin = IERC20Metadata(_newToken);

      // extra configs
      _decimals = stablecoin.decimals();
      maxSupply = intMaxSupply * 10**_decimals; // this will keep the "real" amount of max supply the same
    }

    function lockToVote(address _user, uint256 _amount) public {
      require(msg.sender == address(dao), "Only DAO contract can lock tokens for voting");
      _transfer(_user, msg.sender, _amount); // we transfer to the multisig to keep max suppy constant and not burning
    }

    function mint(uint256 _amount) public {
      require(block.timestamp <= mintOpenUntilTimestamp && block.timestamp >= mintOpenFromTimestamp , "Minting not open");
      
      //require(totalSupply() + _amount <= maxSupply, "max supply reached");

      uint256 stableAmount = _amount  / 1000; //  RATIO TO BE 1000 tokens : 1 stablecoin
      stablecoin.safeTransferFrom(msg.sender, multisig, stableAmount); 
      _mint(msg.sender, _amount);
    }

    function burn(uint256 _amount) public {
      uint256 transferAmount = stablecoin.balanceOf(multisig) * _amount / totalSupply(); // proportional to total supply of tokens
      _burn(msg.sender, _amount);
      stablecoin.safeTransferFrom(multisig, msg.sender, transferAmount);
    }

    function transfer(address to, uint256 amount) public override returns(bool) {
      
      // If tokens are transfered to the contract, automatic burn
      if(to == address(this)) {
        burn(amount);
      } else {
        _transfer(msg.sender, to, amount);
      }
      return true;
    }

    

}