// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title CCXClaim
 * @author ClearCryptos Blockchain Team - G3NOM3
 */
contract CCXClaim is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable private s_token;

    bool private s_paused;
    mapping(address => bool) private s_isOperational;
    mapping(address => bool) private s_isBlacklisted;

    mapping(address => uint256) private s_claimableAmount;

    /**
     * @param _token Address of the token being claimed
     */
    function initialize(address _token) public initializer {
        require(
            _token != address(0),
            "CCXClaim - Token address cannot be the zero address"
        );

        s_token = IERC20Upgradeable(_token);
        s_paused = true;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Function used to return the token address
     *
     * @return s_token token being claimed
     */
    function token() public view returns (IERC20Upgradeable) {
        return s_token;
    }

    /**
     * @dev Set new claimed token
     *
     * @param _token address of the new claimed token
     */
    function setToken(address _token) external onlyOwner {
        require(
            _token != address(0),
            "CCXClaim - Token address cannot be the zero address"
        );
        s_token = IERC20Upgradeable(_token);
    }

    /**
     * @dev Function used to return pause state
     *
     * @return paused activity state of the claim
     */
    function paused() public view returns (bool) {
        return s_paused;
    }

    /**
     * @dev Function used to set new activity state of the claim
     *
     * @param _paused new activity state
     */
    function setPaused(bool _paused) external onlyOwner {
        require(s_paused != _paused, "CCXClaim - Value already set");
        s_paused = _paused;
    }

    /**
     * @dev Function used to check if the input address is an operations provider.
     *
     * @param _operationalAddress is a possible operations provider's address.
     */
    function isOperational(
        address _operationalAddress
    ) external view virtual returns (bool) {
        return s_isOperational[_operationalAddress];
    }

    /**
     * @dev Function used to add Operational Address.
     *
     * @param _operationalAddress is a new operations provider's address.
     */
    function setOperational(
        address _operationalAddress
    ) external virtual onlyOwner {
        require(
            _operationalAddress != address(0),
            "CCXClaim - Zero address cannot be operational"
        );
        s_isOperational[_operationalAddress] = true;
    }

    /**
     * @dev Function used to remove Operational Address
     *
     * @param _operationalAddress is an existing operations provider's address.
     */
    function removeOperational(
        address _operationalAddress
    ) external virtual onlyOwner {
        delete s_isOperational[_operationalAddress];
    }

    /**
     * @dev Function used to check if an address is blacklisted
     *
     * @param _blacklistedAddress is a possible blacklisted address
     */
    function isBlacklisted(
        address _blacklistedAddress
    ) external view virtual returns (bool) {
        return s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev Function used to add new Blacklisted Address
     *
     * Requirements:
     *
     * - `_blacklistedAddress` cannot be the zero address.
     *
     * @param _blacklistedAddress is a new blacklisted address.
     */
    function setBlacklisted(
        address _blacklistedAddress
    ) external virtual onlyOwner {
        require(
            _blacklistedAddress != address(0),
            "CCXClaim - Zero address cannot be blacklisted"
        );
        s_isBlacklisted[_blacklistedAddress] = true;
    }

    /**
     * @dev Function used to remove Blacklisted Address
     *
     * @param _blacklistedAddress is an existing blacklisted address
     */
    function removeBlacklisted(
        address _blacklistedAddress
    ) external virtual onlyOwner {
        delete s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev Function used to add claimable amounts. If an address has initially 0 claimable amount,
     * the new amount is 0 + {new_amount}. The function is used to assign new tokens to wallets without
     * taking into account previous set amounts.
     * Requirements:
     *
     * - `_recipients` length needs to be equal to `_amounts`.
     *
     * @param _recipients array of wallets for which new claimable amounts are added
     * @param _amounts array of claimable amounts
     */
    function addClaimable(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external virtual onlyOwner {
        require(_recipients.length == _amounts.length, "CCXClaim - Bad Inputs");

        for (uint256 i; i < _recipients.length; i++) {
            s_claimableAmount[_recipients[i]] = s_claimableAmount[
                _recipients[i]
            ].add(_amounts[i].mul(1 ether));
        }
    }

    /**
     * @dev Function used to set new claimable amounts.
     *
     * Requirements:
     *
     * - `_recipients` length needs to be equal to `_amounts`.
     *
     * @param _recipients array of wallets for which new claimable amounts are set
     * @param _amounts array of claimable amounts
     */
    function setClaimable(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external virtual onlyOwner {
        require(_recipients.length == _amounts.length, "CCXClaim - Bad Inputs");

        for (uint256 i; i < _recipients.length; i++) {
            s_claimableAmount[_recipients[i]] = _amounts[i].mul(1 ether);
        }
    }

    /**
     * @dev Function used to return the amount claimable by the input address.
     *
     * @param _recipient address for which the claimable amount is returned
     */
    function getClaimableAmountOfAddress(
        address _recipient
    ) external view virtual returns (uint256) {
        return s_claimableAmount[_recipient];
    }

    /**
     * @dev Function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     *
     * Requirements:
     *
     * - `msg.sender` cannot be blacklisted.
     * - `s_claimableAmount[msg.sender]` cannot be lower or equal to 0.
     * - if `msg.sender` is not operational, `s_paused` needs to be false
     */
    function claimTokens() public nonReentrant {
        require(!s_isBlacklisted[msg.sender], "CCXClaim - Address blacklisted");
        require(
            s_claimableAmount[msg.sender] > 0,
            "CCXClaim - Nothing to claim"
        );
        if (!s_isOperational[msg.sender]) {
            require(s_paused == false, "CCXClaim - Activity paused");
        }

        uint256 tempClaimableAmount = s_claimableAmount[msg.sender];
        s_claimableAmount[msg.sender] = 0;
        s_token.transfer(msg.sender, tempClaimableAmount);
    }

    /**
     * @dev Function used to withdraw tokens from the contract and send to the owner.
     *
     * Requirements:
     *
     * - `amountTokens` cannot be higher than the balance of the contract.
     * - `amountTokens` cannot be lower or equal to 0.
     *
     * @param amountTokens total of tokens to be withdrawn
     */
    function withdrawTokens(uint256 amountTokens) external virtual onlyOwner {
        require(
            amountTokens <= s_token.balanceOf(address(this)) &&
                amountTokens > 0,
            "Wrong amount"
        );
        s_token.transfer(owner(), amountTokens.mul(1 ether));
    }
}