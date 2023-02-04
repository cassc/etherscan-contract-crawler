// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./token/WERC20.sol";
import "./utils/Utils.sol";
import "./HavahMitter.sol";

contract HavahMitterFT is HavahMitter {

    using SafeMath for uint256;
    using Strings for address;

    event TransferFT(
        string messageId,
        uint16 originChain,
        string originToken,
        uint16 fromChain,
        address fromToken,
        uint16 toChain, 
        uint256 amount,
        uint256 commission,
        uint256 targetChainFee,
        address sender,
        string recipient
    );

    event ReceiveFT(
        string messageId,
        uint16 originChain,
        string originToken,
        uint16 fromChain,
        string fromToken,
        uint256 amount,  
        address toToken,
        string sender,
        address recipient
    );

    event WrappedTokenRegistered(address wrappedToken, uint16 originChain, string originToken);

    event WrappedTokenUpgraded(uint16 originChain, string originToken, address oldFT, address newFT);

    event Deposit(address indexed from, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint16 chainId_) public initializer {
        __HavahMitter_init(chainId_);
    }

    function transferFT(
        string memory messageId,
        uint256 expires,
        uint16 fromChain,
        address fromToken, 
        uint16 toChain,
        uint256 amount,
        uint256 commission,
        uint256 targetChainFee,
        string memory recipient,
        bytes memory signature
    ) external payable {

        _checkBaseRequirement(messageId, expires, fromChain);
        string memory fromTokenStr = Strings.toHexString(fromToken);
        _verify(
            abi.encodePacked(
                messageId,
                "|",
                Strings.toString(expires),
                "|",
                Strings.toString(fromChain),
                "|",
                fromTokenStr,
                "|",
                Strings.toString(toChain),
                "|",
                Strings.toString(amount),
                "|",                
                Strings.toString(commission),
                "|",
                Strings.toString(targetChainFee),
                "|",
                recipient
            ),
            signature
        );

        _setCompleted(messageId);

        OriginInfo memory originInfo = _transfer(fromToken, fromTokenStr, amount, commission.add(targetChainFee));        

        emit TransferFT(
            messageId,
            originInfo.chainId,
            originInfo.token,
            fromChain,
            fromToken,
            toChain,
            amount,
            commission,
            targetChainFee,
            _msgSender(),
            recipient
        );
    }

    function receiveFT(
        string memory messageId,
        uint256 expires,
        uint16 originChain,
        string memory originToken,
        uint16 fromChain,
        string memory fromToken,
        uint16 toChain,
        uint256 amount,
        string memory sender,
        address recipient,
        bytes memory signature
    ) external {

        _checkBaseRequirement(messageId, expires, toChain);
        _verify(
            abi.encodePacked(
                messageId,
                "|",
                Strings.toString(expires),
                "|",
                Strings.toString(originChain),
                "|",
                originToken,
                "|",
                Strings.toString(fromChain),
                "|",
                fromToken,
                "|",
                Strings.toString(toChain),
                "|",
                sender,                    
                "|",
                abi.encodePacked(
                    Strings.toString(amount),
                    "|",
                    Strings.toHexString(recipient)
                )
            ),
            signature
        );

        _setCompleted(messageId);

        address token = _receive(originChain, originToken, amount, recipient);

        emit ReceiveFT(messageId, originChain, originToken, fromChain, fromToken, amount, token, sender, recipient);
    }

    function registerWrappedFT(uint16 originChain, string memory originToken, address wrappedToken) public onlyAdmin {

        _registerTokenInfo(originChain, originToken, wrappedToken);

        emit WrappedTokenRegistered(wrappedToken, originChain, originToken);
    }

    function upgradeWrappedFT(uint16 originChain, string memory originToken, address oldFT, address newFT) public onlyAdmin {

        _upgradeTokenInfo(originChain, originToken, oldFT, newFT);

        emit WrappedTokenUpgraded(originChain, originToken, oldFT, newFT);
    }

    function wrappedFT(uint16 originChain, string memory originToken) external view returns (address) {
        return _getTokenInfo(originChain, originToken).wrappedToken;        
    }

    function deposit() external payable {

        emit Deposit(_msgSender(), msg.value);
    }

    function _transfer(address fromToken, string memory fromTokenStr, uint256 amount, uint256 fee) private returns (OriginInfo memory) {
        require(amount > fee, "amount should be bigger than fee");

        TokenInfo memory tokenInfo = _getTokenInfo(fromToken);

        if (tokenInfo.wrappedToken != address(0)) {
            require(msg.value == 0, "ether must be 0");
            require(IERC20(fromToken).balanceOf(_msgSender()) >= amount, "not enough balance");

            SafeERC20.safeTransferFrom(IERC20(fromToken), _msgSender(), treasury(), fee);
            WERC20(fromToken).burnFrom(_msgSender(), amount.sub(fee));

            return OriginInfo(tokenInfo.originChainId, tokenInfo.originToken);
        } 
        else {            
            if (fromToken == address(0)) {
                require(msg.value == amount, "check ether amount");

                AddressUpgradeable.sendValue(payable(treasury()), fee);
            } else {
                require(msg.value == 0, "ether must be 0");
                require(IERC20(fromToken).balanceOf(_msgSender()) >= amount, "not enough balance");

                SafeERC20.safeTransferFrom(IERC20(fromToken), _msgSender(), treasury(), fee);
                SafeERC20.safeTransferFrom(IERC20(fromToken), _msgSender(), address(this), amount.sub(fee));
            }
            return OriginInfo(chainId(), fromTokenStr);
        }
    }

    function _receive(uint16 originChain, string memory originToken, uint256 amount, address recipient) private returns (address) {
        if(originChain == chainId()) {
            address token = Utils.parseAddr(originToken);
            if (token == address(0)) {
                require(address(this).balance >= amount, "not enough ether balance");

                AddressUpgradeable.sendValue(payable(recipient), amount);
            } else {                
                require(IERC20(token).balanceOf(address(this)) >= amount, "not enough token balance");

                SafeERC20.safeTransfer(IERC20(token), recipient, amount);
            }

            return token;
        } else {
            TokenInfo memory tokenInfo = _getTokenInfo(originChain, originToken);
            require(tokenInfo.wrappedToken != address(0), "token has not been registered");

            WERC20(tokenInfo.wrappedToken).mint(recipient, amount);

            return tokenInfo.wrappedToken;
        }
    }

}