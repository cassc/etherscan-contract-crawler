// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AxisMundiERC1155.sol";


/// @title Axis Mundi - Energies
/// @author [email protected]
/// @custom:project-website  https://www.axismundi.art/
/// @custom:security-contact [email protected]
contract AxisMundiEnergies is AxisMundiERC1155 {

    uint256 public version;

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    address private _beingsContract;

    event EthersWithdrawn(address indexed payee, uint256 weiAmount);

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE` and `URI_SETTER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC1155-constructor}.
     */
    function initialize(string memory uri, uint256 initialSupply) initializer public {
        __AxisMundiERC1155_init(uri);

        if(initialSupply > 0){
            _mintWithAmount(msg.sender, 1, initialSupply);
        }
        version = 1;
    }

    /**
     * @dev Returns the address of the beings contract.
     */
    function getBeingsContract() virtual public view returns(address) {
        return address(_beingsContract);
    }

    /**
     * @dev Sets the address of the beings contract.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setBeingsContract(address beingsContract ) virtual public onlyRole(DEFAULT_ADMIN_ROLE) {
        _beingsContract = beingsContract ;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minting must not be paused.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if(_beingsContract != address(0) && _beingsContract == operator){
            return true;
        }
        return super.isApprovedForAll(account, operator);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount) virtual public onlyRole(MINTER_ROLE) {
        _mintWithAmount(to, id, amount);
    }

    function balanceEthers() virtual public view returns(uint256) {
        return address(this).balance;
    }

    /**
     * @dev Withdraws all ethers from the contract.
     *
     * Requirements:
     *
     * - the caller must have the `WITHDRAW_ROLE`.
     */
    function withdrawEthers() virtual external onlyRole(WITHDRAW_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

        emit EthersWithdrawn(msg.sender, balance);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        version ++;
    }
}