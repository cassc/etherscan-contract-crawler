pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DividendCollector is OwnableUpgradeable {
    IERC20 public asset;
    address public dividendSetter;
    address public receiver;

    event ReceiveToken(address indexed user, uint256 amount);

    function initialize (
        IERC20 _asset
    ) public initializer {
        __Ownable_init();
        asset = _asset;
    }

    function setReceiver(address _receiver) external onlyOwner {
        require(address(0) != _receiver, "INVLID_ADDR");
        receiver = _receiver;
    }

    modifier onlyReceiver {
        require(msg.sender == receiver, "ONLY_RECEIVER");
        _;
    }

    function setDividendSetter(address _setter) external onlyOwner {
        require(address(0) != _setter, "INVLID_ADDR");
        dividendSetter = _setter;
    }

    modifier onlyDividendSetter {
        require(msg.sender == dividendSetter, "ONLY_Dividend Seeter");
        _;
    }
    

    function handleReceive(uint amount) external {
        // receiver will get token by himself, no need to handle.
    }

    function receiveToken() external {
        uint256 newTokens = asset.balanceOf(address(this));
        asset.transfer(receiver, newTokens);
        emit ReceiveToken(receiver, newTokens);
    }
    
    function receiveTokens(address _asset) external {
        uint256 newTokens = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).transfer(receiver, newTokens);
        emit ReceiveToken(receiver, newTokens);
    }
}