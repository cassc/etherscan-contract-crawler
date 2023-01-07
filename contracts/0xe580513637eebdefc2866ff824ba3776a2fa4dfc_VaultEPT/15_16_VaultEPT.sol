// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Clones} from "openzeppelin/contracts/proxy/Clones.sol";

import {ICollybus} from "../interfaces/ICollybus.sol";
import {ICodex} from "../interfaces/ICodex.sol";
import {Guarded} from "../core/utils/Guarded.sol";
import {WAD, toInt256, wmul, wdiv} from "../core/utils/Math.sol";

import {IVaultEPT} from "../interfaces/IVaultEPT.sol";
import {VaultFactory} from "./VaultFactory.sol";

interface ITrancheFactory {
    function TRANCHE_CREATION_HASH() external view returns (bytes32);
}

interface ITranche {
    function unlockTimestamp() external view returns (uint256);
}

interface IWrappedPosition {
    function token() external view returns (address);
}

/// @title VaultEPT (Element Finance Principal Token Vault)
/// @notice Collateral adapter for Element Finance Principal Tokens
/// @dev To be instantiated by the VaultFactory
contract VaultEPT is Guarded, IVaultEPT, Initializable {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error VaultEPT__setParam_notLive();
    error VaultEPT__setParam_unrecognizedParam();
    error VaultEPT__enter_notLive();
    error VaultEPT__initialize_invalidToken();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Price Feed (set during initialization)
    ICollybus public override collybus;

    /// @notice Element Finance WrappedPosition
    address public immutable wrappedPosition;
    /// @notice Element TrancheFactory
    address public immutable trancheFactory;

    /// @notice Collateral token (set during initialization)
    address public override token;
    /// @notice Scale of collateral token (set during initialization)
    uint256 public override tokenScale;
    /// @notice Underlier of collateral token
    address public immutable override underlierToken;
    /// @notice Scale of underlier of collateral token
    uint256 public immutable override underlierScale;

    /// @notice The vault type (set during initialization)
    bytes32 public immutable override vaultType;

    // @notice Cached maturity of pToken (set during initialization)
    uint256 internal _maturity;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live) (set during initialization)
    uint256 public override live;

    /// ======== Events ======== ///

    event SetParam(bytes32 indexed param, address data);

    event Enter(uint256 indexed tokenId, address indexed user, uint256 amount);
    event Exit(uint256 indexed tokenId, address indexed user, uint256 amount);

    event Lock();

    constructor(
        address codex_,
        address wrappedPosition_,
        address trancheFactory_
    ) Guarded() {
        // disable deposits until proxy contract is initialized
        codex = ICodex(codex_);

        wrappedPosition = wrappedPosition_;
        trancheFactory = trancheFactory_;
        // underlier remains the same for all proxy instances of this contract
        address underlierToken_ = IWrappedPosition(wrappedPosition_).token();
        underlierToken = underlierToken_;
        underlierScale = 10**IERC20Metadata(underlierToken_).decimals();
        vaultType = bytes32("ERC20:EPT");
    }

    /// ======== EIP1167 Minimal Proxy Contract ======== ///

    /// @notice Initializes the proxy (clone) deployed via VaultFactory
    /// @dev Initializer modifier ensures it can only be called once
    /// @param params Constructor arguments of the proxy
    function initialize(bytes calldata params) external initializer {
        (address pToken, address collybus_, address root) = abi.decode(params, (address, address, address));
        uint256 _maturity_ = ITranche(pToken).unlockTimestamp();

        // Validate pToken address
        // see: https://github.com/element-fi/elf-contracts/blob/main/contracts/factories/TrancheFactory.sol#L58
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            trancheFactory,
                            keccak256(abi.encodePacked(wrappedPosition, _maturity_)),
                            ITrancheFactory(trancheFactory).TRANCHE_CREATION_HASH()
                        )
                    )
                )
            )
        );
        if (predictedAddress != pToken) revert VaultEPT__initialize_invalidToken();

        // intialize all mutable vars
        _setRoot(root);
        live = 1;
        collybus = ICollybus(collybus_);
        token = pToken;
        tokenScale = 10**IERC20Metadata(pToken).decimals();
        _maturity = _maturity_;
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(bytes32 param, address data) external virtual override checkCaller {
        if (live == 0) revert VaultEPT__setParam_notLive();
        if (param == "collybus") collybus = ICollybus(data);
        else revert VaultEPT__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// ======== Entering and Exiting Collateral ======== ///

    /// @notice Enters `amount` collateral into the system and credits it to `user`
    /// @dev Caller has to set allowance for this contract
    /// @param *tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address to whom the collateral should be credited to in Codex
    /// @param amount Amount of collateral to enter [tokenScale]
    function enter(
        uint256, /* tokenId */
        address user,
        uint256 amount
    ) external virtual override {
        if (live == 0) revert VaultEPT__enter_notLive();
        int256 wad = toInt256(wdiv(amount, tokenScale));
        codex.modifyBalance(address(this), 0, user, wad);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Enter(0, user, amount);
    }

    /// @notice Exits `amount` collateral into the system and credits it to `user`
    /// @param *tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address to whom the collateral should be credited to
    /// @param amount Amount of collateral to exit [tokenScale]
    function exit(
        uint256, /* tokenId */
        address user,
        uint256 amount
    ) external virtual override {
        int256 wad = toInt256(wdiv(amount, tokenScale));
        codex.modifyBalance(address(this), 0, msg.sender, -int256(wad));
        IERC20(token).safeTransfer(user, amount);
        emit Exit(0, user, amount);
    }

    /// ======== Collateral Asset ======== ///

    /// @notice Returns the maturity of the collateral asset
    /// @param *tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @return maturity [seconds]
    function maturity(
        uint256 /* tokenId */
    ) external view virtual override returns (uint256) {
        return _maturity;
    }

    /// ======== Valuing Collateral ======== ///

    /// @notice Returns the fair price of a single collateral unit
    /// @param *tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param net Boolean indicating whether the liquidation safety margin should be applied to the fair value
    /// @param face Boolean indicating whether the current fair value or the fair value at maturity should be returned
    /// @return fair Price [wad]
    function fairPrice(
        uint256,
        bool net,
        bool face
    ) external view override returns (uint256) {
        return ICollybus(collybus).read(address(this), underlierToken, 0, (face) ? block.timestamp : _maturity, net);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract
    /// @dev Sender has to be allowed to call this method
    function lock() external virtual override checkCaller {
        live = 0;
        emit Lock();
    }
}