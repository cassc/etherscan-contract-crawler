// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "./ERC20Mintable.sol";
import "./ERC20Standard.sol";
import "./ERC20Burnable.sol";

contract CoinSenderFactory is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    event ERC20TokenCreated(address ownerAddress, address tokenAddress);

    address public bank;
    uint256 public minFee;

    // ownerAddress => tokenAddreses
    mapping(address => address[]) public tokenOwners;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function _authorizeUpgrade(address newImplementation)
    internal
    virtual
    override
    onlyOwner
    {}

    receive() external payable {}
    fallback() external payable {}

    function initialize(address _owner, uint256 _minFee) public initializer {
        require(_owner != address(0), "CoinSenderV2: Owner address is not set");

        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        transferOwnership(_owner);
        bank = _owner;
        minFee = _minFee;
    }

    function deployNewERC20Token(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply,
        uint256 maxTotalSupply,
        uint8 tokenType,
        uint256 fee
    ) public payable returns (address) {
        require(tokenType > 0 && tokenType <= 3, "Invalid token type");
        _processFee(fee);

        (address tokenAddress) = _deploy(
            name,
            symbol,
            decimals,
            initialSupply,
            maxTotalSupply,
            tokenType
        );

        require(tokenAddress != address(0), "Token deployment failed");

        tokenOwners[_msgSender()].push(tokenAddress);

        emit ERC20TokenCreated(_msgSender(), address(tokenAddress));

        return address(tokenAddress);
    }

    function _deploy(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 supply,
        uint256 maxTotalSupply,
        uint8 tokenType
    ) private returns(address tokenAddress) {

        if(tokenType == 1) {
            tokenAddress = address(
                new ERC20Standard(name, symbol, decimals, supply, _msgSender())
            );
        } else if (tokenType == 2) {
            tokenAddress = address(
                new ERC20Burnable(name, symbol, decimals, supply, _msgSender())
            );
        } else if(tokenType == 3) {
            tokenAddress = address(
                new ERC20Mintable(name, symbol, decimals, supply, maxTotalSupply, _msgSender())
            );
        }

        return tokenAddress;
    }

    /**
    @notice Returns any excess ether sent to the contract back to the sender.
    @dev If the amount sent is greater than the total fee, the difference is returned to the sender.
    @param _fee - the total fee amount paid by the sender
    */
    function _processFee(uint256 _fee) private {
        require(msg.value >= _fee && _fee >= minFee, "Insufficient fee amount");

        if (_fee > 0) {
            payable(bank).transfer(_fee);
        }

        uint256 excess = msg.value.sub(_fee);
        if (excess > 0) {
            payable(_msgSender()).transfer(excess);
        }
    }

    function _msgSender()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[99] private __gap;
}