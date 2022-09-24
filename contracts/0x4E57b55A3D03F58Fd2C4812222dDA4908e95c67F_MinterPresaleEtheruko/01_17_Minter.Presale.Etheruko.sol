//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./EtherukoGenesis.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/access/AccessControl.sol";
import "./interface/IMinterPresaleEtheruko.sol";

contract MinterPresaleEtheruko is
    Ownable,
    AccessControl,
    IMinterPresaleEtheruko
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    EtherukoGenesis public etherukoGenesis;
    address payable public feeTo;

    uint256 public presalePrice = 1000000000000000000; // 1 ETH
    uint256 public presaleAmount = 0;
    uint256 public presaleNowAmount = 0;

    constructor(EtherukoGenesis _etherukoGenesis, address payable _feeTo) {
        require(
            address(_etherukoGenesis) != address(0),
            "require: _etherukoGenesis is not zero address"
        );
        require(_feeTo != address(0));
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        setGenesis(_etherukoGenesis);
        setFeeTo(_feeTo);
    }

    function setGenesis(EtherukoGenesis _etherukoGenesis) public onlyOwner {
        require(
            address(_etherukoGenesis) != address(0),
            "require: _etherukoGenesis is not zero address"
        );
        etherukoGenesis = _etherukoGenesis;
        emit SetGenesis(address(_etherukoGenesis));
    }

    function setFeeTo(address payable _feeTo) public onlyOwner {
        require(_feeTo != address(0), "require: _feeTo is not zero address");
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function grantAdmin(address account) public onlyOwner {
        _grantRole(ADMIN_ROLE, account);
        emit GrantAdmin(account);
    }

    /** difference of initpresale vs setpresaleamount
      initpresale is for init presale amount include now amount to zero
      setpresaleamount is for set presale amount only.
     */
    function initPresale(uint256 _presaleAmount) public onlyRole(ADMIN_ROLE) {
        presaleNowAmount = 0;
        setPresaleAmount(_presaleAmount);
        emit InitPresale(_presaleAmount, presaleNowAmount);
    }

    function setPresaleAmount(uint256 _presaleAmount)
        public
        onlyRole(ADMIN_ROLE)
    {
        presaleAmount = _presaleAmount;
        emit SetPresaleAmount(_presaleAmount);
    }

    function setPresalePrice(uint256 _presalePrice)
        public
        onlyRole(ADMIN_ROLE)
    {
        presalePrice = _presalePrice;
        emit SetPresalePrice(_presalePrice);
    }

    function presaleMint() public payable {
        require(presaleNowAmount < presaleAmount, "require: presale is over");
        require(
            msg.value == presalePrice,
            "require: msg.value == presalePrice"
        );
        presaleNowAmount++;
        etherukoGenesis.safeMint(msg.sender, 1);
        feeTo.transfer(msg.value);
        emit PresaleMint(msg.sender, 1);
    }
}