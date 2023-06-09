// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

import "../Rewards/RewardDistributor/RewardDistributor.sol";

import "./IBaseTokenLogic.sol";
import "./IToken.sol";

contract Token is IToken, RewardDistributor, ERC20Burnable, ERC20Capped {

    bytes32 public constant override MINT_ROLE = keccak256('MINT_ROLE');

    address private $logic;

    constructor()
    ERC20("Kei Finance", "KEI")
    ERC20Capped(type(uint128).max) {}

    function decimals() public pure virtual override returns (uint8) {
        return 8;
    }

    function logic() external override view returns (address) {
        return $logic;
    }

    function predictTransfer(address from, address to, uint256 amount) external view returns (TransferResult memory result) {
        address _logic = $logic;

        // this can never be more than type(uint128).max as this uint128 is max total supply
        result.amount = uint128(amount);

        if (_logic == address(0)) {
            return result;
        }

        result = IBaseTokenLogic(_logic).predictTransfer(from, to, amount);
    }

    function updateLogic(address newLogic) external onlyRole(MANAGE_ROLE) override {
        emit LogicUpdate($logic, newLogic, _msgSender());
        $logic = newLogic;
    }

    function mint(uint256 amount) external onlyRole(MINT_ROLE) whenNotPaused override {
        _mint(K.treasury(), amount);
    }

    function burn(uint256 amount) public whenNotPaused override(ERC20Burnable, IToken) {
        super.burn(amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IToken).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        address _logic = $logic;

        // this can never be more than type(uint128).max as this uint128 is max total supply
        if (_logic != address(0)) {
            TransferResult memory _result = IBaseTokenLogic(_logic).handleTransfer(from, to, amount);

            unchecked {
                require(amount == (_result.amount + _result.burn + _result.fee), 'Token: INVALID_TRANSFER_RESULT');
            }

            super._transfer(from, to, _result.amount);

            // can only mint or burn, there is no point in doing both, as it would be a waste in gas
            if (_result.mint > 0) _mint(to, _result.mint);
            else if (_result.burn > 0) _burn(from, _result.burn);

            if (_result.fee > 0) {
                IKEI.Core memory _k = _core();
                super._transfer(from, _k.treasury, _result.fee);
                _distributeProfitTokens(_result.fee, _k);
            }
        } else {
            super._transfer(from, to, amount);
        }

    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}