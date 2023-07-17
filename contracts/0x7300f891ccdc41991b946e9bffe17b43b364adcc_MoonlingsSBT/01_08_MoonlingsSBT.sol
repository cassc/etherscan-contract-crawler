// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Minimal1155SBT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author SanLeo461, on behalf of Moonlings
 */
contract MoonlingsSBT is Minimal1155SBT, Ownable {
    bool public canAirdrop = true;
    uint256 public supply = 0;

    string public name = "GMoonling to You - Moonpass";
    string public symbol = "GMLING";

    uint256 private _storageCounter = START_BALANCES_SLOT;
    uint256 private _storageUpto = 0;

    constructor(string memory uri_) Minimal1155SBT(uri_) {}

    function airdrop(bytes calldata addresses) external onlyOwner {
        require(canAirdrop, "Airdrop has been disabled");
        require(addresses.length % 20 == 0, "Invalid addresses length");

        uint256 _storageCounterVal = _storageCounter;
        uint256  _storageUptoVal = _storageUpto;
        supply += addresses.length / 20;
        

        assembly {
            let sz := div(addresses.length, 20)
            let storageCounter := _storageCounterVal
            let currentStoreAcc := sload(_storageCounterVal)
            let upto := _storageUptoVal
            let operator := caller()
            let zeroAddress := 0
            let signature := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
            mstore(0x40, 1)
            mstore(0x60, 1)
            for {
                let i := 0
            } lt(i, sz) {
                i := add(i, 1)
            } {
                let offset := mul(i, 20)
                let toAirdropTo := shr(96, calldataload(add(addresses.offset, offset)))
                log4(0x40, 0x40, signature, operator, zeroAddress, toAirdropTo)
                
                switch gt(upto, 11)
                case 0 {
                    currentStoreAcc := or(currentStoreAcc, shl(sub(96, mul(upto, 8)), toAirdropTo))
                    upto := add(upto, 20)
                }
                default {
                    let overlap := sub(upto, 12)
                    let toStore := or(currentStoreAcc, shr(mul(overlap, 8), toAirdropTo))

                    sstore(storageCounter, toStore)
                    storageCounter := add(storageCounter, 1)
                    currentStoreAcc := shl(sub(256, mul(overlap, 8)), toAirdropTo)
                    upto := overlap
                }
            }
            if gt(upto, 0) {
                sstore(storageCounter, currentStoreAcc)
            }
            _storageCounterVal := storageCounter
            _storageUptoVal := upto
        }
        _storageCounter = _storageCounterVal;
        _storageUpto = _storageUptoVal;
    }

    function getAddressIndexed(uint256 index) public view returns (address toReturn) {
        uint256 startBalancesSlot = START_BALANCES_SLOT;

        assembly {
            toReturn := 0
            let storageCounter := startBalancesSlot
            let slotIn := div(mul(20, index), 32)
            let indexIn := mod(mul(20, index), 32)
            let slot := sload(add(storageCounter, slotIn))
            toReturn := shl(mul(indexIn, 8), slot)
            switch gt(indexIn, 12)
            case 0 {
                toReturn := shr(96, toReturn)
            }
            default {
                let overlap := sub(indexIn, 12)
                toReturn := shl(mul(overlap, 8), shr(add(96, mul(overlap, 8)), toReturn))
                let slot2 := sload(add(storageCounter, add(slotIn, 1)))
                toReturn := or(toReturn, shr(sub(256, mul(overlap, 8)), slot2))
            }
        }
    }

    function _isAddressIncluded(address toFind, uint256 begin, uint256 end) internal view returns (bool ret) {
        uint160 toFindInt = uint160(toFind);
        uint256 len = end - begin;
        if (len == 0) {
            return false;
        } else if (len == 1) {
            return toFind == getAddressIndexed(begin);
        }

        uint256 mid = begin + len / 2;
        uint160 midAddr = uint160(getAddressIndexed(mid));
        if (uint160(midAddr) > toFindInt) {
            return _isAddressIncluded(toFind, begin, mid);
        } else if (uint160(midAddr) < toFindInt) {
            return _isAddressIncluded(toFind, mid, end);
        }
        return true;
    }

    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        require(id == TOKEN_ID, "ERC1155: invalid token ID");
        return _isAddressIncluded(account, 0, supply) ? 1 : 0;
    }

    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function renounceAirdropRights() external onlyOwner {
        canAirdrop = false;
    }
}