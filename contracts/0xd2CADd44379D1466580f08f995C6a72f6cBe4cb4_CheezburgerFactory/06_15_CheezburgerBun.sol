// SPDX-License-Identifier: UNLICENSED
// This token was deployed using the CheezburgerFactory.
// You can check the tokenomics, website and social from the public read functions.
pragma solidity ^0.8.21;

import "solady/src/tokens/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./CheezburgerDynamicTokenomics.sol";
import "./interfaces/ICheezburgerFactory.sol";

contract CheezburgerBun is CheezburgerDynamicTokenomics, ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error TransferToZeroAddress(address from, address to);
    error TransferToToken(address to);
    error TransferMaxTokensPerWallet();
    error OnlyOneBuyPerBlockAllowed();
    error CannotReceiveEtherDirectly();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    string private _name;
    string private _symbol;
    string private _website;
    string private _social;
    IUniswapV2Pair private _pair;
    address public constant owner = address(0);
    mapping(address => uint256) private _holderLastBuyTimestamp;
    ICheezburgerFactory public immutable factory =
        ICheezburgerFactory(msg.sender);
    uint8 internal isSwapping = 1;

    constructor(
        TokenCustomization memory _customization,
        DynamicSettings memory _fees,
        DynamicSettings memory _wallet
    ) CheezburgerDynamicTokenomics(_fees, _wallet) {
        _name = _customization.name;
        _symbol = _customization.symbol;
        _website = _customization.website;
        _social = _customization.social;
        _mint(address(factory), _customization.supply * (10 ** decimals()));
    }

    /// @dev Prevents direct Ether transfers to contract
    receive() external payable {
        revert CannotReceiveEtherDirectly();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function website() public view returns (string memory) {
        return _website;
    }

    function social() public view returns (string memory) {
        return _social;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (to == address(this)) {
            revert TransferToToken(to);
        }

        // Cache pair internally if available
        if (address(_pair) == address(0)) {
            if (address(factory).code.length > 0) {
                _pair = factory.selfPair();
            }
        }

        bool isBuying = from == address(_pair);

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                        LIQUIDITY SWAP                      */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
        if (
            !isBuying &&
            isSwapping == 1 &&
            balanceOf(address(factory)) > 0 &&
            _pair.totalSupply() > 0
        ) {
            doLiquiditySwap();
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        // Must use burn() to burn tokens
        if (to == address(0) && balanceOf(address(0)) > 0) {
            revert TransferToZeroAddress(from, to);
        }

        // Don't look after self transfers
        if (from == to) {
            return;
        }

        // Ignore Factory-related txs
        if (to == address(factory) || from == address(factory)) {
            return;
        }

        bool isBuying = from == address(_pair);
        bool isSelling = to == address(_pair);
        DynamicTokenomicsStruct memory tokenomics = _getTokenomics(
            totalSupply()
        );

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                          TXS LIMITS                        */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

        if (isBuying) {
            bool buyFeeStillDecreasing = tokenomics.earlyAccessPremium !=
                tokenomics.sellFee;
            if (buyFeeStillDecreasing) {
                if (_holderLastBuyTimestamp[tx.origin] == block.number) {
                    revert OnlyOneBuyPerBlockAllowed();
                }
                _holderLastBuyTimestamp[tx.origin] = block.number;
            }
        }

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                            FEES                            */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

        uint256 feeAmount = 0;
        if (isBuying || isSelling) {
            unchecked {
                if (isBuying && tokenomics.earlyAccessPremium > 0) {
                    feeAmount = amount * tokenomics.earlyAccessPremium;
                } else if (isSelling && tokenomics.sellFee > 0) {
                    feeAmount = amount * tokenomics.sellFee;
                }
                if (feeAmount > 0) {
                    super._transfer(to, address(factory), feeAmount / 10000);
                    emit AppliedTokenomics(tokenomics);
                }
            }
        }

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                        WALLET LIMITS                       */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

        if (!isSelling) {
            unchecked {
                bool walletExceedLimits = balanceOf(to) >
                    tokenomics.maxTokensPerWallet;
                if (walletExceedLimits) {
                    revert TransferMaxTokensPerWallet();
                }
            }
        }
    }

    function doLiquiditySwap() private lockSwap {
        factory.afterTokenTransfer(msg.sender, balanceOf(address(factory)));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// Burns tokens from the caller.
    ///
    /// @dev Burns `amount` tokens from the caller.
    ///
    /// See {ERC20-_burn}.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// Burns tokens from an account's allowance.
    ///
    /// @dev Burns `amount` tokens from `account`, deducting from the caller's
    /// allowance.
    ///
    /// See {ERC20-_burn} and {ERC20-allowance}.
    ///
    /// Requirements:
    ///
    /// - the caller must have allowance for ``accounts``'s tokens of at least
    /// `amount`.
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Get current dynamic tokenomics
    /// @return DynamicTokenomics struct with current values
    /// @notice Values will change dynamically based on configured durations and percentages
    function getTokenomics()
        external
        view
        returns (DynamicTokenomicsStruct memory)
    {
        return _getTokenomics(totalSupply());
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier lockSwap() {
        isSwapping = 2;
        _;
        isSwapping = 1;
    }
}