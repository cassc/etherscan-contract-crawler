// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface MEMEINU {
    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address account, uint256 amount) external;
}

contract MEME is ERC20, ERC20Capped, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 private _swapPrice;
    address payable private _treassurey;

    address public constant ADDR_MEMEOG =
        0xD5525D397898e5502075Ea5E830d8914f6F0affe; //meme og address
    address public constant ADDR_MEMEINU =
        0x74B988156925937bD4E082f0eD7429Da8eAea8Db; //meme inu address

    uint256 public constant MEMEOG_SUPPLY = 1035510357683; //will be set after snapshot
    IERC20 public memeOg = IERC20(ADDR_MEMEOG);
    MEMEINU public memeInu = MEMEINU(ADDR_MEMEINU);

    address public cSigner;
    mapping(address => uint256) public memeInuSwapped;
    mapping(address => uint256) public memeOGSwapped;

    //event
    event Swap(address sender, uint256 amount, uint256 received);

    constructor(address _signer)
        ERC20("MEME", "MEME")
        ERC20Capped(28000 * (10**uint256(18)))
    {
        cSigner = _signer;
        ERC20._mint(address(this), MEMEOG_SUPPLY * (10**uint256(10)));
    }

    function _swapInu(
        address _sender,
        uint256 _swapAmount,
        uint256 _maxAmount,
        bytes memory _sig
    ) private {
        require(_signerAddress(_sig, _maxAmount) == cSigner, "invalid signer");
        require(
            memeInu.balanceOf(_sender) >= _swapAmount,
            "swap amount exceeds balance"
        );
        uint256 swappedAmount = memeInuSwapped[_sender].add(_swapAmount);
        require(swappedAmount <= _maxAmount, "swapped amount exceeds");
        //burn inu
        memeInu.burnFrom(_sender, _swapAmount);
        //mint newtoken
        uint256 amountAfterSwap = _swapAmount / (10**uint256(5));
        _mint(_sender, amountAfterSwap);
        memeInuSwapped[_sender] = swappedAmount;

        emit Swap(_sender, _swapAmount, amountAfterSwap);
    }

    function _swapOG(address _sender, uint256 _swapAmount) private {
        require(
            memeOg.balanceOf(_sender) >= _swapAmount,
            "swap amount exceeds balance"
        );
        //transfer meme og to contract
        memeOg.transferFrom(_sender, address(this), _swapAmount);
        memeOGSwapped[_sender] = memeOGSwapped[_sender].add(_swapAmount);
        //transfer newtoken to the sender
        uint256 amountToSwap = _swapAmount * (10**uint256(10));
        _transfer(address(this), _sender, amountToSwap);

        emit Swap(_sender, _swapAmount, amountToSwap);
    }

    function swap(
        bool _isInu,
        uint256 _swapAmount,
        uint256 _maxAmount,
        bytes memory _sig
    ) public payable nonReentrant {
        require(msg.value == _swapPrice, "invalid swapPrice");
        require(_msgSender() != address(0), "swap from the zero address");

        if (msg.value > 0 && _treassurey != address(0))
            _treassurey.transfer(msg.value);

        _isInu
            ? _swapInu(_msgSender(), _swapAmount, _maxAmount, _sig)
            : _swapOG(_msgSender(), _swapAmount);
    }

    function swapBack(uint256 _swapAmount) public payable nonReentrant {
        require(msg.value == _swapPrice, "invalid swapPrice");
        require(_msgSender() != address(0), "swap from the zero address");
        require(
            memeOGSwapped[_msgSender()] >= _swapAmount,
            "swap amount exceeds"
        );
        require(
            balanceOf(_msgSender()) >= _swapAmount,
            "swap amount exceeds balance"
        );

        if (msg.value > 0 && _treassurey != address(0))
            _treassurey.transfer(msg.value);

        //transfer meme og back to the sender
        memeOg.transfer(_msgSender(), _swapAmount);
        memeOGSwapped[_msgSender()] = memeOGSwapped[_msgSender()].sub(
            _swapAmount
        );
        //transfer newtoken back to the contract
        uint256 amountToSwapBack = _swapAmount * (10**uint256(10));
        _transfer(_msgSender(), address(this), amountToSwapBack);

        emit Swap(_msgSender(), amountToSwapBack, _swapAmount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function setSigner(address _signer) public onlyOwner {
        cSigner = _signer;
    }

    function setSwapPrice(uint256 swapPrice_) public onlyOwner {
        _swapPrice = swapPrice_;
    }

    function getSwapPrice() public view returns (uint256) {
        return _swapPrice;
    }

    function setTreassurey(address payable treassurey_) public onlyOwner {
        _treassurey = treassurey_;
    }

    function getTreassurey() public view returns (address) {
        return _treassurey;
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        require(ERC20.totalSupply() + amount <= cap(), "cap exceeded");
        super._mint(account, amount);
    }

    function _signerAddress(bytes memory _sig, uint256 _amount)
        private
        view
        returns (address)
    {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _amount));
        return _recoverSigner(message, _sig);
    }

    function _recoverSigner(bytes32 _message, bytes memory _sig)
        private
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(_sig);
        return ecrecover(_message, v, r, s);
    }

    function _splitSignature(bytes memory _sig)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(_sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return (v, r, s);
    }
}