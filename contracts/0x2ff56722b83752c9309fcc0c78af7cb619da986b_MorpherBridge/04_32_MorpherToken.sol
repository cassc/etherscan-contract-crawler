//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "./MorpherAccessControl.sol";

contract MorpherToken is ERC20Upgradeable, ERC20PausableUpgradeable {

    MorpherAccessControl public morpherAccessControl;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant TRANSFERBLOCKED_ROLE = keccak256("TRANSFERBLOCKED_ROLE");
    bytes32 public constant POLYGONMINTER_ROLE = keccak256("POLYGONMINTER_ROLE");

    uint256 private _totalTokensOnOtherChain;
    uint256 private _totalTokensInPositions;
    bool private _restrictTransfers;

    event SetTotalTokensOnOtherChain(uint256 _oldValue, uint256 _newValue);
    event SetTotalTokensInPositions(uint256 _oldValue, uint256 _newValue);
    event SetRestrictTransfers(bool _oldValue, bool _newValue);

    function initialize(address _morpherAccessControl) public initializer {
        ERC20Upgradeable.__ERC20_init("Morpher", "MPH");
        morpherAccessControl = MorpherAccessControl(_morpherAccessControl);
    }

    modifier onlyRole(bytes32 role) {
        require(morpherAccessControl.hasRole(role, _msgSender()), "MorpherToken: Permission denied.");
        _;
    }

    // function getMorpherAccessControl() public view returns(address) {
    //     return address(morpherAccessControl);
    // }

    function setRestrictTransfers(bool restrictTransfers) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetRestrictTransfers(_restrictTransfers, restrictTransfers);
        _restrictTransfers = restrictTransfers;
    }

    function getRestrictTransfers() public view returns(bool) {
        return _restrictTransfers;
    }

    function setTotalTokensOnOtherChain(uint256 totalOnOtherChain) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetTotalTokensOnOtherChain(_totalTokensInPositions, totalOnOtherChain);
        _totalTokensOnOtherChain = totalOnOtherChain;
    }

    function getTotalTokensOnOtherChain() public view returns(uint256) {
        return _totalTokensOnOtherChain;
    }

    function setTotalInPositions(uint256 totalTokensInPositions) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetTotalTokensInPositions(_totalTokensInPositions, totalTokensInPositions);
        _totalTokensInPositions = totalTokensInPositions;
    }

    function getTotalTokensInPositions() public view returns(uint256) {
        return _totalTokensInPositions;
    }


    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() + _totalTokensOnOtherChain + _totalTokensInPositions;
    }

    function deposit(address user, bytes calldata depositData) external onlyRole(POLYGONMINTER_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    function withdraw(uint256 amount) external onlyRole(POLYGONMINTER_ROLE) {
        _burn(msg.sender, amount);
    }


    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(morpherAccessControl.hasRole(MINTER_ROLE, _msgSender()), "MorpherToken: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Burns `amount` of tokens for `from`.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     */
    function burn(address from, uint256 amount) public virtual {
        require(morpherAccessControl.hasRole(BURNER_ROLE, _msgSender()), "MorpherToken: must have burner role to burn");
        _burn(from, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(morpherAccessControl.hasRole(PAUSER_ROLE, _msgSender()), "MorpherToken: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(morpherAccessControl.hasRole(PAUSER_ROLE, _msgSender()), "MorpherToken: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        require(
            !_restrictTransfers || 
            morpherAccessControl.hasRole(TRANSFER_ROLE, _msgSender()) || 
            morpherAccessControl.hasRole(MINTER_ROLE, _msgSender()) || 
            morpherAccessControl.hasRole(BURNER_ROLE, _msgSender()) || 
            morpherAccessControl.hasRole(TRANSFER_ROLE, from)
            , "MorpherToken: Transfer denied");

        require(!morpherAccessControl.hasRole(TRANSFERBLOCKED_ROLE, _msgSender()), "MorpherToken: Transfer for User is blocked.");

        super._beforeTokenTransfer(from, to, amount);
    }
}