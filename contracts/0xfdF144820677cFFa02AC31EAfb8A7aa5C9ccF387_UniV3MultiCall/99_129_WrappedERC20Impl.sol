// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Constants} from "../../../Constants.sol";
import {DataTypesPeerToPeer} from "../../DataTypesPeerToPeer.sol";
import {Errors} from "../../../Errors.sol";
import {IAddressRegistry} from "../../interfaces/IAddressRegistry.sol";
import {IWrappedERC20Impl} from "../../interfaces/wrappers/ERC20/IWrappedERC20Impl.sol";

contract WrappedERC20Impl is
    ERC20,
    Initializable,
    ReentrancyGuard,
    IWrappedERC20Impl
{
    using SafeERC20 for IERC20Metadata;

    string internal _tokenName;
    string internal _tokenSymbol;
    uint8 internal _tokenDecimals;
    address[] internal _wrappedTokens;

    constructor() ERC20("Wrapped ERC20 Impl", "Wrapped ERC20 Impl") {
        _disableInitializers();
    }

    function initialize(
        address minter,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata wrappedTokens,
        uint256 totalInitialSupply,
        string calldata _name,
        string calldata _symbol
    ) external initializer {
        uint256 wrappedTokensLen = wrappedTokens.length;
        if (wrappedTokensLen == 1) {
            // check for minimum mint amount
            if (totalInitialSupply <= Constants.SINGLE_WRAPPER_MIN_MINT) {
                revert Errors.InvalidMintAmount();
            }
            _tokenDecimals = IERC20Metadata(wrappedTokens[0].tokenAddr)
                .decimals();
            _wrappedTokens.push(wrappedTokens[0].tokenAddr);

            // @dev: mint small dust amount to this address, which will be locked in contract
            // @note: given this initial mint amount the wrapper cannot easily be locked up for future mints
            _mint(address(this), Constants.SINGLE_WRAPPER_MIN_MINT);
            _mint(
                minter,
                totalInitialSupply - Constants.SINGLE_WRAPPER_MIN_MINT
            );
        } else {
            _tokenDecimals = 18;
            for (uint256 i; i < wrappedTokensLen; ) {
                _wrappedTokens.push(wrappedTokens[i].tokenAddr);
                unchecked {
                    ++i;
                }
            }
            _mint(
                minter,
                totalInitialSupply < 10 ** 18 ? totalInitialSupply : 10 ** 18
            );
        }
        _tokenName = _name;
        _tokenSymbol = _symbol;
    }

    function redeem(
        address account,
        address recipient,
        uint256 amount
    ) external nonReentrant {
        if (amount == 0) {
            revert Errors.InvalidAmount();
        }
        if (recipient == address(0)) {
            revert Errors.InvalidAddress();
        }
        uint256 currTotalSupply = totalSupply();
        if (msg.sender != account) {
            _spendAllowance(account, msg.sender, amount);
        }
        _burn(account, amount);

        // @dev: if isIOU then _wrappedTokens.length == 0 and this loop is skipped automatically
        uint256 wrappedTokensLen = _wrappedTokens.length;
        for (uint256 i; i < wrappedTokensLen; ) {
            address tokenAddr = _wrappedTokens[i];
            // @note: The underlying token transfers are all-or-nothing. In other words, if one token transfer fails,
            // the entire redemption process will fail as well. Users should only use wrappers if they deem this risk
            // to be acceptable or non-existent (for example, in cases where the underlying tokens can never have any
            // transfer restrictions).
            uint256 redemptionAmount = Math.mulDiv(
                IERC20Metadata(tokenAddr).balanceOf(address(this)),
                amount,
                currTotalSupply
            );
            IERC20Metadata(tokenAddr).safeTransfer(recipient, redemptionAmount);
            unchecked {
                ++i;
            }
        }
        emit Redeemed(account, recipient, amount);
    }

    function mint(
        address recipient,
        uint256 amount,
        uint256 expectedTransferFee
    ) external nonReentrant {
        if (_wrappedTokens.length != 1) {
            // @dev: only on single token wrappers do we allow minting
            // @note: IOU has no underlying tokens, so they are also disabled from minting
            revert Errors.OnlyMintFromSingleTokenWrapper();
        }
        if (amount == 0) {
            revert Errors.InvalidAmount();
        }
        if (recipient == address(0)) {
            revert Errors.InvalidAddress();
        }
        uint256 currTotalSupply = totalSupply();
        address tokenAddr = _wrappedTokens[0];
        uint256 tokenPreBal = IERC20Metadata(tokenAddr).balanceOf(
            address(this)
        );
        if (tokenPreBal == 0) {
            // @dev: this would be an unintended state, for instance a negative rebase down to 0 balance with still outstanding supply
            // in which case to not allow possibly diluted or unfair proportions for new minters, will revert
            // @note: the state token balance > 0, but total supply == 0 is allowed (e.g. donations to address before mint)
            revert Errors.NonMintableTokenState();
        }
        uint256 mintAmount = Math.mulDiv(amount, currTotalSupply, tokenPreBal);
        // @dev: revert in case mint amount is truncated to zero. This may also happen in case the mint transaction is front-run
        // with donations. Note that griefing with donations will be costly due to redemption fee.
        if (mintAmount == 0) {
            revert Errors.InvalidMintAmount();
        }
        _mint(recipient, mintAmount);
        IERC20Metadata(tokenAddr).safeTransferFrom(
            msg.sender,
            address(this),
            amount + expectedTransferFee
        );
        uint256 tokenPostBal = IERC20Metadata(tokenAddr).balanceOf(
            address(this)
        );
        if (tokenPostBal != tokenPreBal + amount) {
            revert Errors.InvalidSendAmount();
        }
    }

    function isIOU() external view returns (bool) {
        return _wrappedTokens.length == 0;
    }

    function getWrappedTokensInfo() external view returns (address[] memory) {
        return _wrappedTokens;
    }

    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _tokenDecimals;
    }
}