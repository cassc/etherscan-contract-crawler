// SPDX-License-Identifier: MIT

pragma solidity 0.5.14;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract WishMultisender is Ownable, ReentrancyGuard
{
    using SafeMath for uint128;
    using SafeMath for uint256;

    bool private isInitialized;

    uint128 public fee;

    // events
    event MultisendedToken(address token, uint256 amount);
    event MultisendedEth(uint256 amount);
    event AutoMultisendToken(address token, uint256 amount);
    event AutoMultisendEth(uint256 amount);
    event ClaimedTokens(address token, address payable ownerPayable, uint256 amount);

    // modifiers
    modifier initialized{
        require(
            isInitialized == true,
            "WishMultisender: Contract not initialized"
        );
        _;
    }

    modifier hasFee(uint256 ethToDistribute) {
        if (fee > 0) {
            require(
                msg.value.sub(ethToDistribute) >= fee,
                "WishMultisender: No fee"
            );
        }
        _;
    }

    modifier validLists(uint256 _contributorsLength, uint256 _balancesLength) {
        require(_contributorsLength > 0, "WishMultisender: No contributors sent");
        require(
            _contributorsLength == _balancesLength,
            "WishMultisender: Different arrays lengths"
        );
        _;
    }

    // public and external functions
    constructor() public{
        isInitialized = false;
    }

    function init(
        uint128 _fee
    )
        external
        onlyOwner
    {
        require(
            isInitialized == false,
            "WishMultisender: Already initialized"
        );

        fee = _fee;

        isInitialized = true;
    }

    function tokenFallback(address _from, uint _value, bytes calldata _data) external {}

    function multisendToken(
        IERC20 _token,
        address[] calldata contributors,
        uint256[] calldata balances,
        uint256 _total
    )
        external
        payable
        validLists(
            contributors.length,
            balances.length
        )
        hasFee(0)
        initialized
        nonReentrant
    {
        uint256 total = _total;
        require(
            _token.transferFrom(
                msg.sender,
                address(this),
                total
            ),
            "WishMultisender: Couldn't transfer tokens to contract"
        );
        for (uint256 i = 0; i < contributors.length; i++) {
            require(
                _token.transfer(
                    contributors[i],
                    balances[i]
                ),
                "WishMultisender: Couldn't transfer tokens to user"
            );
            total = total.sub(balances[i]);
        }
        require(
            total == 0,
            "WishMultisender: Wrong amount of total"
        );
        emit MultisendedToken(address(_token), _total);
    }

    function multisendEth(
        address payable[] calldata contributors,
        uint256[] calldata balances,
        uint256 _total
    )
        external
        payable
        validLists(
            contributors.length,
            balances.length
        )
        hasFee(_total)
        initialized
        nonReentrant
    {
        uint256 total = _total;

        for (uint256 i = 0; i < contributors.length; i++) {
            contributors[i].transfer(balances[i]);
            total = total.sub(balances[i]);
        }
        require(
            total == 0,
            "WishMultisender: Wrong amount of total"
        );
        emit MultisendedEth(_total);
    }

    function claimTokens(
        address _token,
        uint256 _amount
    )
        external
        onlyOwner
        nonReentrant
    {
        address payable ownerPayable = address(uint160(owner()));
        uint256 amount = _amount;
        if (_amount == 0) {
            amount = address(this).balance;
        }
        if (_token == address(0)) {
            ownerPayable.transfer(amount);
            emit ClaimedTokens(address(0), ownerPayable, amount);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        if (_amount == 0)
            amount = erc20token.balanceOf(address(this));
        else
            amount = _amount;
        require(
            erc20token.transfer(ownerPayable, amount),
            "WishMultisender: Couldn't transfer tokens to owner"
        );
        emit ClaimedTokens(_token, ownerPayable, amount);
    }

    function setFee(uint128 newFee) external onlyOwner
    {
        fee = newFee;
    }

    function autoMultisendToken(
        IERC20 token,
        uint256 amount
    )
        external
        payable
        hasFee(0)
        initialized
        nonReentrant
    {
        require(
            token.transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "WishMultisender: Couldn't transfer tokens to contract"
        );
        emit AutoMultisendToken(address(token), amount);
    }

    function autoMultisendEth(
        uint256 amount
    )
        external
        payable
        hasFee(amount)
        initialized
        nonReentrant
    {
        emit AutoMultisendEth(amount);
    }

    // internal and private functions
}