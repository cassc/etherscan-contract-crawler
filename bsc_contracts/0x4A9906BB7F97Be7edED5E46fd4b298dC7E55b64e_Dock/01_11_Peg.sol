// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libs/ERC20Burnable.sol";
import "./libs/Math.sol";
import "./libs/SafeMath8.sol";
import "./libs/Operator.sol";

import "./interfaces/IOracle.sol";

contract Dock is ERC20Burnable, Operator {
    using SafeMath8 for uint8;
    using SafeMath for uint256;

    // Initial distribution for the first 24h genesis pools
    uint256 public constant INITIAL_GENESIS_POOL_DISTRIBUTION = 2400 ether;
    // Initial distribution for the day 2-5 DOCK-BUSD LP -> DOCK pool
    uint256 public constant INITIAL_DOCK_POOL_DISTRIBUTION = 21600 ether;
    // Distribution for airdrops wallet
    uint256 public constant INITIAL_AIRDROP_WALLET_DISTRIBUTION = 1000 ether;

    // Have the rewards been distributed to the pools
    bool public rewardPoolDistributed = false;

    // Address of the Oracle
    address public dockOracle;

    /**
     * @notice Constructs the DOCK ERC-20 contract.
     */
    constructor() public ERC20("Dock", "DOCK") {
        // Mints 1 DOCK to contract creator for initial pool setup
        _mint(msg.sender, 2001 ether);
    }

    function _getDockPrice() internal view returns (uint256 _dockPrice) {
        try IOracle(dockOracle).consult(address(this), 1e18) returns (uint144 _price) {
            return uint256(_price);
        } catch {
            revert("Dock: failed to fetch DOCK price from Oracle");
        }
    }

    function setDockOracle(address _dockOracle) public onlyOperator {
        require(_dockOracle != address(0), "oracle address cannot be 0 address");
        dockOracle = _dockOracle;
    }

    /**
     * @notice Operator mints DOCK to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of DOCK to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(
        address _genesisPool,
        address _dockPool,
        address _airdropWallet
    ) external onlyOperator {
        require(!rewardPoolDistributed, "only can distribute once");
        require(_genesisPool != address(0), "!_genesisPool");
        require(_dockPool != address(0), "!_dockPool");
        require(_airdropWallet != address(0), "!_airdropWallet");
        rewardPoolDistributed = true;
        _mint(_genesisPool, INITIAL_GENESIS_POOL_DISTRIBUTION);
        _mint(_dockPool, INITIAL_DOCK_POOL_DISTRIBUTION);
        _mint(_airdropWallet, INITIAL_AIRDROP_WALLET_DISTRIBUTION);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}