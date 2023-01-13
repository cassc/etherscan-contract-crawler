// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IMultiMint.sol";
import "./Admins.sol";

// @author: miinded.com

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * possibility to lock/unlock an token to block transfer only by the owner of the token
 */
abstract contract MultiMint is IMultiMint, Admins, ReentrancyGuard {

    string[] public mintsNames;
    mapping(string => Mint) public mints;
    mapping(string => uint8) public mintNamesKey;
    mapping(uint8 => mapping(address => uint256)) balance;

    modifier canMint(string memory _name, uint256 _count) virtual {
        require(mintIsOpen(_name), "Mint not open");
        require(_count <= mints[_name].maxPerTx, "Max per tx limit");
        require(msg.value >= mintPrice(_name, _count), "Value limit");

        if(mints[_name].maxPerWallet > 0){
            require(balance[mintNamesKey[_name]][_msgSender()] + _count <= mints[_name].maxPerWallet, "Max per wallet limit");
            balance[mintNamesKey[_name]][_msgSender()] += _count;
        }

        _;
    }

    function setMint(string memory _name, Mint memory _mint) public override onlyOwnerOrAdmins{
        require(_mint.valid, "_mint.valid is missing");

        if(!mints[_name].valid){
            mintsNames.push(_name);
            mintNamesKey[_name] = uint8(mintsNames.length);
        }

        mints[_name] = _mint;
        emit EventMintChange(_name, _mint);
    }

    function pauseMint(string memory _name, bool _pause) public override onlyOwnerOrAdmins{
        mints[_name].paused = _pause;
    }

    function mintIsOpen(string memory _name) public view override returns(bool){
        return mints[_name].start > 0 && block.timestamp >= mints[_name].start && block.timestamp <= mints[_name].end && !mints[_name].paused;
    }

    function mintCurrent() public override view returns (string memory){
        for(uint256 i = 0; i < mintsNames.length; i++){
            if(mintIsOpen(mintsNames[i])){
                return mintsNames[i];
            }
        }
        return "NONE";
    }

    function mintNames() public view override returns (string[] memory){
        return mintsNames;
    }

    function mintPrice(string memory _name, uint256 _count) public view virtual override returns (uint256){
        return mints[_name].price * _count;
    }

    function mintBalance(string memory _name, address _wallet) public view override returns(uint256){
        return balance[mintNamesKey[_name]][_wallet];
    }
}