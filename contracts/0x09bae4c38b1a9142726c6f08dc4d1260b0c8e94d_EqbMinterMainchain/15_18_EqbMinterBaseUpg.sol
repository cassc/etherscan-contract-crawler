// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./CrossChain/EqbMsgSenderUpg.sol";
import "./CrossChain/EqbMsgReceiverUpg.sol";
import "./Dependencies/Errors.sol";
import "./Interfaces/IEqbMinter.sol";

abstract contract EqbMinterBaseUpg is
    IEqbMinter,
    EqbMsgSenderUpg,
    EqbMsgReceiverUpg
{
    using SafeERC20 for IERC20;

    address public eqb;

    uint256 public constant DENOMINATOR = 10000;

    uint256 public mintedAmount;

    mapping(address => bool) public access;

    uint256[100] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __EqbMinterBase_init(
        address _eqb,
        address _eqbMsgSendEndpoint,
        uint256 _approxDstExecutionGas,
        address _eqbMsgReceiveEndpoint
    ) internal onlyInitializing {
        __EqbMinterBase_init_unchained(
            _eqb,
            _eqbMsgSendEndpoint,
            _approxDstExecutionGas,
            _eqbMsgReceiveEndpoint
        );
    }

    function __EqbMinterBase_init_unchained(
        address _eqb,
        address _eqbMsgSendEndpoint,
        uint256 _approxDstExecutionGas,
        address _eqbMsgReceiveEndpoint
    ) internal onlyInitializing {
        __EqbMsgSender_init_unchained(
            _eqbMsgSendEndpoint,
            _approxDstExecutionGas
        );
        __EqbMsgReceiver_init_unchained(_eqbMsgReceiveEndpoint);

        eqb = _eqb;
    }

    function setAccess(address _operator, bool _access) external onlyOwner {
        require(_operator != address(0), "invalid _operator!");
        access[_operator] = _access;

        emit AccessUpdated(_operator, _access);
    }

    function mint(address _to, uint256 _amount) external returns (uint256) {
        require(access[msg.sender], "!auth");

        uint256 mintAmount = (_amount * getFactor()) / DENOMINATOR;
        uint256 eqbBal = IERC20(eqb).balanceOf(address(this));
        if (eqbBal < mintAmount) {
            revert Errors.InsufficientBalance(eqbBal, mintAmount);
        }
        IERC20(eqb).safeTransfer(_to, mintAmount);

        mintedAmount += mintAmount;

        _afterMint();

        emit MintedAmountUpdated(mintedAmount);
        emit Minted(_to, mintAmount);

        return mintAmount;
    }

    function _afterMint() internal virtual {}

    function getFactor() public view virtual returns (uint256);
}