// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PsionicFarmVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // @TODO: ADD A REWARDS TOKEN LENGTH VARIABLE
    // @TODO: ADD EVENTS

    // Mapping that contains the reward tokens
    mapping (address => bool) tokens;
    address[] public rewardTokens;

    address public farm;
    // Whether it is initialized
    bool public isInitialized;

    // Address of the Psionic Factory
    address public PSIONIC_FACTORY;

    // transfering tokens
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // Only farming modifier
    modifier onlyFarm() {
        require(msg.sender == farm, "Only Farm is allowed");
        _;
    }
    constructor() ERC20("Psionic", "PT") {
        PSIONIC_FACTORY = msg.sender;
    }

    /*
     *   @notice: Initialize the contract
     *   @param _tokens: array of tokens
     *   @param _initialSupply: supply to mint initially
     *   @param _farm: Farm Address
    */
    function initialize(
        address[] memory _rewardTokens,
        uint _initialSupply,
        address _farm,
        address _admin
    )  external  {
        require(!isInitialized, "Already initialized");
        require(msg.sender == PSIONIC_FACTORY, "Not factory");
        require(_rewardTokens.length > 0, "Empty reward tokens");

        // Make this contract initialized
        isInitialized = true;

        // Saving tokens
        rewardTokens = _rewardTokens;

        uint tokenLength = _rewardTokens.length;

        for (uint256 i = 0; i < tokenLength; i++) {
            address token = _rewardTokens[i];
            bool isToken = tokens[token];
            if (isToken) {
                revert("Tokens must be unique");
            }else{
                tokens[token] = true;
            }
        }
        // Minting initial Supply to Psionic Farm
        _mint(_farm, _initialSupply);

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
        farm = _farm;
    }

    // @notice Admin method to add reward token
    function add(address token) external onlyOwner {
        require(!tokens[token], "Vault: Token already added");
        tokens[token] = true;
        rewardTokens.push(token);
    }

    // @notice Admin method to remove reward token
    function remove(address token) external onlyOwner {
        require(tokens[token], "Vault: Token not added");
        require(rewardTokens.length > 1, "At least 1 token is required");
        address[] memory _tokens = rewardTokens;
        uint tokenLength = _tokens.length;
        for (uint256 i = 0; i < tokenLength; i++) {
            address rewardToken = _tokens[i];
            if (token == rewardToken) {
                tokens[token] = false;
                rewardTokens[i] = rewardTokens[rewardTokens.length-1];
                rewardTokens.pop();
                break;
            }
        }
    }

    function modifyRewards(address token, uint amount) onlyOwner external {
        IERC20(token).safeTransfer(owner(), amount);
    }

    /*
    *   @notice Mints amount of tokens to the owner
    *   @param _amount: of tokens to mint
    */
    function adjust(uint _amount, bool shouldMint) external onlyFarm nonReentrant {
        if (shouldMint) {
            _mint(address(owner()), _amount);
        } else {
            _burn(address(owner()), _amount);
        }
    }

    /*
    *   @notice Burn Function to withdraw tokens
    *   @param _to: the address to send the rewards token
    */
    function burn(address _to, uint _liquidity) external onlyFarm nonReentrant {
        require(_to != address(0), "PFV: Invalid address");
        require(_liquidity > 0, "PFV: Not enough");
        address[] memory tokensToWithdraw = rewardTokens;
        uint tokenLength = tokensToWithdraw.length;
        uint ts = totalSupply();

        for (uint256 i = 0; i < tokenLength; i++) {
            IERC20 token = IERC20(tokensToWithdraw[i]);
            uint balance = token.balanceOf(address(this));
            uint amount = (balance * (_liquidity))/ts;
            token.safeTransfer(_to, amount);
        }
        _burn(farm, _liquidity);
    }

}