// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface MistCoin {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract DropBox is Ownable {
    function collect(uint256 value, MistCoin mcInt) public onlyOwner {
        mcInt.transfer(owner(), value);
    }
}

contract WrappedMistCoin is ERC20 {

    event DropBoxCreated(address indexed owner);
    event Wrapped(uint256 indexed value, address indexed owner);
    event Unwrapped(uint256 indexed value, address indexed owner);

    MistCoin mcInt = MistCoin(0xf4eCEd2f682CE333f96f2D8966C613DeD8fC95DD);

    mapping(address => address) public dropBoxes;

    constructor() ERC20("Wrapped MistCoin", "WMC") {}

    function createDropBox() public {
        require(dropBoxes[msg.sender] == address(0), "Drop box already exists.");

        dropBoxes[msg.sender] = address(new DropBox());
        
        emit DropBoxCreated(msg.sender);
    }

    function wrap(uint256 value) public {
        address dropBox = dropBoxes[msg.sender];

        require(dropBox != address(0), "You must create a drop box first."); 
        require(mcInt.balanceOf(dropBox) >= value, "Not enough MistCoin in drop box.");

        DropBox(dropBox).collect(value, mcInt);
        _mint(msg.sender, value);
        
        emit Wrapped(value, msg.sender);
    }

    function unwrap(uint256 value) public {
        require(balanceOf(msg.sender) >= value, "Not enough MistCoin to unwrap.");

        mcInt.transfer(msg.sender, value);
        _burn(msg.sender, value);

        emit Unwrapped(value, msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 2;
    }
}