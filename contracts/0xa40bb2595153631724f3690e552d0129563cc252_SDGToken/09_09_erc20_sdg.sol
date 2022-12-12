// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SDGToken
/// @author supremacygame.eth
/// @notice SDGToken is the ERC20 contract, minting on pledge
/// @custom:security-contact [email protected]
contract SDGToken is ERC20, Ownable {
    using SafeERC20 for ERC20;

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @notice Maximum supply, not changable
    uint256 public immutable supply_cap = 10_000_000 * 10**decimals();

    /// @notice The stablecoin accepted for the DAO
    ERC20 public usd;

    /// @notice difference in decimals between stablecoin and this token
    uint256 public decimal_gap;

    /// @notice Address for dao_allocation amount of DAO tokens
    address public dao_address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event UserPledged(address sender, uint256 amount);
    event AdminHasUpdatedUSD(address usd_addr);
    event AdminHasRescuedERC20(address tokenAddr);
    event AdminHasSetDAOAddress(address dao_address);

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    /// @notice Initializes the ERC20
    constructor(address _usd, address _daoAddress)
        ERC20("Salvation DAO Governance", "SDG")
    {
        usd = ERC20(address(_usd));
        decimal_gap = decimals() - usd.decimals();
        dao_address = _daoAddress;
    }

    /// -----------------------------------------------------------------------
    /// Admin actions
    /// -----------------------------------------------------------------------

    /// @notice AdminSetDAOAddress sets DAO address to receive tokens
    /// @param  _dao_addr New ERC20 address
    function AdminSetDAOAddress(address _dao_addr) public onlyOwner {
        dao_address = _dao_addr;
        emit AdminHasSetDAOAddress(_dao_addr);
    }

    /// @notice AdminSetUSD sets stablecoin address
    /// @param  usd_addr New ERC20 address
    function AdminSetUSD(address usd_addr) public onlyOwner {
        usd = ERC20(usd_addr);
        decimal_gap = 18 - usd.decimals();
        emit AdminHasUpdatedUSD(usd_addr);
    }

    /// @notice AdminRescueERC20 withdraws the ERC20 in case a user has erroneously sent ERC20 tokens over
    /// @param tokenAddr ERC20 to flush out
    function AdminRescueERC20(address tokenAddr) public onlyOwner {
        ERC20 token = ERC20(tokenAddr);
        uint256 amt = token.balanceOf(address(this));
        token.transfer(msg.sender, amt);
        emit AdminHasRescuedERC20(tokenAddr);
    }

    /// -----------------------------------------------------------------------
    /// User views
    /// -----------------------------------------------------------------------

    /// @notice Check if user can pledge amount, just checks against supply cap
    /// @param amount Amount to deposit
    function UserCanPledge(uint256 amount) public view returns (bool) {
        return totalSupply() + amount * 10**decimal_gap <= supply_cap;
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Pledge USD to mint DAO tokens
    /// @param amount Amount to deposit (requires approval first)
    function UserPledge(uint256 amount) public {
        require(
            totalSupply() + amount * 10**decimal_gap <= supply_cap,
            "exceeds supply cap"
        );
        require(usd.balanceOf(msg.sender) >= amount, "not enough usd");

        usd.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount * 10**decimal_gap);
        _mint(dao_address, amount * 10**decimal_gap);

        emit UserPledged(msg.sender, amount);
    }
}