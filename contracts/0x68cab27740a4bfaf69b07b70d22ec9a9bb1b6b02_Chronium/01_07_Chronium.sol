// contracts/Chronium.sol
// SPDX-License-Identifier: MIT
pragma solidity = 0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/*
 *      Chronium: Time-minted ERC20 token.
 *
 *          - Chronium is minted using time balance based on block.number - timestamp.
 *          - Because time is non-fungible between accounts, this contract can allow individual time to be transferred and tracked under "sub"-account.
 *            This can be use to borrow or reserve a third-party's time.
 *
 */

contract Chronium is ERC20, Ownable {
    using Address for address;
    mapping(address=>uint256)                   public timestamp;                                  // time balance = block.number - timestamp
    mapping(address=>mapping(address=>uint256)) public transferrableTimeBalances;
    uint256                                     public deployed;
    bytes32                                     public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor (
        string  memory name, 
        string  memory symbol, 
        address governance
        ) ERC20(name,symbol)
    {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
        transferOwnership(governance);
        deployed = block.number;
        startTime();
    }

    // ERC20 --------------------------------------------------------------------

    function decimals() 
    public pure override returns(uint8)
    {
        return 1;
    }

    function mint(address recipient, uint256 time, uint256 amt) 
    onlyOwner
    external returns(bool)
    {
        _decreaseTime(recipient,time);
        _mint(recipient,amt);
        return true;
    }

    // EIP2612: https://eips.ethereum.org/EIPS/eip-2612
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Chronium: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                hex"1901",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Chronium: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    // TIME -------------------------------------------------------------

    /** 
    *   Start tracking the timestamp. Time balance is 1 after this block is mined.
    */
    event LogStartTime(address Account,uint256 Amount);
    function startTime()
    public returns(bool)
    {
        if (timestamp[_msgSender()]==0)
        {
            timestamp[_msgSender()]=block.number;
            emit LogStartTime(_msgSender(), 0);
        }
        return true;
    }

    /**
     *  Check time balance    
     */
    function checkTimeBalance(address timeOwner)
    public view returns(uint256)
    {
        require(timestamp[timeOwner]>0, "Chronium: NO_TIME_ACCOUNT");
        return block.number - timestamp[timeOwner];
    }

    // EMISSION --------------------------------------------------------------

    /**
     * Time is decreased by moving the timestamp forward and cannot be more than or equal to current block time.
     */
    function _decreaseTime(address sender, uint256 time)
    internal
    {
        uint256 timeBalance = checkTimeBalance(sender);
        require(timeBalance > time, "Chronium: NOT_ENOUGH_TIME");
        timestamp[sender] += time;
    }

    function decreaseTime(address sender, uint256 time)
    onlyOwner
    external
    {
        _decreaseTime(sender,time);
    }

    /**
     * Time is increased by moving the timestamp backward (rewinding time)
     */ 
    function _increaseTime(address sender, uint256 time)
    internal
    {
        require (time < timestamp[sender],"Chronium: NOT_ENOUGH_BLOCKS");        
        unchecked {
            timestamp[sender] -= time;
        }
    }

    function increaseTime(address sender, uint256 time) 
    onlyOwner 
    external
    {
        _increaseTime(sender,time);
    }

    // TIME TRANSFERRABILITY -----------------------------------------------------

    /**
     *  Transfer sender's own time and add to the sender's subaccount under the recipient
     */
    event LogTransferOwnTime(address sender, address recipient, uint256 amount);
    function transferOwnTime(
        address recipient,
        uint256 amount
        ) 
    external virtual returns (bool) {
        _decreaseTime(_msgSender(),amount);
        transferrableTimeBalances[recipient][_msgSender()] += amount;
        emit LogTransferOwnTime(_msgSender(), recipient, amount);
        return true;
    }

    /**
     *   Return transferred originator's time under the sender's subaccount back to the originator
     */
    event LogReturnOtherTime(address sender, address originator, uint256 amount);
    function returnOtherTime(
        address originator,
        uint256 amount
        ) 
    external virtual returns (bool) {
        require(transferrableTimeBalances[_msgSender()][originator] >= amount,"Chronium: NOT_ENOUGH_TIME");
        _increaseTime(originator,amount);
        transferrableTimeBalances[_msgSender()][originator] -= amount;
        emit LogReturnOtherTime(_msgSender(), originator, amount);
        return true;
    }

     /**
     *   Transfer originator's time from own subaccount to others
     */
    event LogTransferOtherTime(address sender, address originator, address recipient, uint256 amount);
    function TransferOtherTime(
        address originator,
        address recipient,
        uint256 amount
        ) 
    external virtual returns (bool) {
        require(transferrableTimeBalances[_msgSender()][originator] >= amount,"Chronium: NOT_ENOUGH_TIME");
        transferrableTimeBalances[_msgSender()][originator] -= amount;
        transferrableTimeBalances[recipient][originator] += amount;
        emit LogTransferOtherTime(_msgSender(), originator, recipient, amount);
        return true;
    }

}