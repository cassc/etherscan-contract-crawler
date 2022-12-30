// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./eUSD_AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./WhitelistUpgradeable.sol";

/**
 * @dev eUSD token
 */
contract ARYZE_eUSD is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    WhitelistUpgradeable
{
    /**
     * @dev Define roles
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Default address for roles
     */
    address private multiSigTreasury;

    mapping(string => bool) private _transactions; // Bridge transactions for prevent recurrence of the transaction
    /**
     * @dev Emitted when the bridge transaction is triggered by BridgeOwner
     */
    event Reforged(address indexed account, uint256 amount, string indexed transaction);
    /**
     * @dev Emitted when the bridge transaction is triggered by `account`.
     */
    event SentToChain(
        address indexed account,
        uint256 amount,
        uint256 fromChainId,
        uint256 indexed destinationChainId,
        address indexed destinationToken
    );
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event BridgePaused(address account);
    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event BridgeUnpaused(address account);
    /**
     * @dev Define bridge owner role
     */
    bytes32 public constant BRIDGE_OWNER_ROLE = keccak256("BRIDGE_OWNER_ROLE");
    /**
     * @dev bridge owner. Should be payable to receive transaction fee
     */
    address payable private _bridgeOwner;
    /**
     * @dev Bridge transactions fee in native currency
     */
    uint256 private _minimumBridgeFee;
    /**
     * @dev Bridge transactions fee
     */
    bool private _bridgePaused;
    /**
     * @dev Bridge transactions fee percentage (10**6 = 1%)
     */
    uint256 private _bridgeFee;
    /**
     * @dev SendToChain minimum required amount
     */
    uint256 private _minimumSendToChainAmount;
    /**
     * @dev feeTreasury
     */
    address private _feeTreasury;
    /**
     * @dev Map of addresses this token on another chains
     */
    mapping(uint256 => address) private _sameTokens;

    function initialize() public initializer {
        __ERC20_init("ARYZE eUSD", "eUSD");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        multiSigTreasury = 0x9D6D54dc7E2FDF018D94fbd71Ed23e49aE31639B;
        /**
         *  Deploying the contract requires msg.sender being admin, to create proxy adress while doing deployment.
         */
        _grantRole(ADMIN_eUSD, msg.sender);
        _grantRole(ADMIN_eUSD, multiSigTreasury);
        _grantRole(PAUSER_ROLE, multiSigTreasury);
        _grantRole(MINTER_ROLE, multiSigTreasury);
        _grantRole(UPGRADER_ROLE, multiSigTreasury);
        setMinimumFee(0);
        setMinimumSentToChainAmount(10000 * (10**uint256(decimals())));
        setBridgeFee(3 * 100000); //0.3%
        setFeeTreasury(multiSigTreasury);
    }

    /**
     * @dev Pause functions that marked by "whenNotPaused" modificator
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause functions that marked by "whenNotPaused" modificator
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Mint tokens to address
     * @param to address of recipient
     * @param amount amount of tokens for minting
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(_whitelist[to], "Address is not in whitelist");
        _mint(to, amount);
    }

    /**
     * @dev override hook that will be called before tranferring funds.
     * Added "whenNotPaused" modificator which is needed for pause/unpause functionality
     * @param from address of sender
     * @param to address of recipient
     * @param amount amount of tokens for transferring
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev An upgradeability mechanism designed for UUPS proxies.
     * This function is overriden to include access restriction to the upgrade mechanism.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Function add address to whitelist, which is used for storing customers allowed to receive minted tokens
     * @param account address which will be added to whitelist
     */
    function addToWhitelist(address account) public onlyRole(ADMIN_eUSD) {
        _addToWhitelist(account);
    }

    /**
     * @dev Function remove address from whitelist, which is used for storing customers allowed to receive minted tokens
     * @param account address which will be removed to whitelist
     */
    function removeFromWhitelist(address account) public onlyRole(ADMIN_eUSD) {
        _removeFromWhitelist(account);
    }

    /**
     * @dev Mint tokens to account by Bridge
     * @param to `address`, token will be burned from
     * @param amount `amount` of token that will be burned
     * @param fee `amount` of token that will be sended to bridge owner
     * @param rate information about the current exchange rate
     * @param sourceChainId id of the chain from where the tokens were sent
     * @param transaction `transaction` on the chain from where the tokens were sent
     */
    function reforge(
        address to,
        uint256 amount,
        uint256 fee,
        string memory rate,
        uint256 sourceChainId,
        string memory transaction
    ) public onlyRole(BRIDGE_OWNER_ROLE) onlyRole(MINTER_ROLE) {
        require(_transactions[transaction] == false, "Already processed!");
        _mint(to, amount);
        if (fee != 0) {
            _mint(_bridgeOwner, fee);
        }
        _transactions[transaction] = true;
        emit Reforged(to, amount, transaction);
    }

    /**
     * @dev Burn tokens from account and emit event for Bridge
     * @param amount `amount` of token that will be burned
     * @param destinationChainId bridge will reforge token on this chain
     * @param destinationToken bridge will reforge this token on destination chain
     */
    function sendToChain(
        uint256 amount,
        uint256 destinationChainId,
        address destinationToken
    ) public payable {
        require(_bridgePaused == false, "Bridge paused");
        require(msg.value >= _minimumBridgeFee, "Fee too small");
        if (_sameTokens[destinationChainId] != destinationToken) {
            require(amount >= _minimumSendToChainAmount, "Amount < Minimum amount");
        }
        require(address(0) != destinationToken, "Destination token undefined");
        uint256 fee = (amount * _bridgeFee) / 100000000; // fee 1% == 1000000
        require(amount > fee, "Fee > 100%");
        uint256 res = amount - fee;
        transfer(_feeTreasury, fee);
        burn(res);
        _bridgeOwner.transfer(msg.value);
        emit SentToChain(msg.sender, amount - fee, block.chainid, destinationChainId, destinationToken);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function bridgePaused() public view returns (bool) {
        return _bridgePaused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function bridgePause() public onlyRole(ADMIN_eUSD) {
        require(_bridgePaused == false, "Bridge paused");
        _bridgePaused = true;
        emit BridgePaused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function bridgeUnpause() public onlyRole(ADMIN_eUSD) {
        require(_bridgePaused, "Bridge not paused");
        _bridgePaused = false;
        emit BridgeUnpaused(_msgSender());
    }

    /**
     * @dev set minimum value of bridge transaction fee
     * @param fee amount in wei of minimum payment for transaction
     */
    function setMinimumFee(uint256 fee) public onlyRole(ADMIN_eUSD) {
        _minimumBridgeFee = fee;
    }

    /**
     * @dev get minimum value of bridge transaction fee
     */
    function minimumFee() public view returns (uint256) {
        return _minimumBridgeFee;
    }

    /**
     * @dev set minimum percentage of bridge transaction fee
     * @param percent 1000000 ==1%
     */
    function setBridgeFee(uint256 percent) public onlyRole(ADMIN_eUSD) {
        require(percent <= 100000000, "Fee can't be > 100%");
        _bridgeFee = percent;
    }

    /**
     * @dev get minimum percentage of bridge transaction fee
     */
    function bridgeFee() public view returns (uint256, string memory) {
        uint256 bFeeFloat = _bridgeFee % 1000000;
        uint256 bFeeRound = _bridgeFee / 1000000;
        uint8 length = 10;
        bytes memory bstr = new bytes(length);
        uint8 notZero = length - 1;
        uint8 temp = 0;
        bstr[1] = bytes1(uint8(48 + (bFeeRound % 10)));
        bFeeRound /= 10;
        if (bFeeRound > 0) {
            bstr[0] = bytes1(uint8(48 + (bFeeRound % 10)));
        }
        if (bFeeFloat > 0) {
            bstr[2] = bytes1(uint8(46)); // .
            for (uint8 i = 6; i > 0; i--) {
                temp = uint8(bFeeFloat % 10);
                if (temp != 0 || notZero != length - 1) {
                    bstr[notZero] = bytes1(uint8(48 + temp));
                    notZero--;
                }
                bFeeFloat /= 10;
            }
        }
        string memory res = string.concat(string(bstr), "%");
        return (_bridgeFee, res);
    }

    /**
     * @dev set minimum percentage of bridge transaction fee
     */
    function setMinimumSentToChainAmount(uint256 amount) public onlyRole(ADMIN_eUSD) {
        _minimumSendToChainAmount = amount;
    }

    /**
     * @dev get minimum percentage of bridge transaction fee
     */
    function minimumSentToChainAmount() public view returns (uint256) {
        return _minimumSendToChainAmount;
    }

    /**
     * @dev Set up bridgeOwner
     * @param account address of new bridgeOwner
     */
    function setBridgeOwner(address payable account) public onlyRole(ADMIN_eUSD) {
        require(account != address(0), "Zero address");
        _revokeRole(BRIDGE_OWNER_ROLE, _bridgeOwner);
        _revokeRole(MINTER_ROLE, _bridgeOwner);
        _bridgeOwner = account;
        _grantRole(BRIDGE_OWNER_ROLE, _bridgeOwner);
        _grantRole(MINTER_ROLE, _bridgeOwner);
    }

    /**
     * @dev Set up new fee treasury
     * @param account address of new fee treasury
     */
    function setFeeTreasury(address account) public onlyRole(ADMIN_eUSD) {
        require(account != address(0), "Zero address");
        _feeTreasury = account;
    }

    /**
     * @dev Get treasury fee
     */
    function feeTreasury() public view returns (address) {
        return _feeTreasury;
    }

    /**
     * @dev Add version of this token on another chain. Required for calculating correct minimum amount of reforging
     * @param chainId Chain Id of required chain in decimal format
     * @param token addtess of `token` on required chain
     */
    function addSameToken(uint256 chainId, address token) public onlyRole(ADMIN_eUSD) {
        require(_sameTokens[chainId] == address(0), "First should remove");
        _sameTokens[chainId] = token;
    }

    /**
     * @dev Remove version of this token on another chain. Required for calculating correct minimum amount of reforging
     * @param chainId Chain Id of required chain in decimal format
     */

    function removeSameToken(uint256 chainId) public onlyRole(ADMIN_eUSD) {
        _sameTokens[chainId] = address(0);
    }

    /**
     * @dev Get address of the same token on another chain
     * @param chainId  Chain Id of required chain in decimal format
     */
    function sameToken(uint256 chainId) public view returns (address) {
        return _sameTokens[chainId];
    }
}