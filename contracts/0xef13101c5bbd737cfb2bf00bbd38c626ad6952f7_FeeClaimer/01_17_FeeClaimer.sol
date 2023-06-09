// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

// helpers
import "../AugustusSwapper.sol";
import "../lib/Utils.sol";

// interfaces
import { IFeeClaimer } from "./IFeeClaimer.sol";

// helpers
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Fee Claimer
 * @author paraswap
 * @notice a contract that holds balances of ParaSwap Protocol as well as partners.
 *         the partners can later claim the tokens from this contract.
 */
contract FeeClaimer is IFeeClaimer {
    using SafeMath for uint256;
    /**@notice mapping for storing partner's and PP's share in fee of various ERC20 tokens */
    mapping(address => mapping(IERC20 => uint256)) public fees;

    /**@notice address of the augustusSwapper */
    address payable public immutable augustusSwapper;

    /**@notice amount of fees in token allocated*/
    mapping(IERC20 => uint256) public allocatedFees;

    //===constructor===
    constructor(address payable _augustusAddress) {
        augustusSwapper = _augustusAddress;
    }

    modifier onlyAugustusSwapper() {
        require(msg.sender == augustusSwapper, "FeeClaimer: 1");
        _;
    }

    //===external functions===

    /**
     * @inheritdoc IFeeClaimer
     */
    function registerFee(
        address _account,
        IERC20 _token,
        uint256 _fee
    ) external override onlyAugustusSwapper {
        uint256 _unallocatedFees = getUnallocatedFees(_token);
        if (_fee > _unallocatedFees) {
            _fee = _unallocatedFees;
        }
        allocatedFees[_token] = allocatedFees[_token].add(_fee);
        fees[_account][_token] = fees[_account][_token].add(_fee);
    }

    /**
     * @inheritdoc IFeeClaimer
     */
    function withdrawSomeERC20(
        IERC20 _token,
        uint256 _tokenAmount,
        address _recipient
    ) public override returns (bool) {
        uint256 _balance = fees[msg.sender][_token];
        require(_balance >= _tokenAmount, "FeeClaimer: 2");
        address _account = _recipient == address(0) ? msg.sender : _recipient;
        fees[msg.sender][_token] = _balance.sub(_tokenAmount);
        allocatedFees[_token] = allocatedFees[_token].sub(_tokenAmount);
        Utils.transferTokens(address(_token), payable(_account), _tokenAmount);
        return true;
    }

    /**
     * @inheritdoc IFeeClaimer
     */
    function batchWithdrawSomeERC20(
        IERC20[] calldata _tokens,
        uint256[] calldata _tokenAmounts,
        address _recipient
    ) external override returns (bool) {
        require(_tokens.length == _tokenAmounts.length, "FeeClaimer: 3");
        for (uint256 _i; _i < _tokens.length; _i++) {
            require(withdrawSomeERC20(_tokens[_i], _tokenAmounts[_i], _recipient), "FeeClaimer: 4");
        }
        return true;
    }

    /**
     * @inheritdoc IFeeClaimer
     */
    function withdrawAllERC20(IERC20 _token, address _recipient) public override returns (bool) {
        uint256 _balance = fees[msg.sender][_token];
        require(_balance > 0, "FeeClaimer: 5");
        address _account = _recipient == address(0) ? msg.sender : _recipient;
        fees[msg.sender][_token] = 0;
        allocatedFees[_token] = allocatedFees[_token].sub(_balance);
        Utils.transferTokens(address(_token), payable(_account), _balance);
        return true;
    }

    /**
     * @inheritdoc IFeeClaimer
     */
    function batchWithdrawAllERC20(IERC20[] calldata _tokens, address _recipient) external override returns (bool) {
        for (uint256 _i; _i < _tokens.length; _i++) {
            require(withdrawAllERC20(_tokens[_i], _recipient), "FeeClaimer: 6");
        }
        return true;
    }

    //===public view functions===

    /**
     * @inheritdoc IFeeClaimer
     */
    function getUnallocatedFees(IERC20 _token) public view override returns (uint256) {
        return Utils.tokenBalance(address(_token), address(this)).sub(allocatedFees[_token]);
    }

    /**
     * @inheritdoc IFeeClaimer
     */
    function getBalance(IERC20 _token, address _partner) external view override returns (uint256) {
        return fees[_partner][_token];
    }

    /**
     * @inheritdoc IFeeClaimer
     */
    function batchGetBalance(IERC20[] calldata _tokens, address _partner)
        external
        view
        override
        returns (uint256[] memory _fees)
    {
        uint256 _len = _tokens.length;
        _fees = new uint256[](_len);
        for (uint256 _i; _i < _tokens.length; _i++) {
            _fees[_i] = fees[_partner][_tokens[_i]];
        }
    }

    receive() external payable {}
}