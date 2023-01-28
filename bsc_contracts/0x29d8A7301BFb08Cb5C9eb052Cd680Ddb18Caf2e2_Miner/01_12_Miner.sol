// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20Burnable.sol";
import "AccessControl.sol";
import "SafeMath.sol";

contract Miner is ERC20Burnable, AccessControl {
    using SafeMath for uint256;

    struct TaxManagement {
        address taxTreasury;
        uint256 startTime;
        uint256 endTime;
        uint256 startRate;
        uint256 endRate;
    }


    mapping(uint256 => TaxManagement) public taxInfo;

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(address => bool) public isTaxed;
    mapping(address => uint256) public isTaxManaged;

    uint256 public maxMintLimit;

    uint256 public totalMinted;

    bool public isInitialised;

    modifier checkRole(address account, bytes32 role) {
        require(hasRole(role, account), "Role Does Not Exist");
        _;
    }

    constructor() ERC20("MINER", "Miner") {}

    function initialize() external {
        require(!isInitialised, "Already Initialised");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        maxMintLimit = 100000*(10**18);
        isInitialised = true;
    }

    function setTaxAddress(address _tax_address, uint256 _taxId, bool _isValid)
        external
        checkRole(msg.sender, OPERATOR_ROLE)
    {
        isTaxed[_tax_address] = _isValid;
        isTaxManaged[_tax_address] = _taxId;
    }

    function mint(address to, uint256 amount)
        external
        checkRole(msg.sender, MINT_ROLE)
    {
        require(
            totalMinted + amount <= maxMintLimit,
            "Minting Limit Will Exceeded"
        );
        _mint(to, amount);
        totalMinted += amount;
    }

    function giveRoleMinter(address wallet)
        external
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINT_ROLE, wallet);
    }

    function revokeRoleMinter(address wallet)
        external
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MINT_ROLE, wallet);
    }

    function transferRoleOwner(address wallet)
        external
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE)
    {
        grantRole(DEFAULT_ADMIN_ROLE, wallet);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function renounceOwnership()
        external
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE)
    {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function checkRoleAdmin(address wallet) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, wallet);
    }

    function checkRoleMinter(address wallet) external view returns (bool) {
        return hasRole(MINT_ROLE, wallet);
    }

    function setMaxMintLimit(uint256 _maxMintLimit)
        external
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE)
    {
        maxMintLimit = _maxMintLimit;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if(isTaxed[_msgSender()]){
            uint256 tax_amount;
            uint256 taxId = isTaxManaged[_msgSender()];
            (amount, tax_amount) = applyTax(taxId, amount);
            _transfer(_msgSender(), taxInfo[taxId].taxTreasury, tax_amount);
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
         if(isTaxed[_msgSender()]){
            uint256 tax_amount;
            uint256 taxId = isTaxManaged[_msgSender()];
            (amount, tax_amount) = applyTax(taxId, amount);
            _transfer(sender, taxInfo[taxId].taxTreasury, tax_amount);
        }

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function applyTax(uint256 taxId, uint256 _amount)
        public
        view
        returns (uint256, uint256)
    {
        TaxManagement memory tax_info = taxInfo[taxId];
        uint256 taxedAmount = 0;
        uint256 taxAmount = 0;
        uint256 currentTime = (block.timestamp.sub(tax_info.startTime));
        uint256 endTime = (tax_info.endTime.sub(tax_info.startTime));
        uint256 newTaxPercent = 0;
        if (tax_info.endTime >= block.timestamp) {
            newTaxPercent = tax_info.startRate.sub(
                ((tax_info.startRate.sub(tax_info.endRate)).div(endTime).mul(currentTime))
            );
        } else {
            newTaxPercent = tax_info.endRate;
        }
        taxAmount = (_amount.mul(newTaxPercent)).div(10**18).div(100);
        taxedAmount = _amount.sub(taxAmount);
        return (taxedAmount, taxAmount);
    }

    function setTaxInfo(
        uint256 taxId,
        address _taxTreasury,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startRate,
        uint256 _endRate
    ) public checkRole(msg.sender, OPERATOR_ROLE) {
        taxInfo[taxId] = TaxManagement({
            taxTreasury: _taxTreasury,
            startTime: _startTime,
            endTime: _endTime,
            startRate: _startRate,
            endRate: _endRate
        });
    }
}