//SPDX-License-Identifier: AFL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

//Box base code
contract BoxBase is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    using Address for address;
    using SafeMath for uint;

    IERC20 public openCoin;
    address public coldWallet;
    address public mainAddress;
    address public upMonsterCoinAddress;
    address public signer;
    uint public price;

    mapping(address => uint256) public nonces;

    function setOpenCoin(address openCoin_) public onlyOwner {
        openCoin = IERC20(openCoin_);
    }
    function setColdWallet(address account_) public onlyOwner {
        coldWallet = account_;
    }
    function setMainAddress(address account_) public onlyOwner {
        mainAddress = account_;
    }
    function setUpMonsterAddress(address account_) public onlyOwner {
        upMonsterCoinAddress = account_;
    }
    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }
    function setSigner(address account_) public onlyOwner {
        signer = account_;
    }


    //init
    function initialize(
        address openCoin_,
        address coldWallet_,
        uint price_,
        address signer_
    ) public initializer
    {
        __UUPSUpgradeable_init();
        __Ownable_init();

        setOpenCoin(openCoin_);
        setColdWallet(coldWallet_);
        setPrice(price_);
        setSigner(signer_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier contractIsReady() {
        require(address(openCoin) != address(0), "Erc20 address is not initialize");
        require(coldWallet != address(0), "Cold wallet address is not initialize");
        require(price != 0, "Price is not initialize");
        require(signer != address(0), "Signer address is not initialize");
        _;
    }
}

//service code
contract DotaBox is BoxBase {

    //open box
    event OpenSuccess(address account, uint count);

    function openBox(uint count) public contractIsReady {
        openCoin.transferFrom(_msgSender(), mainAddress, count * price/19*1);
        openCoin.transferFrom(_msgSender(), upMonsterCoinAddress, count * price/19*3);
        openCoin.transferFrom(_msgSender(), coldWallet, count * price/19*15);
        emit OpenSuccess(_msgSender(), count);
    }

    function getHash(address account_, uint amount_) public view returns (bytes32) {
        return keccak256(abi.encodePacked(account_, amount_, nonces[account_]));
    }

    event WithdrawSuccess(address account, uint amount);

    function withdraw(uint amount_, bytes memory signature_) public contractIsReady {

        //check signature
        require(ECDSA.recover(getHash(_msgSender(), amount_), signature_) == signer, "Invalid signature");

        //rewards
        nonces[_msgSender()] += 1;
        openCoin.transfer(_msgSender(), amount_);

        emit WithdrawSuccess(_msgSender(), amount_);
    }
}