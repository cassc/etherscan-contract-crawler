// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IDfxOracle.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./DfxEurState.sol";

import "../libraries/FullMath.sol";

contract DfxEurLogic is DfxEurState {
    using SafeERC20 for IERC20;

    // **** Initializing functions ****

    // We don't need to check twice if the contract's initialized as
    // __ERC20_init does that check
    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _feeRecipient,
        uint256 _mintBurnFee,
        address _dfxEurTwap,
        uint256 _eursRatio,
        uint256 _dfxRatio,
        uint256 _pokeRatioDelta
    ) public initializer {
        __AccessControl_init();
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __ReentrancyGuard_init();

        _setRoleAdmin(SUDO_ROLE, SUDO_ROLE_ADMIN);
        _setupRole(SUDO_ROLE_ADMIN, _admin);
        _setupRole(SUDO_ROLE, _admin);

        _setRoleAdmin(MARKET_MAKER_ROLE, MARKET_MAKER_ROLE_ADMIN);
        _setupRole(MARKET_MAKER_ROLE_ADMIN, _admin);
        _setupRole(MARKET_MAKER_ROLE, _admin);

        _setRoleAdmin(POKE_ROLE, POKE_ROLE_ADMIN);
        _setupRole(POKE_ROLE_ADMIN, _admin);
        _setupRole(POKE_ROLE, _admin);

        _setRoleAdmin(CR_DEFENDER, CR_DEFENDER_ADMIN);
        _setupRole(CR_DEFENDER_ADMIN, _admin);
        _setupRole(CR_DEFENDER, _admin);

        // Oracle address
        dfxEurTwap = _dfxEurTwap;

        // Initial ratios
        require(_dfxRatio + _eursRatio == 1e18, "invalid-ratio");
        eursRatio = _eursRatio;
        dfxRatio = _dfxRatio;

        // Poke ratio delta
        require(
            _pokeRatioDelta <= MAX_POKE_RATIO_DELTA,
            "poke-ratio-delta: too big"
        );
        pokeRatioDelta = _pokeRatioDelta;

        // Fee recipients
        feeRecipient = _feeRecipient;
        mintBurnFee = _mintBurnFee;
    }

    // **** Modifiers ****

    modifier updatePokes() {
        // Make sure we can poke
        require(
            block.timestamp > lastPokeTime + POKE_WAIT_PERIOD,
            "invalid-poke-time"
        );

        _;

        // Sanity checks
        require(
            dfxRatio > 0 &&
                dfxRatio < 1e18 &&
                eursRatio > 0 &&
                eursRatio < 1e18,
            "invalid-ratios"
        );

        lastPokeTime = block.timestamp;
    }

    // **** Restricted functions ****

    // Sets the 'poke' delta
    /// @notice Manually sets the delta between each poke
    /// @param _pokeRatioDelta The delta between each poke, 100% = 1e18.
    function setPokeDelta(uint256 _pokeRatioDelta) public onlyRole(SUDO_ROLE) {
        require(
            _pokeRatioDelta <= MAX_POKE_RATIO_DELTA,
            "poke-ratio-delta: too big"
        );
        pokeRatioDelta = _pokeRatioDelta;
        emit PokeDeltaSet(pokeRatioDelta);
    }

    /// @notice Used when market price / TWAP is > than backing.
    ///         If set correctly, the underlying backing of the stable
    ///         assets will decrease and the underlying backing of the volatile
    ///         assets will increase.
    function pokeUp() public onlyRole(POKE_ROLE) updatePokes {
        dfxRatio = dfxRatio + pokeRatioDelta;
        eursRatio = eursRatio - pokeRatioDelta;
        emit PokeUp(dfxRatio, eursRatio);
    }

    /// @notice Used when market price / TWAP is < than backing.
    ///         If set correctly, the underlying backing of the stable
    ///         assets will increase and the underlying backing of the volatile
    ///         assets will decrease
    function pokeDown() public onlyRole(POKE_ROLE) updatePokes {
        dfxRatio = dfxRatio - pokeRatioDelta;
        eursRatio = eursRatio + pokeRatioDelta;
        emit PokeDown(dfxRatio, eursRatio);
    }

    /// @notice Sets the TWAP address
    function setDfxEurTwap(address _dfxXgdTwap) public onlyRole(SUDO_ROLE) {
        dfxEurTwap = _dfxXgdTwap;
        emit DfxEurTwapSet(_dfxXgdTwap);
    }

    /// @notice Sets the fee recipient for mint/burn
    function setFeeRecipient(address _recipient) public onlyRole(SUDO_ROLE) {
        feeRecipient = _recipient;
        emit FeeRecipientSet(_recipient);
    }

    /// @notice In case anyone sends tokens to the wrong address
    function recoverERC20(address _a) public onlyRole(SUDO_ROLE) {
        require(_a != DFX && _a != EURS, "no");
        IERC20(_a).safeTransfer(
            msg.sender,
            IERC20(_a).balanceOf(address(this))
        );
        emit ERC20Recovered(_a);
    }

    /// @notice Sets mint/burn fee
    function setMintBurnFee(uint256 _f) public onlyRole(SUDO_ROLE) {
        require(_f < 1e18, "invalid-fee");
        mintBurnFee = _f;
        emit MintBurnFeeSet(_f);
    }

    /// @notice Emergency trigger
    function setPaused(bool _p) public onlyRole(SUDO_ROLE) {
        if (_p) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @notice Execute functionality used to perform buyback and recollateralization
    function execute(address _target, bytes memory _data)
        public
        onlyRole(CR_DEFENDER)
        returns (bytes memory response)
    {
        require(_target != address(0), "target-address-required");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
        emit Executed(_target);
    }

    // **** Public stateful functions ****

    /// @notice Mints the ASC token
    /// @param _amount Amount of ASC token to mint
    function mint(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "non-zero only");

        (uint256 eursAmount, uint256 dfxAmount) = getUnderlyings(_amount);
        IERC20(EURS).safeTransferFrom(msg.sender, address(this), eursAmount);
        IERC20(DFX).safeTransferFrom(msg.sender, address(this), dfxAmount);

        // No fee for market makers
        if (hasRole(MARKET_MAKER_ROLE, msg.sender)) {
            _mint(msg.sender, _amount);
        } else {
            uint256 _fee = (_amount * mintBurnFee) / 1e18;
            _mint(msg.sender, _amount - _fee);
            _mint(feeRecipient, _fee);
        }
    }

    /// @notice Burns the ASC token
    /// @param _amount Amount of ASC token to burn
    function burn(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "non-zero only");

        // No fee for market makers
        if (hasRole(MARKET_MAKER_ROLE, msg.sender)) {
            _burn(msg.sender, _amount);
        } else {
            uint256 _fee = (_amount * mintBurnFee) / 1e18;
            _burn(msg.sender, _amount);
            _mint(feeRecipient, _fee);
            _amount = _amount - _fee;
        }

        (uint256 eursAmount, uint256 dfxAmount) = getUnderlyings(_amount);
        IERC20(EURS).safeTransfer(msg.sender, eursAmount);
        IERC20(DFX).safeTransfer(msg.sender, dfxAmount);
    }

    // **** View only functions ****

    /// @notice Get the underlyings of `_amount` of 'logic' tokens
    ///         For example, how many underlyings will `_amount` token yield?
    ///         Or, how many underlyings do I need to mint `_amount` token?
    /// @param _amount The amount of 'logic' token
    function getUnderlyings(uint256 _amount)
        public
        view
        returns (uint256 eursAmount, uint256 dfxAmount)
    {
        uint256 eurPerDfx = IDfxOracle(dfxEurTwap).read();

        eursAmount = FullMath.mulDivRoundingUp(_amount, eursRatio, 1e34);
        dfxAmount = FullMath.mulDivRoundingUp(_amount, dfxRatio, 1e18);
        dfxAmount = FullMath.mulDivRoundingUp(dfxAmount, 1e18, eurPerDfx);
    }

    /* ========== EVENTS ========== */
    event Executed(address user);
    event MintBurnFeeSet(uint256 fee);
    event ERC20Recovered(address user);
    event FeeRecipientSet(address user);
    event DfxEurTwapSet(address twap);
    event PokeDown(uint256 dfxRatio, uint256 eursRatio);
    event PokeUp(uint256 dfxRatio, uint256 eursRatio);
    event PokeDeltaSet(uint256 pokeRatioDelta);
}