// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./interfaces/IEON.sol";

contract EON is IEON, ERC20 {
    // Tracks the last block that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => uint256) private lastWrite;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;
    //ower
    address public auth;
    // hardcoded max eon supply 5b
    uint256 public constant MAX_EON = 5000000000 ether;

    // amount minted
    uint256 public minted;

    constructor() ERC20("EON", "EON", 18) {
        auth = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        auth = newOwner;
    }

    /**
     * mints $EON to a recipient
     * @param to the recipient of the $EON
     * @param amount the amount of $EON to mint
     */
    function mint(address to, uint256 amount) external override {
        require(admins[msg.sender], "Only admins can mint");
        minted += amount;
        _mint(to, amount);
    }

    /**
     * burns $EON from a holder
     * @param from the holder of the $EON
     * @param amount the amount of $EON to burn
     */
    function burn(address from, uint256 amount) external override {
        require(admins[msg.sender], "Only admins");
        _burn(from, amount);
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
    ) public virtual override(ERC20, IEON) returns (bool) {
        // caught yah
        require(
            admins[msg.sender] || lastWrite[sender] < block.number,
            "hmmmm what are you doing?"
        );
        // If the entity invoking this transfer is an admin (i.e. the gameContract)
        // allow the transfer without approval. This saves gas and a transaction.
        // The sender address will still need to actually have the amount being attempted to send.
        if (admins[msg.sender]) {
            // NOTE: This will omit any events from being written. This saves additional gas,
            // and the event emission is not a requirement by the EIP
            // (read this function summary / ERC20 summary for more details)
            emit Transfer(sender, recipient, amount);
            return true;
        }

        // If it's not an admin entity (Shattered EON contract, pytheas, refinery. etc)
        // The entity will need to be given permission to transfer these funds
        // For instance, someone can't just make a contract and siphon $EON from every account
        return super.transferFrom(sender, recipient, amount);
    }
}