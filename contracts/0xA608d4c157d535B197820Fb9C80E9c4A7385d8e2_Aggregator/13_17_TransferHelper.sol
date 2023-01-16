// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/ICryptoPunks.sol";
import "../interfaces/IMoonCatsRescue.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Constants.sol";

// Do not define "state variables" in this contract ( which will affect the delegatecall to DefaultMarketProxy.batchBuyFromMarket())!!!!
contract TransferHelper is Constants {
    function _uintToBytes5(uint256 id)
        internal
        pure
        returns (bytes5 slicedDataBytes5)
    {
        bytes memory _bytes = new bytes(32);
        assembly {
            mstore(add(_bytes, 32), id)
        }

        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
            let lengthmod := and(5, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
            let mc := add(
                add(tempBytes, lengthmod),
                mul(0x20, iszero(lengthmod))
            )
            let end := add(mc, 5)

            for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                let cc := add(
                    add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
                    27
                )
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(tempBytes, 5)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        assembly {
            slicedDataBytes5 := mload(add(tempBytes, 32))
        }
    }

    // 从msg.sender那买入MoonCat（需要卖方提前挂一个价格为0、并指定onlySellTo为本合约的卖单）
    function _acceptMoonCat(uint256 moonCatId) internal {
        // xxxx -> address(this)
        IMoonCatsRescue moonCat = IMoonCatsRescue(MOONCAT);
        bytes5 catId = _uintToBytes5(moonCatId);
        // address owner = moonCat.catOwners(catId);
        // require(owner == msg.sender, "_acceptMoonCat: invalid mooncat owner");
        moonCat.acceptAdoptionOffer(catId);
    }

    // 将本合约中的MoonCat转出给用户to
    function _transferMoonCat(uint256 moonCatId, address to) internal {
        // address(this) -> msg.sender
        IMoonCatsRescue(MOONCAT).giveCat(_uintToBytes5(moonCatId), to);
    }

    // 从msg.sender那买入CryptoPunk（需要卖方提前挂一个价格为0、并指定onlySellTo为本合约的卖单）
    function _acceptCryptoPunk(uint256 cryptoPunkId) internal {
        // xxxx -> address(this)
        ICryptoPunks cryptoPunk = ICryptoPunks(CRYPTOPUNK);
        // address owner = cryptoPunk.punkIndexToAddress(cryptoPunkId);
        // require(owner == msg.sender, "_acceptCryptoPunk: invalid punk owner");
        cryptoPunk.buyPunk(cryptoPunkId); //msg.value为0
    }

    // 将本合约中的CryptoPunk转出给用户to
    function _transferCryptoPunk(uint256 cryptoPunkId, address to) internal {
        // address(this) -> msg.sender
        ICryptoPunks(CRYPTOPUNK).transferPunk(to, cryptoPunkId);
    }

    // 从本合约中转出主网币 address(this) -> msg.sender
    function _transferETH(address to, uint256 amount) internal {
        payable(to).transfer(amount); //失败则revert
    }

    function _transferERC20s(
        ERC20Detail[] calldata erc20Details, //tokenAddr-amount
        address from,
        address to
    ) internal {
        // from -> to
        for (uint256 i = 0; i < erc20Details.length; i++) {
            // Transfer ERC20
            IERC20(erc20Details[i].tokenAddr).transferFrom(
                from,
                to,
                erc20Details[i].amount
            );
        }
    }

    function _transferERC721s(
        ERC721Detail[] calldata erc721Details, // tokenAddr-id
        address from,
        address to
    ) internal {
        // from -> to
        for (uint256 i = 0; i < erc721Details.length; i++) {
            IERC721(erc721Details[i].tokenAddr).safeTransferFrom(
                from,
                to,
                erc721Details[i].id
            );
        }
    }

    function _transferERC1155s(
        ERC1155Detail[] calldata erc1155Details, //tokenAddr-id- amount
        address from,
        address to
    ) internal {
        // transfer ERC1155 tokens: from -> to
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeTransferFrom(
                from,
                to,
                erc1155Details[i].id,
                erc1155Details[i].amount,
                ""
            );
        }
    }

    function _transferItemsFromThis(OrderItem[] calldata items, address to)
        internal
    {
        //transfer CRYPTOPUNK or MOONCAT or ERC20 or ERC721 or ERC1155: address(this) -> to
        OrderItem calldata item;
        uint256 itemNums = items.length;
        uint256 tokenBalance = 0;
        // for-each
        for (uint256 i = 0; i < itemNums; i++) {
            item = items[i];
            if (item.amount == 0) {
                return;
            }

            if (item.tokenAddr == CRYPTOPUNK) {
                if (
                    ICryptoPunks(CRYPTOPUNK).punkIndexToAddress(item.id) ==
                    address(this)
                ) {
                    _transferCryptoPunk(item.id, to);
                }
            } else if (item.tokenAddr == MOONCAT) {
                if (
                    IMoonCatsRescue(MOONCAT).catOwners(
                        _uintToBytes5(item.id)
                    ) == address(this)
                ) {
                    _transferMoonCat(item.id, to);
                }
            } else if (item.itemType == ItemType.ERC20) {
                tokenBalance = IERC20(item.tokenAddr).balanceOf(address(this));
                if (tokenBalance >= item.amount) {
                    IERC20(item.tokenAddr).transfer(to, item.amount);
                }
            } else if (item.itemType == ItemType.ERC721) {
                if (IERC721(item.tokenAddr).ownerOf(item.id) == address(this)) {
                    // Transfer ERC721
                    IERC721(item.tokenAddr).safeTransferFrom(
                        address(this),
                        to,
                        item.id
                    );
                }
            } else if (item.itemType == ItemType.ERC1155) {
                if (
                    IERC1155(item.tokenAddr).balanceOf(
                        address(this),
                        item.id
                    ) >= item.amount
                ) {
                    // Transfer ERC1155
                    IERC1155(item.tokenAddr).safeTransferFrom(
                        address(this),
                        to,
                        item.id,
                        item.amount,
                        ""
                    );
                }
            } else {
                revert("_transferOrderItem: InvalidItemType");
            }
        }
    }
}