// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Maxity is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant preMintedSupply = 1000000000 * 1e18;
    uint256 private constant maxSupply = 1000000000 * 1e18;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

    mapping(address => uint256) minterMaxSupply;
    mapping(address => uint256) minterAlreadyMinted;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, preMintedSupply);
    }

    function mint(address _to, uint256 _amount)
        external
        onlyMinter
        returns (bool)
    {
        require(_amount.add(totalSupply()) <= maxSupply);
        if (minterMaxSupply[msg.sender] > 0) {
            require(
                _amount.add(minterAlreadyMinted[msg.sender]) <=
                    minterMaxSupply[msg.sender],
                "minting limit exceeded"
            );
            minterAlreadyMinted[msg.sender] = minterAlreadyMinted[msg.sender]
                .add(_amount);
        }

        _mint(_to, _amount);
        return true;
    }

    function addMinter(address _addMinter, uint256 _maxMint)
        public
        onlyOwner
        returns (bool)
    {
        require(_addMinter != address(0), "_addMinter is the zero address");
        minterMaxSupply[_addMinter] = _maxMint;
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "_delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "Index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    function burn(address _from, uint256 _amount)
        external
        onlyOwner
        returns (bool)
    {
        _burn(_from, _amount);
        return true;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Caller is not the minter");
        _;
    }
}