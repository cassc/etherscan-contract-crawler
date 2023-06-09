// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./EndPoint.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IAddressBook.sol";


contract SynthesisV2 is EndPoint, Ownable  {

    using Address for address;

    /// @dev fee denominator
    uint256 public constant FEE_DENOMINATOR = 10000;
    /// @dev chainIdFrom => original => synthetic
    mapping(uint64 => mapping(address => address)) public synthByOriginal;
    /// @dev chainIdFrom => synthetic => adapter
    mapping(address => address) public synthBySynth;

    event Synthesized(address token, uint256 amount, address from, address to);
    event Move(address token, uint256 amount, address from, address to, uint64 chainIdTo);
    event Burn(address token, uint256 amount, address from, address to);
    event SynthRegistered(address originalToken, address syntheticToken);

    modifier onlyRouter() {
        address router = IAddressBook(addressBook).router(uint64(block.chainid));
        require(router == msg.sender, "Portal: router only");
        _;
    }

    constructor(address addressBook_) EndPoint(addressBook_) {}

    /**
     * @dev Sets address book.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     *
     * @param addressBook_ address book contract address.
     */
    function setAddressBook(address addressBook_) external onlyOwner {
        _setAddressBook(addressBook_);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function setCap(address token, uint256 cap_) external onlyOwner {
        ISynthAdapter adapterImpl = ISynthAdapter(token);
        adapterImpl.setCap(cap_);
    }

    /**
     * @dev Get token representation address.
     *
     * @param otoken_ original token address.
     */
    function getSynth(uint64 chainIdFrom, address otoken_) external view returns (address) {
        return synthByOriginal[chainIdFrom][otoken_];
    }

    /**
     * @dev Mints synthetic token. Can be called only by bridge after initiation on a second chain.
     *
     * If synth is thirdparty synth or some another token otoken MUST be an ISynthAdapter with
     * mint\burn like implemenatation. SynthAdapter have to lock\release token.
     *
     * @param otoken origin token address;
     * @param amount amount to mint;
     * @param from minter address;
     * @param to recipient address.
     */
    function mint(
        address otoken,
        uint256 amount,
        address from,
        address to,
        uint64 chainIdFrom
    ) external onlyRouter returns (uint256 amountOut) {
        IAddressBook addressBookImpl = IAddressBook(addressBook);
        address whitelist = addressBookImpl.whitelist();
        address treasury = addressBookImpl.treasury();
        uint256 fee = amount * IWhitelist(whitelist).bridgeFee(otoken) / FEE_DENOMINATOR;
        ISynthERC20 synthImpl = ISynthERC20(synthByOriginal[chainIdFrom][otoken]);
        require(address(synthImpl) != address(0), "Synthesis: synth not set");
        amountOut = amount - fee;
        synthImpl.mint(treasury, fee);
        synthImpl.mint(to, amountOut);
        emit Synthesized(address(synthImpl), amount, from, to);
    }

    /**
     * @dev Mints synthetic token. Can be called only by bridge after initiation on a second chain.
     *
     * If synth is thirdparty synth or some another token otoken MUST be an ISynthAdapter with
     * mint\burn like implemenatation. SynthAdapter have to lock\release token.
     *
     * @param stoken synth token address;
     * @param amount amount to mint;
     * @param from minter address;
     * @param to recipient address.
     */
    function emergencyMint(
        address stoken,
        uint256 amount,
        address from,
        address to
    ) external onlyRouter returns (uint256 amountOut) {
        ISynthERC20 synthImpl = ISynthERC20(stoken);
        require(address(synthImpl) != address(0), "Synthesis: synth not set");
        require(synthByOriginal[synthImpl.chainIdFrom()][synthImpl.originalToken()] == stoken, "Synthesis: synth not set");
        amountOut = amount;
        synthImpl.mint(to, amountOut);
        emit Synthesized(address(synthImpl), amount, from, to);
    }

    /**
     * @dev Burns given synthetic token and unlocks the original one (mints) in the origin (another) chain.
     *
     * @param stoken stoken token address;
     * @param amount amount to burn;
     * @param to recipient address;
     * @param chainIdTo destination chain id.
     */
    function burn(
        address stoken,
        uint256 amount,
        address from,
        address to,
        uint64 chainIdTo
    ) external onlyRouter {
        address adapter = synthBySynth[stoken];
        if (adapter != address(0)) {
            SafeERC20.safeIncreaseAllowance(IERC20(stoken), adapter, amount);
        } else {
            adapter = stoken;
        }
        ISynthAdapter impl = ISynthAdapter(adapter);
        impl.burn(from, amount);
        if (impl.chainIdFrom() != chainIdTo) {
            emit Move(impl.synthToken(), amount, from, to, chainIdTo);
        } else {
            emit Burn(impl.synthToken(), amount, from, to);
        }
    }

    /**
     * @dev Sets synths.
     *
     * Acceptable synth types: DefaultSynth, CustomSynth, ThirdPartySynth, ThirdPartyToken.
     *
     * In cases when synth type is one of our synths (DefaultSynth, CustomSynth) - address must be a ISynthERC20.
     * In cases when synth type is thisd party synth (ThirdPartySynth, ThirdPartyToken) - address must be a ISynthAdapter
     * and synth (or token) created for this token.
     *
     * @param stokens array of ISynthERC20 tokens.
     */
    function setSynths(address[] calldata stokens) external onlyOwner {
        for (uint256 i = 0; i < stokens.length; ++i) {
            _setSynth(stokens[i]);
        }
    }

    function _setSynth(address stoken_) private {
        ISynthAdapter impl = ISynthAdapter(stoken_);
        address otoken = impl.originalToken();
        uint64 chainIdFrom = impl.chainIdFrom();
        require(otoken != address(0), "Synthesis: synth incorrect");
        require(synthByOriginal[chainIdFrom][otoken] == address(0), "Synthesis: synth already set");
        uint8 synthType = impl.synthType();
        if (
            synthType == uint8(ISynthAdapter.SynthType.DefaultSynth) ||
            synthType == uint8(ISynthAdapter.SynthType.CustomSynth)
        ) {
            require(ISynthERC20(stoken_).totalSupply() == 0, "Synthesis: totalSupply incorrect");
        } else if (
            synthType == uint8(ISynthAdapter.SynthType.ThirdPartySynth) ||
            synthType == uint8(ISynthAdapter.SynthType.ThirdPartyToken)
        ) {
            require(synthBySynth[impl.synthToken()] == address(0), "Synthesis: adapter already set");
            synthBySynth[impl.synthToken()] = stoken_;
        } else {
            revert("Synthesis: wrong synth type");
        }
        synthByOriginal[chainIdFrom][otoken] = stoken_;
        emit SynthRegistered(otoken, stoken_);
    }
    
}