//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import {
    IERC721,
    IERC721Receiver
} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "./internal/FundForwarder.sol";
import "./internal/MultiDelegatecall.sol";

import "./internal/Base.sol";
import "./internal/ProxyChecker.sol";

import "./interfaces/ICommandGate.sol";

import "./libraries/Bytes32Address.sol";

contract CommandGate is
    Base,
    Context,
    ProxyChecker,
    ICommandGate,
    FundForwarder,
    IERC721Receiver,
    MultiDelegatecall
{
    using Bytes32Address for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private __isWhitelisted;

    constructor(
        IAuthority authority_,
        ITreasury vault_
    ) payable Base(authority_, Roles.PROXY_ROLE) FundForwarder(vault_) {}

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        _updateTreasury(treasury_);
    }

    function whitelistAddress(
        address addr_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        __isWhitelisted.set(addr_.fillLast96Bits());
    }

    function depositNativeTokenWithCommand(
        address contract_,
        bytes4 fnSig_,
        bytes calldata params_
    ) external payable whenNotPaused {
        address user = _msgSender();
        __checkUser(user);

        require(
            __isWhitelisted.get(contract_.fillLast96Bits()),
            "COMMAND_GATE: UNKNOWN_ADDRESS"
        );

        _safeNativeTransfer(address(treasury()), msg.value);

        __executeTx(
            contract_,
            fnSig_,
            bytes.concat(params_, abi.encode(user, address(0), msg.value))
        );
    }

    function depositERC20PermitWithCommand(
        IERC20Permit token_,
        uint256 value_,
        uint256 deadline_,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes4 fnSig_,
        address contract_,
        bytes memory data_
    ) external whenNotPaused {
        require(
            __isWhitelisted.get(contract_.fillLast96Bits()),
            "COMMAND_GATE: UNKNOWN_ADDRESS"
        );

        address user = _msgSender();
        __checkUser(user);

        token_.permit(user, address(this), value_, deadline_, v, r, s);
        _safeERC20TransferFrom(
            IERC20(address(token_)),
            user,
            address(treasury()),
            value_
        );
        data_ = bytes.concat(data_, abi.encode(user, token_, value_));
        __executeTx(contract_, fnSig_, data_);
    }

    function depositERC20WithCommand(
        IERC20 token_,
        uint256 value_,
        bytes4 fnSig_,
        address contract_,
        bytes memory data_
    ) external whenNotPaused {
        require(
            __isWhitelisted.get(contract_.fillLast96Bits()),
            "COMMAND_GATE: UNKNOWN_ADDRESS"
        );

        address user = _msgSender();
        __checkUser(user);

        _safeERC20TransferFrom(token_, user, address(treasury()), value_);
        data_ = bytes.concat(data_, abi.encode(user, token_, value_));
        __executeTx(contract_, fnSig_, data_);
    }

    function onERC721Received(
        address,
        address from_,
        uint256 tokenId_,
        bytes calldata data_
    ) external override whenNotPaused returns (bytes4) {
        (address target, bytes4 fnSig, bytes memory data) = __decodeData(data_);

        address user = _msgSender();
        _checkBlacklist(user);

        __executeTx(
            target,
            fnSig,
            bytes.concat(data, abi.encode(from_, user, tokenId_))
        );

        return this.onERC721Received.selector;
    }

    function depositERC721MultiWithCommand(
        uint256[] calldata tokenIds_,
        address[] calldata contracts_,
        bytes[] calldata data_
    ) external whenNotPaused {
        uint256 length = tokenIds_.length;
        address sender = _msgSender();
        for (uint256 i; i < length; ) {
            IERC721(contracts_[i]).safeTransferFrom(
                sender,
                address(this),
                tokenIds_[i],
                data_[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function __checkUser(address user_) private view {
        _checkBlacklist(user_);
        _onlyEOA(user_);
    }

    function __decodeData(
        bytes calldata data_
    ) private view returns (address target, bytes4 fnSig, bytes memory params) {
        (target, fnSig, params) = abi.decode(data_, (address, bytes4, bytes));

        require(
            __isWhitelisted.get(target.fillLast96Bits()),
            "COMMAND_GATE: UNKNOWN_ADDRESS"
        );
    }

    function __executeTx(
        address target_,
        bytes4 fnSignature_,
        bytes memory params_
    ) private {
        (bool ok, bytes memory result) = target_.call(
            abi.encodePacked(fnSignature_, params_)
        );
        if (!ok) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert("COMMAND_GATE: EXECUTION_FAILED");
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}