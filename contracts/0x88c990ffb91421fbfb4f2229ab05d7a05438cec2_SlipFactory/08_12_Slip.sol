pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../contracts/external/ERC20.sol";

import "../interfaces/ISlip.sol";

/**
 * @dev ERC20 token to represent a single slip for a bond box
 */
contract Slip is ISlip, ERC20, Initializable {
    address public collateralToken;
    address public override boxOwner;

    /**
     * @dev Constructor for Tranche ERC20 token
     */
    constructor() ERC20("IMPLEMENTATION", "IMPL") {
        // NO-OP
    }

    /**
     * @dev Constructor for Slip ERC20 token
     * @param name the ERC20 token name
     * @param symbol The ERC20 token symbol
     * @param _boxOwner The owner of the box
     * @param _collateralToken The address of the ERC20 collateral token
     */
    function init(
        string memory name,
        string memory symbol,
        address _boxOwner,
        address _collateralToken
    ) public initializer {
        require(_boxOwner != address(0), "Slip: Invalid owner address");
        require(
            _collateralToken != address(0),
            "Slip: invalid collateralToken address"
        );

        boxOwner = _boxOwner;
        collateralToken = _collateralToken;

        super.init(name, symbol);
    }

    /**
     * @dev Throws if called by any account other than the bond.
     */
    modifier onlyBoxOwner() {
        require(boxOwner == _msgSender(), "Ownable: caller is not the bond");
        _;
    }

    /**
     * @inheritdoc ISlip
     */
    function mint(address to, uint256 amount) external override onlyBoxOwner {
        _mint(to, amount);
    }

    /**
     * @inheritdoc ISlip
     */
    function burn(address from, uint256 amount) external override onlyBoxOwner {
        _burn(from, amount);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Uses the same number of decimals as the collateral token
     */
    function decimals() public view override returns (uint8) {
        return IERC20Metadata(collateralToken).decimals();
    }

    /**
     * @inheritdoc ISlip
     */
    function changeOwner(address newOwner) external override onlyBoxOwner {
        if (newOwner != _msgSender()) {
            emit OwnershipTransferred(_msgSender(), newOwner);
            boxOwner = newOwner;
        }
    }
}