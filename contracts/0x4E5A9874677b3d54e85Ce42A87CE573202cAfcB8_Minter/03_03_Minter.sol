// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IERC721 {
    function mint(address to, uint quantity) external virtual;
}

contract Minter is Ownable {
    IERC721 public infinityContract;
    IERC721 public wlPass;

    bool public mintStarted;

    mapping(address => uint) public mintQuantities;

    constructor(IERC721 _infinityContract, IERC721 _wlPass) {
        infinityContract = _infinityContract;
        wlPass = _wlPass;
    }

    function setInfinityContract(IERC721 _infinityContract) public onlyOwner {
        infinityContract = _infinityContract;
    }

    function setWLPass(IERC721 _wlPass) public onlyOwner {
        wlPass = _wlPass;
    }

    function setMintStart(bool _isStarted) public onlyOwner {
        mintStarted = _isStarted;
    }

    function setMintQuantities(address[] memory _users, uint[] memory _quantities) public onlyOwner {
        require(_users.length == _quantities.length, "invalid params");
        for (uint i = 0; i < _users.length; i++) {
            mintQuantities[_users[i]] = _quantities[i];
        }
    }

    function mint() public {
        require(mintStarted, "Mint has not started");
        require(mintQuantities[msg.sender] > 0, "Not whitelisted");
        infinityContract.mint(msg.sender, mintQuantities[msg.sender]);
        wlPass.mint(msg.sender, mintQuantities[msg.sender]);
        mintQuantities[msg.sender] = 0;
    }
}