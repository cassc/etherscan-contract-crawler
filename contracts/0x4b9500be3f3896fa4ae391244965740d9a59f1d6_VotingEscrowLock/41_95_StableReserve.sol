//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/work/interfaces/IStableReserve.sol";
import "../../core/work/interfaces/IGrantReceiver.sol";
import "../../core/tokens/COMMIT.sol";
import "../../core/governance/Governed.sol";
import "../../utils/ERC20Recoverer.sol";

/**
 * @notice StableReserve is the $COMMIT minter. It allows ContributionBoard to mint $COMMIT token.
 */
contract StableReserve is ERC20Recoverer, Governed, IStableReserve {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address private _commitToken;
    address private _baseCurrency;
    uint256 private _priceOfCommit;
    mapping(address => bool) private _allowed; // allowed crypto job board contracts
    address private _deployer;

    function initialize(
        address gov_,
        address commitToken_,
        address baseCurrency_,
        address[] memory admins
    ) public initializer {
        _priceOfCommit = 20000; // denominator = 10000, ~= $2
        _commitToken = commitToken_;
        _baseCurrency = baseCurrency_;

        address[] memory disable = new address[](2);
        disable[0] = commitToken_;
        disable[1] = baseCurrency_;
        ERC20Recoverer.initialize(gov_, disable);
        Governed.initialize(gov_);
        _deployer = msg.sender;
        _allow(gov_, true);
        for (uint256 i = 0; i < admins.length; i++) {
            _allow(admins[i], true);
        }
    }

    modifier onlyAllowed() {
        require(_allowed[msg.sender], "Not authorized");
        _;
    }

    function redeem(uint256 amount) public override {
        require(
            COMMIT(_commitToken).balanceOf(msg.sender) >= amount,
            "Not enough balance"
        );
        COMMIT(_commitToken).burnFrom(msg.sender, amount);
        IERC20(_baseCurrency).transfer(msg.sender, amount);
        emit Redeemed(msg.sender, amount);
    }

    function payInsteadOfWorking(uint256 amount) public override {
        uint256 amountToPay = amount.mul(_priceOfCommit).div(10000);
        IERC20(_baseCurrency).safeTransferFrom(
            msg.sender,
            address(this),
            amountToPay
        );
        _mintCOMMIT(msg.sender, amount);
    }

    function reserveAndMint(uint256 amount) public override onlyAllowed {
        IERC20(_baseCurrency).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _mintCOMMIT(msg.sender, amount);
    }

    function grant(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public override governed {
        _mintCOMMIT(recipient, amount);
        bytes memory returndata =
            address(recipient).functionCall(
                abi.encodeWithSelector(
                    IGrantReceiver(recipient).receiveGrant.selector,
                    _commitToken,
                    amount,
                    data
                ),
                "GrantReceiver: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "GrantReceiver: low-level call failed"
            );
        }
    }

    function allow(address account, bool active) public override governed {
        _allow(account, active);
    }

    function baseCurrency() public view override returns (address) {
        return _baseCurrency;
    }

    function commitToken() public view override returns (address) {
        return _commitToken;
    }

    function priceOfCommit() public view override returns (uint256) {
        return _priceOfCommit;
    }

    function mintable() public view override returns (uint256) {
        uint256 currentSupply = COMMIT(_commitToken).totalSupply();
        uint256 currentRedeemable =
            IERC20(_baseCurrency).balanceOf(address(this));
        return currentRedeemable.sub(currentSupply);
    }

    function allowed(address account) public view override returns (bool) {
        return _allowed[account];
    }

    function _mintCOMMIT(address to, uint256 amount) internal {
        require(amount <= mintable(), "Not enough reserve");
        COMMIT(_commitToken).mint(to, amount);
    }

    function _allow(address account, bool active) internal {
        if (_allowed[account] != active) {
            emit AdminUpdated(account);
        }
        _allowed[account] = active;
    }
}