// SPDX-License-Identifier: Apache License 2.0

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import "./utils/ERC1404.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract that implements the Delphia Platform Token to manage the Bonding Curve
/// @dev This Token is being bonded in the Bonding Curve to gain Phi
///      which is being used in the games. Delphia Platform Token is strictly managed and
///      only whitelisted stakeholders are allowed to own it.
///      Reference implementation of ERC1404 can be found here:
///      https://github.com/simple-restricted-token/reference-implementation/blob/master/contracts/token/ERC1404/ERC1404ReferenceImpl.sol
///      https://github.com/simple-restricted-token/simple-restricted-token/blob/master/contracts/token/ERC1404/SimpleRestrictedToken.sol
contract DelphiaPlatformToken is ERC1404, Ownable {

    uint8 constant private SUCCESS_CODE = 0;
    uint8 constant private ERR_RECIPIENT_CODE = 1;
    uint8 constant private ERR_BONDING_CURVE_CODE = 2;
    uint8 constant private ERR_NOT_WHITELISTED_CODE = 3;
    string constant private SUCCESS_MESSAGE = "DelphiaPlatformToken: SUCCESS";
    string constant private ERR_RECIPIENT_MESSAGE = "DelphiaPlatformToken: RECIPIENT SHOULD BE IN THE WHITELIST";
    string constant private ERR_BONDING_CURVE_MESSAGE = "DelphiaPlatformToken: CAN TRANSFER ONLY TO BONDING CURVE";
    string constant private ERR_NOT_WHITELISTED_MESSAGE = "DelphiaPlatformToken: ONLY WHITELISTED USERS CAN TRANSFER TOKEN";


    struct Role {
        bool awo;
        bool sco;
    }

    mapping(address => Role) public operators;
    mapping(address => bool) public whitelist;
    address public bondingCurve;


    event NewStakeholder(address stakeholer);
    event RemovedStakeholder(address stakeholer);
    event NewSCO(address operator);
    event RemovedSCO(address operator);
    event NewAWO(address operator);
    event RemovedAWO(address operator);

    /// @dev Reverts if the caller is not a Securities Control Operator or an owner
    modifier onlySCOperator() {
        require(owner() == msg.sender || operators[msg.sender].sco == true,
            "DelphiaPlatformToken: Only SC operators can mint/burn token");
        _;
    }

    /// @dev Reverts if the caller is not an Accreditation Whitelist Operator or an owner
    modifier onlyAWOperator() {
        require(owner() == msg.sender || operators[msg.sender].awo == true,
            "DelphiaPlatformToken: Only AW operators can change whitelist");
        _;
    }

    /// @dev Checks if transfer of 'value' amount of tokens from 'from' to 'to' is allowed
    /// @param from address of token sender
    /// @param to address of token receiver
    /// @param value amount of tokens to transfer
    modifier notRestricted (address from, address to, uint256 value) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    /// @notice Constructor function of the token
    /// @param name Name of the token as it will be in the ledger
    /// @param symbol Symbol that will represent the token
    constructor(string memory name, string memory symbol)  ERC20(name, symbol) {}

    /// @notice Function to add AWO
    /// @dev Only owner can add AWO
    /// @param operator Address of the AWO
    function addAWOperator(address operator) external onlyOwner{
        require(operators[operator].awo == false,
            "DelphiaPlatformToken.addAWOperator: Operator already exists");
        operators[operator].awo = true;
        emit NewAWO(operator);
    }

    /// @notice Function to add SCO
    /// @dev Only owner can add SCO
    /// @param operator Address of the SCO
    function addSCOperator(address operator) external onlyOwner{
        require(operators[operator].sco == false,
            "DelphiaPlatformToken.addSCOperator: Operator already exists");
        operators[operator].sco = true;
        emit NewSCO(operator);
    }

    /// @notice Function to remove AWO
    /// @dev Only owner can remove AWO
    /// @param operator Address of the AWO
    function removeAWOperator(address operator) external onlyOwner{
        require(operators[operator].awo == true,
            "DelphiaPlatformToken.removeAWOperator: There is no such operator");
        operators[operator].awo = false;
        emit RemovedAWO(operator);
    }

    /// @notice Function to remove SCO
    /// @dev Only owner can remove SCO
    /// @param operator Address of the SCO
    function removeSCOperator(address operator) external onlyOwner{
        require(operators[operator].sco == true,
            "DelphiaPlatformToken.removeSCOperator: There is no such operator");
        operators[operator].sco = false;
        emit RemovedSCO(operator);
    }

    /// @notice Function to mint DelphiaPlatformToken
    /// @dev Only SCO can mint tokens to the whitelisted addresses
    /// @param account Address of the token receiver
    /// @param amount Amount of minted tokens
    function mint(address account, uint256 amount) external onlySCOperator{
        require(whitelist[account] == true,
            "DelphiaPlatformToken.mint: Only whitelisted users can own tokens");
        _mint(account, amount);
    }

    /// @notice Function to burn DelphiaPlatformToken
    /// @dev Only SCO can burn tokens from addresses
    /// @param account Address from which tokens will be burned
    /// @param amount Amount of burned tokens
    function burn(address account, uint256 amount) external onlySCOperator{
        _burn(account, amount);
    }

    /// @notice Function to add address to Whitelist
    /// @dev Only AWO can add address to Whitelist
    /// @param account Address to add to the Whitelist
    function addToWhitelist(address account) public onlyAWOperator{
        whitelist[account] = true;
        emit NewStakeholder(account);
    }

    /// @notice Function to remove address from Whitelist
    /// @dev Only AWO can remove address from Whitelist on removal from the list user loses all of the tokens
    /// @param account Address to remove from the Whitelist
    function removeFromWhitelist(address account) external onlyAWOperator{
        require(whitelist[account] == true,
            "DelphiaPlatformToken.removeFromWhitelist: User not in whitelist");
        require(account != bondingCurve,
            "DelphiaPlatformToken.removeFromWhitelist: Can't del bondingCurve");
        whitelist[account] = false;
        emit RemovedStakeholder(account);
    }

    /// @notice Function to check the restriction for token transfer
    /// @param from address of sender
    /// @param to address of receiver
    /// @param value amount of tokens to transfer
    /// @return restrictionCode code of restriction for specific transfer
    function detectTransferRestriction (address from, address to, uint256 value)
        public
        view
        override
        returns (uint8 restrictionCode)
    {
        require(value > 0, "DelphiaPlatformToken: need to transfer more than 0.");
        if(from == bondingCurve){
            if(whitelist[to] == true){
                restrictionCode = SUCCESS_CODE;
            } else {
                restrictionCode = ERR_RECIPIENT_CODE;
            }
        } else if (whitelist[from]){
            if(to == bondingCurve){
                restrictionCode = SUCCESS_CODE;
            } else {
                restrictionCode = ERR_BONDING_CURVE_CODE;
            }
        } else{
            restrictionCode = ERR_NOT_WHITELISTED_CODE;
        }
    }


    /// @notice Function to return restriction message based on the code
    /// @param restrictionCode code of restriction
    /// @return message message of restriction for specific code
    function messageForTransferRestriction (uint8 restrictionCode)
        public
        pure
        override
        returns (string memory message)
    {
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        } else if (restrictionCode == ERR_RECIPIENT_CODE) {
            message = ERR_RECIPIENT_MESSAGE;
        } else if (restrictionCode == ERR_BONDING_CURVE_CODE) {
            message = ERR_BONDING_CURVE_MESSAGE;
        } else {
            message = ERR_NOT_WHITELISTED_MESSAGE;
        }
    }


    /// @notice Function to transfer tokens between whitelisted users
    /// @param to Address to which tokens are sent
    /// @param value Amount of tokens to send
    function transfer(address to, uint256 value)
        public
        override
        notRestricted(msg.sender, to, value)
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @notice Function to transfer tokens from some another address(used after approve)
    /// @dev Only Whitelisted addresses that have the approval can send or receive tokens
    /// @param sender Address that will be used to send tokens from
    /// @param recipient Address that will receive tokens
    /// @param amount Amount of tokens that may be sent
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        notRestricted(sender, recipient, amount)
        returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /// @notice Function to set BondingCurve address for the contract
    /// @param curve address of the BondingCurve
    function setupBondingCurve(address curve) external onlyOwner {
        whitelist[bondingCurve] = false;
        bondingCurve = curve;
        whitelist[bondingCurve] = true;
    }


    /// @notice Function to check if user is in a whitelist
    /// @param user Address to check
    /// @return If address is in a whitelist
    function isInWhitelist(address user) external view returns (bool) {
        return whitelist[user];
    }
}