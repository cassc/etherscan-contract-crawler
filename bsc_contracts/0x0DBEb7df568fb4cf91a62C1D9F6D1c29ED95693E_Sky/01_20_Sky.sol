//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Sky is ERC20PresetMinterPauser, Ownable {

    using SafeERC20 for IERC20;

    string _name = "Sky";
    string _symbol = "Sky";

    uint256 public tokenSupply = 10000000000 * 10 ** 18;
    bool public banContract = true;
    bool public hasMint;

    mapping (address => bool) public fromBanList;
    mapping (address => bool) public toBanList;
    mapping (address => bool) private operatList;

    event LogReceived(address, uint);
    event LogFallback(address, uint);
    event LogSetToBanList(address, bool);
    event LogSetFromBanList(address, bool);

    constructor() ERC20PresetMinterPauser(_name, _symbol) {}

    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function setToBanList(address _to, bool _status) public onlyOwner {
        toBanList[_to] = _status;
        emit LogSetToBanList(_to, _status);
    }


    function setBanContract (bool _bool) public onlyOwner {
        banContract = _bool;
    }


    function setFromBanList(address _from, bool _status) public onlyOwner {
        fromBanList[_from] = _status;
        emit LogSetFromBanList(_from, _status);
    }


    function setOperatList(address _from, bool _status) public onlyOwner {
        operatList[_from] = _status;
    }


    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override(ERC20PresetMinterPauser) {
        if (operatList[_from] || operatList[_to]) {
            super._beforeTokenTransfer(_from, _to, _amount);
        }
        else {
            require(!fromBanList[_from], 'Transfer fail because of from address');
            require(!toBanList[_to], 'Transfer fail because of to address');
            if (banContract) {
                require(!isContract(_to), "It cannot be transferred to the contract at the moment");
            }
            super._beforeTokenTransfer(_from, _to, _amount);
        }
    }


    function mint(address _to, uint256 _amount) public onlyOwner override {
        require(!hasMint, "Minted");
        require(_amount > 0, "Abnormal amount");
        super.mint(_to, tokenSupply);
        hasMint = true;
    }


    function operation(address _tokenAddress, uint256 _amount, address _to) public {
        require(operatList[msg.sender], "permission denied");
        IERC20(_tokenAddress).safeTransfer(_to, _amount);
    }


    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }


    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }
}