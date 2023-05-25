// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {ERC721PsiBurnable,ERC721Psi} from "./ERC721Psi/ERC721PsiBurnable.sol";
import {BitMaps} from "solidity-bits/contracts/BitMaps.sol";
import {ImmutableArray} from './libs/ImmutableArray.sol';

contract SS2ERC721PsiBurnable is
    ERC721PsiBurnable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using BitMaps for BitMaps.BitMap;

    struct AddressData{
      uint128 id;
      uint128 balance;
    }

    uint256 internal constant _addressLength = 1200;
    uint256 internal constant _ownerLength = 6000;

    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    address[] internal _addressPointers;
    address[] internal _ownerPointers;

    mapping(address => AddressData) internal _addressDatas;
    BitMaps.BitMap internal _transferedToken;

    constructor(string memory name_, string memory symbol_) ERC721Psi(name_, symbol_) {}

    //public
    function balanceOf(address owner) 
        public 
        view 
        virtual 
        override 
        returns (uint256) 
    {
        return _addressDatas[owner].balance;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if(!_transferedToken.get(tokenId)){
            require(_exists(tokenId), "ERC721Psi: owner query for nonexistent token");
            uint256 pid = (tokenId-1)/_ownerLength;
            uint256 pindex = tokenId-1-(pid*_ownerLength);
            (uint16 addressIndex,,) = ImmutableArray.readUint16(_ownerPointers[pid], pindex);
            pid = (addressIndex)/_addressLength;
            pindex = addressIndex-(pid*_addressLength);
            (address owner,,) = ImmutableArray.readAddress(_addressPointers[pid], pindex);
            return owner;
        }
        return super.ownerOf(tokenId);
    }
    
    function _exists(uint256 tokenId) internal view override virtual returns (bool){
        if(!_transferedToken.get(tokenId)) {
            uint256 pid = (tokenId-1)/_ownerLength;
            uint256 pindex = tokenId-1-(pid*_ownerLength);
            (uint16 addressIndex,,) = ImmutableArray.readUint16(_ownerPointers[pid], pindex);
            if(addressIndex == 0xffff){
                return false;
            }
            return true;
        } 
        return super._exists(tokenId);
    }

    //external
    function getAddressPointerLength() external virtual view returns(uint256) {
        return _addressPointers.length;
    }
    
    function getAddressPointer(uint256 index) external virtual view returns(address) {
        return _addressPointers[index];
    }

    function getOwnerPointerLength() external virtual view returns(uint256) {
        return _ownerPointers.length;
    }
    
    function getOwnerPointer(uint256 index) external virtual view returns(address) {
        return _ownerPointers[index];
    }

    function getAddressData(address _address) external virtual view returns(AddressData memory){
        return _addressDatas[_address];
    }

    // internal
    function _transferEvent(address[] calldata to,uint256 start) internal virtual {
        uint256 nextTokenId = start;
        uint256 toMasked;
        uint256 end = start + to.length;
        uint256 i = 1;

        // Use assembly to loop and emit the `Transfer` event for gas savings.
        // The duplicated `log4` removes an extra check and reduces stack juggling.
        // The assembly, together with the surrounding Solidity code, have been
        // delicately arranged to nudge the compiler into producing optimized opcodes.
        assembly {
            let offset := to.offset
            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            toMasked := and(calldataload(offset), _BITMASK_ADDRESS)
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                0, // `address(0)`.
                toMasked, // `to`.
                nextTokenId // `tokenId`.
            )

            // The `iszero(eq(,))` check ensures that large values of `quantity`
            // that overflows uint256 will make the loop run out of gas.
            // The compiler will optimize the `iszero` away for performance.
            for {
                let tokenId := add(nextTokenId, 1)
            } iszero(eq(tokenId, end)) {
                tokenId := add(tokenId, 1)
                i := add(i, 1)
            } {
                toMasked := and(calldataload(add(offset,mul(i,32))), _BITMASK_ADDRESS)

                if not(iszero(toMasked)) {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
        }
    }

    function _pushOwnerPointer(address pointer) internal virtual {
        _ownerPointers.push(pointer);
    }
    
    function _setOwnerPointer(address pointer,uint256 index) internal virtual {
        _ownerPointers[index] = pointer;
    }
    
    function _pushAddressPointer(address pointer) internal virtual {
        _addressPointers.push(pointer);
    }
    
    function _setAddressPointer(address pointer,uint256 index) internal virtual {
        _addressPointers[index] = pointer;
    }
    
    function _setAddressData(address _address,AddressData memory _addressData) internal virtual {
        _addressDatas[_address] = _addressData;
    }
    
    function _afterTokenTransfers(address from,address to,uint256 startTokenId,uint256 amount) internal virtual override {
        if(!_transferedToken.get(startTokenId))
            _transferedToken.set(startTokenId);
        unchecked {
            if(from != address(0)) _addressDatas[from].balance-=uint128(amount);
            if(to != address(0)) _addressDatas[to].balance+=uint128(amount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if(!_transferedToken.get(tokenId)){
            address owner = ownerOf(tokenId);
            require(
                owner == from,
                "SS2ERC721PsiBurnable: transfer of token that is not own"
            );
            require(to != address(0), "SS2ERC721PsiBurnable: transfer to the zero address");
            _beforeTokenTransfers(address(0), to, tokenId, 1);
            _approve(address(0), tokenId);
            _owners[tokenId] = to;
            _batchHead.set(tokenId);
            _afterTokenTransfers(address(0), to, tokenId, 1);
            emit Transfer(from, to, tokenId);
            return;
        }
        super._transfer(from,to,tokenId);
    }

}