// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "./libraries/ERC20TaxTokenU.sol";

contract RatchetToken is ERC20TaxTokenU, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    struct TokenAllocation {
        string name;                    // LP, Presale, Team, Marketing, Reserve
        address wallet;                 // The wallet address
        uint256 allocationAmount;       // Amount to mint to the wallet
        uint256 lockingDuration;        // Locking Duration
        uint256 vestingDuration;        // Vesting Duration
    }

    // Token time lock
    address public team_vesting_wallet;

    TokenAllocation public teamAllocation;
    TokenAllocation public reserveAllocation;

    mapping(uint8 => uint256) public authMinted;
    IERC20 public paymentToken;
    uint public usdcPrice;


    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory name,
        string memory symbol,
        TokenAllocation memory _teamAllocation,
        TokenAllocation memory _reserveAllocation,
        IERC20 _paymentToken,
        uint _usdcPrice
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);

        TaxFee[] memory taxFees;
        __TaxToken_init(taxFees);
        __Pausable_init();

        teamAllocation = _teamAllocation;
        reserveAllocation = _reserveAllocation;
        paymentToken = _paymentToken;
        usdcPrice = _usdcPrice;

        team_vesting_wallet = address(
            new VestingWallet(
                _teamAllocation.wallet,
                uint64(block.timestamp + _teamAllocation.lockingDuration),
                uint64(_teamAllocation.vestingDuration)
            )
        );

        _mint(_reserveAllocation.wallet, _reserveAllocation.allocationAmount);
        _mint(team_vesting_wallet, _teamAllocation.allocationAmount);

        addAuthorized(_msgSender());

        startTaxToken(true);
        setTaxExclusion(address(this), true);
        setTaxExclusion(_msgSender(), true);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////


    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function buyTokens(uint quantityToBuy) public {
        uint remaining = balanceOf(reserveAllocation.wallet);

        require(remaining >= quantityToBuy, "[email protected] tokens remaining in reserve wallet.");
        uint costInUsdc = usdcPrice * quantityToBuy;
        bool success = paymentToken.transferFrom(_msgSender(), address(this), costInUsdc);
        require(success, "[email protected] to transfer payment from sender");
        _transfer(reserveAllocation.wallet, _msgSender(), quantityToBuy);
    }

    function withdraw() public onlyOwner {
        address payable to = payable(_msgSender());
        uint balance = paymentToken.balanceOf(address(this));
        bool success = paymentToken.transfer(to, balance);
        require(success, "[email protected] to withdraw funds");
    }

    function updatePurchaseSettings(IERC20 _paymentToken, uint _paymentPrice) public onlyAuthorized {
        paymentToken = _paymentToken;
        usdcPrice = _paymentPrice;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function authMint(uint8 _type, address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
        authMinted[_type] = authMinted[_type].add(_amount);
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        uint256 _transAmount = _amount;
        if (isTaxTransable(_from)) {
            uint256 taxAmount = super.calcTransFee(_amount);
            transFee(_from, taxAmount);
            _transAmount = _amount.sub(taxAmount);
        }
        super._transfer(_from, _to, _transAmount);
    }

}