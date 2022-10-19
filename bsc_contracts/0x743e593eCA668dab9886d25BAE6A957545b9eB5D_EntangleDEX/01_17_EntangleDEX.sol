// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.15;

import "./Lender.sol";
import "./PausableAccessControl.sol";
import "./EntangleSynth.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EntangleDEX is PausableAccessControl, Lender {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;
    using SafeERC20 for EntangleSynth;

    uint256 public fee;
    uint256 public feeRate = 1e3;
    address public feeCollector;

    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event Rebalancing(address token, uint256 amount);

    struct SynthData {
        bool isActive;
    }

    mapping(EntangleSynth => SynthData) public synths;

    /**
     * @dev Sets the values for `synth`, `opToken` and `rate`.
     */
    constructor(
        address _feeCollector
    ) {

        _setRoleAdmin(ADMIN, OWNER);
        _setRoleAdmin(OWNER, OWNER);
        _setRoleAdmin(PAUSER_ROLE, ADMIN);
        _setRoleAdmin(BORROWER_ROLE, ADMIN);
        _setupRole(OWNER, msg.sender);

        feeCollector = _feeCollector;
    }

    modifier exist(EntangleSynth _synth) {
        require(synths[_synth].isActive, "Is not active");
        _;
    }

    function add(
        EntangleSynth _synth
    ) public onlyRole(ADMIN) whenNotPaused {
        require(!synths[_synth].isActive, "Already added");
        synths[_synth] = SynthData({
            isActive: true 
        });
    }

    /**
     * @notice Trade function to buy synth token.
     * @param _amount The amount of the source token being traded.
     *
     * Requirements:
     *
     * - the caller must have `BUYER` role.
     */
    function buy(EntangleSynth _synth, uint256 _amount)
        public
        exist(_synth)
        whenNotPaused
        returns(uint256 synthAmount)
    {
        IERC20 opToken = _synth.opToken();
        uint256 fee_ = _amount * fee / feeRate;
        _amount -= fee_;
        synthAmount = _synth.convertOpAmountToSynthAmount(_amount);
        opToken.safeTransferFrom(msg.sender, address(this), _amount);
        opToken.safeTransfer(feeCollector, fee_);
        _synth.safeTransfer(msg.sender, synthAmount);
    }

    function sell(EntangleSynth _synth, uint256 _amount)
        public
        exist(_synth)
        whenNotPaused 
        returns (uint256 opTokenAmount)
    {
        IERC20 opToken = _synth.opToken();
        opTokenAmount = _synth.convertSynthAmountToOpAmount(_amount);
        uint256 fee_ = opTokenAmount * fee / feeRate;
        opTokenAmount = opTokenAmount - fee_;
        _synth.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        opToken.safeTransfer(feeCollector, fee_);
        opToken.safeTransfer(msg.sender, opTokenAmount);
    }

    /**
     * @dev function for setting fee
     *
     * Requirements:
     *
     * - the caller must have admin role.
     */
    function changeFee(uint256 _fee, uint256 _feeRate) public onlyRole(ADMIN) whenNotPaused {
        fee = _fee;
        feeRate = _feeRate;
    }

    /**
     * @dev function for stopping token acceptance
     *
     * Requirements:
     *
     * - the caller must have admin role.
     */
    function switchSynthState(EntangleSynth _synth) public exist(_synth) whenNotPaused onlyRole(ADMIN) {
        synths[_synth].isActive = !synths[_synth].isActive;
    }
}