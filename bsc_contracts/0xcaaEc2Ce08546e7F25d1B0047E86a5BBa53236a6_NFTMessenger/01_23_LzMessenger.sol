// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
pragma abicoder v2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../lz/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PowerNFT.sol";


contract NFTMessenger is NonblockingLzApp, Pausable {
    
    PowerNFT public _powerNFT;
    IERC20 public stableCoin;
    address _owner;
    // constructor requires the LayerZero endpoint for this chain
    constructor(address _endpoint, address _stableCoinAddress) NonblockingLzApp(_endpoint) {
        _owner = msg.sender;
        stableCoin = IERC20(_stableCoinAddress);
    }

    modifier isOwner {
        require(_owner == msg.sender, "Access denied");
        _;
    }

    function MintNFTOnMsg(
        uint16 _dstChainId, // send a ping to this destination chainId
        address _user, // destination address of PingPong contract
        uint256 _nftType,
        uint256 _value
    ) public payable {
        bytes memory payload = abi.encode(uint256(1), address(_user), _nftType, _value);
        uint16 version = 1;
        uint gasForDestinationLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        _lzSend(
            _dstChainId,
            payload,
            payable(msg.sender),
            address(0),
            adapterParams
        );

        SafeERC20.safeTransferFrom(stableCoin, msg.sender, address(this), _value);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        // use assembly to extract the address from the bytes memory parameter
        address sendBackToAddress;
        assembly {
            sendBackToAddress := mload(add(_srcAddress, 20))
        }

        (uint256 _msgType, address _user, uint256 _nftType, uint256 _value) = abi.decode(_payload, (uint256, address, uint256, uint256));
        if(_msgType == 1){
            uint256 price = PowerNFT(_powerNFT).getNFTPrice(_nftType);
            require(price == _value, "Invalid Payment");
            PowerNFT(_powerNFT).mint(_user, _nftType);
        }

    }

    function setPowerNFTAddress(PowerNFT _powerNFTAddress) isOwner public {
        _powerNFT = _powerNFTAddress;
    }

    function setStableCoinAddress(address _stableCoinAddress) public isOwner {
        stableCoin = IERC20(_stableCoinAddress);
    }

    function withDraw(uint256 _value) isOwner public {
        SafeERC20.safeTransfer(IERC20(stableCoin),msg.sender, _value);
    }

    // allow this contract to receive ether
    receive() external payable {}
}