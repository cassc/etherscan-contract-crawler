// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BlackList is Ownable {

    mapping (address => bool) public isBlackListed;

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

}

contract KOLOToken is ERC20, BlackList {

    string private constant _name = "KOLO Music";
    string private constant _symbol = "KOLO";
    uint8 private constant _decimals = 6;

    uint256 private constant INITIAL_SUPPLY = 10 * (10 ** 8) * (10 ** uint256(_decimals));

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    constructor(address to) ERC20(_name, _symbol) {
        _mint(to, INITIAL_SUPPLY);
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount) public onlyPayloadSize(2 * 32) override returns (bool) {
        require(!isBlackListed[msg.sender], "This address is in the blacklist");

        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender,address recipient,uint256 amount) public onlyPayloadSize(3 * 32) override returns (bool) {
        require(!isBlackListed[sender], "From address is in the blacklist");
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public onlyPayloadSize(2 * 32) override returns (bool) {

        return super.approve(spender, amount);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);

        _burn(_blackListedUser, dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

}