// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/token/IToken.sol";
import "../interfaces/chainlink/IAggregatorV3.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "./../Owned.sol";

/**
 * @title RevenueSplitter
 * @dev This contract allows to split ERC20 and Ether tokens among a group of accounts. The sender does not need to be aware
 * that the token(s) (revenue) will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the fund this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `RevenueSplitter` follows a pull revenue model. This means that revenue is not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release} or {releaseEther}
 * function.
 */
contract RevenueSplitter is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // events
    event PayeeAdded(address indexed payee, uint256 share);
    event PaymentReleased(address indexed payee, address indexed asset, uint256 tokens);
    event VTokenAdded(address indexed vToken, address indexed oracle);
    event VTokenRemoved(address indexed vToken, address indexed oracle);

    // Total share.
    uint256 public totalShare;
    // Total released for an asset.
    mapping(address => uint256) public totalReleased;
    // Payee's share
    mapping(address => uint256) public share;
    // Payee's share released for an asset
    mapping(address => mapping(address => uint256)) public released;
    // list of payees
    address[] public payees;
    address[] public vTokens;
    mapping(address => bool) private isVToken;
    mapping(address => address) public oracles; // vToken to collateral token's oracle mapping
    address private constant VESPER_DEPLOYER = 0xB5AbDABE50b5193d4dB92a16011792B22bA3Ef51;
    uint256 public constant HIGH = 20e18; // 20 Ether
    uint256 public constant LOW = 10e18; // 10 Ether
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    bool public isAutoTopUpEnabled;
    bool public isTopUpEnabled;

    /**
     * @dev Creates an instance of `RevenueSplitter` where each account in `_payees` is assigned token(s) at
     * the matching position in the `_share` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * @param _payees -  address(es) of payees eligible to receive token(s)
     * @param _share - list of shares, transferred to payee in provided ratio.
     */

    constructor(address[] memory _payees, uint256[] memory _share) public {
        // solhint-disable-next-line max-line-length
        require(_payees.length == _share.length, "payees-and-share-length-mismatch");
        require(_payees.length > 0, "no-payees");
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _share[i]);
        }
    }

    /**
     * @dev Add vToken for vesper deployer top-up
     * @param _vToken - Vesper token
     * @param _oracle - Chainlink oracle address used for collateral token to ETH estimation
     * Find chainlink oracle details here https://docs.chain.link/docs/ethereum-addresses/
     * For pool with WETH as collateral token, we do not need _oracle and _oracle can have ZERO address.
     */
    function addVToken(address _vToken, address _oracle) external onlyOwner {
        require(_vToken != address(0), "vToken-is-zero-address");
        require(!isVToken[_vToken], "duplicate-vToken");
        if (IVesperPool(_vToken).token() != WETH) {
            require(_oracle != address(0), "oracle-is-zero-address");
            oracles[_vToken] = _oracle;
        }
        vTokens.push(_vToken);
        isVToken[_vToken] = true;
        emit VTokenAdded(_vToken, _oracle);
    }

    /**
     * @dev Remove vToken for vesper deployer top-up
     * @param _vToken - Vesper token
     */
    function removeVToken(address _vToken) external onlyOwner {
        require(_vToken != address(0), "vToken-is-zero-address");
        require(isVToken[_vToken], "vToken-not-found");
        for (uint256 i = 0; i < vTokens.length; i++) {
            if (vTokens[i] == _vToken) {
                vTokens[i] = vTokens[vTokens.length - 1];
                vTokens.pop();
                delete isVToken[_vToken];
                emit VTokenRemoved(_vToken, oracles[_vToken]);
                delete oracles[_vToken];
                break;
            }
        }
    }

    //solhint-disable no-empty-blocks
    receive() external payable {}

    /**
     * @dev Transfer of ERC20 token(s) to `payee` based on share and their previous withdrawals.
     * @param _payee - payee's address to receive token(s)
     * @param _asset - ERC20 token's address
     */
    function release(address _payee, address _asset) external {
        require(share[_payee] > 0, "payee-does-not-have-share");
        if (isAutoTopUpEnabled) {
            _topUp();
        }
        uint256 totalReceived = IERC20(_asset).balanceOf(address(this)).add(totalReleased[_asset]);
        uint256 tokens = _calculateAndUpdateReleasedTokens(_payee, _asset, totalReceived);
        IERC20(_asset).safeTransfer(_payee, tokens);
        emit PaymentReleased(_payee, _asset, tokens);
    }

    /**
     * @dev Transfer of ether to `payee` based on share and their previous withdrawals.
     * @param _payee - payee's address to receive ether
     */
    function releaseEther(address payable _payee) external {
        require(share[_payee] > 0, "payee-does-not-have-share");
        uint256 totalReceived = address(this).balance.add(totalReleased[ETH]);
        // find total received amount
        uint256 amount = _calculateAndUpdateReleasedTokens(_payee, ETH, totalReceived);
        // Transfer Ether to Payee.
        Address.sendValue(_payee, amount);
        emit PaymentReleased(_payee, ETH, amount);
    }

    /**
     * @notice Toggle auto top-up
     * @dev Toggle auto top-up to true will enable top-up too.
     */
    function toggleAutoTopUp() external onlyOwner {
        if (isAutoTopUpEnabled) {
            isAutoTopUpEnabled = false;
        } else {
            isAutoTopUpEnabled = true;
            isTopUpEnabled = true;
        }
    }

    /**
     * @notice Toggle top-up status
     * @dev Toggle top-up status to false will disable auto top-up too.
     */
    function toggleTopUpStatus() external onlyOwner {
        if (isTopUpEnabled) {
            isTopUpEnabled = false;
            isAutoTopUpEnabled = false;
        } else {
            isTopUpEnabled = true;
        }
    }

    /// @notice top-up Vesper deployer address
    function topUp() external {
        require(isTopUpEnabled, "top-up-is-disabled");
        _topUp();
    }

    /**
     * @dev Get vToken token value in Eth
     * @param _vToken - Vesper token
     * @param _owner - address owning vToken.
     */
    function _estimateVTokenValueInETh(IVesperPool _vToken, address _owner)
        private
        view
        returns (uint256 _valueInEth)
    {
        uint256 _collateralTokenAmount =
            _vToken.totalValue().mul(_vToken.balanceOf(_owner)).div(_vToken.totalSupply());
        if (_collateralTokenAmount > 0) {
            if (_vToken.token() == WETH) {
                _valueInEth = _collateralTokenAmount;
            } else {
                // answer is 1 collateral token price in ETH (18 decimals)
                int256 _answer = IAggregatorV3(oracles[address(_vToken)]).latestAnswer();
                uint256 _decimals = TokenLike(_vToken.token()).decimals();
                _valueInEth = uint256(_answer).mul(_collateralTokenAmount).div(10**_decimals);
            }
        }
    }

    /// @dev Top up Vesper deployer address when balance goes below low mark.
    function _topUp() private {
        uint256 _totalTokenValueInEth = VESPER_DEPLOYER.balance;
        if (_totalTokenValueInEth >= LOW) {
            return;
        }
        for (uint256 i = 0; i < vTokens.length; i++) {
            _totalTokenValueInEth = _totalTokenValueInEth.add(
                _estimateVTokenValueInETh(IVesperPool(vTokens[i]), VESPER_DEPLOYER)
            );
            if (_totalTokenValueInEth >= LOW) {
                return;
            }
        }
        uint256 _want = HIGH.sub(_totalTokenValueInEth);
        for (uint256 i = 0; i < vTokens.length; i++) {
            uint256 _vTokenBalanceInEth =
                _estimateVTokenValueInETh(IVesperPool(vTokens[i]), address(this));
            uint256 _tokenToTransfer = IERC20(vTokens[i]).balanceOf(address(this));
            if (_want > _vTokenBalanceInEth) {
                _want = _want.sub(_vTokenBalanceInEth);
                IERC20(vTokens[i]).safeTransfer(VESPER_DEPLOYER, _tokenToTransfer);
            } else {
                // transfer proportionally
                _tokenToTransfer = _want.mul(_tokenToTransfer).div(_vTokenBalanceInEth);
                IERC20(vTokens[i]).safeTransfer(VESPER_DEPLOYER, _tokenToTransfer);
                break;
            }
        }
    }

    /**
     * @dev Calculate token(s) for `payee` based on share and their previous withdrawals.
     * @param _payee - payee's address
     * @param _asset - token's address
     * return token(s)/ ether to be released
     */
    function _calculateAndUpdateReleasedTokens(
        address _payee,
        address _asset,
        uint256 _totalReceived
    ) private returns (uint256 tokens) {
        // find eligible token(s)/ether for a payee
        uint256 releasedTokens = released[_payee][_asset];
        tokens = _totalReceived.mul(share[_payee]).div(totalShare).sub(releasedTokens);
        require(tokens != 0, "payee-is-not-due-for-tokens");
        // update released token(s)
        released[_payee][_asset] = releasedTokens.add(tokens);
        totalReleased[_asset] = totalReleased[_asset].add(tokens);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param _payee - payee address
     * @param _share -  payee's share
     */
    function _addPayee(address _payee, uint256 _share) private {
        require(_payee != address(0), "payee-is-zero-address");
        require(_share > 0, "payee-with-zero-share");
        require(share[_payee] == 0, "payee-exists-with-share");
        payees.push(_payee);
        share[_payee] = _share;
        totalShare = totalShare.add(_share);
        emit PayeeAdded(_payee, _share);
    }
}