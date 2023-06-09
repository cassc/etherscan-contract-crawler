// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/UniversalERC20.sol";

contract FeeCollector {
    using UniversalERC20 for IERC20;

    // Partner -> TokenAddress -> Balance
    mapping(address => mapping(address => uint256)) private _balances;
    // TokenAddress -> Balance
    mapping(address => uint256) private _swingBalances;
    address public owner;
    address public partnerAddress;
    address public protocolAddress;
    uint256 public partnerShare;
    uint256 public constant BASE = 10000;

    /// Events ///
    event FeesCollected(address indexed _token, address indexed _partner, uint256 _partnerFee, uint256 _swingFee);
    event FeesWithdrawn(address indexed _token, address indexed _partner, address indexed _to, uint256 _amount);
    event SwingFeesWithdrawn(address indexed _token, address indexed _owner, address indexed _to, uint256 _amount);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor (address _owner) public {
        owner = _owner;
    }

    /// @notice Collects fees for the partner
    /// @param tokenAddress address of the token to collect fees for
    /// @param partnerFee amount of fees to collect going to the partner
    /// @param swingFee amount of fees to collect going to swing
    /// @param partnerAddress address of the partner
    function collectTokenFees(
        address tokenAddress,
        uint256 partnerFee,
        uint256 swingFee,
        address partnerAddress
    ) external payable {
        IERC20(tokenAddress).universalTransferFrom(msg.sender, address(this), partnerFee + swingFee);
        _balances[partnerAddress][tokenAddress] += partnerFee;
        _swingBalances[tokenAddress] += swingFee;
        emit FeesCollected(tokenAddress, partnerAddress, partnerFee, swingFee);
    }

    function withdrawPartnerFees(address[] memory tokenAddresses, address receiver) external {
        uint256 length = tokenAddresses.length;
        uint256 balance;
        for (uint256 i = 0; i < length; i++) {
            balance = _balances[msg.sender][tokenAddresses[i]];
            if (balance == 0) {
                continue;
            }
            _balances[msg.sender][tokenAddresses[i]] = 0;
            IERC20(tokenAddresses[i]).universalTransfer(receiver, balance);
            emit FeesWithdrawn(tokenAddresses[i], msg.sender, receiver, balance);
        }
    }

    function withdrawSwingFees(address[] memory tokenAddresses, address receiver) external onlyOwner {
        uint256 length = tokenAddresses.length;
        uint256 balance;
        for (uint256 i = 0; i < length; i++) {
            balance = _swingBalances[tokenAddresses[i]];
            if (balance == 0) {
                continue;
            }
            _swingBalances[tokenAddresses[i]] = 0;
            IERC20(tokenAddresses[i]).universalTransfer(receiver, balance);
            emit SwingFeesWithdrawn(tokenAddresses[i], msg.sender, receiver, balance);
        }
    }

    function getTokenBalance(address partnerAddress, address[] memory tokenAddresses) external view returns (uint256[] memory) {
        uint256 length = tokenAddresses.length;
        uint256[] memory partnerBalances = new uint[](length);
        for (uint256 i = 0; i < length; i++) {
            partnerBalances[i] = _balances[partnerAddress][tokenAddresses[i]];
        }
        return partnerBalances;
    }

    function getSwingTokenBalance(address[] memory tokenAddresses) external view returns (uint256[] memory) {
        uint256 length = tokenAddresses.length;
        uint256[] memory swingBalances = new uint[](length);
        for (uint256 i = 0; i < length; i++) {
            swingBalances[i] = _swingBalances[tokenAddresses[i]];
        }
        return swingBalances;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(msg.sender, owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

}