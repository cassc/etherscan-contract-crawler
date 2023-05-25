pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EditableERC20 is Ownable, ERC20 {
    string public _name;
    string public _symbol;

    event NameChanged(string newName, address by);
    event SymbolChanged(string newName, address by);
    event Mint(address receiver, uint256 amount, address by);

    constructor (string memory _tempName, string memory _tempSymbol) ERC20(_name, _symbol) public {
        _name = _tempName;
        _symbol = _tempSymbol;
    }

    function setName(string memory _newName) public onlyOwner {
        _name = _newName;
        emit NameChanged(_newName, msg.sender);
    }

    function setSymbol(string memory _newSymbol) public onlyOwner {
        _symbol = _newSymbol;
        emit SymbolChanged(_newSymbol, msg.sender);
    }

    function mint(address _receiver, uint256 _amount) public onlyOwner {
        _mint(_receiver, _amount);
        emit Mint(_receiver, _amount, msg.sender);
    }

    function name() public view virtual override returns (string memory){
      return _name;
    }

    function symbol() public view virtual override returns (string memory){
      return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function burnBurned() public {
        address burned = address(1);
        _burn(burned, balanceOf(burned));
    }
}