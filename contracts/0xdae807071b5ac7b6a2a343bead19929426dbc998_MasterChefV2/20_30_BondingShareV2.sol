// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "./UbiquityAlgorithmicDollarManager.sol";
import "./utils/SafeAddArray.sol";

contract BondingShareV2 is ERC1155, ERC1155Burnable, ERC1155Pausable {
    using SafeAddArray for uint256[];
    struct Bond {
        // address of the minter
        address minter;
        // lp amount deposited by the user
        uint256 lpFirstDeposited;
        uint256 creationBlock;
        // lp that were already there when created
        uint256 lpRewardDebt;
        uint256 endBlock;
        // lp remaining for a user
        uint256 lpAmount;
    }

    UbiquityAlgorithmicDollarManager public manager;
    // Mapping from account to operator approvals
    mapping(address => uint256[]) private _holderBalances;
    mapping(uint256 => Bond) private _bonds;
    uint256 private _totalLP;
    uint256 private _totalSupply;

    // ----------- Modifiers -----------
    modifier onlyMinter() {
        require(
            manager.hasRole(manager.UBQ_MINTER_ROLE(), msg.sender),
            "Governance token: not minter"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            manager.hasRole(manager.UBQ_BURNER_ROLE(), msg.sender),
            "Governance token: not burner"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            manager.hasRole(manager.PAUSER_ROLE(), msg.sender),
            "Governance token: not pauser"
        );
        _;
    }

    /**
     * @dev constructor
     */
    constructor(address _manager, string memory uri) ERC1155(uri) {
        manager = UbiquityAlgorithmicDollarManager(_manager);
    }

    /// @dev update bond LP amount , LP rewards debt and end block.
    /// @param _bondId bonding share id
    /// @param _lpAmount amount of LP token deposited
    /// @param _lpRewardDebt amount of excess LP token inside the bonding contract
    /// @param _endBlock end locking period block number
    function updateBond(
        uint256 _bondId,
        uint256 _lpAmount,
        uint256 _lpRewardDebt,
        uint256 _endBlock
    ) external onlyMinter whenNotPaused {
        Bond storage bond = _bonds[_bondId];
        uint256 curLpAmount = bond.lpAmount;
        if (curLpAmount > _lpAmount) {
            // we are removing LP
            _totalLP -= curLpAmount - _lpAmount;
        } else {
            // we are adding LP
            _totalLP += _lpAmount - curLpAmount;
        }
        bond.lpAmount = _lpAmount;
        bond.lpRewardDebt = _lpRewardDebt;
        bond.endBlock = _endBlock;
    }

    // @dev Creates `amount` new tokens for `to`, of token type `id`.
    /// @param to owner address
    /// @param lpDeposited amount of LP token deposited
    /// @param lpRewardDebt amount of excess LP token inside the bonding contract
    /// @param endBlock block number when the locking period ends
    function mint(
        address to,
        uint256 lpDeposited,
        uint256 lpRewardDebt,
        uint256 endBlock
    ) public virtual onlyMinter whenNotPaused returns (uint256 id) {
        id = _totalSupply + 1;
        _mint(to, id, 1, bytes(""));
        _totalSupply += 1;
        _holderBalances[to].add(id);
        Bond storage _bond = _bonds[id];
        _bond.minter = to;
        _bond.lpFirstDeposited = lpDeposited;
        _bond.lpAmount = lpDeposited;
        _bond.lpRewardDebt = lpRewardDebt;
        _bond.creationBlock = block.number;
        _bond.endBlock = endBlock;
        _totalLP += lpDeposited;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     */
    function pause() public virtual onlyPauser {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     */
    function unpause() public virtual onlyPauser {
        _unpause();
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override whenNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
        _holderBalances[to].add(id);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenNotPaused {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        _holderBalances[to].add(ids);
    }

    /**
     * @dev Total amount of tokens  .
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Total amount of LP tokens deposited.
     */
    function totalLP() public view virtual returns (uint256) {
        return _totalLP;
    }

    /**
     * @dev return bond details.
     */
    function getBond(uint256 id) public view returns (Bond memory) {
        return _bonds[id];
    }

    /**
     * @dev array of token Id held by the msg.sender.
     */
    function holderTokens(address holder)
        public
        view
        returns (uint256[] memory)
    {
        return _holderBalances[holder];
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override whenNotPaused {
        require(amount == 1, "amount <> 1");
        super._burn(account, id, 1);
        Bond storage _bond = _bonds[id];
        require(_bond.lpAmount == 0, "LP <> 0");
        _totalSupply -= 1;
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override whenNotPaused {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply -= amounts[i];
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}