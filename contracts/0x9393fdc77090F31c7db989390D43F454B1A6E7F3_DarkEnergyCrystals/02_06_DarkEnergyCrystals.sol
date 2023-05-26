pragma solidity ^0.5.8;

import "./ERC20.sol";
import "./Ownable.sol";

contract DarkEnergyCrystals is ERC20, Ownable {

    string public name = "DarkEnergyCrystals";
    string public symbol = "DEC";
    uint public decimals = 3;

    address minter;

    event SetMinter(address indexed minter);
    event LockCrystals(address indexed holder, uint256 indexed amount, string steemAddr);

    function setMinter(address _newMinter) public onlyOwner {
        minter = _newMinter;
        emit SetMinter(_newMinter);
    }

    function mint(uint256 _quantity) public onlyMinter() {
        _mint(address(this), _quantity);
    }

    function burn(uint256 _quantity) public onlyMinter() {
        _burn(address(this), _quantity);
    }

    function unlock(address _holder, uint256 _quantity) public onlyMinter() {
        _transfer(address(this), _holder, _quantity);
    }

    function lock(string memory _steemAddr, uint256 _quantity) public {
        transfer(address(this), _quantity);
        emit LockCrystals(msg.sender, _quantity, _steemAddr);
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "DarkEnergyCrystals: Not Minter");
        _;
    }
}
