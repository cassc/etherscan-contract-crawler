// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IERC1155 } from "./interfaces/IERC1155.sol";
import { IERC721Receiver } from "./interfaces/IERC721Receiver.sol";
import { IERC1155Receiver } from "./interfaces/IERC1155Receiver.sol";

import { IERC165 } from "./interfaces/IERC165.sol";
import { EscrowOwnable } from "./utils/EscrowOwnable.sol";
import { Context } from "./oz-simplified/Context.sol";
import { Initializable } from "./oz-simplified/Initializable.sol";

import { IEscrow } from "./interfaces/IEscrow.sol";

import { Errors } from "./library/errors/Errors.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Escrow is IEscrow, IERC165, IERC721Receiver, IERC1155Receiver, EscrowOwnable {
    struct PrizeToken {
        uint256 tokenId;
        address token;
        uint8 tokenType;
        uint16 quantity;
    }

    uint8 constant TYPE_ERC721 = 2;
    uint8 constant TYPE_ERC1155 = 3;

    IERC20 private _currencyContract;

    uint256 private _lastId;

    mapping(uint256 => PrizeToken[]) private _prizes;
    mapping(uint256 => address) private _claims;

    constructor(address currency) {
        // confirm currency is a contract
        if (currency.code.length == 0) {
            revert Errors.NotAContract();
        }
        _currencyContract = IERC20(currency);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return (
            interfaceId == type(IEscrow).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId
        );
    }

    function updateCurrency(address newCurrencyAddress) external onlyOwner {
       if (newCurrencyAddress.code.length == 0) {
            revert Errors.NotAContract();
        }
        _currencyContract = IERC20(newCurrencyAddress);
    }

    function currencyBalance() public view returns (uint256) {
        return _currencyContract.balanceOf(address(this));
    }

    function deposit(address spender, uint256 amount) public onlyAuthorized {
        _currencyContract.transferFrom(spender, address(this), amount);

        emit Deposit(amount, spender);
    }

    function withdraw(address recipient, uint256 amount) public onlyAuthorized {
        _currencyContract.transfer(recipient, amount);

        emit Withdrawal(amount, recipient);
    }

    function getPrizeInfo(uint256 claimId) public view returns (PrizeToken[] memory) {
        return _prizes[claimId];
    }

    function addPrize(
        address[] calldata tokens,
        uint256[] calldata tokenIds,
        uint8[] calldata tokenTypes,
        uint16[] calldata quantities
    ) public onlyAuthorized {
        uint256 arrayLength = tokens.length;
        if (
            arrayLength != tokenIds.length
            || arrayLength != tokenTypes.length
            || arrayLength != quantities.length
        ) {
            revert Errors.ArrayMismatch();
        }

        uint256 claimId = ++_lastId;

        for (uint256 i = 0; i < arrayLength;) {
            PrizeToken storage prize = _prizes[claimId].push();
            prize.token = tokens[i];
            prize.tokenId = tokenIds[i];
            prize.tokenType = tokenTypes[i];
            prize.quantity = quantities[i];

            unchecked {
                ++i;
            }
        }

        _transferPrize(claimId, msg.sender, address(this));

        emit PrizeAdded(claimId);
    }

    function removePrize(uint256 claimId, address to) public onlyAuthorized {
        _transferPrize(claimId, address(this), to);

        // delete the PrizeToken array to get a gas refund
        // iterating to delete each struct costs more than we save
        delete _prizes[claimId];

        emit PrizeRemoved(claimId, to);
    }

    function authorizeClaim(uint256 claimId, address claimant) public onlyAuthorized {
        if ( _prizes[ claimId ].length == 0) {
            revert Errors.AlreadyClaimed(claimId);
        }

        _claims[claimId] = claimant;

        emit ClaimAuthorized(claimId, claimant);
    }

    function authorizedClaimant(uint256 claimId) public view returns (address) {
        return _claims[claimId];
    }

    function claim(uint256 claimId, address destination) public {
        _claim(claimId, msg.sender, destination);
    }

    function claimFor(address claimant, uint256 claimId, address destination) onlyAuthorized public {
        _claim(claimId, claimant, destination);
    }

    function _claim(uint256 claimId, address claimant, address recipient) internal {
       if (claimant != _claims[claimId]) {
            revert Errors.BadSender(_claims[claimId], claimant);
        }

        _transferPrize(claimId, address(this), recipient);
        emit PrizeReceived(claimId, recipient);

        // cancel the authorization and receive a gas refund
        _claims[claimId] = address(0);

        // delete the PrizeToken array to get a gas refund
        // iterating to delete each struct costs more than we save
        delete _prizes[claimId];
    }

    function _transferPrize(uint256 claimId, address from, address to) internal {
        PrizeToken[] memory prize = _prizes[claimId];

        for (uint256 i = 0; i < prize.length;) {
            if (prize[i].tokenType == TYPE_ERC721) {
                IERC721 ct = IERC721(prize[i].token);
                ct.safeTransferFrom(from, to, prize[i].tokenId);
            } else if (prize[i].tokenType == TYPE_ERC1155) {
                IERC1155 ct = IERC1155(prize[i].token);
                ct.safeTransferFrom(from, to, prize[i].tokenId, prize[i].quantity, new bytes(0));
            } else {
                revert Errors.InvalidTokenType();
            }

            unchecked {
                ++i;
            }
        }
    }

    function onERC721Received(
        address, // operator,
        address from,
        uint256, // tokenId,
        bytes calldata // data
    ) public view returns (bytes4 selector) {
        // for safety, only allow transfer of ERC721 tokens from the banker
        if (banker() == from) {
            selector = IERC721Receiver.onERC721Received.selector;
        }
    }

    function onERC1155Received(
        address, // operator,
        address from,
        uint256, // id,
        uint256, // value,
        bytes calldata // data
    ) public view returns (bytes4 selector) {
        // for safety, only allow transfer of ERC1155 tokens from the banker
        if (banker() == from) {
            selector = IERC1155Receiver.onERC1155Received.selector;
        }
    }

    function onERC1155BatchReceived(
        address, // operator,
        address from,
        uint256[] calldata, // ids,
        uint256[] calldata, // values,
        bytes calldata // data
    ) public view returns (bytes4 selector) {
        // for safety, only allow transfer of ERC1155 tokens from the banker
        if (banker() == from) {
            selector = IERC1155Receiver.onERC1155BatchReceived.selector;
        }
    }
}