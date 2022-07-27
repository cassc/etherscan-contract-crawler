// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EquitySplitter is Context {
    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _shareHolders;

    constructor() payable {
        address communityWalletAddress = 0x4A18125bd508dbb15956ca455E6c4200237b931E;
        uint256 communityWalletEquity = 400;
        _addShareHolder(communityWalletAddress, communityWalletEquity);

        address banditAddress = 0x3B2E4f122de2413Ea547440Ac2696f1c85692C57;
        _addShareHolder(banditAddress, _getEquity(350));

        address winkyAddress = 0xE076E510D4Da2133207d26090C4FDf0961efE53d;
        _addShareHolder(winkyAddress, _getEquity(200));

        address spliffyAddress = 0x856f4eB0CAb52C7470f79905E929409101143DEB;
        _addShareHolder(spliffyAddress, _getEquity(150));

        address djDabsAddress = 0xB34EbA47FFDcf33153928F3C64baAFa269059006;
        _addShareHolder(djDabsAddress, _getEquity(50));

        address vcmAddress = 0x3AC610d0Abe06609B9C13cF35CbfAe0f4D886205;
        _addShareHolder(vcmAddress, _getEquity(125));

        address tonyPAddress = 0x92bf7D200b62ea43CFE26BDAbc1779E2dC076D67;
        _addShareHolder(tonyPAddress, _getEquity(75));

        address aliasOrphanAddress = 0xE51537CA658728208aA41bfc27c04D7fdE203eE3;
        _addShareHolder(aliasOrphanAddress, _getEquity(50));

        require(_totalShares == 1000, "Equity split needs to equal 100%");
    }

    function shares(address _address) public view returns (uint256) {
        return _shares[_address];
    }

    function unreleasedShares(address _address) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased;
        return
            (totalReceived * _shares[_address]) /
            _totalShares -
            _released[_address];
    }

    function release(address payable _address) public virtual {
        require(_shares[_address] > 0, "Address is not a shareholder");

        uint256 payment = unreleasedShares(_address);

        require(payment != 0, "Shareholder is not due a payment");

        _released[_address] = _released[_address] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(_address, payment);
    }

    function _addShareHolder(address _address, uint256 _equity) private {
        require(_address != address(0), "Invalid address");
        require(_equity > 0, "Invalid equity");
        require(_shares[_address] == 0, "Account already exists");

        _shareHolders.push(_address);
        _shares[_address] = _equity;
        _totalShares = _totalShares + _equity;
    }

    function _getEquity(uint256 _equity) private pure returns (uint256) {
        uint256 totalShares = 1000;
        uint256 communityWalletEquity = 400;

        uint256 remainingEquity = totalShares - communityWalletEquity;

        return (remainingEquity * _equity) / totalShares;
    }
}