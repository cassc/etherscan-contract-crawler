// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BlokToken.sol";

contract Governance is Context, Ownable {
    using SafeMath for uint256;

    address admin; // admin address
    address token; // token address

    IERC20 stableCoin; // stable Coin address for dividends

    mapping(address => uint256) public claimableStable; // Claimable StableCoin for Specific User
    mapping(address => uint256) public totalClaimedDiv; // Total Claimed Dividend Stable Coin by Specific User
    uint256 public totalDividend; // Total Dividend Sent to This Property

    constructor(address _token, address _stableCoin) {
        admin = _msgSender();
        token = _token;
        stableCoin = IERC20(_stableCoin);
    }

    /**
     * @dev onlyAdmin Modifier only Admin will allow to perform action
     */
    modifier onlyAdmin(address user) {
        require(user == admin, "Only Admin Allowed");
        _;
    }
    /**
     * @dev List of All event which performing in Contract
     */
    event SendDividends(uint256 dividend);
    event SendDividend(address user, uint256 dividend);
    event SetStableCoin(address stableCoin, address admin);
    event ClaimDividend(address claimer, uint256 claimingTokenAmount);

    /**
     * @notice Only Admin is possible to call
     * @param _dividend the total Stable Coins from Admin
     * @dev Send Stable Coins to Contract and add claimable dividends for all users
     */
    function sendDividends(uint256 _dividend) external onlyAdmin(_msgSender()) {
        require(
            stableCoin.allowance(_msgSender(), address(this)) >= _dividend,
            "Not allowed to send dividends"
        );
        stableCoin.transferFrom(_msgSender(), address(this), _dividend);
        totalDividend = totalDividend.add(_dividend);
        uint256 totalSupply = BlokToken(token).totalSupply();
        for (uint256 i = 0; i < BlokToken(token).getHolders().length; i++) {
            uint256 balance = BlokToken(token).balanceOf(
                BlokToken(token).getHolders()[i]
            );
            claimableStable[BlokToken(token).getHolders()[i]] = claimableStable[
                BlokToken(token).getHolders()[i]
            ].add(_dividend.mul(balance).div(totalSupply));
        }
        emit SendDividends(_dividend);
    }

    /**
     * @notice Only Admin is possible to call
     * @param _user the token holder to receive dividend.
     * @param _dividend the dividend for a specific user.
     * @dev Send a dividend for a specific user.
     */
    function sendDividend(
        address _user,
        uint256 _dividend
    ) external onlyAdmin(_msgSender()) {
        require(
            stableCoin.allowance(_msgSender(), address(this)) >= _dividend,
            "Not allowed to send dividend"
        );
        stableCoin.transferFrom(_msgSender(), address(this), _dividend);
        totalDividend = totalDividend.add(_dividend);
        claimableStable[_user] = claimableStable[_user].add(_dividend);
        emit SendDividend(_user, _dividend);
    }

    /**
     * @param _users the addresses to compare
     * @param _user the address to compare
     * @dev Compare a specfic address is belong to address array
     */
    function _isBelongTo(
        address[] memory _users,
        address _user
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _users.length; i++) {
            if (_users[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @param _stableCoin the stable coin address
     * @dev Change Stable Coin that accepting for Dividends
     */
    function setStableCoin(
        address _stableCoin
    ) external onlyAdmin(_msgSender()) {
        stableCoin = IERC20(_stableCoin);
        emit SetStableCoin(_stableCoin, _msgSender());
    }

    /**
     * @dev Claim Dividend by Investor/BlokToken Owners
     */
    function claimDividend() external {
        require(
            claimableStable[_msgSender()] > 0,
            "You do not have any Dividend"
        );
        uint256 dividend = claimableStable[_msgSender()];
        totalClaimedDiv[_msgSender()] = totalClaimedDiv[_msgSender()].add(
            dividend
        );
        claimableStable[_msgSender()] = 0;
        stableCoin.transfer(_msgSender(), dividend);
        emit ClaimDividend(_msgSender(), dividend);
    }

    /**
     * @dev  Return claimable Stable Coins for each holders
     */
    function getClaimableStable() external view returns (uint256) {
        return claimableStable[_msgSender()];
    }

    /**
     * @dev Return total claimed dividend for each holders
     */
    function getTotalClaimedDiv() external view returns (uint256) {
        return totalClaimedDiv[_msgSender()];
    }
}