// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ETHDeposit {
    event Deposit(bytes32 consumerPubKey, uint256 tokenId, uint256 amount, bytes sig);

    address public owner;
    mapping(uint256 => address) public tokenAddresses;

    constructor() {
        owner = msg.sender;

        tokenAddresses[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        tokenAddresses[2] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        tokenAddresses[3] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        tokenAddresses[4] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; // WBTC
        tokenAddresses[5] = 0x7c9f4C87d911613Fe9ca58b579f737911AAD2D43; // WMATIC
    }

    function transferOwnership(address _newOwner) external {
        assert(msg.sender == owner);
        owner = _newOwner;
    }

    function setTokenAddress(uint256 _tokenId, address _tokenAddress) external {
        assert(msg.sender == owner);
        tokenAddresses[_tokenId] = _tokenAddress;
    }

    function deposit(bytes32 _consumerPubKey, bytes calldata _sig) external payable {
        assert(msg.value > 0);

        require(_recoverSigner(_consumerPubKey, _sig) == owner, "ConsumerFacet: Invalid signature");

        emit Deposit(_consumerPubKey, 5, msg.value, _sig);
    }

    function depositERC20(
        bytes32 _consumerPubKey,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _sig
    ) external {
        address tokenAddress = tokenAddresses[_tokenId];
        assert(tokenAddress != address(0));

        require(_recoverSigner(_consumerPubKey, _sig) == owner, "ConsumerFacet: Invalid signature");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        emit Deposit(_consumerPubKey, _tokenId, _amount, _sig);
    }

    function withdrawERC20(uint256 _tokenId) external {
        assert(msg.sender == owner);

        address tokenAddress = tokenAddresses[_tokenId];
        assert(tokenAddress != address(0));

        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function withdrawETH() external {
        assert(msg.sender == owner);

        payable(msg.sender).transfer(address(this).balance);
    }

    function _recoverSigner(bytes32 _msg, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        require(_signature.length == 65, "ConsumerFacet: Invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_msg)))
        );

        return ecrecover(prefixedHash, v, r, s);
    }
}