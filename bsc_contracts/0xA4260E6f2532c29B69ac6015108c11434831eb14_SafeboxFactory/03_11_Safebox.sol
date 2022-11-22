// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../zkPass/ZKPass.sol";
import "./SafeboxFactory.sol";

contract Safebox is Context {
    using SafeERC20 for IERC20;

    ZKPass public zkPass;

    event WithdrawERC20(address indexed tokenAddr, uint amount);

    event WithdrawERC721(address indexed tokenAddr, uint tokenId);

    event WithdrawETH(uint amount);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public factory;

    address private _owner;

    bool isInit;

    constructor() {}

    receive() external payable {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Safebox: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function init(address newOwner) external {
        require(!isInit, "function forbidden");
        isInit = true;
        factory = _msgSender();
        zkPass = SafeboxFactory(factory).zkPass();
        _transferOwnership(newOwner);
    }

    function transferOwnership(
        uint[8] memory proof,
        address newOwner,
        uint expiration,
        uint allhash
    ) external onlyOwner {
        require(
            newOwner != address(0),
            "Safebox: new owner is the zero address"
        );

        uint datahash = uint(uint160(newOwner));
        zkPass.verify(owner(), proof, datahash, expiration, allhash);

        _doTransferOwnership(newOwner);
    }

    function _doTransferOwnership(address newOwner) private {
        SafeboxFactory(factory).changeSafeboxOwner(owner(), newOwner);

        _transferOwnership(newOwner);
    }

    ///////////////////////////////////
    // withdraw
    ///////////////////////////////////

    function withdrawETH(
        uint[8] memory proof,
        uint amount,
        uint expiration,
        uint allhash
    ) external onlyOwner {
        zkPass.verify(owner(), proof, amount, expiration, allhash);

        payable(owner()).transfer(amount);

        emit WithdrawETH(amount);
    }

    function withdrawERC20(
        uint[8] memory proof,
        address tokenAddr,
        uint amount,
        uint expiration,
        uint allhash
    ) external onlyOwner {
        uint datahash = uint(keccak256(abi.encodePacked(tokenAddr, amount)));
        zkPass.verify(owner(), proof, datahash, expiration, allhash);

        IERC20(tokenAddr).safeTransfer(owner(), amount);

        emit WithdrawERC20(tokenAddr, amount);
    }

    function withdrawERC721(
        uint[8] memory proof,
        address tokenAddr,
        uint tokenId,
        uint expiration,
        uint allhash
    ) external onlyOwner {
        uint datahash = uint(keccak256(abi.encodePacked(tokenAddr, tokenId)));
        zkPass.verify(owner(), proof, datahash, expiration, allhash);

        IERC721(tokenAddr).transferFrom(address(this), owner(), tokenId);

        emit WithdrawERC721(tokenAddr, tokenId);
    }

    ///////////////////////////////////
    // SocialRecover
    ///////////////////////////////////

    event SetSocialRecover(address[] guardians, uint needGuardiansNum);

    event Cover(
        address indexed operator,
        address indexed newOwner,
        uint doneNum
    );

    address[] public guardians;
    uint public needGuardiansNum;
    address[] public doneGuardians;
    address public prepareOwner;

    function getSocialRecover()
        public
        view
        returns (
            address[] memory,
            uint,
            address[] memory
        )
    {
        return (guardians, needGuardiansNum, doneGuardians);
    }

    function setSocialRecover(
        uint[8] memory proof,
        address[] memory _guardians,
        uint _needGuardiansNum,
        uint expiration,
        uint allhash
    ) external onlyOwner {
        require(
            _needGuardiansNum > 0 && _needGuardiansNum <= _guardians.length,
            "setSocialRecover: needGuardiansNum error"
        );

        uint datahash = uint(
            keccak256(abi.encodePacked(_guardians, _needGuardiansNum))
        );

        zkPass.verify(owner(), proof, datahash, expiration, allhash);

        guardians = _guardians;
        needGuardiansNum = _needGuardiansNum;
        doneGuardians = new address[](_needGuardiansNum);
        prepareOwner = address(0);

        emit SetSocialRecover(_guardians, needGuardiansNum);
    }

    function transferOwnership2(address newOwner) external {
        require(
            newOwner != address(0),
            "transferOwnership2: newOwner can't be 0x00"
        );

        bool isGuardian;
        for (uint j = 0; j < guardians.length; ++j) {
            if (guardians[j] == _msgSender()) {
                isGuardian = true;
                break;
            }
        }
        require(isGuardian, "transferOwnership2: you're not the Guardian");

        if (prepareOwner == newOwner) {
            uint insertIndex = 0;
            bool insertIndexOnce;
            for (uint i = 0; i < doneGuardians.length; ++i) {
                if (!insertIndexOnce && doneGuardians[i] == address(0)) {
                    insertIndex = i;
                    insertIndexOnce = true;
                }
                require(
                    doneGuardians[i] != _msgSender(),
                    "transferOwnership2: don't repeat"
                );
            }

            if (insertIndex == needGuardiansNum - 1) {
                //fire!
                _doTransferOwnership(newOwner);
                doneGuardians = new address[](needGuardiansNum); //clear doneGuardians
            } else {
                doneGuardians[insertIndex] = _msgSender();
            }

            emit Cover(_msgSender(), newOwner, insertIndex + 1);
        } else {
            if (needGuardiansNum == 1) {
                //fire!
                _doTransferOwnership(newOwner);
            } else {
                doneGuardians = new address[](needGuardiansNum);
                doneGuardians[0] = _msgSender();
                prepareOwner = newOwner;
            }

            emit Cover(_msgSender(), newOwner, 1);
        }
    }
}